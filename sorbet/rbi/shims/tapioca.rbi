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
      module ActiveRecordColumnTypeHelper
        class ColumnTypeOption < T::Enum
          class << self
            sig do
              params(
                options: T::Hash[String, T.untyped],
                block: T.proc.params(value: String, default_column_type_option: ColumnTypeOption).void,
              ).returns(ColumnTypeOption)
            end
            def from_options(options, &block); end
          end

          sig { returns(T::Boolean) }
          def persisted?; end
          sig { returns(T::Boolean) }
          def untyped?; end
        end
      end

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
