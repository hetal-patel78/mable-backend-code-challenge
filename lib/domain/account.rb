# frozen_string_literal: true

require_relative 'errors'

# An account number and a balance that never goes below $0.
class Account
  attr_reader :number, :balance

  def self.check_opening_balance(balance)
    raise NegativeBalance, balance if balance.negative?
  end

  def initialize(number, balance)
    self.class.check_opening_balance(balance)
    @number = number
    @balance = balance
  end
end
