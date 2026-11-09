# frozen_string_literal: true

require 'csv'
require_relative '../application/errors'
require_relative 'display_path'
require_relative 'row'

# The non-blank rows of one CSV file, read one at a time, each with the physical line where it starts.
class CsvRows
  include Enumerable

  HEADER_HINT = 'This looks like a header row; files must not have a header.'
  ADVICE = 'Check for an unclosed quote or characters that are not text.'
  BLANK = /\A[ \t\r\n]*\z/
  PADDING = /\A[ \t]+|[ \t]+\z/
  LINE_BREAK = /\r\n|\r|\n/
  DIGIT = /[0-9]/

  def initialize(path, expected_size)
    @path = path
    @expected_size = expected_size
  end

  def each(&)
    @lines_read = 0
    @first_row_given = false
    csv = open_file
    each_row_of(csv, &)
  ensure
    csv&.close
  end

  private

  # Opened as UTF-8 text with any byte-order mark dropped.
  def open_file
    CSV.open(@path, 'r:bom|utf-8')
  rescue SystemCallError => e
    raise cannot_open(e)
  end

  # Read as raw bytes, so the CSV parser never raises an encoding error of its own at the wrong line;
  # check_text then checks each row's bytes at its physical line.
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
    raise unreadable_at(line_number) unless text(bytes).valid_encoding?
  end

  def text(bytes)
    bytes.to_s.dup.force_encoding(Encoding::UTF_8)
  end

  # A system error while reading is reported like one while opening; the caller's block is outside this rescue.
  def next_fields(csv)
    csv.shift
  rescue CSV::MalformedCSVError
    raise unreadable_at(@lines_read + 1)
  rescue SystemCallError => e
    raise cannot_open(e)
  end

  # Ruby's system error messages end in " @ rb_sysopen - <path>"; only the part before " @ " is kept.
  def cannot_open(error)
    UnreadableFile.new("cannot read file #{DisplayPath.of(@path)}: #{error.message.split(' @ ').first}")
  end

  def unreadable_at(line_number)
    shown = DisplayPath.of(@path)
    UnreadableFile.new("cannot read #{shown} from line #{line_number}. #{ADVICE}",
                       line_number: line_number, line_problem: "cannot read #{shown} from this line. #{ADVICE}")
  end

  # The physical lines a row's raw text spans: one per line break, plus a last line with no final break,
  # so the next row starts at the right line.
  def lines_in(raw)
    breaks = raw.scan(LINE_BREAK).size
    raw.empty? || raw.end_with?("\n", "\r") ? breaks : breaks + 1
  end

  # The fields, read as raw bytes, become UTF-8 text with the spaces and tabs around them removed.
  def row(line_number, fields)
    values = fields.map { |field| text(field).gsub(PADDING, '') }
    hint = HEADER_HINT if header_like?(values.first)
    @first_row_given = true
    Row.new(line_number: line_number, fields: values, expected_size: @expected_size, header_hint: hint)
  end

  # Only the first row can look like a header: its first field is not empty and has no digit.
  def header_like?(first_field)
    !@first_row_given && !first_field.empty? && !first_field.match?(DIGIT)
  end
end
