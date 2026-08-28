## ActsAsTaggableOn

`Tapioca::Dsl::Compilers::ActsAsTaggableOn` decorates RBI files for models using the
`acts-as-taggable-on` gem. https://github.com/mbleigh/acts-as-taggable-on

The gem extends `ActiveRecord::Base` from an `ActiveSupport.on_load(:active_record)` hook and, for every
tag context a model declares, defines methods in an anonymous mixin. Neither is visible during gem RBI
generation, so a taggable model reaches Sorbet without its tagging API.

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
  acts_as_taggable_on :tags
end
~~~

This compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  include ActsAsTaggableOn::Taggable::Core
  include ActsAsTaggableOn::Taggable::Collection
  extend ActsAsTaggableOn::Taggable::Core::ClassMethods
  extend ActsAsTaggableOn::Taggable

  sig { returns(::ActsAsTaggableOn::TagList) }
  def all_tags_list; end

  sig { params(options: T.untyped).returns(T.untyped) }
  def tag_counts(options = {}); end

  sig { returns(::ActsAsTaggableOn::TagList) }
  def tag_list; end

  sig { params(new_tags: T.untyped).returns(T.untyped) }
  def tag_list=(new_tags); end

  sig { params(owner: T.untyped).returns(::ActsAsTaggableOn::TagList) }
  def tags_from(owner); end

  sig { params(limit: Integer).returns(T.untyped) }
  def top_tags(limit = 10); end

  class << self
    sig { params(options: T.untyped).returns(T.untyped) }
    def tag_counts(options = {}); end

    sig { params(limit: Integer).returns(T.untyped) }
    def top_tags(limit = 10); end
  end
end
~~~

The mixins the gem adds to the model are declared rather than re-implemented, so `tagged_with`,
`tag_list_on` and the rest keep the signatures they have in the gem RBI. Only the per-context methods,
which exist for the contexts of this model alone, are generated.
