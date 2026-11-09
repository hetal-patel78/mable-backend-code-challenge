# frozen_string_literal: true

require 'domain/transfer_service'
require 'domain/errors'

RSpec.describe TransferService do
  let(:repository) { three_accounts }
  let(:service) { described_class.new(repository) }
  let(:balances) { repository.all.map { |held| held.balance.to_s } }
  let(:total) { repository.all.map(&:balance).reduce(:+).to_s }

  describe '#apply' do
    it 'moves the amount from one account to the other (DEC-13)' do
      service.apply(transfer(amount: '30.00'))
      expect(balances).to eq(%w[70.00 80.00 0.00])
    end

    it 'returns nil' do
      expect(service.apply(transfer)).to be_nil
    end

    it 'applies a transfer that leaves exactly 0.00 (DEC-13)' do
      service.apply(transfer(amount: '100.00'))
      expect(balances).to eq(%w[0.00 150.00 0.00])
    end

    it 'applies two equal transfers both (DEC-16)' do
      2.times { service.apply(transfer(to: '0000123412341234', amount: '20.00')) }
      expect(balances).to eq(%w[60.00 50.00 40.00])
    end

    it 'applies the next transfer after a refusal (DEC-14)' do
      attempt(InsufficientFunds) { service.apply(transfer(amount: '100.01')) }
      service.apply(transfer(amount: '30.00'))
      expect(balances).to eq(%w[70.00 80.00 0.00])
    end

    context 'when the from account would go below 0.00' do
      it 'refuses a transfer one cent too large (DEC-13)' do
        expect { service.apply(transfer(amount: '100.01')) }.to raise_error(InsufficientFunds)
      end

      it 'deposits nothing after the refusal (DEC-18)' do
        attempt(InsufficientFunds) { service.apply(transfer(amount: '100.01')) }
        expect(balances).to eq(%w[100.00 50.00 0.00])
      end

      it 'leaves the balances unchanged for an account at 0.00 (DEC-18)' do
        attempt(InsufficientFunds) do
          service.apply(transfer(from: '0000123412341234', to: '1111234522226789', amount: '0.01'))
        end
        expect(balances).to eq(%w[100.00 50.00 0.00])
      end
    end

    context 'when the to account is not loaded' do
      let(:to_unknown) { transfer(to: '9999888877776666', amount: '10.00') }

      it 'refuses the transfer (DEC-17)' do
        expect { service.apply(to_unknown) }.to raise_error(UnknownAccount)
      end

      it 'withdraws nothing after the refusal (DEC-18)' do
        attempt(UnknownAccount) { service.apply(to_unknown) }
        expect(balances).to eq(%w[100.00 50.00 0.00])
      end

      it 'holds only the three loaded accounts after the refusal (DEC-17)' do
        attempt(UnknownAccount) { service.apply(to_unknown) }
        expect(repository.all.map { |held| held.number.to_s })
          .to eq(%w[1111234522226789 1212343433335665 0000123412341234])
      end

      it 'refuses it as unknown before checking the money (DEC-19)' do
        expect { service.apply(transfer(to: '9999888877776666', amount: '1000000.00')) }
          .to raise_error(UnknownAccount)
      end
    end

    context 'when the from account is not loaded' do
      let(:from_unknown) { transfer(from: '9999888877776666', to: '1111234522226789', amount: '10.00') }

      it 'refuses the transfer (DEC-17)' do
        expect { service.apply(from_unknown) }.to raise_error(UnknownAccount)
      end

      it 'leaves the balances unchanged (DEC-18)' do
        attempt(UnknownAccount) { service.apply(from_unknown) }
        expect(balances).to eq(%w[100.00 50.00 0.00])
      end

      it 'names the from account when both are unknown (DEC-17)' do
        expect { service.apply(transfer(from: '9999888877776666', to: '8888777766665555', amount: '10.00')) }
          .to raise_error(UnknownAccount, /9999888877776666/)
      end
    end

    context 'when the transfer is refused while it is built' do
      {
        InvalidAmount => { amount: '0' },
        SameAccount => { to: '1111234522226789' },
        InvalidAccountNumber => { from: '12345' }
      }.each do |error_class, fields|
        it "leaves the balances unchanged after #{error_class} (DEC-18)" do
          attempt(error_class) { service.apply(transfer(**fields)) }
          expect(balances).to eq(%w[100.00 50.00 0.00])
        end
      end
    end

    context 'with one refusal of each kind' do
      let(:refusals) do
        { InvalidAccountNumber => { from: '12345' }, InvalidAmount => { amount: '0' },
          SameAccount => { to: '1111234522226789' }, UnknownAccount => { to: '9999888877776666' },
          InsufficientFunds => { amount: '100.01' } }
      end

      it 'keeps the total at 150.00 after them' do
        refusals.each { |error_class, fields| attempt(error_class) { service.apply(transfer(**fields)) } }
        expect(total).to eq('150.00')
      end
    end

    context 'with the sample accounts and transfers (DEC-35)' do
      let(:repository) do
        repository_with(*{ '1111234522226789' => '5000.00', '1111234522221234' => '10000.00',
                           '2222123433331212' => '550.00', '1212343433335665' => '1200.00',
                           '3212343433335755' => '50000.00' }.map { |number, opening| account(number, opening) })
      end

      before do
        [%w[1111234522226789 1212343433335665 500.00], %w[3212343433335755 2222123433331212 1000.00],
         %w[3212343433335755 1111234522226789 320.50], %w[1111234522221234 1212343433335665 25.60]]
          .each { |from, to, money| service.apply(transfer(from: from, to: to, amount: money)) }
      end

      it 'gives the exact closing balances' do
        expect(balances).to eq(%w[4820.50 9974.40 1550.00 1725.60 48679.50])
      end

      it 'keeps the total at 66750.00' do
        expect(total).to eq('66750.00')
      end
    end
  end
end
