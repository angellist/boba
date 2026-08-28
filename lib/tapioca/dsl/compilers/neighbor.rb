# typed: strict
# frozen_string_literal: true

return unless defined?(Neighbor)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Neighbor` decorates RBI files for models using the `neighbor` gem.
      # https://github.com/ankane/neighbor
      #
      # `Neighbor::Model` is extended into `ActiveRecord::Base` from an
      # `ActiveSupport.on_load(:active_record)` hook, which does not run during gem RBI generation, so
      # `has_neighbors` is invisible to Sorbet in the very model that declares it.
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Document < ApplicationRecord
      #   has_neighbors :embedding
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `document.rbi` with the following content:
      #
      # ~~~rbi
      # # document.rbi
      # # typed: true
      # class Document
      #   extend Neighbor::Model
      # end
      # ~~~
      #
      # `has_neighbors` and `neighbor_attributes` keep the signatures they have in the gem RBI. The
      # `nearest_neighbors` scope the gem defines per attribute is an ordinary Active Record scope, so
      # Tapioca's own `ActiveRecordScope` compiler already types it on the model's relations.
      class Neighbor < Tapioca::Dsl::Compiler
        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        # @override
        #: -> void
        def decorate
          root.create_path(constant) do |model|
            model.create_extend("Neighbor::Model")
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActiveRecord::Base)
              .reject(&:abstract_class?)
              .select { |model| model.singleton_class.include?(::Neighbor::Model) }
          end
        end
      end
    end
  end
end
