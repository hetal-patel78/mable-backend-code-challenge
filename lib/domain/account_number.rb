# frozen_string_literal: true

require_relative 'errors'

# One valid 16-digit account number, kept as text.
AccountNumber = Data.define(:text) do
  def initialize(text:)
    raise InvalidAccountNumber, text unless text.match?(AccountNumber::PATTERN)

    # A frozen copy, so changing the caller's string later cannot change this account number.
    super(text: text.dup.freeze)
  end

  def to_s
    text
  end
end

# Set here, not in the block: a constant written inside a Data.define block belongs to the enclosing scope.
AccountNumber::PATTERN = /\A[0-9]{16}\z/
