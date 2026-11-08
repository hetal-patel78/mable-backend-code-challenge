# frozen_string_literal: true

require_relative 'errors'

# The loaded accounts, one per account number, in load order.
class AccountRepository
  def initialize
    @accounts = {}
  end

  def add(account)
    key = account.number.to_s
    raise DuplicateAccount, account.number if @accounts.key?(key)

    @accounts[key] = account
  end

  def include?(account_number)
    @accounts.key?(account_number.to_s)
  end

  def find(account_number)
    @accounts.fetch(account_number.to_s) { raise UnknownAccount, account_number }
  end

  def all
    @accounts.values
  end
end
