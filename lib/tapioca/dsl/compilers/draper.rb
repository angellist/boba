# typed: strict
# frozen_string_literal: true

return unless defined?(Draper)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Draper` decorates RBI files for `Draper::Decorator`
      # subclasses and the source classes they decorate, provided by the `draper` gem.
      # https://github.com/drapergem/draper
      #
      # The compiler emits a typed `object` / `model` / underscored-source-name accessor
      # for every decorator, plus a typed `decorate` instance method on the source class.
      #
      # For example, with the following classes:
      # ~~~rb
      # class Post < ActiveRecord::Base
      # end
      #
      # class PostDecorator < Draper::Decorator
      # end
      # ~~~
      #
      # This compiler will generate the following RBI for the decorator:
      # ~~~rbi
      # class PostDecorator
      #   include DraperGeneratedInstanceMethods
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
      #
      # ## Why `delegate_all` is not supported
      #
      # `delegate_all` forwards every public instance method of the source class via
      # `method_missing`. Reflecting that into RBI requires emitting one explicit method
      # per name — Sorbet ignores `method_missing` for type inference, and there is no
      # other annotation that lets us say "this class has all the methods of that one"
      # without the `is_a?` lie of declaring `class PostDecorator < Post`.
      #
      # Mirroring AR's full instance method set per decorator turned out to be wildly
      # noisy in practice (several thousand lines per decorator on real models, mostly
      # AR-internal methods like `__callbacks` and `_before_commit_callbacks` that no
      # one calls through a decorator). Argument and return types also collapse to
      # `T.untyped`, so the noise doesn't even buy strong typing.
      #
      # The recommended pattern is therefore to access the source through the typed
      # `object` accessor — `decorator.object.title` carries the typing produced by
      # Tapioca's `ActiveRecordColumns` compiler, with no per-decorator bloat.
      #
      # Concretely, with `Post#title` (a string column):
      # ~~~rb
      # post = Post.new(title: "post 1")
      # post.title              # ✓ Sorbet sees ::String (from ActiveRecordColumns)
      #
      # decorator = post.decorate
      # decorator.title         # ✗ Sorbet errors — even with `delegate_all`, no
      #                         #   `title` is declared on PostDecorator
      # decorator.object.title  # ✓ Sorbet sees ::String (via the typed `object`)
      # ~~~
      class Draper < Tapioca::Dsl::Compiler
        InstanceMethodModuleName = "DraperGeneratedInstanceMethods"
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
      end
    end
  end
end
