require "rubygems"
require "bundler"
Bundler.setup

require 'rspec'
require 'preflight'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f }

RSpec.configure do |config|
  config.include PreflightSpecHelper

  # Enable the old :should syntax
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  # Enable the have(n).items syntax
  config.include(Module.new do
    def have(n)
      be_a_collection_containing_exactly(*Array.new(n))
    end
  end)
end
