# frozen_string_literal: true

require 'fileutils'
require_relative 'errors'

# Writes the final balances to a new CSV file, one "<account number>,<balance>" line per account, LF only.
class FinalBalancesCsvWriter
  # EXCL makes the open fail when the file already exists; BINARY writes each "\n" as is, never as CRLF.
  NEW_FILE = File::WRONLY | File::CREAT | File::EXCL | File::BINARY

  def self.default_path(run_time)
    "output/final_balances_#{run_time.strftime('%Y-%m-%d_%H%M%S')}.csv"
  end

  # The same path as the class method gives, for a caller that holds a writer rather than the class.
  def default_path(run_time)
    self.class.default_path(run_time)
  end

  def write(accounts, path)
    file = open_new(path)
    write_lines(file, accounts, path)
    nil
  end

  private

  def open_new(path)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, NEW_FILE)
  rescue SystemCallError, IOError => e
    raise OutputNotWritable.new(path, e)
  end

  def write_lines(file, accounts, path)
    accounts.each { |account| file.write("#{account.number},#{account.balance}\n") }
    file.close # buffered lines reach the disk here, so a failure must be rescued too
  rescue SystemCallError, IOError => e
    discard(file, path)
    raise OutputNotWritable.new(path, e)
  ensure
    file.close unless file.closed?
  end

  def discard(file, path)
    begin
      file.close unless file.closed?
    rescue SystemCallError, IOError
      nil # the write already failed; the first error is the one reported
    end
    File.delete(path)
  end
end
