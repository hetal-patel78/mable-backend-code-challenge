# frozen_string_literal: true

# The outcome of one transfer row: applied, or rejected with a reason code.
class TransferResult
  REASON_CODES = %i[
    malformed_row invalid_account_number invalid_amount same_account unknown_account insufficient_funds
  ].freeze

  attr_reader :line_number, :fields, :reason, :header_hint

  def self.applied(line_number:, fields:)
    new(line_number, fields)
  end

  def self.rejected(line_number:, fields:, reason:, header_hint: nil)
    raise ArgumentError, "unknown reason code #{reason.inspect}" unless REASON_CODES.include?(reason)

    new(line_number, fields, reason, header_hint)
  end

  def initialize(line_number, fields, reason = nil, header_hint = nil)
    @line_number = line_number
    @fields = fields.dup.freeze
    @reason = reason
    @header_hint = header_hint
    freeze
  end
  private_class_method :new

  def applied?
    reason.nil?
  end

  def rejected?
    !applied?
  end
end
