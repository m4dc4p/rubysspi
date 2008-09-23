require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
	s.name = "rubysspi"
	s.summary = "A library which implements Ruby bindings to the Win32 SSPI library. Also includes a module to add Negotiate authentication support to Net::HTTP."
	s.version = "1.2.4"
	s.author = "Justin Bailey"
	s.email = "jgbailey @nospam@ gmail.com"
	s.homepage = "http://rubyforge.org/projects/rubysspi/"
	s.rubyforge_project = "http://rubyforge.org/projects/rubysspi/"
	s.description = <<EOS
This gem provides bindings to the Win32 SSPI libraries, primarily to support Negotiate (i.e. SPNEGO, NTLM)
authentication with a proxy server. Enough support is implemented to provide the necessary support for
the authentication.

A module is also provided which overrides Net::HTTP and adds support for Negotiate authentication to it.

This implies that open-uri automatically gets support for it, as long as the http_proxy environment variable
is set.
EOS

	s.files = FileList["lib/**/*", "test/*", "*.txt", "Rakefile", "spa.rb"].to_a
	s.bindir = "bin"
	s.executables = ["apply_sspi_patch"]

	s.require_path = "lib"

	s.has_rdoc = true
	s.extra_rdoc_files = ["README.txt", "CHANGELOG.txt", "LICENSE.txt"]
	s.rdoc_options << '--title' << 'Ruby SSPI -- Win32 SSPI Bindings for Ruby' <<
                       '--main' << 'README.txt' <<
                       '--line-numbers'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
