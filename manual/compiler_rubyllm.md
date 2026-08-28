## RubyLLM

`Tapioca::Dsl::Compilers::RubyLLM` decorates RBI files for models using the `acts_as_*` DSL of the
`ruby_llm` gem. https://github.com/crmne/ruby_llm

The gem includes its DSL into `ActiveRecord::Base` from an `ActiveSupport.on_load(:active_record)`
hook in its railtie, and each `acts_as_chat` / `acts_as_message` / `acts_as_model` /
`acts_as_tool_call` call then mixes the matching methods module into the model. None of that survives
gem RBI generation.

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Chat < ApplicationRecord
  acts_as_chat
end
~~~

This compiler will produce the RBI file `chat.rbi` with the following content:

~~~rbi
# chat.rbi
# typed: true
class Chat
  include RubyLLM::ActiveRecord::ChatMethods
  include RubyLLM::ActiveRecord::ActsAs
  extend RubyLLM::ActiveRecord::ActsAs::ClassMethods
end
~~~

The mixins are read off the model as it is actually configured, so `ask`, `with_instructions`,
`with_tool` and the rest keep the signatures they have in the gem RBI, and a model using the legacy
`ActsAsLegacy` API gets the modules that go with it. Models that never call an `acts_as_*` method are
left alone.
