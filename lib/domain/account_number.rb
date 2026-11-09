# frozen_string_literal: true

require_relative 'errors'

# One valid 16-digit account number, kept as text.
AccountNumber = Data.define(:text) do
  def initialize(text:)
    raise InvalidAccountNumber, text unless text.match?(AccountNumber::PATTERN)

    super(text: text.dup.freeze)
  end

  def to_s
    text
  end
end

AccountNumber::PATTERN = /\A[0-9]{16}\z/
