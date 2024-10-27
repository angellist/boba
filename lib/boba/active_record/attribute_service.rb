# typed: strict
# frozen_string_literal: true

module Boba
  module ActiveRecord
    module AttributeService
      class << self
        extend T::Sig

        sig { params(constant: T.class_of(::ActiveRecord::Base), attribute: String).returns(T::Boolean) }
        def has_unconditional_presence_validator?(constant, attribute)
          return false unless constant.respond_to?(:validators_on)

          constant.validators_on(attribute).any? do |validator|
            next false unless validator.is_a?(::ActiveRecord::Validations::PresenceValidator)

            !validator.options.key?(:if) && !validator.options.key?(:unless) && !validator.options.key?(:on)
          end
        end

        sig { params(constant: T.class_of(::ActiveRecord::Base), column_name: String).returns(T::Boolean) }
        def has_non_null_database_constraint?(constant, column_name)
          column = constant.columns_hash[column_name]
          return false if column.nil?

          !column.null
        rescue StandardError
          false
        end

        sig { params(constant: T.class_of(::ActiveRecord::Base), column_name: String).returns(T::Boolean) }
        def virtual_attribute?(constant, column_name)
          constant.columns_hash[column_name].nil?
        end
      end
    end
  end
end
