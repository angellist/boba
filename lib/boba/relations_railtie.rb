# typed: true
# frozen_string_literal: true

require "rails/railtie"

class Boba::RelationsRailtie < Rails::Railtie
  railtie_name(:boba)

  initializer("boba.add_private_relation_constants") do
    ActiveSupport.on_load(:active_record) do
      module AciveRecordInheritDefineRelationTypes
        def inherited(child)
          super(child)

          # Tapioca defines these three classes for each active record model as proxies for the actual AR internal
          # classes. In order to be able to use these as types in signatures, we need to expose them as actual constants
          # at runtime. Tapioca intentionally obfuscates these classes because they're private, so exposing them is
          # _slightly_ dangerous in that someone could do something naughty. But we're not super worried about it.
          child.const_set("PrivateRelation", child.const_get(:ActiveRecord_Relation))
          child.const_set("PrivateAssociationRelation", child.const_get(:ActiveRecord_AssociationRelation))
          child.const_set("PrivateCollectionProxy", child.const_get(:ActiveRecord_Associations_CollectionProxy))

          # Expose a common type so that signatures can be typed to the broader `RelationType` since the three are often
          # used interchangeably.
          relation_type = T.type_alias do
            T.any(
              child.const_get(:PrivateRelation),
              child.const_get(:PrivateAssociationRelation),
              child.const_get(:PrivateCollectionProxy),
            )
          end
          child.const_set(:RelationType, relation_type)
        end
      end

      class ::ActiveRecord::Base
        class << self
          prepend AciveRecordInheritDefineRelationTypes
        end
      end
    end
  end
end
