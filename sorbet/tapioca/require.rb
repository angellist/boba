# typed: true
# frozen_string_literal: true

# Add your extra requires here (`bin/tapioca require` can be used to bootstrap this list)

require "minitest/spec"
require "money-rails/active_record/monetizable"
require "rails/all"
require "rails/generators"
require "rails/generators/app_base"

tapioca_gem_folder = File.join(
  Gem::Specification.find_by_name("tapioca").gem_dir,
  "lib",
  "tapioca",
  "dsl",
  "**",
  "*.rb",
)
Dir[tapioca_gem_folder].each { |file| require file }
require "tapioca/helpers/test/dsl_compiler"
require "zeitwerk"
