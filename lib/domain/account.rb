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

  def withdraw(money)
    check_amount(money)
    remaining = balance - money
    raise InsufficientFunds.new(number, money, balance) if remaining.negative?

    @balance = remaining
  end

  def deposit(money)
    check_amount(money)
    @balance = balance + money
  end

  private

  def check_amount(money)
    raise ArgumentError, "amount #{money} must be greater than 0.00" unless money.positive?
  end
end
