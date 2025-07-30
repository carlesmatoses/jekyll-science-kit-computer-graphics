# frozen_string_literal: true

require_relative "lib/jekyll-skcg/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-science-kit-computer-graphics"
  spec.version = JekyllSkcg::VERSION
  spec.authors = ["Carles"]
  spec.email = ["72021364+carlesmatoses@users.noreply.github.com"]

  spec.summary = "A comprehensive Jekyll plugin for computer graphics and scientific writing"
  spec.description = "Provides LaTeX-like features including figure management with captions and references, 3D canvas integration, mathematical formulas, bibliography support, and academic writing tools specifically designed for computer graphics articles and scientific posts."
  spec.homepage = "https://github.com/carlesmatoses/jekyll-science-kit-computer-graphics"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE*", "CHANGELOG.md", "sig/**/*"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "jekyll", ">= 3.0"
  spec.add_dependency "bibtex-ruby"
  
  # Development dependencies
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
