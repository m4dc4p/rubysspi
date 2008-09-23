#
# = test/test_gem_list.rb
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
require 'rubygems'
$: << (File.dirname(__FILE__) << "/../lib")
require 'win32/sspi/http_proxy_patch'

class NTLMTest < Test::Unit::TestCase
  def setup
    assert ENV["http_proxy"], "http_proxy must be set before running tests."
  end
  
  # Previous implementation of rubysspi used dl/win32 and a
  # bug occurred when gem list was executed. This tests to ensure
  # bug does not come back.
  def test_gem_list
		
		if Gem::Version.new(Gem::RubyGemsVersion) < Gem::Version.new("1.2")
			Gem.manage_gems
			if Gem::Version.new(Gem::RubyGemsVersion) < Gem::Version.new("0.9.2")
				assert_nothing_raised "'gem list --remote rubysspi' failed to execute"  do
					Gem::GemRunner.new.run(%w(list rubysspi --remote --http-proxy ))
				end
			else 
				# --http-proxy  option not needed after 0.9.2 (at least)
				assert_nothing_raised "'gem list --remote rubysspi' failed to execute"  do
					Gem::GemRunner.new.run(%w(list rubysspi --remote))
				end
			end
		elsif Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new("1.2")
			require 'rubygems/command_manager'
			# Gem::GemRunner not used after 1.2
			assert_nothing_raised "'gem list --remote rubysspi' failed to execute"  do
				Gem::CommandManager.instance.run(%w(list rubysspi --remote))
			end
		end
  end
end
