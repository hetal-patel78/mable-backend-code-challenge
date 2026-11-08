# frozen_string_literal: true

require 'logger'
require 'stringio'
require 'infrastructure/errors'

# A reader that yields the rows it is given and records each path; it can fail before or after the rows.
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
    raise UnreadableFile.at_line(path, @unreadable_at) if @unreadable_at
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
