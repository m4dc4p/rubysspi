#
# = test/test_ruby_sspi.rb
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

# Magic constant will ensure that, if the SSPI patch has been applied, it won't break these tests
DISABLE_RUBY_SSPI_PATCH = true

require 'test/unit'
require 'net/http'
require 'pathname'
$: << (File.dirname(__FILE__) << "/../lib")
require 'win32/sspi'

class NTLMTest < Test::Unit::TestCase
  def test_auth
    proxy = get_proxy
    
    Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
      nego_auth = Win32::SSPI::NegotiateAuth.new 
      sr = http.request_get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.get_initial_token }
      resp = http.get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.complete_authentication(sr["Proxy-Authenticate"].split(" ").last.strip) }
      # Google redirects to country of origins domain if not US.
      assert success_or_redirect(resp.code), "Response code not as expected: #{resp.inspect}"
      resp = http.get "/foobar.html"
      # Some proxy servers don't return 404 but 407.
      assert(resp.code.to_i == 404 || resp.code.to_i == 407, "Response code not as expected: #{resp.inspect}")
    end
  end
  
  def test_proxy_auth_get
    proxy = get_proxy
    
    Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
      resp = Win32::SSPI::NegotiateAuth.proxy_auth_get http, "/"
      assert success_or_redirect(resp.code), "Response code not as expected: #{resp.inspect}"
    end
  end
  
  def test_one_time_use_only
    proxy = get_proxy
    
    Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
      nego_auth = Win32::SSPI::NegotiateAuth.new 
      sr = http.request_get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.get_initial_token }
      resp = http.get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.complete_authentication(sr["Proxy-Authenticate"].split(" ").last.strip) }
      assert success_or_redirect(resp.code), "Response code not as expected: #{resp.inspect}"
      assert_raises(RuntimeError, "Should not be able to call complete_authentication again") do
        nego_auth.complete_authentication "foo"
      end
    end
  end
  
  def test_token_variations
    proxy = get_proxy

    # Test that raw token works
    Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
      nego_auth = Win32::SSPI::NegotiateAuth.new 
      sr = http.request_get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.get_initial_token }
      token = Base64.decode64(sr["Proxy-Authenticate"].split(" ").last.strip)
      completed_token = nego_auth.complete_authentication(token)
      resp = http.get "/", { "Proxy-Authorization" => "Negotiate " + completed_token }
      assert success_or_redirect(resp.code), "Response code not as expected: #{resp.inspect}"
    end

    # Test that token w/ "Negotiate" header included works
    Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
      nego_auth = Win32::SSPI::NegotiateAuth.new 
      sr = http.request_get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.get_initial_token }
      resp = http.get "/", { "Proxy-Authorization" => "Negotiate " + nego_auth.complete_authentication(sr["Proxy-Authenticate"]) }
      assert success_or_redirect(resp.code), "Response code not as expected: #{resp.inspect}"
    end
  end
  
private
  
  # Gets the proxy from the environment and makes some assertions
  def get_proxy
    assert ENV["http_proxy"], "http_proxy environment variable must be set."
    proxy = URI.parse(ENV["http_proxy"])
    assert proxy.host && proxy.port, "Could not parse http_proxy (#{ENV["http_proxy"]}). http_proxy should be a URL with a port (e.g. http://proxy.corp.com:8080)."
    
    return proxy
  end
  
  # Returns true if code given is 200 or 302. I.e. if HTTP request was successful or resulted in redirect.
  def success_or_redirect(code)
    code.to_i == 200 || code.to_i == 302
  end
  
end
