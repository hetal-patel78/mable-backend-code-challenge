# frozen_string_literal: true

require 'fileutils'
require_relative 'errors'

# Writes the final balances to a new CSV file, one "<account number>,<balance>" line per account, LF only.
class FinalBalancesCsvWriter
  NEW_FILE = File::WRONLY | File::CREAT | File::EXCL | File::BINARY

  def self.default_path(run_time)
    "output/final_balances_#{run_time.strftime('%Y-%m-%d_%H%M%S')}.csv"
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
  rescue SystemCallError, IOError => e
    file.close
    File.delete(path)
    raise OutputNotWritable.new(path, e)
  ensure
    file.close
  end
end
