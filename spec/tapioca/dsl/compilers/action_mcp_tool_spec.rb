# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "rails"
require "action_mcp"

module Tapioca
  module Dsl
    module Compilers
      class ActionMCPToolSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActionMCPTool" do
          describe "initialize" do
            it "gathers no constants if there are no tools" do
              assert_empty(gathered_constants)
            end

            it "gathers only concrete tools" do
              add_ruby_file("tools.rb", <<~RUBY)
                class SearchTool < ActionMCP::Tool
                  property :query, type: "string", required: true
                end

                class AbstractTool < ActionMCP::Tool
                  abstract!
                end
              RUBY

              assert_equal(["SearchTool"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates non-nilable readers for required properties and typed collections" do
              add_ruby_file("search_tool.rb", <<~RUBY)
                class SearchTool < ActionMCP::Tool
                  property :query, type: "string", required: true
                  property :limit, type: "integer"
                  collection :tags, type: "string"
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class SearchTool
                  sig { returns(::String) }
                  def query; end

                  sig { returns(T.nilable(T::Array[::String])) }
                  def tags; end
                end
              RBI

              assert_equal(expected, rbi_for(:SearchTool))
            end

            it "generates nothing for a tool without properties" do
              add_ruby_file("ping_tool.rb", <<~RUBY)
                class PingTool < ActionMCP::Tool
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:PingTool))
            end
          end
        end
      end
    end
  end
end
