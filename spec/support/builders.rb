# frozen_string_literal: true

# Test builders that make valid domain objects by default.
module Builders
  def account_number(text = '1111234522226789')
    require 'domain/account_number'
    AccountNumber.new(text)
  end

  def amount(text = '10.00')
    require 'domain/money'
    Money.amount(text)
  end

  def balance(text = '100.00')
    require 'domain/money'
    Money.balance(text)
  end

  def account(number = '1111234522226789', opening = '100.00')
    require 'domain/account'
    Account.new(account_number(number), balance(opening))
  end

  def attempt(error_class)
    yield
  rescue error_class
    nil
  end
end
