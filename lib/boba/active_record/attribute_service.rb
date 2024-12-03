# typed: strict
# frozen_string_literal: true

module Boba
  module ActiveRecord
    module AttributeService
      class << self
        extend T::Sig

        sig do
          params(
            constant: T.class_of(::ActiveRecord::Base),
            attribute: String,
            column_name: String,
          ).returns(T::Boolean)
        end
        def nilable_attribute?(constant, attribute, column_name: attribute)
          return false if has_non_null_database_constraint?(constant, column_name)

          !has_unconditional_presence_validator?(constant, attribute)
        end

        sig { params(constant: T.class_of(::ActiveRecord::Base), column_name: String).returns(T::Boolean) }
        def virtual_attribute?(constant, column_name)
          constant.columns_hash[column_name].nil?
        end

        sig { params(constant: T.class_of(::ActiveRecord::Base), column_name: String).returns(T::Boolean) }
        def has_non_null_database_constraint?(constant, column_name)
          column = constant.columns_hash[column_name]
          return false if column.nil?

          !column.null
        rescue StandardError
          false
        end

        sig { params(constant: T.class_of(::ActiveRecord::Base), attribute: String).returns(T::Boolean) }
        def has_unconditional_presence_validator?(constant, attribute)
          return false unless constant.respond_to?(:validators_on)

          constant.validators_on(attribute).any? do |validator|
            unconditional_presence_validator?(validator)
          end
        end

        private

        sig { params(validator: ActiveModel::Validator).returns(T::Boolean) }
        def unconditional_presence_validator?(validator)
          return false unless validator.is_a?(::ActiveRecord::Validations::PresenceValidator)

          unconditional_validator?(validator)
        end

        sig { params(validator: ActiveModel::Validator).returns(T::Boolean) }
        def unconditional_validator?(validator)
          !validator.options.key?(:if) && !validator.options.key?(:unless) && !validator.options.key?(:on)
        end
      end
    end
  end
end
