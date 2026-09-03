## FriendlyId

`Tapioca::Dsl::Compilers::FriendlyId` decorates RBI files for models using the `friendly_id` gem.
https://github.com/norman/friendly_id

A model opts in with `extend FriendlyId`, but the modules that carry the DSL are mixed in from
`self.extended` and `Configuration#use` hooks at runtime, so Sorbet sees none of them: not the
`friendly_id` declaration itself, not `friendly`, and not the instance methods the `use:` modules add.

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
  extend FriendlyId

  friendly_id :title, use: :slugged
end
~~~

This compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  include FriendlyId::Slugged
  include FriendlyId::Model
  include FriendlyId::Reserved
  include FriendlyId::UnfriendlyUtils
  extend FriendlyId::Base

  module GeneratedAssociationRelationMethods
    sig { returns(PrivateAssociationRelation) }
    def friendly; end
  end

  module GeneratedRelationMethods
    sig { returns(PrivateRelation) }
    def friendly; end
  end
end
~~~

The mixins are taken from the model as it is actually configured, so a model using `use: :history`
or `use: :scoped` gets the modules that go with it. Their signatures already live in the gem RBI,
which leaves nothing to hand-write here. `friendly` is declared on the relation modules as well
because `ActiveRecord::Relation` reaches it by delegating to the model class.
