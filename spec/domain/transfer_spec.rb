# frozen_string_literal: true

require 'domain/transfer'
require 'domain/errors'

RSpec.describe Transfer do
  describe '.new' do
    subject(:transfer) do
      described_class.new(from: account_number('1111234522226789'), to: account_number('1212343433335665'),
                          amount: amount('30.00'))
    end

    it 'returns the from account number' do
      expect(transfer.from).to eq(account_number('1111234522226789'))
    end

    it 'returns the to account number' do
      expect(transfer.to).to eq(account_number('1212343433335665'))
    end

    it 'returns the amount' do
      expect(transfer.amount).to eq(amount('30.00'))
    end

    it 'accepts the smallest amount, 0.01 (DEC-10)' do
      expect(described_class.new(from: account_number, to: account_number('1212343433335665'),
                                 amount: amount('0.01')).amount).to eq(amount('0.01'))
    end

    %w[0 0.00 -5.00 -0 -0.00].each do |text|
      it "rejects an amount of #{text} as not greater than 0.00 (DEC-10)" do
        to = account_number('1212343433335665')
        expect { described_class.new(from: account_number, to: to, amount: amount(text)) }
          .to raise_error(InvalidAmount, %(amount "#{text}" must be greater than 0.00))
      end
    end

    it 'rejects the same account, even one that is not loaded (DEC-19)' do
      same = account_number('9999888877776666')
      expect { described_class.new(from: same, to: same, amount: amount('5.00')) }
        .to raise_error(SameAccount, 'account 9999888877776666 cannot transfer to itself')
    end

    it 'checks the amount before the same account (DEC-19)' do
      same = account_number('1111234522226789')
      expect { described_class.new(from: same, to: same, amount: amount('0')) }
        .to raise_error(InvalidAmount, 'amount "0" must be greater than 0.00')
    end
  end
end
