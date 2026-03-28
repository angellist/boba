# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

require "tapioca/dsl/helpers/active_record_constants_helper"
require "tapioca/dsl/compilers/active_record_relations"

return unless defined?(Tapioca::Dsl::Compilers::ActiveRecordRelations)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordRelationTypes` extends
      # `Tapioca::Dsl::Compilers::ActiveRecordRelationTypes` to generate a `RelationType` type alias for each class.
      # This type alias is defined a runtime through the Boba railtie, and is useful for typing signatures to accept or
      # return relations. For instance, with the following `ActiveRecord::Base` subclass:
      # ~~~rb
      # class Post < ApplicationRecord
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `post.rbi` with the following content:
      # ~~~rbi
      # # post.rbi
      # # typed: true
      #
      # class Post
      #   RelationType = T.any(PrivateRelation, PrivateAssociationRelation, PrivateCollectionProxy)
      # end
      # ~~~
      # So that the following method will accept any of the private relation types as an argument:
      # ~~~rb
      # sig { params(posts: Post::RelationType).void }
      # def process_posts(posts)
      #   # ...
      # end
      # ~~~
      class ActiveRecordRelationTypes < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          root.create_path(constant) do |rbi_class|
            relation_type_alias = "T.any(" \
              "#{Tapioca::Dsl::Helpers::ActiveRecordConstantsHelper::RelationClassName}, " \
              "#{Tapioca::Dsl::Helpers::ActiveRecordConstantsHelper::AssociationRelationClassName}, " \
              "#{Tapioca::Dsl::Helpers::ActiveRecordConstantsHelper::AssociationsCollectionProxyClassName}" \
              ")"
            rbi_class.create_type_variable("RelationType", type: "T.type_alias { #{relation_type_alias} }")
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[T::Module[T.anything]]) }
          def gather_constants
            Tapioca::Dsl::Compilers::ActiveRecordRelations.gather_constants
          end
        end
      end
    end
  end
end
