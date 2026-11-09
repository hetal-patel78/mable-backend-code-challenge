# frozen_string_literal: true

require 'domain/account'
require 'domain/errors'

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

  describe '#withdraw' do
    let(:holder) { account('1111234522226789', '100.00') }

    it 'takes the amount from the balance' do
      holder.withdraw(amount('30.00'))
      expect(holder.balance.to_s).to eq('70.00')
    end

    it 'applies a withdrawal that leaves exactly 0.00 (DEC-13)' do
      holder.withdraw(amount('100.00'))
      expect(holder.balance.to_s).to eq('0.00')
    end

    it 'refuses a withdrawal that would leave the balance one cent below 0.00 (DEC-13)' do
      expect { holder.withdraw(amount('100.01')) }
        .to raise_error(InsufficientFunds, 'account 1111234522226789 cannot pay 100.01 from a balance of 100.00')
    end

    it 'keeps the balance after a refused withdrawal (DEC-18)' do
      attempt(InsufficientFunds) { holder.withdraw(amount('100.01')) }
      expect(holder.balance.to_s).to eq('100.00')
    end

    it 'refuses any withdrawal from an account holding 0.00 (DEC-10)' do
      expect { account('0000123412341234', '0.00').withdraw(amount('0.01')) }
        .to raise_error(InsufficientFunds, 'account 0000123412341234 cannot pay 0.01 from a balance of 0.00')
    end

    it 'writes both values in the refusal with 2 decimal places' do
      expect { account('1111234522226789', '5').withdraw(amount('007.50')) }
        .to raise_error(InsufficientFunds, 'account 1111234522226789 cannot pay 7.50 from a balance of 5.00')
    end

    %w[0.00 -5.00].each do |text|
      it "raises ArgumentError for an amount of #{text}, a programming error (DEC-18, DEC-30)" do
        expect { holder.withdraw(amount(text)) }
          .to raise_error(ArgumentError, "amount #{text} must be greater than 0.00")
      end
    end

    it 'keeps the balance after an amount that is not above 0.00 (DEC-18)' do
      attempt(ArgumentError) { holder.withdraw(amount('-5.00')) }
      expect(holder.balance.to_s).to eq('100.00')
    end
  end

  describe '#deposit' do
    let(:holder) { account('1111234522226789', '0.00') }

    it 'adds the amount to the balance' do
      holder.deposit(amount('30.00'))
      expect(holder.balance.to_s).to eq('30.00')
    end

    %w[0.00 -5.00].each do |text|
      it "raises ArgumentError for an amount of #{text}, a programming error (DEC-18, DEC-30)" do
        expect { holder.deposit(amount(text)) }
          .to raise_error(ArgumentError, "amount #{text} must be greater than 0.00")
      end
    end

    it 'keeps the balance after an amount that is not above 0.00 (DEC-18)' do
      attempt(ArgumentError) { holder.deposit(amount('-5.00')) }
      expect(holder.balance.to_s).to eq('0.00')
    end
  end
end
