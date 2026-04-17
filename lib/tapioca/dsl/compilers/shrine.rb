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
      #   extend ShrineGeneratedClassMethods
      #
      #   module ShrineGeneratedClassMethods
      #     sig { params(options: T.untyped).returns(::Shrine::Attacher) }
      #     def image_attacher(**options); end
      #   end
      #
      #   module ShrineGeneratedMethods
      #     sig { returns(T.nilable(::Shrine::UploadedFile)) }
      #     def image; end
      #
      #     sig { params(value: T.untyped).returns(T.untyped) }
      #     def image=(value); end
      #
      #     sig { params(options: T.untyped).returns(T.nilable(::Shrine::Attacher)) }
      #     def image_attacher(**options); end
      #
      #     sig { returns(T::Boolean) }
      #     def image_changed?; end
      #
      #     sig { params(args: T.untyped, options: T.untyped).returns(T.nilable(String)) }
      #     def image_url(*args, **options); end
      #   end
      # end
      # ~~~
      class Shrine < Tapioca::Dsl::Compiler
        include RBIHelper

        InstanceMethodModuleName = "ShrineGeneratedMethods"
        ClassMethodModuleName = "ShrineGeneratedClassMethods"

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
          attachments = shrine_attachments(constant)
          return if attachments.empty?

          root.create_path(constant) do |klass|
            instance_module = RBI::Module.new(InstanceMethodModuleName)
            class_module = RBI::Module.new(ClassMethodModuleName)

            attachments.each do |attachment|
              name = attachment.attachment_name

              # Filter to methods that follow shrine's naming convention (<name> or <name>= or <name>_*).
              # This excludes method overrides like `reload` from the ActiveRecord plugin.
              attachment.instance_methods(false).sort
                .filter { |m| m == name || m == :"#{name}=" || m.start_with?("#{name}_") }
                .each do |method_name|
                method_obj = attachment.instance_method(method_name)
                instance_module.create_method(
                  method_name.to_s,
                  parameters: compile_parameters(method_obj),
                  return_type: return_type_for(name, method_name),
                )
              end

              # Class method from entity plugin:
              #   .<name>_attacher - returns a class-level attacher instance
              next unless constant.respond_to?(:"#{name}_attacher")

              class_method_obj = constant.method(:"#{name}_attacher")
              class_module.create_method(
                "#{name}_attacher",
                parameters: compile_parameters(class_method_obj),
                return_type: "::Shrine::Attacher",
              )
            end

            klass << instance_module
            klass.create_include(InstanceMethodModuleName)
            klass << class_module
            klass.create_extend(ClassMethodModuleName)
          end
        end

        private

        #: (singleton(Object) klass) -> Array[::Shrine::Attachment]
        def shrine_attachments(klass)
          klass.ancestors
            .filter_map { |ancestor| ancestor if ancestor.is_a?(::Shrine::Attachment) }
            .sort_by(&:attachment_name)
        end

        # Maps a dynamically discovered method name to its return type.
        #
        # Known method patterns (from shrine's entity/model plugins) are given
        # specific return types. Methods that don't match any known pattern
        # (e.g. those added by third-party shrine plugins) fall back to
        # T.untyped so they still appear in the generated RBI.
        #
        #   #<name>           -> entity plugin: returns the attached file
        #   #<name>_url       -> entity plugin: returns the URL to the file
        #   #<name>_attacher  -> entity plugin: returns the Attacher instance
        #   #<name>=          -> model plugin:  assigns a file (setter)
        #   #<name>_changed?  -> model plugin:  checks if attachment changed
        #
        #: (Symbol attachment_name, Symbol method_name) -> String?
        def return_type_for(attachment_name, method_name)
          case method_name
          when attachment_name
            "T.nilable(::Shrine::UploadedFile)"
          when :"#{attachment_name}_url"
            "T.nilable(::String)"
          when :"#{attachment_name}_attacher"
            "T.nilable(::Shrine::Attacher)"
          when /=$/
            nil
          when /\?$/
            "T::Boolean"
          else
            "T.untyped"
          end
        end

        #: (UnboundMethod | Method method_obj) -> Array[RBI::TypedParam]
        def compile_parameters(method_obj)
          method_obj.parameters.filter_map do |(type, name)|
            name_str = name.to_s
            name_str = "arg" if name_str.empty?
            case type
            when :req
              create_param(name_str, type: "T.untyped")
            when :opt
              create_opt_param(name_str, type: "T.untyped", default: "T.unsafe(nil)")
            when :rest
              create_rest_param(name_str, type: "T.untyped")
            when :keyreq
              create_kw_param(name_str, type: "T.untyped")
            when :key
              create_kw_opt_param(name_str, type: "T.untyped", default: "T.unsafe(nil)")
            when :keyrest
              create_kw_rest_param(name_str, type: "T.untyped")
            when :block
              create_block_param(name_str, type: "T.untyped")
            end
          end
        end
      end
    end
  end
end
