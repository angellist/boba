# typed: strict
# frozen_string_literal: true

return unless defined?(RubyLLM::ActiveRecord)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::RubyLLM` decorates RBI files for models using the `acts_as_*` DSL of the
      # `ruby_llm` gem. https://github.com/crmne/ruby_llm
      #
      # The gem includes its DSL into `ActiveRecord::Base` from an `ActiveSupport.on_load(:active_record)`
      # hook in its railtie, and each `acts_as_chat` / `acts_as_message` / `acts_as_model` /
      # `acts_as_tool_call` call then mixes the matching methods module into the model. None of that survives
      # gem RBI generation.
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Chat < ApplicationRecord
      #   acts_as_chat
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `chat.rbi` with the following content:
      #
      # ~~~rbi
      # # chat.rbi
      # # typed: true
      # class Chat
      #   include RubyLLM::ActiveRecord::ChatMethods
      #   include RubyLLM::ActiveRecord::ActsAs
      #   extend RubyLLM::ActiveRecord::ActsAs::ClassMethods
      # end
      # ~~~
      #
      # The mixins are read off the model as it is actually configured, so `ask`, `with_instructions`,
      # `with_tool` and the rest keep the signatures they have in the gem RBI, and a model using the legacy
      # `ActsAsLegacy` API gets the modules that go with it. Models that never call an `acts_as_*` method are
      # left alone.
      class RubyLLM < Tapioca::Dsl::Compiler
        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        MODULE_PREFIX = "RubyLLM::"

        # @override
        #: -> void
        def decorate
          root.create_path(constant) do |model|
            ruby_llm_modules(constant.ancestors).each { |name| model.create_include(name) }
            ruby_llm_modules(constant.singleton_class.ancestors).each { |name| model.create_extend(name) }
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActiveRecord::Base)
              .reject(&:abstract_class?)
              .select { |model| acts_as_model?(model) }
          end

          # The DSL itself is included into `ActiveRecord::Base`, so every model carries it. What tells a
          # model apart is the methods module an `acts_as_*` call mixed into the model itself.
          #: (singleton(::ActiveRecord::Base) model) -> bool
          def acts_as_model?(model)
            own_ancestors = model.ancestors - ::ActiveRecord::Base.ancestors

            own_ancestors.any? { |ancestor| ancestor.name&.start_with?(MODULE_PREFIX) }
          end
        end

        private

        #: (Array[Module[top]] ancestors) -> Array[String]
        def ruby_llm_modules(ancestors)
          ancestors.filter_map do |ancestor|
            name = ancestor.name
            next unless name
            next unless name.start_with?(MODULE_PREFIX)

            name
          end
        end
      end
    end
  end
end
