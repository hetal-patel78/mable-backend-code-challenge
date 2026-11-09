# frozen_string_literal: true

# The outcome of one transfer row: applied, or rejected with a reason code.
TransferResult = Data.define(:line_number, :fields, :reason, :header_hint) do
  def self.applied(line_number:, fields:)
    new(line_number:, fields:)
  end

  def self.rejected(line_number:, fields:, reason:, header_hint: nil)
    new(line_number:, fields:, reason:, header_hint:)
  end

  # Data builds with [] as well as new, so both are private: results come only from .applied and .rejected.
  private_class_method :new, :[]

  # Data passes the keywords given to new on to initialize; the defaults let an applied result leave two out.
  def initialize(line_number:, fields:, reason: nil, header_hint: nil)
    unless reason.nil? || TransferResult::REASON_CODES.include?(reason)
      raise ArgumentError, "unknown reason code #{reason.inspect}"
    end

    # A frozen copy, so changing the caller's array later cannot change this result.
    super(line_number:, fields: fields.dup.freeze, reason:, header_hint:)
  end

  def applied?
    reason.nil?
  end

  def rejected?
    !applied?
  end
end

# Set here, not in the block: a constant written inside a Data.define block belongs to the enclosing scope.
TransferResult::REASON_CODES = %i[
  malformed_row invalid_account_number invalid_amount same_account unknown_account insufficient_funds
].freeze
