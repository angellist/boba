# typed: strict
# frozen_string_literal: true

require_relative("attribute_service")

module Boba
  module ActiveRecord
    module ReflectionService
      class << self
        extend T::Sig

        ReflectionType = T.type_alias do
          T.any(::ActiveRecord::Reflection::ThroughReflection, ::ActiveRecord::Reflection::AssociationReflection)
        end

        sig { params(reflection: ReflectionType).returns(T::Boolean) }
        def required_reflection?(reflection)
          return true if has_one_and_required_reflection?(reflection)

          belongs_to_and_non_optional_reflection?(reflection)
        end

        private

        sig { params(reflection: ReflectionType).returns(T::Boolean) }
        def has_one_and_required_reflection?(reflection)
          return false unless reflection.has_one?
          return true if !!reflection.options[:required]

          Boba::ActiveRecord::AttributeService.has_unconditional_presence_validator?(
            reflection.active_record,
            reflection.name.to_s,
          )
        end

        sig { params(reflection: ReflectionType).returns(T::Boolean) }
        def belongs_to_and_non_optional_reflection?(reflection)
          return false unless reflection.belongs_to?

          optional = if reflection.options.key?(:required)
            !reflection.options[:required]
          else
            reflection.options[:optional]
          end
          return !optional unless optional.nil?
          return true if Boba::ActiveRecord::AttributeService.has_non_null_database_constraint?(
            reflection.active_record,
            reflection.foreign_key.to_s,
          )
          return true if Boba::ActiveRecord::AttributeService.has_unconditional_presence_validator?(
            reflection.active_record,
            reflection.foreign_key.to_s,
          )
          return true if Boba::ActiveRecord::AttributeService.has_unconditional_presence_validator?(
            reflection.active_record,
            reflection.name.to_s,
          )

          # nothing defined, so fall back to the default active record config
          !!reflection.active_record.belongs_to_required_by_default
        end
      end
    end
  end
end
