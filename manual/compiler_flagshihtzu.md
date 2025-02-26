## FlagShihTzu

`Tapioca::Dsl::Compilers::FlagShihTzu` decorates RBI files for models
using FlagShihTzu.

For example, with FlagShihTzu installed and the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
  has_flags(
    1 => :published,
    2 => :deleted,
  )
end
~~~

This compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  include FlagShihTzu
  include FlagShihTzuGeneratedMethods

  module FlagShihTzuGeneratedMethods
    sig { returns(T::Boolean) }
    def published; end
    sig { params(value: T::Boolean).returns(T::Boolean) }
    def published=(value); end
    sig { returns(T::Boolean) }
    def published?; end

    sig { returns(T::Boolean) }
    def deleted; end
    sig { params(value: T::Boolean).returns(T::Boolean) }
    def deleted=(value); end
    sig { returns(T::Boolean) }
    def deleted?; end
  end
end
~~~
