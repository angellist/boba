## PaperTrail

`Tapioca::Dsl::Compilers::PaperTrail` decorates RBI files for models versioned with the `paper_trail`
gem. https://github.com/paper-trail-gem/paper_trail

`PaperTrail::Model` is included into `ActiveRecord::Base` once, by the gem itself, so a
`sorbet/tapioca/require.rb` carrying `require "paper_trail/frameworks/active_record"` is enough for
`has_paper_trail` to land in the gem RBI — no compiler needed for that part. What no shim can express
is what `has_paper_trail` then does to the model that declares it, at runtime: it includes
`PaperTrail::Model::InstanceMethods` into that class and defines two accessors on it, one of them
under a name the model chooses.

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

  sig { returns(T.nilable(::PaperTrail::Version)) }
  def version; end

  sig { params(value: T.nilable(::PaperTrail::Version)).returns(T.nilable(::PaperTrail::Version)) }
  def version=(value); end

  sig { returns(T.nilable(::String)) }
  def paper_trail_event; end

  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
  def paper_trail_event=(value); end
end
~~~

`version` holds the version record the model was reified from; it is named by the `:version` option
and typed by `versions: { class_name: ... }`, so both are only knowable per model. The `versions`
association is declared with `has_many`, which Tapioca's own association compiler already sees.
