# typed: true
# frozen_string_literal: true

require "rails/railtie"

module Boba
  class EnumsRailtie < Rails::Railtie
    railtie_name(:boba)

    initializer("boba.add_enum_classes") do
      ActiveSupport.on_load(:active_record) do
        next if defined?(ActiveRecordTypedEnum)

        module ActiveRecordTypedEnum
          extend T::Sig
          extend T::Helpers

          module ClassMethods
            extend T::Sig
            extend T::Helpers
            include Kernel

            abstract!

            sig { abstract.returns(T::Hash[String, T::Hash[String, T.untyped]]) }
            def defined_enums; end

            sig { abstract.params(name: String, value: T.untyped).returns(T.untyped) }
            def const_set(name, value)
            end

            sig { abstract.params(name: String, block: T.proc.params(args: T.untyped).void).returns(T.untyped) }
            def define_method(name, &block)
            end

            sig { params(args: T.untyped, kwargs: T.untyped).returns(T.untyped) }
            def enum(*args, **kwargs)
              # Call the original enum method first
              result = super

              # Extract definitions based on how enum was called
              definitions = if args.first.is_a?(Hash)
                # Rails 6 style: enum(status: {draft: 0, published: 1})
                args.first
              elsif args.length >= 2
                # Rails 7 style: enum(:status, {draft: 0, published: 1})
                { args[0] => args[1] }
              elsif kwargs.any?
                # Keyword style: enum(status: {draft: 0, published: 1})
                kwargs
              else
                {}
              end

              # Add typed enum methods for each enum
              definitions.each_key do |name|
                enum_values = defined_enums.fetch(name.to_s, nil)
                next if enum_values.nil?

                enum_class = Class.new(T::Enum) do
                  enums { enum_values.each { |key, _| const_set(key.to_s.camelize, new(key)) } }
                end

                const_set(name.to_s.camelize, enum_class)

                # Define typed getter method
                define_method("typed_#{name}") do
                  value = send(name)
                  return if value.nil?

                  enum_class.try_deserialize(value)
                end

                # Define typed setter method
                define_method("typed_#{name}=") do |typed_value|
                  send("#{name}=", typed_value&.serialize)
                end
              end

              result
            end
          end

          mixes_in_class_methods(ClassMethods)
        end

        module ::ActiveRecord
          class Base
            include ActiveRecordTypedEnum
          end
        end
      end
    end
  end
end
