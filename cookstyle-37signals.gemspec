Gem::Specification.new do |s|
  s.name = "cookstyle-37signals"
  s.summary = "37signals style for Chef cookbooks"
  s.author = "37signals"
  s.email = "support@37signals.com"
  s.homepage = "https://github.com/basecamp/cookstyle-37signals"

  s.license = "MIT"

  s.version = "0.1.0"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">= 3.1"

  s.add_dependency "cookstyle", "~> 8.6"

  s.files = Dir["config/*.yml", "lib/**/*.rb", "exe/*"]
  s.bindir = "exe"
  s.executables = %w[ cookbook-lint ]
end
