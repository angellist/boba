# typed: strict
# frozen_string_literal: true

return unless defined?(Shrine)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Shrine` decorates RBI files for classes that include
      # a `Shrine::Attachment` module provided by the `shrine` gem.
      # https://github.com/shrinerb/shrine
      #
      # For example, with the following model:
      # ~~~rb
      # class Photo < ActiveRecord::Base
      #   include ImageUploader::Attachment(:image)
      # end
      # ~~~
      #
      # This compiler will generate the following RBI:
      # ~~~rbi
      # class Photo
      #   include ShrineGeneratedMethods
      #
      #   module ShrineGeneratedMethods
      #     sig { returns(T.nilable(::Shrine::UploadedFile)) }
      #     def image; end
      #
      #     sig { params(value: T.untyped).returns(T.untyped) }
      #     def image=(value); end
      #
      #     sig { returns(T.nilable(::Shrine::Attacher)) }
      #     def image_attacher; end
      #
      #     sig { returns(T::Boolean) }
      #     def image_changed?; end
      #
      #     sig { returns(T.nilable(String)) }
      #     def image_url; end
      #   end
      #
      #   class << self
      #     sig { returns(::Shrine::Attacher) }
      #     def image_attacher; end
      #   end
      # end
      # ~~~
      class Shrine < Tapioca::Dsl::Compiler
        include RBIHelper

        InstanceMethodModuleName = "ShrineGeneratedMethods"

        ConstantType = type_member { { fixed: T.class_of(Object) } }

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            all_classes.select do |klass|
              klass.ancestors.any? { |ancestor| ancestor.is_a?(::Shrine::Attachment) }
            end
          end
        end

        # @override
        #: -> void
        def decorate
          attachments = shrine_attachments
          return if attachments.empty?

          root.create_path(constant) do |klass|
            instance_module = RBI::Module.new(InstanceMethodModuleName)

            attachments.each do |attachment|
              name = attachment.attachment_name

              # Instance methods from entity plugin:
              #   #<name>       - returns the attached file
              #   #<name>_url   - returns the URL to the attached file
              #   #<name>_attacher - returns the attacher instance
              instance_module.create_method(
                name.to_s,
                return_type: "T.nilable(::Shrine::UploadedFile)",
              )

              instance_module.create_method(
                "#{name}_url",
                return_type: "T.nilable(::String)",
              )

              instance_module.create_method(
                "#{name}_attacher",
                return_type: "T.nilable(::Shrine::Attacher)",
              )

              # Instance methods from model plugin:
              #   #<name>=        - assigns a file
              #   #<name>_changed? - returns whether the attachment has changed
              instance_module.create_method(
                "#{name}=",
                parameters: [create_param("value", type: "T.untyped")],
                return_type: nil,
              )

              instance_module.create_method(
                "#{name}_changed?",
                return_type: "T::Boolean",
              )

              # Class method from entity plugin:
              #   .<name>_attacher - returns a class-level attacher instance
              klass.create_method(
                "#{name}_attacher",
                return_type: "::Shrine::Attacher",
                class_method: true,
              )
            end

            klass << instance_module
            klass.create_include(InstanceMethodModuleName)
          end
        end

        private

        #: -> Array[::Shrine::Attachment]
        def shrine_attachments
          constant.ancestors
            .select { |ancestor| ancestor.is_a?(::Shrine::Attachment) }
            .sort_by(&:attachment_name)
        end
      end
    end
  end
end
