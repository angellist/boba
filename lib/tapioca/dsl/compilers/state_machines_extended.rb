# typed: ignore
# frozen_string_literal: true

require "tapioca/dsl/compilers/state_machines"

return unless defined?(Tapioca::Dsl::Compilers::StateMachines)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::StateMachinesExtended` extends the default state machines compiler provided by Tapioca
      # to allow for calling `with_state` and `without_state` on all Active Record relations. This is a temporary fix
      # until a more durable solution can be found for this type of issue.
      # See https://github.com/Shopify/tapioca/pull/1994#issuecomment-2302624697.
      class StateMachinesExtended < ::Tapioca::Dsl::Compilers::StateMachines
        ACTIVE_RECORD_RELATION_MODULE_NAMES = [
          "GeneratedRelationMethods",
          "GeneratedAssociationRelationMethods",
        ].freeze

        def decorate
          return if constant.state_machines.empty?

          # This is a hack to make sure the instance methods are defined on the constant. Somehow the constant is being
          # loaded but the actual `state_machine` call is not being executed, so the instance methods don't exist yet.
          # Instantiating an empty class fixes it.
          constant.try(:new)

          super()

          root.create_path(T.unsafe(constant)) do |klass|
            class_module_name = "StateMachineClassHelperModule"

            ACTIVE_RECORD_RELATION_MODULE_NAMES.each do |module_name|
              klass.create_module(module_name).create_include(class_module_name)
            end
          end
        end
      end
    end
  end
end
