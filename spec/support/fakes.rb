# frozen_string_literal: true

require 'logger'
require 'stringio'
require 'domain/account'
require 'domain/money'
require 'application/errors'

# A reader that yields the rows it is given and records each path; it can fail before or after the rows.
# Its UnreadableFile for a line has the same texts as the one CsvRows raises.
class FakeReader
  attr_reader :paths

  def initialize(rows, unreadable_at: nil, error: nil)
    @rows = rows
    @unreadable_at = unreadable_at
    @error = error
    @paths = []
  end

  def each_row(path, &)
    @paths << path
    raise @error if @error

    @rows.each(&)
    raise unreadable_line(path) if @unreadable_at
  end

  private

  def unreadable_line(path)
    advice = 'Check for an unclosed quote or characters that are not text.'
    UnreadableFile.new("cannot read #{path} from line #{@unreadable_at}. #{advice}",
                       line_number: @unreadable_at, line_problem: "cannot read #{path} from this line. #{advice}")
  end
end

# A reporter that records each day result it is given, and whether its output file existed at that moment.
class FakeReporter
  attr_reader :printed, :file_existed

  def initialize
    @printed = []
    @file_existed = []
  end

  def print(day_result)
    @printed << day_result
    @file_existed << File.exist?(day_result.output_path)
  end
end

# A repository whose accounts lose 1.00 from the second call to all, so the total after the transfers changes.
class ChangingTotalRepository
  def initialize(repository)
    @repository = repository
    @all_calls = 0
  end

  def add(account) = @repository.add(account)

  def include?(number) = @repository.include?(number)

  def find(number) = @repository.find(number)

  def all
    @all_calls += 1
    accounts = @repository.all
    return accounts if @all_calls == 1

    first = accounts.first
    [Account.new(first.number, first.balance - Money.amount('1.00')), *accounts.drop(1)]
  end
end

# A Logger writing to memory, so a spec can read back what was logged.
class MemoryLogger < Logger
  attr_reader :io

  def initialize(level)
    @io = StringIO.new
    super(@io, level: level)
  end
end

# Builds a logger in memory and reads its lines back as "<LEVEL> <text>".
module Logs
  PREFIX = /\A[A-Z], \[[^\]]*\] +([A-Z]+) -- [^:]*: /

  def memory_logger(level = Logger::INFO)
    MemoryLogger.new(level)
  end

  def log_lines(logger)
    logger.io.string.lines(chomp: true).map { |line| line.sub(PREFIX, '\1 ') }
  end
end

RSpec.configure { |config| config.include Logs }
