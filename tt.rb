require 'harvested'
require 'date'
require 'yaml'
require 'hashie'
require 'httparty'

def get_opts(msg)
  puts msg
  opt = gets
  opt.chomp
end

def create_time_entry(harvest, opts)
  time_entry = Harvest::TimeEntry.new(opts)
  harvest.time.create(time_entry)
end

def create_day_entry(harvest, date, opts)
  opts[:spent_at] = date.to_s
  opts[:started_at] = "8:00"
  opts[:ended_at] = "11:30"
  entry = create_time_entry(harvest, opts)
  opts[:started_at] = "11:45"
  opts[:ended_at] = "17:00"
  entry = create_time_entry(harvest, opts)
end

def read_config
  path = "#{ENV['HOME']}/.timetracking"
  return {} unless File.exist?(path)
  Hashie.symbolize_keys!(YAML.load_file(path))
end

opts = read_config
if opts.empty?
  opts[:subdomain] = get_opts("Enter your harvest domain:")
  opts[:username] = get_opts("Enter your username:")
  opts[:password] = get_opts("Enter your password:")
end

HTTParty::Basement.default_options.update(verify: false)

harvest = Harvest.hardy_client(opts)
projects = harvest.projects.all
projects.each_with_index  do |p, id|
  puts "#{id}.\t#{p.name}"
end

project = get_opts("Select project").to_i
project = projects[project]
puts "#{project.name} was selected"

tasks = harvest.tasks.all
tasks.each_with_index  do |t, id|
  puts "#{id}.\t#{t.name}"
end

task = get_opts("Select task:").to_i
task = tasks[task]
puts "#{task.name} was selected"

time = {project_id: project.id, task_id: task.id}
date = Time.now.to_date

(date...Date.new(date.year, date.month + 1, 1)).each do |m|
  create_day_entry(harvest, m, time) unless m.saturday? || m.sunday?
end
