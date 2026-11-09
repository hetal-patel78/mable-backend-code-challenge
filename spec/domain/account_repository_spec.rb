# frozen_string_literal: true

require 'domain/account_repository'
require 'domain/errors'

RSpec.describe AccountRepository do
  let(:three_numbers) { %w[1111234522226789 1212343433335665 0000123412341234] }

  describe '#all' do
    it 'is empty for a new repository' do
      expect(described_class.new.all).to eq([])
    end

    it 'returns the accounts in the order they were added (DEC-31)' do
      repository = repository_with(*three_numbers.map { |number| account(number) })
      expect(repository.all.map { |held| held.number.to_s }).to eq(three_numbers)
    end
  end

  describe '#include?' do
    let(:repository) { repository_with(account('1111234522226789')) }

    it 'is true for a number it holds (DEC-12)' do
      expect(repository.include?(account_number('1111234522226789'))).to be(true)
    end

    it 'is false for a number it does not hold (DEC-12)' do
      expect(repository.include?(account_number('9999888877776666'))).to be(false)
    end

    it 'is true for a different AccountNumber object built from the same text' do
      other_object = account_number('1111234522226789')
      expect(repository.include?(other_object)).to be(true)
    end

    it 'is false for the text of a number it holds, as it is keyed by AccountNumber' do
      expect(repository.include?('1111234522226789')).to be(false)
    end
  end

  describe '#add' do
    let(:repository) { repository_with(account('1111234522226789', '100.00')) }

    it 'refuses a second account with the same number and the same balance (DEC-11)' do
      expect { repository.add(account('1111234522226789', '100.00')) }
        .to raise_error(DuplicateAccount, 'account 1111234522226789 appears more than once')
    end

    it 'refuses a second account with the same number and a different balance (DEC-11)' do
      expect { repository.add(account('1111234522226789', '999.00')) }
        .to raise_error(DuplicateAccount, 'account 1111234522226789 appears more than once')
    end

    it 'keeps only the first account after a refused duplicate (DEC-31)' do
      attempt(DuplicateAccount) { repository.add(account('1111234522226789', '999.00')) }
      expect(repository.all.map { |held| held.balance.to_s }).to eq(%w[100.00])
    end
  end

  describe '#find' do
    let(:added) { account('1111234522226789', '100.00') }
    let(:repository) { repository_with(added) }

    it 'returns the same Account object that was added' do
      expect(repository.find(account_number('1111234522226789'))).to equal(added)
    end

    it 'returns an account whose changes are seen in all' do
      repository.find(account_number('1111234522226789')).withdraw(amount('30.00'))
      expect(repository.all.map { |held| held.balance.to_s }).to eq(%w[70.00])
    end

    context 'with a number it does not hold' do
      let(:unknown) { account_number('9999888877776666') }
      let(:empty) { described_class.new }

      it 'raises UnknownAccount (DEC-17)' do
        three_accounts = repository_with(*three_numbers.map { |number| account(number) })
        expect { three_accounts.find(unknown) }
          .to raise_error(UnknownAccount, 'account 9999888877776666 is not loaded')
      end

      it 'does not create the account (DEC-17)' do
        attempt(UnknownAccount) { empty.find(unknown) }
        expect(empty.include?(unknown)).to be(false)
      end

      it 'leaves all empty (DEC-31)' do
        attempt(UnknownAccount) { empty.find(unknown) }
        expect(empty.all).to eq([])
      end
    end
  end
end
