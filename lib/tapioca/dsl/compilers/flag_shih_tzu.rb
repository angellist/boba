# typed: strict
# frozen_string_literal: true

return unless defined?(FlagShihTzu)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::FlagShihTzu` decorates RBI files for models
      # using FlagShihTzu.
      #
      # For example, with FlagShihTzu installed and the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #   has_flags(
      #     1 => :published,
      #     2 => :deleted,
      #   )
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   include FlagShihTzu
      #   include FlagShihTzuGeneratedMethods
      #
      #   module FlagShihTzuGeneratedMethods
      #     sig { returns(T::Boolean) }
      #     def published; end
      #     sig { params(value: T::Boolean).returns(T::Boolean) }
      #     def published=(value); end
      #     sig { returns(T::Boolean) }
      #     def published?; end
      #
      #     sig { returns(T::Boolean) }
      #     def deleted; end
      #     sig { params(value: T::Boolean).returns(T::Boolean) }
      #     def deleted=(value); end
      #     sig { returns(T::Boolean) }
      #     def deleted?; end
      #   end
      # end
      # ~~~
      class FlagShihTzu < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.all(T.class_of(::FlagShihTzu), ::FlagShihTzu::GeneratedClassMethods) } }

        InstanceMethodsModuleName = "FlagShihTzuGeneratedMethods"
        ClassMethodsModuleName = "::FlagShihTzu"

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[T::Module[T.anything]]) }
          def gather_constants
            all_classes.select { |c| c < ::FlagShihTzu }
          end
        end

        sig { override.void }
        def decorate
          return if constant.flag_mapping.blank?

          root.create_path(constant) do |klass|
            instance_module = RBI::Module.new(InstanceMethodsModuleName)

            # has_flags(
            #   1 => :warpdrive,
            #   2 => shields,
            #   column: 'features',
            # )
            constant.flag_mapping.each do |_, flags|
              # column: 'features', flags: { warpdrive: ..., shields: ... }
              flags.each do |flag_key, _|
                # .warpdrive
                # .warpdrive=
                # .warpdrive?
                # .warpdrive_changed?
                instance_module.create_method(flag_key.to_s, return_type: "T::Boolean")
                instance_module.create_method(
                  "#{flag_key}=",
                  parameters: [create_param("value", type: "T::Boolean")],
                  return_type: "T::Boolean",
                )
                instance_module.create_method("#{flag_key}?", return_type: "T::Boolean")
                instance_module.create_method("#{flag_key}_changed?", return_type: "T::Boolean")

                # .not_warpdrive
                # .not_warpdrive=
                # .not_warpdrive?
                instance_module.create_method("not_#{flag_key}", return_type: "T::Boolean")
                instance_module.create_method("not_#{flag_key}?", return_type: "T::Boolean")
                instance_module.create_method(
                  "not_#{flag_key}=",
                  parameters: [create_param("value", type: "T::Boolean")],
                  return_type: "T::Boolean",
                )

                # .has_warpdrive?
                instance_module.create_method("has_#{flag_key}?", return_type: "T::Boolean")
              end
            end

            klass << instance_module
            klass.create_include(ClassMethodsModuleName)
            klass.create_include(InstanceMethodsModuleName)
          end
        end
      end
    end
  end
end
