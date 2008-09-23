#
# = test/test_patched_net_http.rb
#
# Copyright (c) 2006-2007 Justin Bailey
# 
# Written and maintained by Justin Bailey <jgbailey@gmail.com>.
#
# This program is free software. You can re-distribute and/or
# modify this program under the same terms of ruby itself ---
# Ruby Distribution License or GNU General Public License.
#

require 'test/unit'
require 'net/http'

# Intended to test 'patched' version of Net::HTTP. Notice lack of requires at the top.
class PatchedRubyTest < Test::Unit::TestCase
  def setup
    assert ENV["http_proxy"], "http_proxy must be set before running tests."
  end
  
  def test_net_http
		
		assert_nothing_raised "net/http does not appear to be patched" do
			assert Net::HTTP.sspi?, "sspi? patch applied but did not return true."
		end
		
    assert ENV["http_proxy"], "http_proxy environment variable must be set."
    proxy = URI.parse(ENV["http_proxy"])
    assert proxy.host && proxy.port, "Could not parse http_proxy (#{ENV["http_proxy"]}). http_proxy should be a URL with a port (e.g. http://proxy.corp.com:8080)."
    
    Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
      resp = http.get("/")
      assert resp.code.to_i == 200, "Did not get response from Google as expected."
    end
  end
end
