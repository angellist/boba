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
    sig { returns(::Integer) }
    def price_cents; end

    sig { params(value: Integer).returns(::Integer) }
    def price_cents=(value); end
  end
end
~~~
