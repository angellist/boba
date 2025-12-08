# typed: strict
# frozen_string_literal: true

return unless defined?(Paperclip)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Paperclip` decorates RBI files for classes that use the `has_attached_file` method
      # provided by the `paperclip` gem.
      # https://github.com/thoughtbot/paperclip
      #
      # For example, with the following ActiveRecord model:
      # ~~~rb
      # class Product < ActiveRecord::Base
      #   has_attached_file(:marketing_image)
      # end
      # ~~~
      #
      # This compiler will generate the following RBI:
      # ~~~rbi
      # class Product
      #  include PaperclipGeneratedMethods
      #
      #  module PaperclipGeneratedMethods
      #    sig { returns(::Paperclip::Attachment) }
      #    def marketing_image; end
      #
      #    sig { params(value: T.untyped).void }
      #    def marketing_image=(value); end
      #  end
      # end
      # ~~~
      class Paperclip < Tapioca::Dsl::Compiler
        extend T::Sig
        include RBIHelper

        ClassMethodsModuleName = "::Paperclip::Glue"
        InstanceMethodModuleName = "PaperclipGeneratedMethods"

        ConstantType = type_member { { fixed: T.class_of(::Paperclip::Glue) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[T::Module[T.anything]]) }
          def gather_constants
            all_classes.select { |c| c < ::Paperclip::Glue }
          end
        end

        sig { override.void }
        def decorate
          # this is a bit awkward, but load order determines the return order here, so sort to ensure consistency across
          # all environments.
          attachments = ::Paperclip::AttachmentRegistry.names_for(constant).sort
          return if attachments.empty?

          root.create_path(constant) do |klass|
            instance_module = RBI::Module.new(InstanceMethodModuleName)

            attachments.each do |attachment_name|
              # Model: has_attached_file(:marketing_image)
              # => marketing_image
              # => marketing_image=
              instance_module.create_method(attachment_name, return_type: "::Paperclip::Attachment")
              instance_module.create_method(
                "#{attachment_name}=",
                parameters: [create_param("value", type: "T.untyped")],
                return_type: nil,
              )
            end

            klass << instance_module
            klass.create_include(ClassMethodsModuleName)
            klass.create_include(InstanceMethodModuleName)
          end
        end
      end
    end
  end
end
