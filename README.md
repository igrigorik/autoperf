**For updated version, see: https://github.com/jmervine/autoperf**


Autoperf is a ruby driver for httperf, designed to help you automate load and performance testing of any web application - for a single end point, or through log replay. More: http://www.igvita.com/2008/09/30/load-testing-with-log-replay/

To get started, first download & install httperf:
http://www.hpl.hp.com/research/linux/httperf/

Next, either run a simple test straight from the command line (man httperf), or create
an execution plan for autoperf. If you want to replay an access log from your production
environment, follow these steps:

# grab last 10000 lines from nginx log, and extract a certain pattern (if needed)
tail -n 10000 nginx.log | grep "__pattern__" > requests

# extract the request path (ex. /homepage) from the log file
awk '{print $7}' requests > requests_path

# replace newlines with null terminators (httperf format)
tr "\n" "\0" < requests_path > replay_log

Next, configure your execution plan (see sample.conf), and run autoperf:
ruby autoperf.rb -c sample.conf

Sample output:
+-----------------------------------------------------------------------------+
| rate | conn/s | req/s | replies/s avg | errors | 5xx status | net io (KB/s) |
+-----------------------------------------------------------------------------+
|  100 | 99.9   | 99.9  | 99.7          | 0      | 0          | 45.4          |
|  120 | 119.7  | 119.7 | 120.0         | 0      | 0          | 54.4          |
|  140 | 139.3  | 139.3 | 138.0         | 0      | 0          | 63.6          |
|> 160 | 151.9  | 151.9 | 147.0         | 0      | 0          | 69.3          |
|  180 | 132.2  | 129.8 | 137.4         | 27     | 0          | 59.6          |
|  200 | 119.8  | 117.6 | 139.9         | 31     | 14         | 53.9          |
+-----------------------------------------------------------------------------+

If your server uses caching, making it pointless to run the same requests over
and over, you can use different requests for each run.

# Create 10 1000-line files (xa, xb, xc etc)
split -a 1 requests_path

# Convert to null-terminated strings
for x in x?; do tr "\n" "\0" < $x > $x.nul; done

# run as before, but use the `wlog` line instead of `httperf_wlog` in the conf file
ruby autoperf.rb -c sample.conf
