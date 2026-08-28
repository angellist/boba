## PaperTrail

`Tapioca::Dsl::Compilers::PaperTrail` decorates RBI files for models versioned with the `paper_trail`
gem. https://github.com/paper-trail-gem/paper_trail

`PaperTrail::Model` is mixed into `ActiveRecord::Base` from the gem's railtie, and
`PaperTrail::Model::InstanceMethods` is mixed into a model by `has_paper_trail` itself. Neither runs
during gem RBI generation, so Sorbet sees neither the declaration nor what it adds.

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
  has_paper_trail
end
~~~

This compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  include PaperTrail::Model::InstanceMethods
  include PaperTrail::Model
  extend PaperTrail::Model::ClassMethods
end
~~~

The signatures of `has_paper_trail`, of the class-level `paper_trail` and of the instance-level
`paper_trail` all live in the gem RBI already, so declaring the mixins is enough. The `versions`
association is declared with `has_many` at runtime, which Tapioca's own association compiler sees.
