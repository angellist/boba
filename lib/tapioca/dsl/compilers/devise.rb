# typed: true
# frozen_string_literal: true

require "devise"

module Tapioca
  module Dsl
    module Compilers
      class Devise < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { upper: ActiveRecord::Base } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            return [] unless defined?(::Devise)

            ::Devise.mappings.values.map(&:class_name).map(&:constantize)
          end
        end

        sig { override.void }
        def decorate
          ::Devise.mappings.each do |key, mapping|
            root.create_path(ApplicationController) do |klass|
              klass.create_method("current_#{key}", return_type: "T.nilable(#{mapping.class_name})")
              klass.create_method("authenticate_#{key}!", return_type: "void")
              klass.create_method("#{key}_session", return_type: "T.nilable(T::Hash[T.untyped, T.untyped])")
              klass.create_method("#{key}_signed_in?", return_type: "T::Boolean")
            end
          end
        end
      end
    end
  end
end
