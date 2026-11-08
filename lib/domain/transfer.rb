# frozen_string_literal: true

require_relative 'errors'

# One request to move an amount from one account to another.
class Transfer
  attr_reader :from, :to, :amount

  def initialize(from:, to:, amount:)
    raise InvalidAmount, %(amount "#{amount.text}" must be greater than 0.00) unless amount.positive?
    raise SameAccount, from if from == to

    @from = from
    @to = to
    @amount = amount
    freeze
  end
end
