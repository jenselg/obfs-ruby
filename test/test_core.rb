# core dependencies
require 'fileutils'
require 'json'
require 'set'
require 'benchmark'
require 'securerandom'

# load each file in test
req_files = Dir.glob("../lib/**/*").reject { |e| !e.end_with?(".rb") || e.end_with?("obfs.rb") }
req_files.each do |f|
    require f
end