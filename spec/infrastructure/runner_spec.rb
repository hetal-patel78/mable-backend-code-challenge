# frozen_string_literal: true

require 'infrastructure/runner'

RSpec.describe Runner do
  describe 'FR-08 The end-of-day result and its output' do
    describe 'AC-08.1 the sample files give the exact expected result' do
      subject(:run) do
        run_scenario(files: sample_files,
                     arguments: %w[data/mable_account_balances.csv data/mable_transactions.csv
                                   output/final_balances_2026-11-07_143005.csv])
      end

      let(:sample_files) do
        %w[mable_account_balances.csv mable_transactions.csv].to_h do |name|
          ["data/#{name}", File.binread(fixture_path('sample', name))]
        end
      end

      it_behaves_like 'a completed run', stdout: sample_report, output_file: sample_output_file
    end
  end

  describe 'FR-09 The runner' do
    let(:given) { {} }
    let(:paths) { run.then { given[:paths] } }
    let(:files) { { 'b.csv' => "1111234522226789,100.00\n", 't.csv' => "1111234522226789,1212343433335665,10.00\n" } }
    let(:project_output) { Dir.glob(File.join(Runs::PROJECT_ROOT, 'output', '*')) }

    before do
      day = instance_double(ProcessDailyTransfer, call: nil)
      allow(day).to receive(:call) { |*called_with| given[:paths] = called_with }
      allow(ProcessDailyTransfer).to receive(:new) { |**parts| given.store(:parts, parts) && day }
    end

    def in_project(path)
      File.expand_path(path, Runs::PROJECT_ROOT)
    end

    def in_temp(path)
      File.expand_path(path, run.temp_folder)
    end

    def default_output
      in_project(FinalBalancesCsvWriter.default_path(given[:parts][:run_time]))
    end

    describe 'AC-09.1 no arguments' do
      subject(:run) { run_scenario(files: files, arguments: []) }

      it 'reads the sample balances file in the project data folder (DEC-22)' do
        expect(in_temp(paths[0])).to eq(in_project('data/mable_account_balances.csv'))
      end

      it 'reads the sample transfers file in the project data folder (DEC-22)' do
        expect(in_temp(paths[1])).to eq(in_project('data/mable_transactions.csv'))
      end

      it 'writes to the default output path under the project root, named from the run time (DEC-27)' do
        expect(in_temp(paths[2])).to eq(default_output)
      end

      it 'gives the input files in full, as they are outside the current folder (DEC-26)' do
        expect(paths.first(2)).to eq([in_project('data/mable_account_balances.csv'),
                                      in_project('data/mable_transactions.csv')])
      end

      it 'returns 0' do
        expect(run.status).to eq(0)
      end

      it "writes nothing in the project's output folder (DEC-27)" do
        expect { run }.not_to(change { project_output })
      end
    end

    describe 'AC-09.1 b.csv t.csv' do
      subject(:run) { run_scenario(files: files, arguments: %w[b.csv t.csv]) }

      it 'reads b.csv in the current folder (DEC-22)' do
        expect(in_temp(paths[0])).to eq(File.join(run.temp_folder, 'b.csv'))
      end

      it 'reads t.csv in the current folder (DEC-22)' do
        expect(in_temp(paths[1])).to eq(File.join(run.temp_folder, 't.csv'))
      end

      it 'writes to the default output path under the project root (DEC-27)' do
        expect(in_temp(paths[2])).to eq(default_output)
      end

      it 'gives the input paths in their shown form (DEC-26)' do
        expect(paths.first(2)).to eq(%w[b.csv t.csv])
      end

      it 'returns 0' do
        expect(run.status).to eq(0)
      end

      it "writes nothing in the project's output folder (DEC-27)" do
        expect { run }.not_to(change { project_output })
      end
    end

    describe 'AC-09.1 b.csv t.csv out/day1.csv' do
      subject(:run) { run_scenario(files: files, arguments: %w[b.csv t.csv out/day1.csv]) }

      it 'writes to out/day1.csv in the current folder (DEC-22)' do
        expect(in_temp(paths[2])).to eq(File.join(run.temp_folder, 'out/day1.csv'))
      end

      it 'gives the output path in full' do
        expect(paths[2]).to eq(File.join(run.temp_folder, 'out/day1.csv'))
      end

      it 'returns 0' do
        expect(run.status).to eq(0)
      end
    end

    describe 'the parts given to ProcessDailyTransfer (DEC-30)' do
      subject(:run) { run_scenario(files: files, arguments: %w[b.csv t.csv]) }

      let(:parts) { run.then { given[:parts] } }

      it 'gives a run time that is a Time' do
        expect(parts[:run_time]).to be_a(Time)
      end

      it 'gives exactly the six parts and the run time' do
        expect(parts.keys).to contain_exactly(:run_time, :balances_reader, :transfers_reader, :writer, :repository,
                                              :reporter, :logger)
      end

      it 'gives the real readers, writer, repository, reporter and logger' do
        expect(parts.except(:run_time).transform_values(&:class)).to eq(
          balances_reader: BalancesCsvReader, transfers_reader: TransfersCsvReader, writer: FinalBalancesCsvWriter,
          repository: AccountRepository, reporter: ReportPrinter, logger: Logger
        )
      end
    end
  end
end
