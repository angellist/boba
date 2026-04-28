## Draper

`Tapioca::Dsl::Compilers::Draper` decorates RBI files for `Draper::Decorator`
subclasses and the source classes they decorate, provided by the `draper` gem.
https://github.com/drapergem/draper

The compiler emits a typed `object` / `model` / underscored-source-name accessor
for every decorator, plus a typed `decorate` instance method on the source class.
When the decorator uses `delegate_all`, every public instance method of the source
class (column accessors, persistence methods, etc.) is also mirrored onto the
decorator with `T.untyped` argument and return types, so that calls like
`post.decorate.title` are visible to Sorbet. The source class's own RBI remains
the authoritative type source.

For example, with the following classes:
~~~rb
class Post < ActiveRecord::Base
  # columns: title:string, body:text, hidden:boolean, ...
end

class PostDecorator < Draper::Decorator
  delegate_all
end
~~~

This compiler will generate the following RBI for the decorator:
~~~rbi
class PostDecorator
  include DraperGeneratedInstanceMethods
  include DraperGeneratedDelegationMethods

  module DraperGeneratedDelegationMethods
    sig { returns(T.untyped) }
    def title; end

    sig { params(value: T.untyped).returns(T.untyped) }
    def title=(value); end

    sig { returns(T.untyped) }
    def hidden?; end

    # ... and every other public instance method on Post
  end

  module DraperGeneratedInstanceMethods
    sig { returns(::Post) }
    def model; end

    sig { returns(::Post) }
    def object; end

    sig { returns(::Post) }
    def post; end
  end
end
~~~

And the following RBI for the source class:
~~~rbi
class Post
  include DraperGeneratedDecoratableMethods

  module DraperGeneratedDecoratableMethods
    sig { params(options: T.untyped).returns(::PostDecorator) }
    def decorate(options = T.unsafe(nil)); end
  end
end
~~~
