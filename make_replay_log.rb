#!/usr/bin/env ruby
# Make replay log by extracting the URI from an Apache CLF log file
# replacing string 'match' by 'substitute' and concatenating them
# together by replacing \n by \0

progname = File.basename($0)

if ARGV.size < 2
  puts "Usage: ruby #{progname} 'match' 'substitute' file1 [file2 [file3]] > output_file"
  puts "Usage: cat logfile | ruby #{progname} 'match' 'substitute' > output_file"
  puts
  puts "Example: cat /var/log/access_log | ruby #{progname} '/app' '/' > replay_log"
  exit
end

match = ARGV.shift
sub   = ARGV.shift

ARGF.each do |line|
  request = line.split('"')[1]
  next if request.nil?
  
  uri = request.split[1]
  next if uri.nil?
  
  begin
    uri[match] = sub
  rescue IndexError
    # simply output line that don't contain the 'replace' string
  ensure
    print uri.chomp + "\0"
  end
end