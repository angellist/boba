# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "boba/version"

Gem::Specification.new do |spec|
  spec.name        = "boba"
  spec.version     = Boba::VERSION
  spec.summary     = "Custom Tapioca compilers"

  spec.authors     = ["Angellist"]
  spec.email       = ["alex.stathis@angellist.com"]
  spec.homepage    = "https://github.com/angellist/boba"
  spec.license     = "MIT"

  spec.files       = Dir.glob("lib/**/*.rb") + ["README.md", "LICENSE"]

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/angellist/boba/issues",
    "changelog_uri" => "https://github.com/angellist/boba/blob/#{Boba::VERSION}/History.md",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/angellist/boba/tree/#{Boba::VERSION}",
    "rubygems_mfa_required" => "true",
  }

  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency("sorbet-static-and-runtime", "~> 0.5")
  spec.add_dependency("tapioca", "<= 0.17.3")
end
