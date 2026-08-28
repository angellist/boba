## ActionMCPTool

`Tapioca::Dsl::Compilers::ActionMCPTool` decorates RBI files for tools of the `actionmcp` gem.
https://github.com/seuros/action_mcp

`property` and `collection` declare an Active Model attribute, so Tapioca's own
`ActiveModelAttributes` compiler already generates a reader for each of them — but always nilable and,
for collections, always `T::Array[T.untyped]`. A tool knows more than the attribute does: a property
declared `required: true` is validated before `perform` runs, and a collection knows its item type.

For example, with the following tool:

~~~rb
class SearchTool < ApplicationMCPTool
  property :query, type: "string", required: true
  property :limit, type: "integer"
  collection :tags, type: "string"
end
~~~

This compiler will produce the RBI file `search_tool.rbi` with the following content:

~~~rbi
# search_tool.rbi
# typed: true
class SearchTool
  sig { returns(::String) }
  def query; end

  sig { returns(T.nilable(T::Array[::String])) }
  def tags; end
end
~~~

`limit` is left to the `ActiveModelAttributes` compiler: nothing is known about it beyond the
attribute type. The readers generated here sit on the class itself, so they take precedence over the
ones in `GeneratedAttributeMethods` without conflicting with them.
