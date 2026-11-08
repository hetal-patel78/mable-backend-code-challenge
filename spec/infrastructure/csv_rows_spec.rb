# frozen_string_literal: true

require 'infrastructure/csv_rows'

RSpec.describe CsvRows do
  around { |example| in_temp_folder { example.run } }

  def rows_of(path, expected_size = 2)
    described_class.new(path, expected_size).map { |row| [row.line_number, row.fields, row.header_hint] }
  end

  def written(text, expected_size = 2)
    write_file('written.csv', text)
    rows_of('written.csv', expected_size)
  end

  def lines_before_error(path)
    given = []
    described_class.new(path, 2).each { |row| given << row.line_number }
    given
  rescue UnreadableFile
    given
  end

  def reading(*parts)
    fixture_path('reading', *parts)
  end

  let(:hint) { described_class::HEADER_HINT }

  describe 'blank lines' do
    it 'skips an empty line, a line of spaces and a line with a tab, keeping line numbers (DEC-05, DEC-07)' do
      expect(rows_of(reading('blank_lines.csv')).map(&:first)).to eq([1, 5])
    end

    it 'yields no row and raises nothing for an empty file (DEC-05, DEC-11, DEC-20)' do
      expect(rows_of(reading('empty.csv'))).to eq([])
    end

    it 'yields no row and raises nothing for a file of blank lines only (DEC-05, DEC-20)' do
      expect(rows_of(reading('only_blank_lines.csv'))).to eq([])
    end

    it 'keeps a line of commas as a row of empty fields (DEC-05)' do
      expect(written(",,\n", 3)).to eq([[1, ['', '', ''], nil]])
    end
  end

  describe 'the byte-order mark' do
    it 'drops the mark from the first field and gives no header hint (DEC-04)' do
      expect(rows_of(reading('byte_order_mark.csv'))).to eq([[1, %w[1111234522226789 100.00], nil]])
    end
  end

  describe 'the header hint' do
    it 'is HEADER_HINT, the text DEC-06 gives' do
      expect(hint).to eq('This looks like a header row; files must not have a header.')
    end

    it 'marks a header-looking line 1 (DEC-06)' do
      expect(rows_of(reading('header_row.csv')).first).to eq([1, %w[account balance], hint])
    end

    it 'does not mark line 2 of the header row file (DEC-06)' do
      expect(rows_of(reading('header_row.csv')).last).to eq([2, %w[1111234522226789 100.00], nil])
    end

    it 'marks the first data row when it follows an empty line (DEC-06)' do
      expect(written("\naccount,balance\n")).to eq([[2, %w[account balance], hint]])
    end

    it 'marks no row when the header-looking row is not the first data row (DEC-06)' do
      expect(written("1111234522226789,100.00\naccount,balance\n").map(&:last)).to eq([nil, nil])
    end

    it 'is not given when the first field has a digit (DEC-06)' do
      expect(written("1111O34522226789,100.00\n").first.last).to be_nil
    end

    it 'is not given when the first field is empty (DEC-06)' do
      expect(written(",100.00\n").first.last).to be_nil
    end

    it 'is not given for a row of empty fields (DEC-06)' do
      expect(written(",,\n", 3).first.last).to be_nil
    end

    it 'is given on a header-looking row with too many fields (DEC-06)' do
      expect(written("account,balance,x\n").first.last).to eq(hint)
    end

    it 'is given on a header-looking row with too few fields (DEC-06)' do
      expect(written("from,to\n", 3).first.last).to eq(hint)
    end
  end

  describe 'values and line endings' do
    it 'reads Windows line endings and no final newline with no carriage return (DEC-04)' do
      rows = written("1111234522226789,100.00\r\n1212343433335665,50.00")
      expect(rows).to eq([[1, %w[1111234522226789 100.00], nil], [2, %w[1212343433335665 50.00], nil]])
    end

    it 'removes quotes and the spaces around values (DEC-04)' do
      expect(written("\"1111234522226789\", 100.00 \n").first[1]).to eq(%w[1111234522226789 100.00])
    end

    it 'trims tabs around a value (DEC-04, DEC-05)' do
      expect(written("1111234522226789,\t100.00\t\n").first[1]).to eq(%w[1111234522226789 100.00])
    end

    it 'keeps spaces inside a value (DEC-04)' do
      expect(written("1111234522226789,1 0\n").first[1]).to eq(['1111234522226789', '1 0'])
    end

    it 'gives a quoted value over two lines the line where it starts (DEC-07)' do
      text = "1111234522226789,100.00\n1212343433335665,\"50\n.00\"\n0000123412341234,0.00\n"
      expect(written(text).map(&:first)).to eq([1, 2, 4])
    end

    it 'keeps the expected size on each row (DEC-04, DEC-19)' do
      rows = described_class.new(reading('field_counts.csv'), 3).map(&:wrong_field_count?)
      expect(rows).to eq([true, true, false, true])
    end
  end

  describe 'a line that cannot be read' do
    let(:path) { reading('unclosed_quote.csv') }
    let(:message) do
      "cannot read #{path} from line 2. Check for an unclosed quote or characters that are not text."
    end

    it 'yields the rows before an unclosed quote (DEC-04, DEC-07)' do
      expect(lines_before_error(path)).to eq([1])
    end

    it 'raises UnreadableFile naming the line of an unclosed quote (DEC-04, DEC-07)' do
      expect { rows_of(path) }.to raise_error(UnreadableFile, message)
    end

    it 'gives the line number of an unclosed quote (DEC-07)' do
      expect { rows_of(path) }.to raise_error(an_object_having_attributes(line_number: 2))
    end

    it 'yields the rows before bytes that are not UTF-8 (DEC-04)' do
      write_file('bytes.csv', "1111234522226789,100.00\n1212343433335665,\xFF50.00\n".b)
      expect(lines_before_error('bytes.csv')).to eq([1])
    end

    it 'raises UnreadableFile at the line of bytes that are not UTF-8 (DEC-04)' do
      write_file('bytes.csv', "1111234522226789,100.00\n1212343433335665,\xFF50.00\n".b)
      expect { rows_of('bytes.csv') }.to raise_error(UnreadableFile, message.sub(path, 'bytes.csv'))
    end
  end

  describe 'a file that cannot be opened' do
    let(:missing) { reading('missing.csv') }

    it 'raises UnreadableFile with the reason from the system for a missing file (DEC-23)' do
      expect { rows_of(missing) }
        .to raise_error(UnreadableFile, /\Acannot read file #{Regexp.escape(missing)}: \S.*\z/)
    end

    it 'gives no line number for a missing file (DEC-23)' do
      expect { rows_of(missing) }.to raise_error(an_object_having_attributes(line_number: nil))
    end

    it 'leaves out the call details after " @ " (P9)' do
      expect { rows_of(missing) }.to raise_error(UnreadableFile, /\A(?!.* @ )/)
    end

    it 'raises UnreadableFile for a folder at the path (DEC-23)' do
      Dir.mkdir('folder.csv')
      expect { rows_of('folder.csv') }.to raise_error(UnreadableFile, /\Acannot read file folder\.csv: \S/)
    end
  end
end
