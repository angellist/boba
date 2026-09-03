# typed: strict
# frozen_string_literal: true

return unless defined?(ActionMCP::Tool)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActionMCPTool` decorates RBI files for tools of the `actionmcp` gem.
      # https://github.com/seuros/action_mcp
      #
      # `property` and `collection` declare an Active Model attribute, so Tapioca's own
      # `ActiveModelAttributes` compiler already generates a reader for each of them — but always nilable and,
      # for collections, always `T::Array[T.untyped]`. A tool knows more than the attribute does: a property
      # declared `required: true` is validated before `perform` runs, and a collection knows its item type.
      #
      # For example, with the following tool:
      #
      # ~~~rb
      # class SearchTool < ApplicationMCPTool
      #   property :query, type: "string", required: true
      #   property :limit, type: "integer"
      #   collection :tags, type: "string"
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `search_tool.rbi` with the following content:
      #
      # ~~~rbi
      # # search_tool.rbi
      # # typed: true
      # class SearchTool
      #   sig { returns(::String) }
      #   def query; end
      #
      #   sig { returns(T.nilable(T::Array[::String])) }
      #   def tags; end
      # end
      # ~~~
      #
      # `limit` is left to the `ActiveModelAttributes` compiler: nothing is known about it beyond the
      # attribute type. The readers generated here sit on the class itself, so they take precedence over the
      # ones in `GeneratedAttributeMethods` without conflicting with them.
      class ActionMCPTool < Tapioca::Dsl::Compiler
        ConstantType = type_member { { fixed: T.class_of(::ActionMCP::Tool) } }

        JSON_TYPES = {
          "string" => "::String",
          "integer" => "::Integer",
          "number" => "::Float",
          "boolean" => "T::Boolean",
          "object" => "T::Hash[::String, T.untyped]",
        }.freeze #: Hash[String, String]

        # @override
        #: -> void
        def decorate
          methods = readers_to_narrow
          return if methods.empty?

          root.create_path(constant) do |tool|
            methods.each do |name, type|
              tool.create_method(name, return_type: type)
            end
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActionMCP::Tool).reject { |tool| T.unsafe(tool).abstract? }
          end
        end

        private

        # Only properties the attribute type cannot describe on its own: required ones, whose reader is not
        # nilable, and collections, whose item type is known.
        #: -> Hash[String, String]
        def readers_to_narrow
          required = T.unsafe(constant)._required_properties.map(&:to_s)

          T.unsafe(constant)._schema_properties.each_with_object({}) do |(name, definition), methods|
            property_name = name.to_s
            type = type_for(definition)
            next unless type

            property_required = required.include?(property_name)
            next unless property_required || definition[:type].to_s == "array"

            methods[property_name] = property_required ? type : "T.nilable(#{type})"
          end
        end

        #: (Hash[Symbol, untyped] definition) -> String?
        def type_for(definition)
          json_type = definition[:type].to_s
          return array_type_for(definition) if json_type == "array"

          JSON_TYPES[json_type]
        end

        #: (Hash[Symbol, untyped] definition) -> String?
        def array_type_for(definition)
          item_type = definition.dig(:items, :type).to_s
          item = JSON_TYPES[item_type]
          return unless item

          "T::Array[#{item}]"
        end
      end
    end
  end
end
