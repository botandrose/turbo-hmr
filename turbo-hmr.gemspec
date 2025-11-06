# frozen_string_literal: true

require_relative "lib/turbo/hmr/version"

Gem::Specification.new do |spec|
  spec.name = "turbo-hmr"
  spec.version = Turbo::Hmr::VERSION
  spec.authors = ["Micah Geisel"]
  spec.email = ["micah@botandrose.com"]

  spec.summary = "Hot Module Replacement for Turbo"
  spec.description = "Enables HMR (Hot Module Replacement) for ES modules during Turbo navigations, with special support for Stimulus controllers."
  spec.homepage = "https://github.com/botandrose/turbo-hmr"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 6.0"
  spec.add_dependency "importmap-rails"

  spec.add_development_dependency "rspec-rails", "~> 6.0"
end
