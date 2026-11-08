# frozen_string_literal: true

require 'pathname'

# The one way a path is shown: relative to the folder when the file is in or below it, otherwise in full.
module DisplayPath
  def self.of(path, folder = Dir.pwd)
    full = File.expand_path(path, folder)
    relative = Pathname.new(full).relative_path_from(File.expand_path(folder))
    relative.each_filename.include?('..') ? full : relative.to_s
  rescue ArgumentError
    full
  end
end
