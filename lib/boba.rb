# typed: true
# frozen_string_literal: true

module Boba
  require "boba/version"
  require "boba/relations_railtie" if defined?(Rails)
  require "boba/enums_railtie" if defined?(Rails)
end
