# typed: strict
# frozen_string_literal: true

return unless defined?(PaperTrail)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::PaperTrail` decorates RBI files for models versioned with the `paper_trail`
      # gem. https://github.com/paper-trail-gem/paper_trail
      #
      # `PaperTrail::Model` is included into `ActiveRecord::Base` once, by the gem itself, so a
      # `sorbet/tapioca/require.rb` carrying `require "paper_trail/frameworks/active_record"` is enough for
      # `has_paper_trail` to land in the gem RBI — no compiler needed for that part. What no shim can express
      # is what `has_paper_trail` then does to the model that declares it, at runtime: it includes
      # `PaperTrail::Model::InstanceMethods` into that class and defines two accessors on it, one of them
      # under a name the model chooses.
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #   has_paper_trail
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   include PaperTrail::Model::InstanceMethods
      #
      #   sig { returns(T.nilable(::Post)) }
      #   def version; end
      #
      #   sig { params(value: T.nilable(::Post)).returns(T.nilable(::Post)) }
      #   def version=(value); end
      #
      #   sig { returns(T.nilable(::String)) }
      #   def paper_trail_event; end
      #
      #   sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
      #   def paper_trail_event=(value); end
      # end
      # ~~~
      #
      # `version` is named by the `:version` option, so its name is only knowable per model. The `versions`
      # association is declared with `has_many`, which Tapioca's own association compiler already sees.
      class PaperTrail < Tapioca::Dsl::Compiler
        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        # @override
        #: -> void
        def decorate
          reified_type = "T.nilable(::#{constant})"
          version_name = T.unsafe(constant).version_association_name.to_s

          root.create_path(constant) do |model|
            model.create_include("PaperTrail::Model::InstanceMethods")
            create_accessor(model, version_name, reified_type)
            create_accessor(model, "paper_trail_event", "T.nilable(::String)")
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActiveRecord::Base)
              .reject(&:abstract_class?)
              .select { |model| model.include?(::PaperTrail::Model::InstanceMethods) }
          end
        end

        private

        #: (RBI::Scope model, String name, String type) -> void
        def create_accessor(model, name, type)
          model.create_method(name, return_type: type)
          model.create_method(
            "#{name}=",
            parameters: [create_param("value", type: type)],
            return_type: type,
          )
        end
      end
    end
  end
end
