# frozen_string_literal: true

require 'logger'
require_relative '../domain/account_repository'
require_relative '../application/errors'
require_relative '../application/process_daily_transfer'
require_relative 'balances_csv_reader'
require_relative 'display_path'
require_relative 'final_balances_csv_writer'
require_relative 'report_printer'
require_relative 'transfers_csv_reader'

# Runs the day from the command line: works out the paths, builds the parts and returns the exit status.
class Runner
  PROJECT_ROOT = File.expand_path('../..', __dir__)
  DEFAULT_INPUTS = %w[data/mable_account_balances.csv data/mable_transactions.csv].freeze
  STOPPING_ERRORS = [InvalidBalancesFile].freeze

  def initialize(stdout: $stdout, stderr: $stderr, env: ENV)
    @stdout = stdout
    @stderr = stderr
    @env = env
  end

  def run(arguments)
    logger = Logger.new(@stderr, level: Logger::WARN)
    run_time = Time.now
    balances, transfers = input_paths(arguments)
    output = output_path(arguments, run_time)
    day(run_time, logger).call(DisplayPath.of(balances), DisplayPath.of(transfers), output)
    0
  rescue *STOPPING_ERRORS => e
    stop(e, logger)
  end

  private

  def stop(error, logger)
    @stderr.puts("Error: #{error.message}")
    logger.error("Run stopped: #{error.stop_reason}")
    1
  end

  def input_paths(arguments)
    return DEFAULT_INPUTS.map { |path| File.expand_path(path, PROJECT_ROOT) } if arguments.empty?

    arguments.first(2).map { |path| File.expand_path(path) }
  end

  def output_path(arguments, run_time)
    return File.expand_path(arguments[2]) if arguments[2]

    File.expand_path(FinalBalancesCsvWriter.default_path(run_time), PROJECT_ROOT)
  end

  def day(run_time, logger)
    ProcessDailyTransfer.new(
      run_time: run_time, balances_reader: BalancesCsvReader.new, transfers_reader: TransfersCsvReader.new,
      writer: FinalBalancesCsvWriter.new, repository: AccountRepository.new,
      reporter: ReportPrinter.new(output: @stdout), logger: logger
    )
  end
end
