# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# Helpers for temporary folders, files written byte for byte, and fixture paths.
module Files
  FIXTURES = File.expand_path('../fixtures', __dir__)

  def in_temp_folder
    Dir.mktmpdir do |folder|
      Dir.chdir(folder) { yield(folder) }
    end
  end

  def write_file(name, text)
    FileUtils.mkdir_p(File.dirname(name))
    File.binwrite(name, text)
  end

  def fixture_path(*parts)
    File.join(FIXTURES, *parts)
  end
end

RSpec.configure { |config| config.include Files }
