# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'watchy/version'

Gem::Specification.new do |s|
  s.name        = 'watchy'
  s.version     = Watchy::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['David François']
  s.email       = ['david.francois@paymium.com']
  s.homepage    = 'https://github.com/paymium/watchy'
  s.summary     = 'The best way to keep an eye on your database'
  s.description = 'Watchy works by maintaining a copy of the database to watch and permanently enforcing a set of user-defined rules'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'

  s.add_dependency 'configliere'
  s.add_dependency 'mysql2'

  s.files        = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md)
  s.executables  = ['watchy']
  s.require_path = 'lib'
end
