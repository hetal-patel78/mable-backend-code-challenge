# frozen_string_literal: true

# One row as a reader gives it: its line, its trimmed fields, the number of fields expected and any header hint.
Row = Data.define(:line_number, :fields, :expected_size, :header_hint) do
  # Written only to give header_hint a default of nil; bare super passes every keyword on to Data.
  def initialize(line_number:, fields:, expected_size:, header_hint: nil)
    super
  end

  def wrong_field_count?
    fields.size != expected_size
  end
end
