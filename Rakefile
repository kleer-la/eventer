#!/usr/bin/env rake
# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'English'
require File.expand_path('config/application', __dir__)

Eventer::Application.load_tasks

task :ci do
  ["rake spec SPEC_OPTS='--tag ~slow'"].each do |cmd|
    #  ["rake spec", "rake cucumber"].each do |cmd|
    puts "Starting to run #{cmd}..."
    system("export DISPLAY=:99.0 && bundle exec #{cmd}")
    raise "#{cmd} failed!" unless $CHILD_STATUS.exitstatus.zero?
  end
end

task :slow_tests do
  puts 'Starting to run slow tests...'
  system("export DISPLAY=:99.0 && bundle exec rake spec SPEC_OPTS='--tag slow'")
  raise "#{cmd} failed!" unless $CHILD_STATUS.exitstatus.zero?
end
