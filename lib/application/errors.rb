# frozen_string_literal: true

# A balances file with problems, or with no rows; it lists each problem and stops the run.
class InvalidBalancesFile < StandardError
  attr_reader :problems

  def self.no_rows(path)
    message = "the balances file has no rows: #{path}"
    new([message], message: message)
  end

  def initialize(problems, message: nil)
    @problems = problems
    super(message || (["the balances file is invalid (#{count}):"] + problems).join("\n  "))
  end

  def stop_reason
    "balances file invalid: #{count}"
  end

  private

  def count
    problems.one? ? '1 problem' : "#{problems.size} problems"
  end
end

# A transfers file with no rows; it stops the run.
class NoTransfers < StandardError
  def initialize(path)
    super("the transfers file has no transfers: #{path}")
  end

  def stop_reason
    'transfers file has no transfers'
  end
end
