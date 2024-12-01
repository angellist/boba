# typed: true
# frozen_string_literal: true

return unless defined?(AttrJson::Record)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::AttrJson` decorates RBI files for classes that use the `AttrJson` gem.
      # https://github.com/jrochkind/attr_json
      #
      # For example, with the following ActiveRecord model:
      # ~~~rb
      # class Product < ActiveRecord::Base
      #   include AttrJson::Record
      #
      #   attr_json :price_cents, :integer
      # end
      # ~~~
      #
      # This compiler will generate the following RBI:
      # ~~~rbi
      # class Product
      #   include AttrJsonGeneratedMethods
      #   extend AttrJson::Record::ClassMethods
      #
      #   module AttrJsonGeneratedMethods
      #     sig { returns(::Integer) }
      #     def price_cents; end
      #
      #     sig { params(value: Integer).returns(::Integer) }
      #     def price_cents=(value); end
      #   end
      # end
      # ~~~
      class AttrJson < Tapioca::Dsl::Compiler
        extend T::Sig

        # Class methods module is already defined in the gem rbi, so just reference it here.
        ClassMethodsModuleName = "AttrJson::Record::ClassMethods"
        InstanceMethodModuleName = "AttrJsonGeneratedMethods"
        ConstantType = type_member { { fixed: T.any(T.class_of(::AttrJson::Record), T.class_of(::AttrJson::Model)) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |constant| constant < ::AttrJson::Record || constant < ::AttrJson::Model }
          end
        end

        sig { override.void }
        def decorate
          rbi_class = root.create_path(constant)
          instance_module = RBI::Module.new(InstanceMethodModuleName)

          decorate_attributes(instance_module)

          rbi_class << instance_module
          rbi_class.create_include(InstanceMethodModuleName)
          rbi_class.create_extend(ClassMethodsModuleName) if constant < ::AttrJson::Record
        end

        private

        def decorate_attributes(rbi_scope)
          constant.attr_json_registry
            .definitions
            .sort_by(&:name) # this is annoying, but we need to sort to force consistent ordering or the rbi checks fail
            .each do |definition|
              _, type, options = definition.original_args
              attribute_name = definition.name
              type_name = sorbet_type(type, array: !!options[:array], nilable: !!options[:nil])

              # Model: attr_json(:other_model_id, :string)
              # => other_model_id
              # => other_model_id=
              rbi_scope.create_method(attribute_name, return_type: type_name)
              rbi_scope.create_method(
                "#{attribute_name}=",
                parameters: [create_param("value", type: type_name)],
                return_type: type_name,
              )
            end
        end

        def symbol_type(type_name)
          return type_name if type_name.is_a?(Symbol)
          return type_name.to_sym if type_name.is_a?(String)

          type_name.type
        end

        def sorbet_type(type_name, array: false, nilable: false)
          sorbet_type = if type_name.respond_to?(:model)
            type_name.model
          else
            case symbol_type(type_name)
            when :string, :immutable_string, :text, :uuid, :binary
              "String"
            when :boolean
              "T::Boolean"
            when :integer, :big_integer
              "Integer"
            when :float
              "Float"
            when :decimal
              "BigDecimal"
            when :time, :datetime
              "Time"
            when :date
              "Date"
            when :money
              "Money"
            when :json
              "T.untyped"
            else
              "T.untyped"
            end
          end

          sorbet_type = "::#{sorbet_type}"
          sorbet_type = "T::Array[#{sorbet_type}]" if array
          sorbet_type = "T.nilable(#{sorbet_type})" if nilable # TODO: improve this

          sorbet_type
        end
      end
    end
  end
end
