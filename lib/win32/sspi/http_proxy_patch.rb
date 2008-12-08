#
# = win32/net/http_proxy_patch.rb
#
# Copyright (c) 2006-2007 Justin Bailey
# 
# Written and maintained by Justin Bailey <jgbailey@gmail.com>.
#
# This file extends code originally found in lib/net/net.http,
# see that file for attribution.
# 
# This program is free software. You can re-distribute and/or
# modify this program under the same terms of ruby itself ---
# Ruby Distribution License or GNU General Public License.
#

require 'net/http'
require 'win32/sspi'

module Net 
  # Replaces Net::HTTP.request to understand Negotiate HTTP proxy authorization. Uses native Win32
  # libraries to authentic as the current user (as defined by the ENV["USERNAME"] and ENV["USERDOMAIN"]
  # environment variables.
  class HTTP 
		
		# Indicates that net/http has been patched by SSPI.
		def self.sspi?
			true
		end

		# Suppress warnings about redefining request
		@old_verbose = $VERBOSE
		$VERBOSE = nil

    # Determines if authorization is required and returns
    # the expected type ("NTLM" or "Negotiate"). Otherwise,
    # returns nil.
		def sspi_auth_required?(res)
      header = 
        if proxy? && res.kind_of?(HTTPProxyAuthenticationRequired)
          "Proxy-Authenticate"
        elsif res.kind_of?(HTTPUnauthorized)
          "WWW-Authenticate"
        else
          nil
        end
        
      if header
        # Critical to start with Negotiate. NTLM is fallback.
        ["Negotiate", "NTLM"].find { |tok| res[header].include? tok }
      else
        nil
      end
		end
		
    def request(req, body = nil, &block) # :yield: +response+
      unless started?
        start {
          req['connection'] ||= 'close'
          return request(req, body, &block)
        }
      end
      if proxy_user()
        unless use_ssl?
          req.proxy_basic_auth proxy_user(), proxy_pass()
        end
      end

      req.set_body_internal body
      begin_transport req
        req.exec @socket, @curr_http_version, edit_path(req.path)
        begin
          res = HTTPResponse.read_new(@socket)
        end while res.kind_of?(HTTPContinue)
        if tok = sspi_auth_required?(res)
          begin
            n = Win32::SSPI::NegotiateAuth.new
            res.reading_body(@socket, req.response_body_permitted?) { }
            end_transport req, res
            begin_transport req
            if proxy?
              req["Proxy-Authorization"] = "#{tok} #{n.get_initial_token(tok)}"
              req["Proxy-Connection"] = "Keep-Alive"
            else
              req["Authorization"] = "#{tok} #{n.get_initial_token(tok)}"
            end
            # Some versions of ISA will close the connection if this isn't present.
            req["Connection"] = "Keep-Alive"
            req.exec @socket, @curr_http_version, edit_path(req.path)
            begin
              res = HTTPResponse.read_new(@socket)
            end while res.kind_of?(HTTPContinue)
            if (proxy? && res["Proxy-Authenticate"]) || (! proxy? && res["WWW-Authenticate"])
              res.reading_body(@socket, req.response_body_permitted?) { }
              if proxy?
                req["Proxy-Authorization"] = "#{tok} #{n.complete_authentication res["Proxy-Authenticate"]}"
                req["Proxy-Connection"] = "Keep-Alive"
              else
                token = res["WWW-Authenticate"].split(" ").last
                req["Authorization"] = "#{tok} #{n.complete_authentication token}"
              end
              req["Connection"] = "Keep-Alive"
              req.exec @socket, @curr_http_version, edit_path(req.path)
              begin
                res = HTTPResponse.read_new(@socket)
              end while res.kind_of?(HTTPContinue)
            end
          rescue
            exc = $!.exception("Error occurred during proxy negotiation. req: #{req["Proxy-Authorization"].inspect}; res: #{res.inspect}; Original message: #{$!.message}")
            exc.set_backtrace $!.backtrace
            raise exc
          end
        end

        res.reading_body(@socket, req.response_body_permitted?) {
          yield res if block_given?
        }
      end_transport req, res

      res
    end
		
		$VERBOSE = @old_verbose
  end
end
