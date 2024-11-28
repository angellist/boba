# typed: true
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      module ActiveRecordConstantsHelper
        RelationMethodsModuleName = T.let(T.unsafe(nil), String)
        AssociationRelationMethodsModuleName = T.let(T.unsafe(nil), String)
      end
    end
  end
end
