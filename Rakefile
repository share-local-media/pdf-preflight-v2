require "rubygems"
require "bundler"
Bundler.setup

require 'rake'
require 'rspec/core/rake_task'
require 'roodi'
require 'roodi_task'
require_relative 'spec/support/pdf_samples'

desc "Default Task"
task :default => :spec

# run all rspecs
desc "Run all rspec files"
RSpec::Core::RakeTask.new(:spec)

# Fix the RoodiTask initialization
RoodiTask.new do |t|
  t.patterns = ['lib/**/*.rb']
end

namespace :samples do
  desc "Generate PDF test samples with different color spaces"
  task :generate do
    puts "Generating PDF test samples..."
    PDFSamples.create_test_pdfs
    puts "PDF samples generated in spec/pdf directory"
  end

  desc "Clean generated PDF samples"
  task :clean do
    puts "Cleaning PDF test samples..."
    FileUtils.rm_rf('spec/pdf')
    puts "PDF samples cleaned"
  end
end

# Optional: Add samples generation to spec preparation
task :spec => ['samples:generate']
