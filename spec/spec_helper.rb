$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "rubygems"
require "bundler"
Bundler.setup

require 'rspec'
require 'preflight'
require 'pdf/reader'
require 'preflight/rules/image_colorspace'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

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

def pdf_spec_file(name)
  File.join(File.dirname(__FILE__), "pdfs", "#{name}.pdf")
end
