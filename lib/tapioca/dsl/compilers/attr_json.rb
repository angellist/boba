# typed: true
# frozen_string_literal: true

return unless defined?(AttrJson::Record)

require "boba/active_record/attribute_service"

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
      #     sig { returns(T.nilable(::Integer)) }
      #     def price_cents; end
      #
      #     sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
      #     def price_cents=(value); end
      #   end
      # end
      # ~~~
      #
      # A scalar attribute reads as `nil` until it is set, so it is typed as nilable unless it has a non-nil
      # `default:`. As with columns in `ActiveRecordColumnsPersisted`, an unconditional presence validator
      # (no `if:`, `unless:` or `on:`) types it as it is on a valid record instead:
      # `validates :price_cents, presence: true` turns the methods above into `returns(::Integer)` and
      # `params(value: ::Integer)`.
      class AttrJson < Tapioca::Dsl::Compiler
        # Class methods module is already defined in the gem rbi, so just reference it here.
        ClassMethodsModuleName = "AttrJson::Record::ClassMethods"
        InstanceMethodModuleName = "AttrJsonGeneratedMethods"
        ConstantType = type_member { { fixed: T.any(T.class_of(::AttrJson::Record), T.class_of(::AttrJson::Model)) } }

        class << self
          # @override
          #: -> Enumerable[Module]
          def gather_constants
            all_classes.select { |constant| constant < ::AttrJson::Record || constant < ::AttrJson::Model }
          end
        end

        # @override
        #: -> void
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
          # Both AttrJson::Record and AttrJson::Model bring in ActiveModel validations; the check lets Sorbet see it.
          klass = constant
          validated = klass if klass.is_a?(::ActiveModel::Validations::ClassMethods)

          constant.attr_json_registry
            .definitions
            .sort_by(&:name) # this is annoying, but we need to sort to force consistent ordering or the rbi checks fail
            .each do |definition|
              _, type, options = definition.original_args
              attribute_name = definition.name.to_s
              array = !!options[:array]
              # AttrJson has no option that forbids nil: an attribute reads as nil unless it has a default,
              # which AttrJson also fills in when a stored record lacks the key. An array one defaults to []
              # on its own unless the default is overridden. As with columns, an unconditional presence
              # validator types the attribute as it is on a valid record.
              nilable = array ? options.key?(:default) && options[:default].nil? : options[:default].nil?
              nilable &&= !(validated && Boba::ActiveRecord::AttributeService.has_unconditional_presence_validator?(
                validated,
                attribute_name,
              ))
              type_name = sorbet_type(type, array: array, nilable: nilable)

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
