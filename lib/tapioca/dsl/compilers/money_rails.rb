# typed: strict
# frozen_string_literal: true

return unless defined?(MoneyRails)

require "tapioca/helpers/rbi_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::MoneyRails` decorates RBI files for classes that use the `monetize` method provided
      # by the `money-rails` gem.
      # https://github.com/RubyMoney/money-rails
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

        ConstantType = type_member { { fixed: T.class_of(::MoneyRails::ActiveRecord::Monetizable) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < ::MoneyRails::ActiveRecord::Monetizable }
          end
        end

        sig { override.void }
        def decorate
          return if constant.monetized_attributes.empty?

          root.create_path(constant) do |klass|
            instance_module_name = "MoneyRailsGeneratedMethods"
            instance_module = RBI::Module.new(instance_module_name)

            constant.monetized_attributes.each do |attribute_name, column_name|
              column = T.unsafe(constant).columns_hash[column_name]

              type_name = "::Money"
              type_name = as_nilable_type(type_name) if column.nil? || !!column.null

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
            klass.create_include(instance_module_name)
          end
        end
      end
    end
  end
end
