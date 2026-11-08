# frozen_string_literal: true

# An account number that is not exactly 16 digits.
class InvalidAccountNumber < StandardError
  def initialize(text)
    super(%(account number "#{text}" must be exactly 16 digits))
  end
end

# An amount or balance that is not valid money, or a transfer amount that is not above $0.
class InvalidAmount < StandardError
end

# A transfer whose from and to accounts are the same.
class SameAccount < StandardError
  def initialize(account_number)
    super("account #{account_number} cannot transfer to itself")
  end
end

# An opening balance below $0.
class NegativeBalance < StandardError
  def initialize(balance)
    super(%(balance "#{balance.text}" must not be negative))
  end
end

# A second account with a number that is already held.
class DuplicateAccount < StandardError
  def initialize(account_number)
    super("account #{account_number} appears more than once")
  end
end

# A withdrawal that would take a balance below $0.
class InsufficientFunds < StandardError
  def initialize(account_number, amount, balance)
    super("account #{account_number} cannot pay #{amount} from a balance of #{balance}")
  end
end
