#
# = test/test_net_http.rb
#
# Copyright (c) 2006-2007 Justin Bailey
# 
# Written and maintained by Justin Bailey <jgbailey@gmail.com>.
#
# This program is free software. You can re-distribute and/or
# modify this program under the same terms of ruby itself ---
# Ruby Distribution License or GNU General Public License.
#

# Ruby gems > 0.9 loads patch automatically so DISABLE_RUBY_SSPI_PATCH doesn't do any good.
# Therefore, need to ensure ruby gems isn't loaded automatically.
if ENV["RUBYOPT"]
	puts "Unset RUBYOPT environment variable before running these tests."
	exit!
end

DISABLE_RUBY_SSPI_PATCH = true

require 'test/unit'
require 'net/http'
require 'pathname'
$: << (File.dirname(__FILE__) << "/../lib")
require 'win32/sspi/http_proxy_patch'

class NTLMTest < Test::Unit::TestCase
  def test_net_http
    proxy = get_proxy 
    Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
      resp = http.get("/")
      assert resp.code.to_i == 200, "Did not get response from Google as expected."
    end
  end
  
  def test_head_request
    proxy = get_proxy 
    Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
      resp = http.head("/")
      assert resp.code.to_i == 200, "Did not get response from Google as expected."
    end
    
  end
  
  def get_proxy
    assert ENV["http_proxy"], "http_proxy environment variable must be set."
    proxy = URI.parse(ENV["http_proxy"])
    assert proxy.host && proxy.port, "Could not parse http_proxy (#{ENV["http_proxy"]}). http_proxy should be a URL with a port (e.g. http://proxy.corp.com:8080)."
    
    return proxy
  end
end
