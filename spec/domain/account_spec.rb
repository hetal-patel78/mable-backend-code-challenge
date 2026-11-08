# frozen_string_literal: true

require 'domain/account'

RSpec.describe Account do
  describe '.check_opening_balance' do
    %w[0 0.00 5000.00 550].each do |text|
      it "accepts an opening balance of #{text} (DEC-10)" do
        expect { described_class.check_opening_balance(balance(text)) }.not_to raise_error
      end
    end

    %w[-5.00 -0 -0.00].each do |text|
      it "rejects an opening balance of #{text} as negative, with no account number needed (DEC-11)" do
        expect { described_class.check_opening_balance(balance(text)) }
          .to raise_error(NegativeBalance, %(balance "#{text}" must not be negative))
      end
    end
  end

  describe '.new' do
    it 'rejects a negative opening balance' do
      expect { described_class.new(account_number('1111234522226789'), balance('-5.00')) }
        .to raise_error(NegativeBalance, 'balance "-5.00" must not be negative')
    end

    it 'holds its number' do
      expect(described_class.new(account_number('1111234522226789'), balance('100.00')).number.to_s)
        .to eq('1111234522226789')
    end

    it 'holds its balance' do
      expect(described_class.new(account_number('1111234522226789'), balance('100.00')).balance.to_s).to eq('100.00')
    end
  end
end
