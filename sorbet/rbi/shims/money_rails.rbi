# frozen_string_literal: true
# typed: strict

module MoneyRails::ActiveRecord::Monetizable
  class << self
    sig { returns(T::Array[String]) }
    def monetized_attributes; end
  end
end
