# frozen_string_literal: true

# The outcome of one transfer row: applied, or rejected with a reason code.
TransferResult = Data.define(:line_number, :fields, :reason, :header_hint) do
  def self.applied(line_number:, fields:)
    new(line_number:, fields:)
  end

  def self.rejected(line_number:, fields:, reason:, header_hint: nil)
    new(line_number:, fields:, reason:, header_hint:)
  end

  private_class_method :new, :[]

  def initialize(line_number:, fields:, reason: nil, header_hint: nil)
    unless reason.nil? || TransferResult::REASON_CODES.include?(reason)
      raise ArgumentError, "unknown reason code #{reason.inspect}"
    end

    super(line_number:, fields: fields.dup.freeze, reason:, header_hint:)
  end

  def applied?
    reason.nil?
  end

  def rejected?
    !applied?
  end
end

TransferResult::REASON_CODES = %i[
  malformed_row invalid_account_number invalid_amount same_account unknown_account insufficient_funds
].freeze
