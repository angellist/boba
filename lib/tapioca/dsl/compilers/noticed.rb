# typed: strict
# frozen_string_literal: true

return unless defined?(Noticed::Event)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Noticed` decorates RBI files for subclasses
      # of `Noticed::Event` and `Noticed::Ephemeral`.
      #
      # For example, with the following notifier class:
      #
      # ~~~rb
      # class NewCommentNotifier < Noticed::Event
      #   required_params :comment
      #   deliver_by :email
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `new_comment_notifier.rbi` with the following content:
      #
      # ~~~rbi
      # # new_comment_notifier.rbi
      # # typed: true
      # class NewCommentNotifier
      #   class << self
      #     sig { params(params: T::Hash[Symbol, T.untyped]).returns(T.class_of(NewCommentNotifier)) }
      #     def with(params); end
      #
      #     sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).void }
      #     def deliver(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end
      #
      #     sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).void }
      #     def deliver_later(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end
      #   end
      # end
      # ~~~
      class Noticed < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::Noticed::Event) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[T::Module[T.anything]]) }
          def gather_constants
            markers = [::Noticed::Event]
            markers << ::Noticed::Ephemeral if defined?(::Noticed::Ephemeral)

            all_classes.select do |klass|
              markers.any? { |marker| klass < marker }
            end
          end
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            klass.create_class("<<", superclass_name: "self") do |singleton|
              singleton.create_method(
                "with",
                parameters: [create_param("params", type: "T::Hash[Symbol, T.untyped]")],
                return_type: "T.class_of(::#{constant})",
              )

              singleton.create_method(
                "deliver",
                parameters: [
                  create_opt_param("recipients", type: "T.untyped", default: "T.unsafe(nil)"),
                  create_kw_opt_param("enqueue_job", type: "T.nilable(T::Boolean)", default: "T.unsafe(nil)"),
                  create_rest_param("options", type: "T.untyped"),
                ],
                return_type: "void",
              )

              singleton.create_method(
                "deliver_later",
                parameters: [
                  create_opt_param("recipients", type: "T.untyped", default: "T.unsafe(nil)"),
                  create_kw_opt_param("enqueue_job", type: "T.nilable(T::Boolean)", default: "T.unsafe(nil)"),
                  create_rest_param("options", type: "T.untyped"),
                ],
                return_type: "void",
              )
            end
          end
        end
      end
    end
  end
end
