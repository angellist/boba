# typed: strict
# frozen_string_literal: true

return unless defined?(Draper)

require "tapioca/dsl/helpers/parameter_compilation"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Draper` decorates RBI files for `Draper::Decorator`
      # subclasses and the source classes they decorate, provided by the `draper` gem.
      # https://github.com/drapergem/draper
      #
      # The compiler emits a typed `object` / `model` / underscored-source-name accessor
      # for every decorator, plus a typed `decorate` instance method on the source class.
      # When the decorator uses `delegate_all`, every public instance method of the source
      # class (column accessors, persistence methods, etc.) is also mirrored onto the
      # decorator with `T.untyped` argument and return types, so that calls like
      # `post.decorate.title` are visible to Sorbet. The source class's own RBI remains
      # the authoritative type source.
      #
      # For example, with the following classes:
      # ~~~rb
      # class Post < ActiveRecord::Base
      #   # columns: title:string, body:text, hidden:boolean, ...
      # end
      #
      # class PostDecorator < Draper::Decorator
      #   delegate_all
      # end
      # ~~~
      #
      # This compiler will generate the following RBI for the decorator:
      # ~~~rbi
      # class PostDecorator
      #   include DraperGeneratedInstanceMethods
      #   include DraperGeneratedDelegationMethods
      #
      #   module DraperGeneratedDelegationMethods
      #     sig { returns(T.untyped) }
      #     def title; end
      #
      #     sig { params(value: T.untyped).returns(T.untyped) }
      #     def title=(value); end
      #
      #     sig { returns(T.untyped) }
      #     def hidden?; end
      #
      #     # ... and every other public instance method on Post
      #   end
      #
      #   module DraperGeneratedInstanceMethods
      #     sig { returns(::Post) }
      #     def model; end
      #
      #     sig { returns(::Post) }
      #     def object; end
      #
      #     sig { returns(::Post) }
      #     def post; end
      #   end
      # end
      # ~~~
      #
      # And the following RBI for the source class:
      # ~~~rbi
      # class Post
      #   include DraperGeneratedDecoratableMethods
      #
      #   module DraperGeneratedDecoratableMethods
      #     sig { params(options: T.untyped).returns(::PostDecorator) }
      #     def decorate(options = T.unsafe(nil)); end
      #   end
      # end
      # ~~~
      class Draper < Tapioca::Dsl::Compiler
        include Helpers::ParameterCompilation

        InstanceMethodModuleName = "DraperGeneratedInstanceMethods"
        DelegationMethodModuleName = "DraperGeneratedDelegationMethods"
        DecoratableMethodModuleName = "DraperGeneratedDecoratableMethods"

        ConstantType = type_member { { fixed: T.class_of(Object) } }

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            decorators = gather_decorators
            decorators + gather_decoratables(decorators)
          end

          private

          # Decorator subclasses with an inferable `object_class` (e.g. `PostDecorator`).
          # Filters out anonymous classes and abstract bases like `ApplicationDecorator`
          # which have no `decorates` call. Uses Draper's own `object_class?` predicate.
          #: -> Array[singleton(::Draper::Decorator)]
          def gather_decorators
            descendants_of(::Draper::Decorator).select do |klass|
              klass.name && klass.object_class?
            end
          end

          # Source classes (e.g. `Post`) whose Draper-inferred decorator matches one of
          # the gathered decorators. The inference check ensures we only emit
          # `Source#decorate` when this decorator is the one Draper would actually
          # return at runtime, avoiding conflicting return-type RBIs when multiple
          # decorators target the same source.
          #: (Array[singleton(::Draper::Decorator)] decorators) -> Array[Class[top]]
          def gather_decoratables(decorators)
            decorators.filter_map do |decorator|
              source = decorator.object_class
              source if source.is_a?(Class) &&
                source < ::Draper::Decoratable &&
                T.unsafe(source).decorator_class? == decorator
            end
          end
        end

        # @override
        #: -> void
        def decorate
          if constant.is_a?(Class) && constant < ::Draper::Decorator
            decorate_decorator(T.cast(constant, T.class_of(::Draper::Decorator)))
          else
            decorate_decoratable(T.unsafe(constant))
          end
        end

        private

        #: (singleton(::Draper::Decorator) decorator) -> void
        def decorate_decorator(decorator)
          object_class = decorator.object_class
          object_class_name = "::#{object_class.name}"

          root.create_path(decorator) do |klass|
            instance_module = RBI::Module.new(InstanceMethodModuleName)

            instance_module.create_method("object", return_type: object_class_name)
            instance_module.create_method("model", return_type: object_class_name)

            # `create_method` silently no-ops on names Prism rejects (e.g. `Foo::Bar`
            # underscoring to `foo/bar`), so we only need to guard against `object` /
            # `model` which we already create above.
            underscore_name = object_class.name.to_s.underscore
            if underscore_name != "object" && underscore_name != "model"
              instance_module.create_method(underscore_name, return_type: object_class_name)
            end

            klass << instance_module
            klass.create_include(InstanceMethodModuleName)

            if decorator.include?(::Draper::AutomaticDelegation)
              add_delegated_methods(klass, decorator, object_class)
            end
          end
        end

        #: (Class[top] source) -> void
        def decorate_decoratable(source)
          decorator = T.unsafe(source).decorator_class
          decorator_class_name = "::#{decorator.name}"

          root.create_path(source) do |klass|
            decoratable_module = RBI::Module.new(DecoratableMethodModuleName)
            decoratable_module.create_method(
              "decorate",
              parameters: [create_opt_param("options", type: "T.untyped", default: "T.unsafe(nil)")],
              return_type: decorator_class_name,
            )

            klass << decoratable_module
            klass.create_include(DecoratableMethodModuleName)
          end
        end

        # Emits a `DraperGeneratedDelegationMethods` module mirroring every method
        # returned by `delegatable_methods`. Parameter shape is preserved; types fall
        # back to `T.untyped` since the source class's own RBI is the authoritative
        # type source.
        #: (RBI::Scope klass, singleton(::Draper::Decorator) decorator, Class[top] object_class) -> void
        def add_delegated_methods(klass, decorator, object_class)
          eagerly_define_attribute_methods(object_class)

          method_names = delegatable_methods(decorator, object_class)
          return if method_names.empty?

          delegation_module = RBI::Module.new(DelegationMethodModuleName)

          method_names.each do |method_name|
            method_obj = T.unsafe(object_class).instance_method(method_name)
            delegation_module.create_method(
              method_name.to_s,
              parameters: compile_parameters(method_obj),
              return_type: "T.untyped",
            )
          end

          klass << delegation_module
          klass.create_include(DelegationMethodModuleName)
        end

        # ActiveRecord defines column accessors lazily; they only appear in `instance_methods`
        # after `define_attribute_methods` runs. Trigger it so `delegate_all` picks up
        # column-derived methods like `title`, `title=`, `title?`, etc.
        #: (Class[top] object_class) -> void
        def eagerly_define_attribute_methods(object_class)
          return unless object_class.respond_to?(:define_attribute_methods)

          T.unsafe(object_class).define_attribute_methods
        end

        # The set of method names that `delegate_all` would forward to `object` at
        # runtime. Mirrors `Draper::AutomaticDelegation#delegatable?`.
        #
        # Set arithmetic — `delegatable = S − D − U − P`:
        #
        #   | sym | source                                       | role                                  |
        #   |-----|----------------------------------------------|---------------------------------------|
        #   | `S` | `object_class.public_instance_methods`       | candidates from the source class      |
        #   | `D` | `::Draper::Decorator.public_instance_methods`| already on Decorator (covers Object)  |
        #   | `U` | `decorator.instance_methods(false)`          | user-defined public/protected on sub  |
        #   | `P` | `decorator.private_instance_methods(false)`  | user-defined private (short-circuits) |
        #
        # Example outcomes:
        #
        #   | method                              | S | D | U | P | delegated? |
        #   |-------------------------------------|---|---|---|---|------------|
        #   | `Post#title` (column accessor)      | ✓ | ✗ | ✗ | ✗ |     ✓      |
        #   | `Post#save` (AR persistence)        | ✓ | ✗ | ✗ | ✗ |     ✓      |
        #   | `Object#object_id` (via Post)       | ✓ | ✓ | ✗ | ✗ |     ✗      |
        #   | `==` (Decorator overrides Post's)   | ✓ | ✓ | ✗ | ✗ |     ✗      |
        #   | user wrote `def title` on decorator | ✓ | ✗ | ✓ | ✗ |     ✗      |
        #   | user wrote `private def title`      | ✓ | ✗ | ✗ | ✓ |     ✗      |
        #
        # Names Ruby's parser rejects (e.g. `define_method(:"foo bar")`) are filtered
        # out downstream by `RBI::Scope#create_method`, which calls
        # `Tapioca::RBIHelper.valid_method_name?`.
        #: (singleton(::Draper::Decorator) decorator, Class[top] object_class) -> Array[Symbol]
        def delegatable_methods(decorator, object_class)
          (
            object_class.public_instance_methods -
            ::Draper::Decorator.public_instance_methods -
            decorator.instance_methods(false) -
            decorator.private_instance_methods(false)
          ).sort
        end
      end
    end
  end
end
