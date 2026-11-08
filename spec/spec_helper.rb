# frozen_string_literal: true

require 'simplecov'
SimpleCov.start { add_filter '/spec/' }

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

Dir[File.join(__dir__, 'support', '*.rb')].sort.each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
  config.include Builders
end
