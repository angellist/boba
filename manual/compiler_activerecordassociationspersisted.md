## ActiveRecordAssociationsPersisted

`Tapioca::Dsl::Compilers::ActiveRecordAssociationsPersisted` extends the default Tapioca compiler `Tapioca::Dsl::Compilers::ActiveRecordAssociations`
to provide an option to generate RBI files for associations on models assuming that the model is persisted. These sigs therefore respect
validations and DB constraints, and generate non-nilable types for associations that are required or non-optional.

This compiler accepts a `ActiveRecordAssociationTypes` option that can be used to specify
how the types of `belongs_to` and `has_one` associations should be generated. The option can be one of the
following:
 - `nilable (_default_)`: All association methods will be generated with `T.nilable` return types. This is
 strictly the most correct way to type the methods, but it can make working with the models more cumbersome, as
 you will have to handle the `nil` cases explicitly using `T.must` or the safe navigation operator `&.`, even
 for valid persisted models.
 - `persisted`: The methods will be generated with the type that matches validations on the association. If
 there is a `required: true` or `optional: false`, then the types will be generated as non-nilable. This mode
 basically treats each model as if it was a valid and persisted model. Note that this makes typing Active Record
 models easier, but does not match the behaviour of non-persisted or invalid models, which can have `nil`
 associations.

For example, with the following model class:

~~~rb
class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  has_one :author, class_name: "User", optional: false

  accepts_nested_attributes_for :category, :comments, :author
end
~~~

By default, the compiler will generate types consistent with `Tapioca::Dsl::Compilers::ActiveRecordAssociationsPersisted`.
If `ActiveRecordAssociationTypes` is `persisted`, the `author` method will be generated as:
~~~rbi
    sig { returns(::User) }
    def author; end
~~~
and if the option is set to `untyped`, the `author` method will be generated as:
~~~rbi
    sig { returns(T.untyped) }
    def author; end
~~~
