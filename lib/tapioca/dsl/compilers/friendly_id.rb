# typed: strict
# frozen_string_literal: true

return unless defined?(FriendlyId)

require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::FriendlyId` decorates RBI files for models using the `friendly_id` gem.
      # https://github.com/norman/friendly_id
      #
      # A model opts in with `extend FriendlyId`, but the modules that carry the DSL are mixed in from
      # `self.extended` and `Configuration#use` hooks at runtime, so Sorbet sees none of them: not the
      # `friendly_id` declaration itself, not `friendly`, and not the instance methods the `use:` modules add.
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #   extend FriendlyId
      #
      #   friendly_id :title, use: :slugged
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   include FriendlyId::Slugged
      #   include FriendlyId::Model
      #   include FriendlyId::Reserved
      #   include FriendlyId::UnfriendlyUtils
      #   extend FriendlyId::Base
      #
      #   module GeneratedAssociationRelationMethods
      #     sig { returns(PrivateAssociationRelation) }
      #     def friendly; end
      #   end
      #
      #   module GeneratedRelationMethods
      #     sig { returns(PrivateRelation) }
      #     def friendly; end
      #   end
      # end
      # ~~~
      #
      # The mixins are taken from the model as it is actually configured, so a model using `use: :history`
      # or `use: :scoped` gets the modules that go with it. Their signatures already live in the gem RBI,
      # which leaves nothing to hand-write here. `friendly` is declared on the relation modules as well
      # because `ActiveRecord::Relation` reaches it by delegating to the model class.
      class FriendlyId < Tapioca::Dsl::Compiler
        include Helpers::ActiveRecordConstantsHelper

        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        # @override
        #: -> void
        def decorate
          root.create_path(constant) do |model|
            model_mixins.each { |name| model.create_include(name) }
            model_class_mixins.each { |name| model.create_extend(name) }

            target_modules.each do |module_name, return_type|
              model.create_module(module_name).create_method("friendly", return_type: return_type)
            end
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActiveRecord::Base)
              .reject(&:abstract_class?)
              .select { |model| model.singleton_class.include?(::FriendlyId::Base) }
          end
        end

        private

        #: -> Array[String]
        def model_mixins
          friendly_id_modules(constant.ancestors - ::Object.ancestors)
        end

        #: -> Array[String]
        def model_class_mixins
          friendly_id_modules(constant.singleton_class.ancestors - ::Object.singleton_class.ancestors)
        end

        # `FriendlyId::ObjectUtils` and friends are mixed into `Object` when the gem is required, so they
        # are already part of the gem RBI. Only the modules the model itself picked up are of interest here.
        #: (Array[Module[top]] ancestors) -> Array[String]
        def friendly_id_modules(ancestors)
          ancestors.filter_map do |ancestor|
            name = ancestor.name
            next unless name
            next unless name.start_with?("FriendlyId::")

            name
          end
        end

        #: -> Array[[String, String]]
        def target_modules
          if compiler_enabled?("ActiveRecordRelations")
            [
              [RelationMethodsModuleName, RelationClassName],
              [AssociationRelationMethodsModuleName, AssociationRelationClassName],
            ]
          else
            [[RelationMethodsModuleName, "T.untyped"]]
          end
        end
      end
    end
  end
end
