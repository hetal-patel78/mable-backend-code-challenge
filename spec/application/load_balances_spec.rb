# frozen_string_literal: true

require 'application/load_balances'
require 'domain/account_repository'

RSpec.describe LoadBalances do
  let(:reader) do
    FakeReader.new([balances_row(1, '1111234522226789', '100.00'),
                    balances_row(2, '1212343433335665', '50.00'),
                    balances_row(3, '0000123412341234', '0.00')])
  end
  let(:repository) { AccountRepository.new }
  let(:loader) { described_class.new(reader, repository) }

  describe '#call' do
    context 'with a valid file' do
      before { loader.call('balances.csv') }

      it 'adds the accounts in file order (DEC-31)' do
        expect(repository.all.map { |held| held.number.to_s })
          .to eq(%w[1111234522226789 1212343433335665 0000123412341234])
      end

      it 'adds the balances in file order (DEC-31)' do
        expect(repository.all.map { |held| held.balance.to_s }).to eq(%w[100.00 50.00 0.00])
      end

      it 'keeps leading zeros, so the account is found by its number as written (DEC-08)' do
        expect(repository.include?(account_number('0000123412341234'))).to be(true)
      end

      it 'accepts a starting balance of 0.00 (DEC-10)' do
        expect(repository.find(account_number('0000123412341234')).balance).to eq(balance('0.00'))
      end

      it 'asks the reader once, with the path it was given' do
        expect(reader.paths).to eq(['balances.csv'])
      end
    end

    it 'returns nil' do
      expect(loader.call('balances.csv')).to be_nil
    end
  end
end
