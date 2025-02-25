# typed: strict
# frozen_string_literal: true

return unless defined?(MoneyRails)

require "tapioca/helpers/rbi_helper"
require "tapioca/dsl/helpers/active_record_column_type_helper"
require "boba/active_record/attribute_service"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::MoneyRails` decorates RBI files for classes that use the `monetize` method provided
      # by the `money-rails` gem.
      # https://github.com/RubyMoney/money-rails
      #
      # In order to use this compiler, you will need to add
      #   `require "money-rails/active_record/monetizable"`
      # to your `sorbet/tapioca/require.rb` file, since it relies on the module
      # `MoneyRails::ActiveRecord::Monetizable::ClassMethods` having been detected and sigs generated for it in the gem
      # rbis.
      #
      # For example, with the following ActiveRecord model:
      # ~~~rb
      # class Product < ActiveRecord::Base
      #   monetize :price_cents
      # end
      # ~~~
      #
      # This compiler will generate the following RBI:
      # ~~~rbi
      # class Product
      #  include MoneyRailsGeneratedMethods
      #
      #  module MoneyRailsGeneratedMethods
      #    sig { returns(::Money) }
      #    def price; end
      #
      #    sig { params(value: ::Money).returns(::Money) }
      #    def price=(value); end
      #  end
      # end
      # ~~~
      class MoneyRails < Tapioca::Dsl::Compiler
        extend T::Sig
        include RBIHelper

        ConstantType = type_member do
          {
            fixed: T.all(
              T.class_of(::MoneyRails::ActiveRecord::Monetizable),
              ::MoneyRails::ActiveRecord::Monetizable::ClassMethods,
            ),
          }
        end

        ClassMethodModuleName = "MoneyRails::ActiveRecord::Monetizable::ClassMethods"
        InstanceModuleName = "MoneyRailsGeneratedMethods"

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < ::MoneyRails::ActiveRecord::Monetizable }
          end
        end

        ColumnTypeOption = Tapioca::Dsl::Helpers::ActiveRecordColumnTypeHelper::ColumnTypeOption

        sig { returns(ColumnTypeOption) }
        def column_type_option
          @column_type_option ||= T.let(
            ColumnTypeOption.from_options(options) do |value, default_column_type_option|
              add_error(<<~MSG.strip)
                Unknown value for compiler option `ActiveRecordColumnTypes` given: `#{value}`.
                Proceeding with the default value: `#{default_column_type_option.serialize}`.
              MSG
            end,
            T.nilable(ColumnTypeOption),
          )
        end

        sig { override.void }
        def decorate
          return if constant.monetized_attributes.empty?

          root.create_path(constant) do |klass|
            instance_module = RBI::Module.new(InstanceModuleName)

            constant.monetized_attributes.each do |attribute_name, column_name|
              if column_type_option.untyped?
                type_name = "T.untyped"
              else
                type_name = "::Money"

                nilable_attribute = if constant < ::ActiveRecord::Base && column_type_option.persisted?
                  Boba::ActiveRecord::AttributeService.nilable_attribute?(
                    T.cast(constant, T.class_of(::ActiveRecord::Base)),
                    attribute_name,
                    column_name: column_name,
                  )
                else
                  true
                end

                type_name = as_nilable_type(type_name) if nilable_attribute
              end

              # Model: monetize :amount_cents
              # => amount
              # => amount=
              instance_module.create_method(attribute_name, return_type: type_name)
              instance_module.create_method(
                "#{attribute_name}=",
                parameters: [create_param("value", type: type_name)],
                return_type: type_name,
              )
            end

            klass << instance_module
            klass.create_include(InstanceModuleName)
            klass.create_extend(ClassMethodModuleName)
          end
        end
      end
    end
  end
end
