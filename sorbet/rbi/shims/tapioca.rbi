# typed: true
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordRelations < Compiler
        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }
      end
    end

    module Helpers
      module ActiveRecordConstantsHelper
        RelationMethodsModuleName = T.let(T.unsafe(nil), String)
        AssociationRelationMethodsModuleName = T.let(T.unsafe(nil), String)

        RelationClassName = T.let(T.unsafe(nil), String)
        AssociationRelationClassName = T.let(T.unsafe(nil), String)
        AssociationsCollectionProxyClassName = T.let(T.unsafe(nil), String)
      end
    end
  end
end
