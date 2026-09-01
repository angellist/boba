# typed: strict
# frozen_string_literal: true

return unless defined?(ActsAsTaggableOn)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActsAsTaggableOn` decorates RBI files for models using the
      # `acts-as-taggable-on` gem. https://github.com/mbleigh/acts-as-taggable-on
      #
      # `acts_as_taggable_on` itself needs no compiler: the gem extends `ActiveRecord::Base` from an
      # `ActiveSupport.on_load(:active_record)` hook, and anything that loads `ActiveRecord::Base` during gem
      # RBI generation fires it, so tapioca records the extend in the gem RBI. What only exists per model is
      # what the declaration then installs on the declaring class: the five mixin pairs that carry the
      # tagging API, and one set of accessors per tag context.
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #   acts_as_taggable_on :tags
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   include ActsAsTaggableOn::Taggable::Core
      #   extend ActsAsTaggableOn::Taggable::Core::ClassMethods
      #   include ActsAsTaggableOn::Taggable::Collection
      #   extend ActsAsTaggableOn::Taggable::Collection::ClassMethods
      #
      #   sig { returns(::ActsAsTaggableOn::TagList) }
      #   def all_tags_list; end
      #
      #   sig { params(options: T.untyped).returns(T.untyped) }
      #   def tag_counts(options = {}); end
      #
      #   sig { returns(::ActsAsTaggableOn::TagList) }
      #   def tag_list; end
      #
      #   sig { params(new_tags: T.untyped).returns(T.untyped) }
      #   def tag_list=(new_tags); end
      #
      #   sig { params(owner: T.untyped).returns(::ActsAsTaggableOn::TagList) }
      #   def tags_from(owner); end
      #
      #   sig { params(limit: Integer).returns(T.untyped) }
      #   def top_tags(limit = 10); end
      #
      #   class << self
      #     sig { params(options: T.untyped).returns(T.untyped) }
      #     def tag_counts(options = {}); end
      #
      #     sig { params(limit: Integer).returns(T.untyped) }
      #     def top_tags(limit = 10); end
      #   end
      # end
      # ~~~
      #
      # The mixins are declared rather than re-implemented, so `tagged_with`, `tag_list_on` and the rest keep
      # the signatures they have in the gem RBI. Only the per-context methods, which exist for the contexts of
      # this model alone, are generated.
      class ActsAsTaggableOn < Tapioca::Dsl::Compiler
        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        # Every `acts_as_taggable_on` call installs this set; the names are fixed, so there is nothing to
        # discover by walking ancestors.
        MIXINS = ["Core", "Collection", "Caching", "Ownership", "Related"] #: Array[String]

        # @override
        #: -> void
        def decorate
          tag_types = T.unsafe(constant).tag_types.map(&:to_s)
          return if tag_types.empty?

          root.create_path(constant) do |model|
            MIXINS.each do |mixin|
              model.create_include("ActsAsTaggableOn::Taggable::#{mixin}")
              model.create_extend("ActsAsTaggableOn::Taggable::#{mixin}::ClassMethods")
            end

            tag_types.each do |tag_type|
              create_context_methods(model, tag_type)
            end
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActiveRecord::Base)
              .reject(&:abstract_class?)
              .select { |model| model.respond_to?(:taggable?) && T.unsafe(model).taggable? }
          end
        end

        private

        #: (RBI::Scope model, String tag_type) -> void
        def create_context_methods(model, tag_type)
          singular = tag_type.singularize

          model.create_method("#{singular}_list", return_type: "::ActsAsTaggableOn::TagList")
          model.create_method(
            "#{singular}_list=",
            parameters: [create_param("new_tags", type: "T.untyped")],
            return_type: "T.untyped",
          )
          model.create_method("all_#{tag_type}_list", return_type: "::ActsAsTaggableOn::TagList")
          model.create_method(
            "#{tag_type}_from",
            parameters: [create_param("owner", type: "T.untyped")],
            return_type: "::ActsAsTaggableOn::TagList",
          )

          [false, true].each do |class_method|
            model.create_method(
              "#{singular}_counts",
              parameters: [create_opt_param("options", type: "T.untyped", default: "{}")],
              return_type: "T.untyped",
              class_method: class_method,
            )
            model.create_method(
              "top_#{tag_type}",
              parameters: [create_opt_param("limit", type: "Integer", default: "10")],
              return_type: "T.untyped",
              class_method: class_method,
            )
          end
        end
      end
    end
  end
end
