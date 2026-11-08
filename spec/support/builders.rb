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

  def repository_with(*accounts)
    require 'domain/account_repository'
    AccountRepository.new.tap do |repository|
      accounts.each { |held| repository.add(held) }
    end
  end

  def transfer(from: '1111234522226789', to: '1212343433335665', amount: '30.00')
    require 'domain/transfer'
    Transfer.new(from: account_number(from), to: account_number(to), amount: amount(amount))
  end

  def three_accounts
    repository_with(
      account('1111234522226789', '100.00'),
      account('1212343433335665', '50.00'),
      account('0000123412341234', '0.00')
    )
  end

  def attempt(error_class)
    yield
  rescue error_class
    nil
  end
end
