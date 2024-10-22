require "rubygems"
require "bundler"
Bundler.setup

require 'rake'
require 'rspec/core/rake_task'
require 'roodi'
require 'roodi_task'

desc "Default Task"
task :default => :spec

# run all rspecs
desc "Run all rspec files"
RSpec::Core::RakeTask.new(:spec)

# Fix the RoodiTask initialization
RoodiTask.new do |t|
  t.patterns = ['lib/**/*.rb']
end
