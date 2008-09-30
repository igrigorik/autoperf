#!/usr/bin/env ruby
#
# autoperf - tool to drive httperf benchmark tests for a web server

require 'rubygems'
require 'optparse'
require 'ruport'

class AutoPerf
  def initialize(opts = {})
    @conf = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: autoperf.rb [-c config]"

      opts.on("-c", "--config [string]", String, "configuration file") do |v|
        @conf = parse_config(v)
      end
    end.parse!

    run()
  end

  def parse_config(config_file)
    raise Errno::EACCES, "#{config_file} is not readable" unless File.readable?(config_file)

    conf = {}
    open(config_file).each { |line|
      line.chomp
      unless (/^\#/.match(line))
        if(/\s*=\s*/.match(line))
          param, value = line.split(/\s*=\s*/, 2)
          var_name = "#{param}".chomp.strip
          value = value.chomp.strip
          new_value = ''
          if (value)
            if value =~ /^['"](.*)['"]$/
              new_value = $1
            else
              new_value = value
            end
          else
            new_value = ''
          end
          conf[var_name] = new_value =~ /\d+/ ? new_value.to_i : new_value
        end
      end
    }

    return conf
  end

  def benchmark(conf)
    httperf_opt = conf.keys.grep(/httperf/).collect {|k| "--#{k.gsub(/httperf_/, '')} #{conf[k]}"}.join(" ")
    httperf_cmd = "httperf --hog --server #{conf['host']} --port #{conf['port']} #{httperf_opt}"

    res = Hash.new("")
    IO.popen("#{httperf_cmd} 2>&1") do |pipe|
      puts "\n#{httperf_cmd}"

      while((line = pipe.gets))
        res['output'] += line

        case line
        when /^Total: .*replies (\d+)/ then res['replies'] = $1
        when /^Connection rate: (\d+\.\d)/ then res['conn/s'] = $1
        when /^Request rate: (\d+\.\d)/ then res['req/s'] = $1
        when /^Reply time .* response (\d+\.\d)/ then res['reply time'] = $1
        when /^Net I\/O: (\d+\.\d)/ then res['net io (KB/s)'] = $1
        when /^Errors: total (\d+)/ then res['errors'] = $1
        when /^Reply rate .*min (\d+\.\d) avg (\d+\.\d) max (\d+\.\d) stddev (\d+\.\d)/ then
          res['replies/s min'] = $1
          res['replies/s avg'] = $2
          res['replies/s max'] = $3
          res['replies/s stddev'] = $4
        end
      end
    end

    return res
  end

  def run
    results = {}
    report = Table(:column_names => ['rate', 'conn/s', 'req/s', 'replies/s avg',
                                     'errors', 'net io (KB/s)'])

    (@conf['low_rate']..@conf['high_rate']).step(@conf['rate_step']) do |rate|
      results[rate] = benchmark(@conf.merge({'httperf_rate' => rate}))
      report << results[rate].merge({'rate' => rate})

      puts report.to_s
      puts results[rate]['output'] if results[rate]['errors'].to_i > 0
    end
  end
end

trap("INT") {
  puts "Terminating tests."
  Process.exit
}

AutoPerf.new()