## MoneyRails

`Tapioca::Dsl::Compilers::MoneyRails` decorates RBI files for classes that use the `monetize` method provided
by the `money-rails` gem.
https://github.com/RubyMoney/money-rails

In order to use this compiler, you will need to add
  `require "money-rails/active_record/monetizable"`
to your `sorbet/tapioca/require.rb` file, since it relies on the module
`MoneyRails::ActiveRecord::Monetizable::ClassMethods` having been detected and sigs generated for it in the gem
rbis.

For example, with the following ActiveRecord model:
~~~rb
class Product < ActiveRecord::Base
  monetize :price_cents
end
~~~

This compiler will generate the following RBI:
~~~rbi
class Product
 include MoneyRailsGeneratedMethods

 module MoneyRailsGeneratedMethods
   sig { returns(::Money) }
   def price; end

   sig { params(value: ::Money).returns(::Money) }
   def price=(value); end
 end
end
~~~
