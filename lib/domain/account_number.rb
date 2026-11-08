# frozen_string_literal: true

require_relative 'errors'

# One valid 16-digit account number, kept as text.
class AccountNumber
  PATTERN = /\A[0-9]{16}\z/

  def initialize(text)
    raise InvalidAccountNumber, text unless text.match?(PATTERN)

    @text = text
    freeze
  end

  def to_s
    @text
  end

  def ==(other)
    other.is_a?(AccountNumber) && to_s == other.to_s
  end
  alias eql? ==

  def hash
    @text.hash
  end
end
