# frozen_string_literal: true

require_relative 'account_repository'
require_relative 'transfer'

# Applies one transfer to the accounts in a repository, all or nothing.
class TransferService
  def initialize(repository)
    @repository = repository
  end

  def apply(transfer)
    from = @repository.find(transfer.from)
    to = @repository.find(transfer.to)
    from.withdraw(transfer.amount)
    to.deposit(transfer.amount)
    nil
  end
end
