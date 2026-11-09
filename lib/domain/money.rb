# frozen_string_literal: true

require 'bigdecimal'
require_relative 'errors'

# One exact amount of money with at most 2 decimal places.
class Money
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
    raise ArgumentError, "Money needs a BigDecimal, got #{value.class}" unless value.is_a?(BigDecimal)

    @value = value
    @written = text
    freeze
  end

  # The amount as written in the file, such as "10.5" or "-0.00", so an error message quotes what the user typed.
  # A Money not read from a file, such as a balance after a withdrawal, has no written text and gives to_s.
  def text
    @written || to_s
  end

  # The amount as the program shows it, with exactly 2 decimal places: "10", "10.5" and "10.50" all give "10.50".
  # Used for the report, the output file and the log lines.
  # to_s('F') writes plain digits, not BigDecimal's default form such as 0.1e2; the sign is added once, in front.
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

  def ==(other)
    other.is_a?(Money) && value == other.value
  end
  alias eql? ==

  # 0.00 and -0.00 are equal, so they must share a hash.
  def hash
    value.zero? ? BigDecimal('0').hash : value.hash
  end

  protected

  # Protected: another Money can read the value, but code outside Money cannot.
  attr_reader :value
end
