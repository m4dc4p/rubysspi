#
# = test/trace_proxy.rb
#
# Copyright (c) 2006-2007 Justin Bailey
# 
# Written and maintained by Justin Bailey <jgbailey@gmail.com>.
#
# This program is free software. You can re-distribute and/or
# modify this program under the same terms of ruby itself ---
# Ruby Distribution License or GNU General Public License.
#

# This file provides a trace of the HTTP request/response sequence between the local computer and the proxy. Useful
# for debugging problems with the library. Outputs trace to standard output.
 
# Magic constant will ensure that, if the SSPI patch has been applied, it won't break these tests
DISABLE_RUBY_SSPI_PATCH = true

require 'net/http'
require 'pathname'
$: << (File.dirname(__FILE__) << "/../lib")
require 'win32/sspi'

raise "http_proxy environment variable must be set." unless ENV["http_proxy"]
proxy = URI.parse(ENV["http_proxy"])
raise "Could not parse http_proxy (#{ENV["http_proxy"]}). http_proxy should be a URL with a port (e.g. http://proxy.corp.com:8080)." unless proxy.host && proxy.port

conn =  Net::HTTP.Proxy(proxy.host, proxy.port).new("www.google.com")
conn.set_debug_output $stdout
conn.start() do |http|
  nego_auth = Win32::SSPI::NegotiateAuth.new 
  sr = http.request_get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.get_initial_token("Negotiate") }
  if sr["Proxy-Authenticate"].include? "Negotiate"
    resp = http.get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.complete_authentication(sr["Proxy-Authenticate"].split(" ").last.strip) }
  elsif sr["Proxy-Authenticate"].include? "NTLM"
    sr = http.request_get "/", { "Proxy-Authorization" => "NTLM " + nego_auth.get_initial_token("NTLM") }
    resp = http.get "/", { "Proxy-Authorization" => "NTLM " + nego_auth.complete_authentication(sr["Proxy-Authenticate"].split(" ").last.strip) }
  end
  
  # Google redirects to country of origins domain if not US.
  raise "Response code not as expected: #{resp.inspect}" unless resp.code.to_i == 200 || resp.code.to_i == 302
  resp = http.get "/foobar.html"
  # Some proxy servers don't return 404 but 407.
  raise "Response code not as expected: #{resp.inspect}" unless resp.code.to_i == 404 || resp.code.to_i == 407
end
