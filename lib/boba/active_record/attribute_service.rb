# typed: strict
# frozen_string_literal: true

module Boba
  module ActiveRecord
    module AttributeService
      class << self
        extend T::Sig

        #: (singleton(::ActiveRecord::Base) constant, String attribute, ?column_name: String) -> bool
        def nilable_attribute?(constant, attribute, column_name: attribute)
          return false if has_non_null_database_constraint?(constant, column_name)

          !has_unconditional_presence_validator?(constant, attribute)
        end

        #: (singleton(::ActiveRecord::Base) constant, String column_name) -> bool
        def virtual_attribute?(constant, column_name)
          constant.columns_hash[column_name].nil?
        end

        #: (singleton(::ActiveRecord::Base) constant, String column_name) -> bool
        def has_non_null_database_constraint?(constant, column_name)
          column = constant.columns_hash[column_name]
          return false if column.nil?

          !column.null
        rescue StandardError
          false
        end

        #: (singleton(::ActiveRecord::Base) constant, String attribute) -> bool
        def has_unconditional_presence_validator?(constant, attribute)
          return false unless constant.respond_to?(:validators_on)

          constant.validators_on(attribute).any? do |validator|
            unconditional_presence_validator?(validator)
          end
        end

        private

        #: (ActiveModel::Validator validator) -> bool
        def unconditional_presence_validator?(validator)
          return false unless validator.is_a?(::ActiveRecord::Validations::PresenceValidator)

          unconditional_validator?(validator)
        end

        #: (ActiveModel::Validator validator) -> bool
        def unconditional_validator?(validator)
          !validator.options.key?(:if) && !validator.options.key?(:unless) && !validator.options.key?(:on)
        end
      end
    end
  end
end
