# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'rbconfig'
require 'stringio'
require 'tmpdir'

# Runs the Runner in a temporary folder, or bin/run as its own process, and gives back what the run showed and wrote.
module Runs
  PROJECT_ROOT = File.expand_path('../..', __dir__)
  OUTPUT_FILE = 'output/final_balances_2026-11-07_143005.csv'
  DEFAULT_FILES = {
    'balances.csv' => "1111234522226789,100.00\n1212343433335665,50.00\n0000123412341234,0.00\n",
    'transfers.csv' => "1111234522226789,1212343433335665,10.00\n"
  }.freeze
  DEFAULT_ARGUMENTS = ['balances.csv', 'transfers.csv', OUTPUT_FILE].freeze
  PLACEHOLDERS = {
    '<timestamp>' => '\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{6}',
    '<pid>' => '\d+',
    '<reason from the system>' => '.+'
  }.freeze

  Run = Struct.new(:stdout, :stderr, :status, :temp_folder, :output_file, :files, keyword_init: true)

  def run_runner(*arguments, env: {})
    require 'infrastructure/runner'
    stdout = StringIO.new
    stderr = StringIO.new
    status = Runner.new(stdout: stdout, stderr: stderr, env: env).run(arguments)
    Run.new(stdout: stdout.string, stderr: stderr.string, status: status)
  end

  def run_scenario(files: {}, arguments: DEFAULT_ARGUMENTS, env: {}, folder: nil, read: [])
    in_temp_folder do
      write_files(DEFAULT_FILES.merge(files))
      run = in_subfolder(folder) { run_runner(*arguments, env: env) }
      run.temp_folder = Dir.pwd
      run.output_file = read_path(OUTPUT_FILE)
      run.files = read.to_h { |path| [path, read_path(path)] }
      run
    end
  end

  def sample_files
    %w[mable_account_balances.csv mable_transactions.csv].to_h do |name|
      ["data/#{name}", File.binread(fixture_path('sample', name))]
    end
  end

  def stream_pattern(text)
    parts = text.split(/(#{PLACEHOLDERS.keys.join('|')})/o)
    Regexp.new("\\A#{parts.map { |part| PLACEHOLDERS.fetch(part) { Regexp.escape(part) } }.join}\\z")
  end

  def run_command(*arguments, files:)
    Dir.mktmpdir do |folder|
      files.each { |name, source| copy_file(source, File.join(folder, name)) }
      stdout, stderr, status = Open3.capture3({ 'LOG_LEVEL' => nil }, RbConfig.ruby,
                                              File.join(PROJECT_ROOT, 'bin', 'run'), *arguments, chdir: folder)
      output_file = File.join(folder, OUTPUT_FILE)
      Run.new(stdout: stdout.gsub("\r\n", "\n"), stderr: stderr.gsub("\r\n", "\n"), status: status.exitstatus,
              output_file: File.file?(output_file) ? File.binread(output_file) : nil)
    end
  end

  private

  def write_files(files)
    files.each do |name, content|
      next if content.nil?

      content == :folder ? FileUtils.mkdir_p(name) : write_file(name, content)
    end
  end

  def in_subfolder(folder, &)
    return yield unless folder

    FileUtils.mkdir_p(folder)
    Dir.chdir(folder, &)
  end

  def read_path(path)
    return folder_names(path) if path.end_with?('/')
    return :folder if File.directory?(path)

    File.binread(path) if File.file?(path)
  end

  def folder_names(path)
    Dir.children(path).sort if File.directory?(path)
  end

  def copy_file(source, target)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(source, target)
  end
end

RSpec.shared_examples 'a completed run' do |stdout:, stderr: '', output_file: nil|
  it 'prints exactly the expected report on standard output' do
    expect(run.stdout).to eq(stdout)
  end

  it 'writes exactly the expected standard error' do
    expect(run.stderr).to match(stream_pattern(stderr))
  end

  it 'exits with status 0' do
    expect(run.status).to eq(0)
  end

  if output_file
    it 'writes exactly the expected output file' do
      expect(run.output_file).to eq(output_file)
    end
  end
end

RSpec.shared_examples 'a stopped run' do |stderr:|
  it 'prints nothing on standard output' do
    expect(run.stdout).to eq('')
  end

  it 'writes exactly the expected standard error' do
    expect(run.stderr).to match(stream_pattern(stderr))
  end

  it 'exits with status 1' do
    expect(run.status).to eq(1)
  end

  it 'leaves no output file (SC-004)' do
    expect(run.output_file).to be_nil
  end
end

RSpec.configure { |config| config.include Runs }
