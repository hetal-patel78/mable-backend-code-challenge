# frozen_string_literal: true

require 'csv'
require_relative 'row'
require_relative 'errors'

# The non-blank rows of one CSV file, read one at a time, each with the physical line where it starts.
class CsvRows
  include Enumerable

  HEADER_HINT = 'This looks like a header row; files must not have a header.'
  BLANK = /\A[ \t\r\n]*\z/
  PADDING = /\A[ \t]+|[ \t]+\z/
  LINE_BREAK = /\r\n|\r|\n/

  def initialize(path, expected_size)
    @path = path
    @expected_size = expected_size
  end

  def each(&)
    @lines_read = 0
    @first_row_given = false
    CSV.open(@path, 'r:bom|utf-8') { |csv| each_row_of(csv, &) }
  rescue SystemCallError => e
    raise UnreadableFile.cannot_open(@path, e)
  end

  private

  def each_row_of(csv)
    csv.to_io.set_encoding(Encoding::BINARY)
    while (fields = next_fields(csv))
      line_number = @lines_read + 1
      @lines_read += lines_in(csv.line)
      check_text(csv.line, line_number)
      yield row(line_number, fields) unless csv.line.match?(BLANK)
    end
  end

  def check_text(bytes, line_number)
    raise UnreadableFile.at_line(@path, line_number) unless text(bytes).valid_encoding?
  end

  def text(bytes)
    bytes.to_s.dup.force_encoding(Encoding::UTF_8)
  end

  def next_fields(csv)
    csv.shift
  rescue CSV::MalformedCSVError
    raise UnreadableFile.at_line(@path, @lines_read + 1)
  end

  def lines_in(raw)
    breaks = raw.scan(LINE_BREAK).size
    raw.empty? || raw.end_with?("\n", "\r") ? breaks : breaks + 1
  end

  def row(line_number, fields)
    values = fields.map { |field| text(field).gsub(PADDING, '') }
    hint = HEADER_HINT if header_like?(values.first)
    @first_row_given = true
    Row.new(line_number: line_number, fields: values, expected_size: @expected_size, header_hint: hint)
  end

  def header_like?(first_field)
    !@first_row_given && !first_field.empty? && !first_field.match?(/[0-9]/)
  end
end
