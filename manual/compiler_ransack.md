## Ransack

`Tapioca::Dsl::Compilers::Ransack` decorates RBI files for models searchable with the `ransack` gem.
https://github.com/activerecord-hackery/ransack

Ransack extends `ActiveRecord::Base` from an `ActiveSupport.on_load(:active_record)` hook, which does
not run during gem RBI generation, so neither the class methods (`ransack`, `ransacker`,
`ransackable_attributes`, ...) nor their relation-delegated counterparts are visible to Sorbet.

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
end
~~~

This compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  extend Ransack::Adapters::ActiveRecord::Base

  module GeneratedAssociationRelationMethods
    sig { params(params: T.untyped, options: T.untyped).returns(::Ransack::Search) }
    def ransack(params = nil, options = nil); end

    sig { params(params: T.untyped, options: T.untyped).returns(::Ransack::Search) }
    def ransack!(params = nil, options = nil); end
  end

  module GeneratedRelationMethods
    sig { params(params: T.untyped, options: T.untyped).returns(::Ransack::Search) }
    def ransack(params = nil, options = nil); end

    sig { params(params: T.untyped, options: T.untyped).returns(::Ransack::Search) }
    def ransack!(params = nil, options = nil); end
  end
end
~~~

The class methods come from the gem's own `Ransack::Adapters::ActiveRecord::Base` module, so they only
need the `extend` to be made explicit. The relation methods are generated because `ActiveRecord::Relation`
reaches them through delegation to the model class, which Sorbet cannot see.
