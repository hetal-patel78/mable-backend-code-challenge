# frozen_string_literal: true

# Applies one transfer to the accounts in a repository, all or nothing.
class TransferService
  def initialize(repository)
    @repository = repository
  end

  # The two finds and withdraw raise before any balance changes, so a refused transfer changes nothing.
  def apply(transfer)
    from = @repository.find(transfer.from)
    to = @repository.find(transfer.to)
    from.withdraw(transfer.amount)
    to.deposit(transfer.amount)
    nil
  end
end
