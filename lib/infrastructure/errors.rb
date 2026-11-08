# frozen_string_literal: true

require_relative 'display_path'

# An input file that cannot be opened, or a line in it that the CSV library cannot read past.
class UnreadableFile < StandardError
  ADVICE = 'Check for an unclosed quote or characters that are not text.'

  attr_reader :path, :line_number

  def self.cannot_open(path, error)
    new("cannot read file #{DisplayPath.of(path)}: #{error.message.split(' @ ').first}", path: path)
  end

  def self.at_line(path, line_number)
    new("cannot read #{DisplayPath.of(path)} from line #{line_number}. #{ADVICE}", path: path, line_number: line_number)
  end

  def initialize(message, path:, line_number: nil)
    super(message)
    @path = path
    @line_number = line_number
  end

  def line_problem
    "cannot read #{DisplayPath.of(path)} from this line. #{ADVICE}"
  end

  def stop_reason
    'cannot read file'
  end
end
