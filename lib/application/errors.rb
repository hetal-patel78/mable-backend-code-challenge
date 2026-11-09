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
    # Without a message: a heading line, then each problem on its own line, indented by two spaces.
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

# A total of all balances that changed during the day; it stops the run before the output file is written.
class TotalChanged < StandardError
  attr_reader :before, :after

  def initialize(before, after)
    @before = before
    @after = after
    super("the total of all balances changed from #{before} to #{after}. No output file was written.")
  end

  def stop_reason
    'total of all balances changed'
  end
end
