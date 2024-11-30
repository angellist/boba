# typed: true
# frozen_string_literal: true

require "rails/railtie"

class Boba::RelationsRailtie < Rails::Railtie
  railtie_name(:boba)

  initializer("boba.add_private_relation_constant") do
    ActiveSupport.on_load(:active_record) do
      module AciveRecordInheritDefineRelationTypes
        def inherited(child)
          super(child)

          child.const_set("PrivateRelation", Object)
          child.const_set("PrivateAssociationRelation", Object)
          child.const_set("PrivateCollectionProxy", Object)
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
