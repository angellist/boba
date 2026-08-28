# typed: strict
# frozen_string_literal: true

return unless defined?(PaperTrail)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::PaperTrail` decorates RBI files for models versioned with the `paper_trail`
      # gem. https://github.com/paper-trail-gem/paper_trail
      #
      # `PaperTrail::Model` is mixed into `ActiveRecord::Base` from the gem's railtie, and
      # `PaperTrail::Model::InstanceMethods` is mixed into a model by `has_paper_trail` itself. Neither runs
      # during gem RBI generation, so Sorbet sees neither the declaration nor what it adds.
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
      #   include PaperTrail::Model
      #   extend PaperTrail::Model::ClassMethods
      # end
      # ~~~
      #
      # The signatures of `has_paper_trail`, of the class-level `paper_trail` and of the instance-level
      # `paper_trail` all live in the gem RBI already, so declaring the mixins is enough. The `versions`
      # association is declared with `has_many` at runtime, which Tapioca's own association compiler sees.
      class PaperTrail < Tapioca::Dsl::Compiler
        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        # @override
        #: -> void
        def decorate
          root.create_path(constant) do |model|
            paper_trail_modules(constant.ancestors).each { |name| model.create_include(name) }
            paper_trail_modules(constant.singleton_class.ancestors).each { |name| model.create_extend(name) }
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

        #: (Array[Module[top]] ancestors) -> Array[String]
        def paper_trail_modules(ancestors)
          ancestors.filter_map do |ancestor|
            name = ancestor.name
            next unless name
            next unless name.start_with?("PaperTrail::")

            name
          end
        end
      end
    end
  end
end
