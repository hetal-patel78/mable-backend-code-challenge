# frozen_string_literal: true

require 'bigdecimal'
require_relative 'errors'

# One exact amount of money with at most 2 decimal places.
class Money
  include Comparable

  MORE_THAN_TWO_PLACES = /\A-?[0-9]+\.[0-9]{3,}\z/
  VALID = /\A-?[0-9]+(\.[0-9]{1,2})?\z/

  def self.amount(text)
    parse(text, 'amount')
  end

  def self.balance(text)
    parse(text, 'balance')
  end

  def self.parse(text, label)
    raise InvalidAmount, "#{label} is empty" if text.empty?
    raise InvalidAmount, %(#{label} "#{text}" has more than 2 decimal places) if text.match?(MORE_THAN_TWO_PLACES)
    raise InvalidAmount, %(#{label} "#{text}" is not a valid amount) unless text.match?(VALID)

    new(BigDecimal(text), text)
  end
  private_class_method :parse

  def initialize(value, text = nil)
    @value = value
    @written = text
    freeze
  end

  def text
    @written || to_s
  end

  def to_s
    units, fraction = value.abs.to_s('F').split('.')
    "#{'-' if value.negative?}#{units}.#{fraction.ljust(2, '0')}"
  end

  # A written minus sign counts too: BigDecimal treats -0.00 as not below zero, but "-0.00" is still a negative balance.
  def negative?
    @written.to_s.start_with?('-') || value.negative?
  end

  def positive?
    value.positive?
  end

  def +(other)
    Money.new(value + other.value)
  end

  def -(other)
    Money.new(value - other.value)
  end

  def <=>(other)
    value <=> other.value
  end

  def ==(other)
    other.is_a?(Money) && value == other.value
  end
  alias eql? ==

  # 0.00 and -0.00 are equal, so they must share a hash.
  def hash
    value.zero? ? BigDecimal('0').hash : value.hash
  end

  protected

  attr_reader :value
end
