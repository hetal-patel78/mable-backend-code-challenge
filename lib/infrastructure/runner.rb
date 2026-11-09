# frozen_string_literal: true

require 'logger'
require_relative '../domain/account_repository'
require_relative '../application/errors'
require_relative '../application/process_daily_transfer'
require_relative 'balances_csv_reader'
require_relative 'display_path'
require_relative 'errors'
require_relative 'final_balances_csv_writer'
require_relative 'report_printer'
require_relative 'transfers_csv_reader'

# Runs the day from the command line: works out the paths, builds the parts and returns the exit status.
class Runner
  PROJECT_ROOT = File.expand_path('../..', __dir__)
  DEFAULT_INPUTS = %w[data/mable_account_balances.csv data/mable_transactions.csv].freeze
  STOPPING_ERRORS = [InvalidBalancesFile, NoTransfers, TotalChanged, UnreadableFile, OutputNotWritable].freeze
  ARGUMENT_COUNTS = [0, 2, 3].freeze
  USAGE = "Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]\n" \
          "With no arguments, runs the sample files in data/.\n"

  def initialize(stdout: $stdout, stderr: $stderr, env: ENV)
    @stdout = stdout
    @stderr = stderr
    @env = env
  end

  def run(arguments)
    return usage unless ARGUMENT_COUNTS.include?(arguments.size)

    logger = Logger.new(@stderr, level: log_level)
    run_time = Time.now
    balances, transfers, output = paths(arguments, run_time)
    problems = start_problems(balances, transfers, output)
    return stop_at_start(problems, logger) if problems.any?

    day(run_time, logger).call(DisplayPath.of(balances), DisplayPath.of(transfers), output)
    0
  rescue *STOPPING_ERRORS => e
    stop(e, logger)
  end

  private

  def usage
    @stderr.print(USAGE)
    1
  end

  # Only "info", in any letter case, gives info. Anything else gives warn, and so does an unset LOG_LEVEL:
  # it is nil, and nil.to_s is "".
  def log_level
    @env['LOG_LEVEL'].to_s.casecmp?('info') ? Logger::INFO : Logger::WARN
  end

  def paths(arguments, run_time)
    [*input_paths(arguments), output_path(arguments, run_time)]
  end

  def start_problems(balances, transfers, output)
    problems = [balances, transfers].reject { |path| File.exist?(path) }.map do |path|
      ["file not found: #{DisplayPath.of(path)}", 'file not found']
    end
    # Only an existing file is refused here; a folder at the output path fails when the writer opens it.
    problems << output_exists(output) if File.file?(output)
    problems
  end

  def output_exists(output)
    ["output file already exists: #{DisplayPath.of(output)}. Delete it or give another output path.",
     'output file already exists']
  end

  def stop_at_start(problems, logger)
    @stderr.puts(problems.map { |message, _reason| "Error: #{message}" })
    logger.error("Run stopped: start checks failed (#{problems.map(&:last).uniq.join(', ')})")
    1
  end

  def stop(error, logger)
    @stderr.puts("Error: #{error.message}")
    logger.error("Run stopped: #{error.stop_reason}")
    1
  end

  # The sample files are found from the project root; given paths are taken from the current folder.
  def input_paths(arguments)
    return DEFAULT_INPUTS.map { |path| File.expand_path(path, PROJECT_ROOT) } if arguments.empty?

    arguments.first(2).map { |path| File.expand_path(path) }
  end

  def output_path(arguments, run_time)
    return File.expand_path(arguments[2]) if arguments[2]

    File.expand_path(FinalBalancesCsvWriter.default_path(run_time), PROJECT_ROOT)
  end

  def day(run_time, logger)
    parts = ProcessDailyTransfer::Parts.new(
      balances_reader: BalancesCsvReader.new, transfers_reader: TransfersCsvReader.new,
      writer: FinalBalancesCsvWriter.new, repository: AccountRepository.new,
      reporter: ReportPrinter.new(output: @stdout), logger: logger
    )
    ProcessDailyTransfer.new(parts, run_time: run_time)
  end
end
