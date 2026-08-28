## Neighbor

`Tapioca::Dsl::Compilers::Neighbor` decorates RBI files for models using the `neighbor` gem.
https://github.com/ankane/neighbor

`Neighbor::Model` is extended into `ActiveRecord::Base` from an
`ActiveSupport.on_load(:active_record)` hook, which does not run during gem RBI generation, so
`has_neighbors` is invisible to Sorbet in the very model that declares it.

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Document < ApplicationRecord
  has_neighbors :embedding
end
~~~

This compiler will produce the RBI file `document.rbi` with the following content:

~~~rbi
# document.rbi
# typed: true
class Document
  extend Neighbor::Model
end
~~~

`has_neighbors` and `neighbor_attributes` keep the signatures they have in the gem RBI. The
`nearest_neighbors` scope the gem defines per attribute is an ordinary Active Record scope, so
Tapioca's own `ActiveRecordScope` compiler already types it on the model's relations.
