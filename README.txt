= Introduction

This library provides bindings to the Win32 SSPI libraries, which implement various security protocols for Windows. The library was primarily developed to give Negotiate/NTLM proxy authentication abilities to Net::HTTP, similar to support found in Internet Explorer or Firefox.

The libary is NOT an implementation of the NTLM protocol, and does not give the ability to authenticate as any given user. It is able to authenticate with a proxy server as the current user.

This project can be found on rubyforge at:

http://rubyforge.org/projects/rubysspi

= Using with rubygems (and other libraries)

If RubyGems is not working because of proxy authorization errors, the rubysspi library can be used to solve the problem. The gem includes a file called <tt>spa.rb</tt> in the root directory. Copy this file to your site_ruby directory and then run the gem script directly:

  ruby -rspa 'C:\Program Files\ruby\gem' 

For example, to list remote gems that match "sspi" this command can be used  

  ruby -rspa 'C:\Program Files\ruby\gem' list --remote sspi

You must copy the <tt>spa.rb</tt> file yourself, however. Rubygems is not able to do it for you on install.

= Using with open-uri

To use the library with open-uri, make sure to set the environment variable +http_proxy+ to your proxy server. This must be a hostname and port in URL form. E.g.:

  http://proxy.corp.com:8080
  
The library will grab your current username and domain from the environment variables +USERNAME+ and +USERDOMAIN+. This should be set for you by Windows already.

The library implements a patch on top of Net::HTTP, which means open-uri gets it too. At the top of your script, make sure to require the patch after <tt>open-uri</tt>:

  require 'open-uri'
  require 'win32/sspi/http_proxy_patch'
  
  open("http://www.google.com") { |f| puts(f.gets(nil)) }

Note that this patch does NOT work with the +http_proxy_user+ and +http_proxy_password+ environment variables. The library will ONLY authenticate as the current user.

= Using with Net::HTTP

Net::HTTP will not use the proxy server supplied in the environment variable automatically, so you have to supply the proxy address yourself. Otherwise, it's exactly the same:

  require 'net/http'
  require 'win32/sspi/http_proxy_patch'
  
  Net::HTTP::Proxy("proxy.corp.com", 8080).start("www.google.com") do |http|
    resp = http.request_get "/"
    puts resp.body
  end
  
= Using rubysspi directly

As stated, the library is geared primarily towards supporting Negotiate/NTLM authentication with proxy servers. In this vein, you can manually authenticate a given HTTP connection with a single call:

  require 'win32/sspi'

  Net::HTTP.Proxy(proxy.host, proxy.port).start("www.google.com") do |http|
    resp = SSPI::NegotiateAuth.proxy_auth_get http, "/"
  end

The +resp+ variable will contain the response from Google, with any proxy authorization necessary taken care of automatically. Note that if the +http+ connection is not closed, any subsequent requests will NOT require authentication. 

If the above method is used, you should NOT require the 'win32/sspi/http_proxy_patch' library, as the interaction between the two will fail.

The library can be used directly to generate tokens appropriate for the current user, too.

To get started, first create an instance of the SSPI::NegotiateAuth class:

  require 'win32/sspi'
  
  n = SSPI::NegotiateAuth.new
  
Next, get the first token by calling get_initial_token:

  token = n.get_initial_token
  
This token returned will be Base64 encoded and can be directly placed in an HTTP header. This token can be easily decoded, however, and is usually an NTLM Type 1 message.

After getting a response from the server (usually an NTLM Type 2 message), pass it into the complete_authentication:

  token = n.complete_authentication(server_token)
  
Note that server_token can be Base64 encoded or not, and if it starts with "Negotiate", that phrase will be stripped off. This allows the response from a Proxy-Authentication header to be passed into the method directly. The token can be decoded externally and passed in, too.

The token returned (usually an NTLM Type 3) message can then be sent to the server and the connection should be authenticated.

= Patching Ruby

 A short script to patch Net::HTTP is also included. This patch will give the Net::HTTP (and consequently, open-uri) the ability to directly authenticate with Negotiate/NTLM proxy servers. The main advantage of patching Ruby itself is that other scripts, such as gems, will work directly with these proxy servers and will not require running with the 'spa' library. Similarly, any scripts which use open-uri or Net::HTTP will gain the ability to authenticate with the proxy server.
 
 To run the script, just run <tt>apply_sspi_patch</tt>. The backup will be made of the original 'http.rb' file, and a new patched file will be copied in. After patching, run the test script 'test\test_patched_net_http.rb'. It ensures that proxy authentication now works without extra libraries. 
 
 Be aware - this has only been tested on Ruby 1.8.4 and 1.8.5. Though the Net::HTTP libraries are not likely to change much, do some testing afterwards. 
 
 If you want the patch disabled for a certain script, just define the constant DISABLE_RUBY_SSPI_PATCH at the top level. If you want to back the patch out, go to the ruby library directory, open the net folder, and rename the file called "http.orig.X.rb" (where X is some number) to http.rb. If the patch has been applied multiple times, uses the lowest "X" found. 
 
= Upgrading to a new version of the library

 If you have installed the RubySSPI library previously, and wish to upgrade to a new version, follow these steps:
 
  * Install the new version of the gem
  * If you applied the patch before, go to your Ruby library directory (under the One-click installer, its usually ruby\lib\ruby\1.8):
    * If any http.orig.N.rb files exist (where N is a number), then delete http.rb and rename the lowest http.orig.N.rb file to http.rb
    * Delete any other nttp.orig.N.rb files.
  * Run "apply_sspi_patch" to apply the patch again
 
= Disabling proxy for certain servers

 Sometimes it is necessary to NOT use the proxy for certain addresses, especially in a LAN environment. While not a feature directly provided by this library, setting the 'no_proxy' environment variable to a list of servers will ensure no proxy connection is made for them. The list should be comma-delimited, and can consist of any mix of domain names and ports. URLs, however, are not allowed. For example "somehost, somehost.corporate.com, myhost:9000, myhost.corporate.com:80" would all be legal. Note that if a port is NOT specified, then no proxying occurs for that host regardless of the port requested by open-uri. 
 
 Finally, the above technique will only work with the open-uri library. Net::HTTP will not use a proxy automatically in any case.

= Thanks & References

Many references were used in decoding both NTLM messages and integrating with the SSPI library. Among them are:

* Managed SSPI Sample - A .NET implementation of a simple client/server using SSPI. A complex undertaking but provides a great resource for playing with the API.
  * http://msdn.microsoft.com/library/?url=/library/en-us/dndotnet/html/remsspi.asp?frame=true
* John Lam's RubyCLR - http://www.rubyclr.com
  * Originally, I used RubyCLR to call into the Managed SSPI sample which really helped me decode what the SSPI interface did and how it worked. I did not end up using that implementation but it was great for research.
* The NTLM Authentication Protocol - The definitive explanation for the NTLM protocol (outside MS internal documents, I presume).
  * http://davenport.sourceforge.net/ntlm.html
* Ruby/NTLM - A pure Ruby implementation of the NTLM protocol. Again, not used in this project but invaluable for decoding NTLM messages and figuring out what SSPI was returning.
  * http://rubyforge.org/projects/rubyntlm/
* Seamonkey/Mozilla NTLM implementation - The only source for an implementation in an actual browser. How they figured out how to use SSPI themselves is beyond me.
  * http://lxr.mozilla.org/seamonkey/source/mailnews/base/util/nsMsgProtocol.cpp#899

And of course, thanks to my Lord and Savior, Jesus Christ. In the name of the Father, the Son, and the Holy Spirit.


