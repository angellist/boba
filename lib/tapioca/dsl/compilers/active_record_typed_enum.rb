# typed: true
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordTypedEnum` generates type-safe enum classes and methods
      # for ActiveRecord models that use the built-in enum feature.
      #
      # For each enum defined in a model, this compiler:
      # 1. Creates a `T::Enum` subclass with all the enum values
      # 2. Generates `typed_<enum_name>` getter method that returns the enum instance
      # 3. Generates `typed_<enum_name>=` setter method that accepts the enum instance
      #
      # The compiler respects the nullability of the enum attribute based on the database schema.
      #
      # For example, with the following ActiveRecord model:
      #
      # ~~~rb
      # class Order < ActiveRecord::Base
      #   enum status: { pending: 0, processing: 1, completed: 2, cancelled: 3 }
      #   enum priority: { low: 0, medium: 1, high: 2 }, _prefix: true
      # end
      # ~~~
      #
      # This compiler will produce the following RBI:
      #
      # ~~~rbi
      # class Order
      #   class Status < T::Enum
      #     enums do
      #       Pending = new(0)
      #       Processing = new(1)
      #       Completed = new(2)
      #       Cancelled = new(3)
      #     end
      #   end
      #
      #   class Priority < T::Enum
      #     enums do
      #       Low = new(0)
      #       Medium = new(1)
      #       High = new(2)
      #     end
      #   end
      #
      #   sig { returns(Order::Status) }
      #   def typed_status; end
      #
      #   sig { params(value: Order::Status).returns(void) }
      #   def typed_status=(value); end
      #
      #   sig { returns(Order::Priority) }
      #   def typed_priority; end
      #
      #   sig { params(value: Order::Priority).returns(void) }
      #   def typed_priority=(value); end
      # end
      # ~~~
      class ActiveRecordTypedEnum < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(ActiveRecord::Base) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            ActiveRecord::Base.descendants.select do |klass|
              klass.respond_to?(:defined_enums) && klass.defined_enums.any? && klass.table_exists?
            end
          end
        end

        sig { override.void }
        def decorate
          return unless constant.respond_to?(:defined_enums)

          constant.defined_enums.each do |enum_name, enum_values|
            # Create the enum class
            enum_class_name = enum_name.camelize

            root.create_path(constant) do |model|
              # Create the T::Enum using RBI::TEnum
              enum_class =
                RBI::TEnum.new(enum_class_name) do |tenum|
                  # Try to create a TEnumBlock for the enums do block
                  enum_block =
                    RBI::TEnumBlock.new do |block|
                      enum_values.each do |key, _|
                        block.create_constant(key.to_s.camelize, value: "new('#{key}')")
                      end
                    end

                  tenum << enum_block
                end

              model << enum_class

              nullability = Boba::ActiveRecord::AttributeService.nilable_attribute?(constant, enum_name)
              base_enum_type = "#{constant}::#{enum_class_name}"
              enum_type = nullability ? "T.nilable(#{base_enum_type})" : base_enum_type

              # Generate typed getter
              model.create_method("typed_#{enum_name}", return_type: enum_type)

              # Generate typed setter
              model.create_method(
                "typed_#{enum_name}=",
                parameters: [create_param("value", type: enum_type)],
                return_type: "void",
              )
            end
          end
        end
      end
    end
  end
end
