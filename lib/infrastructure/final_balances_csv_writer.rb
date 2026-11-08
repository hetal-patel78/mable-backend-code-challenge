# frozen_string_literal: true

require 'fileutils'

# Writes the final balances to a new CSV file, one "<account number>,<balance>" line per account, LF only.
class FinalBalancesCsvWriter
  NEW_FILE = File::WRONLY | File::CREAT | File::EXCL | File::BINARY

  def self.default_path(run_time)
    "output/final_balances_#{run_time.strftime('%Y-%m-%d_%H%M%S')}.csv"
  end

  def write(accounts, path)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, NEW_FILE) do |file|
      accounts.each { |account| file.write("#{account.number},#{account.balance}\n") }
    end
    nil
  end
end
