# frozen_string_literal: true

require 'infrastructure/display_path'

RSpec.describe DisplayPath do
  let(:root) { File.join(Dir.tmpdir, 'display_path') }
  let(:folder) { File.join(root, 'project') }
  let(:docs) { File.join(folder, 'docs') }
  let(:output_file) { File.join(folder, 'output', 'final_balances_2026-11-07_143005.csv') }

  describe '.of' do
    it 'shows a file in the folder by its name (DEC-26)' do
      expect(described_class.of(File.join(folder, 'day1.csv'), folder)).to eq('day1.csv')
    end

    it 'keeps a relative path relative (DEC-26)' do
      expect(described_class.of('output/day1.csv', folder)).to eq('output/day1.csv')
    end

    it 'shows a file below the folder relative to it (DEC-26)' do
      expect(described_class.of(output_file, folder)).to eq('output/final_balances_2026-11-07_143005.csv')
    end

    it 'shows a file in another folder of the parent in full (AC-08.4, DEC-26)' do
      expect(described_class.of(output_file, docs)).to eq(File.expand_path(output_file))
    end

    it 'shows a file two steps up in full (AC-08.4, DEC-26)' do
      file = File.join(root, 'b', 'day1.csv')
      expect(described_class.of(file, File.join(root, 'a', 'sub'))).to eq(File.expand_path(file))
    end

    it 'shows a file outside the folder in full (AC-08.4, DEC-26)' do
      expect(described_class.of(File.expand_path('/day1.csv'), docs)).to eq(File.expand_path('/day1.csv'))
    end

    it 'leaves a relative path already in its shown form unchanged' do
      expect(described_class.of(described_class.of('output/x.csv', folder), folder)).to eq('output/x.csv')
    end

    it 'leaves a full path already in its shown form unchanged' do
      shown = described_class.of(output_file, docs)
      expect(described_class.of(shown, docs)).to eq(shown)
    end

    it 'shows a file on another drive in full when it cannot be made relative (DEC-34)' do
      other_drive = instance_double(Pathname)
      allow(other_drive).to receive(:relative_path_from).and_raise(ArgumentError)
      allow(Pathname).to receive(:new).and_return(other_drive)
      expect(described_class.of('D:/day1.csv', 'C:/project')).to eq(File.expand_path('D:/day1.csv', 'C:/project'))
    end

    it 'uses the current folder when no folder is given' do
      in_temp_folder do
        expect(described_class.of(File.join(Dir.pwd, 'b.csv'))).to eq('b.csv')
      end
    end
  end
end
