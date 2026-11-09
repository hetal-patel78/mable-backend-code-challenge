# frozen_string_literal: true

require_relative 'errors'

# One request to move an amount from one account to another.
Transfer = Data.define(:from, :to, :amount) do
  def initialize(from:, to:, amount:)
    raise InvalidAmount, %(amount "#{amount.text}" must be greater than 0.00) unless amount.positive?
    raise SameAccount, from if from == to

    # Bare super passes the same keywords on to Data, which sets the members.
    super
  end
end
