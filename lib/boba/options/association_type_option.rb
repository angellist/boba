# typed: strict
# frozen_string_literal: true

module Boba
  module Options
    class AssociationTypeOption < T::Enum
      enums do
        Nilable = new("nilable")
        Persisted = new("persisted")
      end

      class << self
        #: (
        #|   Hash[String, untyped] options
        #| ) { (String value, AssociationTypeOption default_association_type_option) -> void } -> AssociationTypeOption
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

      #: -> bool
      def persisted?
        self == AssociationTypeOption::Persisted
      end

      #: -> bool
      def nilable?
        self == AssociationTypeOption::Nilable
      end
    end
  end
end
