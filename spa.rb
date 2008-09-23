# Copy this file to site_ruby directory to enable inclusion of Negotiate authoritation on arbitrary scripts. 
# For example, to run gems w/ the library use:
#
#  ruby -rspa 'C:\Program Files\ruby\bin\gem'
#
# Notice the gem script is executed directly, instead of executing the gem.cmd file.
#

require 'pathname'
if (Pathname.new(__FILE__).dirname + "/lib/sspi.rb").exist? 
  # If running directly from root of gem, load rubysspi directly
  $: << (Pathname.new(__FILE__).dirname + "/lib").to_s
  require 'win32/sspi/http_proxy_patch'
else
  # Production require - must be running from site_ruby. Use rubygems to get
  # to rubysspi 
  require 'rubygems'
  require 'win32/sspi/http_proxy_patch'
end
