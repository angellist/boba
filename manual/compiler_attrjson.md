## AttrJson

`Tapioca::Dsl::Compilers::AttrJson` decorates RBI files for classes that use the `AttrJson` gem.
https://github.com/jrochkind/attr_json

For example, with the following ActiveRecord model:
~~~rb
class Product < ActiveRecord::Base
  include AttrJson::Record

  attr_json :price_cents, :integer
end
~~~

This compiler will generate the following RBI:
~~~rbi
class Product
  include AttrJsonGeneratedMethods
  extend AttrJson::Record::ClassMethods

  module AttrJsonGeneratedMethods
    sig { returns(T.nilable(::Integer)) }
    def price_cents; end

    sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
    def price_cents=(value); end
  end
end
~~~

A scalar attribute reads as `nil` until it is set, so it is typed as nilable unless it has a non-nil
`default:`. As with columns in `ActiveRecordColumnsPersisted`, an unconditional presence validator
(no `if:`, `unless:` or `on:`) types it as it is on a valid record instead:
`validates :price_cents, presence: true` turns the methods above into `returns(::Integer)` and
`params(value: ::Integer)`.
