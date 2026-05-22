## ActiveRecordTypedEnum

`Tapioca::Dsl::Compilers::ActiveRecordTypedEnum` generates type-safe enum classes and methods
for ActiveRecord models that use the built-in enum feature.

For each enum defined in a model, this compiler:
1. Creates a `T::Enum` subclass with all the enum values
2. Generates `typed_<enum_name>` getter method that returns the enum instance
3. Generates `typed_<enum_name>=` setter method that accepts the enum instance

The compiler respects the nullability of the enum attribute based on the database schema.

For example, with the following ActiveRecord model:

~~~rb
class Order < ActiveRecord::Base
  enum status: { pending: 0, processing: 1, completed: 2, cancelled: 3 }
  enum priority: { low: 0, medium: 1, high: 2 }, _prefix: true
end
~~~

This compiler will produce the following RBI:

~~~rbi
class Order
  class Status < T::Enum
    enums do
      Pending = new(0)
      Processing = new(1)
      Completed = new(2)
      Cancelled = new(3)
    end
  end

  class Priority < T::Enum
    enums do
      Low = new(0)
      Medium = new(1)
      High = new(2)
    end
  end

  sig { returns(Order::Status) }
  def typed_status; end

  sig { params(value: Order::Status).returns(void) }
  def typed_status=(value); end

  sig { returns(Order::Priority) }
  def typed_priority; end

  sig { params(value: Order::Priority).returns(void) }
  def typed_priority=(value); end
end
~~~
