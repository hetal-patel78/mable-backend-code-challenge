# frozen_string_literal: true

require_relative 'display_path'

# An output file that cannot be created or written; it stops the run.
class OutputNotWritable < StandardError
  # Ruby's system error messages end in " @ rb_sysopen - <path>"; only the part before " @ " is kept, as in CsvRows.
  def initialize(path, error)
    super("cannot write output file #{DisplayPath.of(path)}: #{error.message.split(' @ ').first}")
  end

  def stop_reason
    'cannot write output file'
  end
end
