# typed: strict
# frozen_string_literal: true

module Boba
  module Options
    class AssociationTypeOption < T::Enum
      extend T::Sig

      enums do
        Nilable = new("nilable")
        Persisted = new("persisted")
      end

      class << self
        extend T::Sig

        sig do
          params(
            options: T::Hash[String, T.untyped],
            block: T.proc.params(value: String, default_association_type_option: AssociationTypeOption).void,
          ).returns(AssociationTypeOption)
        end
        def from_options(options, &block)
          association_type_option = Nilable
          value = options["ActiveRecordAssociationTypes"]

          if value
            if has_serialized?(value)
              association_type_option = from_serialized(value)
            else
              block.call(value, association_type_option)
            end
          end

          association_type_option
        end
      end

      sig { returns(T::Boolean) }
      def persisted?
        self == AssociationTypeOption::Persisted
      end

      sig { returns(T::Boolean) }
      def nilable?
        self == AssociationTypeOption::Nilable
      end
    end
  end
end
