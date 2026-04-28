## Draper

`Tapioca::Dsl::Compilers::Draper` decorates RBI files for `Draper::Decorator`
subclasses and the source classes they decorate, provided by the `draper` gem.
https://github.com/drapergem/draper

The compiler emits a typed `object` / `model` / underscored-source-name accessor
for every decorator, plus a typed `decorate` instance method on the source class.

For example, with the following classes:
~~~rb
class Post < ActiveRecord::Base
end

class PostDecorator < Draper::Decorator
end
~~~

This compiler will generate the following RBI for the decorator:
~~~rbi
class PostDecorator
  include DraperGeneratedInstanceMethods

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

## Why `delegate_all` is not supported

`delegate_all` forwards every public instance method of the source class via
`method_missing`. Reflecting that into RBI requires emitting one explicit method
per name — Sorbet ignores `method_missing` for type inference, and there is no
other annotation that lets us say "this class has all the methods of that one"
without the `is_a?` lie of declaring `class PostDecorator < Post`.

Mirroring AR's full instance method set per decorator turned out to be wildly
noisy in practice (several thousand lines per decorator on real models, mostly
AR-internal methods like `__callbacks` and `_before_commit_callbacks` that no
one calls through a decorator). Argument and return types also collapse to
`T.untyped`, so the noise doesn't even buy strong typing.

The recommended pattern is therefore to access the source through the typed
`object` accessor — `decorator.object.title` carries the typing produced by
Tapioca's `ActiveRecordColumns` compiler, with no per-decorator bloat.

Concretely, with `Post#title` (a string column):
~~~rb
post = Post.new(title: "post 1")
post.title              # ✓ Sorbet sees ::String (from ActiveRecordColumns)

decorator = post.decorate
decorator.title         # ✗ Sorbet errors — even with `delegate_all`, no
                        #   `title` is declared on PostDecorator
decorator.object.title  # ✓ Sorbet sees ::String (via the typed `object`)
~~~
