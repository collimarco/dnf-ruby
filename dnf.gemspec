require_relative 'lib/dnf/version'

Gem::Specification.new do |s|
  s.name = 'dnf'
  s.version = Dnf::VERSION
  s.summary = 'Convert any boolean expression to disjunctive normal form (DNF).'
  s.author = 'Marco Colli'
  s.homepage = 'https://github.com/collimarco/dnf-ruby'
  s.license = 'MIT'
  s.files = `git ls-files`.split("\n")
  s.add_development_dependency 'rspec'
end
