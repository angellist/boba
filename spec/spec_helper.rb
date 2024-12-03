# typed: strict
# frozen_string_literal: true

require "minitest/autorun"
require "minitest/hooks/default"
require "minitest/reporters"
require "minitest/spec"
require "rails/test_unit/line_filtering"
require "tapioca/internal"
require "tapioca/helpers/test/content"
require "tapioca/helpers/test/isolation"

require_relative "dsl_spec_helper"

backtrace_filter = Minitest::ExtensibleBacktraceFilter.default_filter
backtrace_filter.add_filter(%r{gems/sorbet-runtime})
backtrace_filter.add_filter(%r{gems/railties})
backtrace_filter.add_filter(%r{tapioca/helpers/test/})

Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new(color: true), ENV, backtrace_filter)

module Minitest
  class Test
    extend T::Sig
    extend Rails::LineFiltering
  end
end
