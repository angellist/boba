# typed: ignore
# frozen_string_literal: true

require "tapioca/dsl/compilers/active_record_columns"

return unless defined?(Tapioca::Dsl::Compilers::ActiveRecordColumns)

require "tapioca/dsl/helpers/active_record_column_type_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordColumnsPersisted` is an extension of the default Tapioca compiler `Tapioca::Dsl::Compilers::ActiveRecordColumns`.
      # It extends the `persisted` option of the `ActiveRecordColumnTypes` to respect not only database constraints, but
      # also validations on the attributes in the model.
      #
      # [`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
      # This compiler is only responsible for defining the attribute methods that would be
      # created for columns and virtual attributes that are defined in the Active Record
      # model.
      #
      # This compiler accepts a `ActiveRecordColumnTypes` option that can be used to specify
      # how the types of the column related methods should be generated. The option can be one of the following:
      #  - `persisted` (_default_): The methods will be generated with the type that matches the actual database
      #  column type as the return type. This means that if the column is a string, the method return type
      #  will be `String`, but if the column is also nullable, then the return type will be `T.nilable(String)`. This
      #  mode basically treats each model as if it was a valid and persisted model. Note that this makes typing
      #  Active Record models easier, but does not match the behaviour of non-persisted or invalid models, which can
      #  have all kinds of non-sensical values in their column attributes.
      #  - `nilable`: All column methods will be generated with `T.nilable` return types. This is strictly the most
      #  correct way to type the methods, but it can make working with the models more cumbersome, as you will have to
      #  handle the `nil` cases explicitly using `T.must` or the safe navigation operator `&.`, even for valid
      #  persisted models.
      #  - `untyped`: The methods will be generated with `T.untyped` return types. This mode is practical if you are not
      #  ready to start typing your models strictly yet, but still want to generate RBI files for them.
      #
      # For example, with the following model class:
      # ~~~rb
      # class Post < ActiveRecord::Base
      # end
      # ~~~
      #
      # and the following database schema:
      #
      # ~~~rb
      # # db/schema.rb
      # create_table :posts do |t|
      #   t.string :title, null: false
      #   t.string :body
      #   t.boolean :published
      #   t.timestamps
      # end
      # ~~~
      #
      # this compiler will, by default, produce the following methods in the RBI file
      # `post.rbi`:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   include GeneratedAttributeMethods
      #
      #   module GeneratedAttributeMethods
      #     sig { returns(T.nilable(::String)) }
      #     def body; end
      #
      #     sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
      #     def body=; end
      #
      #     sig { returns(T::Boolean) }
      #     def body?; end
      #
      #     sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
      #     def created_at; end
      #
      #     sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
      #     def created_at=; end
      #
      #     sig { returns(T::Boolean) }
      #     def created_at?; end
      #
      #     sig { returns(T.nilable(T::Boolean)) }
      #     def published; end
      #
      #     sig { params(value: T::Boolean).returns(T::Boolean) }
      #     def published=; end
      #
      #     sig { returns(T::Boolean) }
      #     def published?; end
      #
      #     sig { returns(::String) }
      #     def title; end
      #
      #     sig { params(value: ::String).returns(::String) }
      #     def title=(value); end
      #
      #     sig { returns(T::Boolean) }
      #     def title?; end
      #
      #     sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
      #     def updated_at; end
      #
      #     sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
      #     def updated_at=; end
      #
      #     sig { returns(T::Boolean) }
      #     def updated_at?; end
      #
      #     ## Also the methods added by https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Dirty.html
      #     ## Also the methods added by https://api.rubyonrails.org/classes/ActiveModel/Dirty.html
      #     ## Also the methods added by https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/BeforeTypeCast.html
      #   end
      # end
      # ~~~
      #
      # However, if `ActiveRecordColumnTypes` is set to `nilable`, the `title` method will be generated as:
      # ~~~rbi
      #     sig { returns(T.nilable(::String)) }
      #     def title; end
      # ~~~
      # and if the option is set to `untyped`, the `title` method will be generated as:
      # ~~~rbi
      #     sig { returns(T.untyped) }
      #     def title; end
      # ~~~
      class ActiveRecordColumnsPersisted < ::Tapioca::Dsl::Compilers::ActiveRecordColumns
        extend T::Sig

        private

        def column_type_helper
          ::Tapioca::Dsl::Helpers::ActiveRecordColumnTypeHelper.new(
            constant,
            column_type_option: column_type_option,
          )
        end

        sig do
          params(
            attribute_name: String,
            column_name: String,
          ).returns([String, String])
        end
        def type_for(attribute_name, column_name = attribute_name)
          return column_type_helper.send(:id_type) if attribute_name == "id"

          column_type_for(column_name)
        end

        sig { params(column_name: String).returns([String, String]) }
        def column_type_for(column_name)
          return ["T.untyped", "T.untyped"] if column_type_option.untyped?

          nilable_column = !has_non_null_database_constraint?(column_name) &&
            !has_unconditional_presence_validator?(column_name)

          column_type = @constant.attribute_types[column_name]
          getter_type = column_type_helper.send(
            :type_for_activerecord_value,
            column_type,
            column_nullability: nilable_column,
          )
          setter_type =
            case column_type
            when ActiveRecord::Enum::EnumType
              column_type_helper.send(:enum_setter_type, column_type)
            else
              getter_type
            end

          if column_type_option.persisted? && (virtual_attribute?(column_name) || !nilable_column)
            [getter_type, setter_type]
          else
            getter_type = as_nilable_type(getter_type) unless column_type_helper.send(
              :not_nilable_serialized_column?,
              column_type,
            )
            [getter_type, as_nilable_type(setter_type)]
          end
        end

        sig { params(column_name: String).returns(T::Boolean) }
        def virtual_attribute?(column_name)
          @constant.columns_hash[column_name].nil?
        end

        sig { params(column_name: String).returns(T::Boolean) }
        def has_non_null_database_constraint?(column_name)
          column = @constant.columns_hash[column_name]
          return false if column.nil?

          !column.null
        end

        sig { params(column_name: String).returns(T::Boolean) }
        def has_unconditional_presence_validator?(column_name)
          return false unless @constant.respond_to?(:validators_on)

          @constant.validators_on(column_name).any? do |validator|
            next false unless validator.is_a?(ActiveRecord::Validations::PresenceValidator)

            !validator.options.key?(:if) && !validator.options.key?(:unless) && !validator.options.key?(:on)
          end
        end

        sig do
          params(
            klass: RBI::Scope,
            attribute_name: String,
            column_name: String,
            methods_to_add: T.nilable(T::Array[String]),
          ).void
        end
        def add_methods_for_attribute(klass, attribute_name, column_name = attribute_name, methods_to_add = nil)
          getter_type, setter_type = type_for(attribute_name, column_name)

          # Added by ActiveRecord::AttributeMethods::Read
          #
          add_method(
            klass,
            attribute_name.to_s,
            methods_to_add,
            return_type: getter_type,
          )

          # Added by ActiveRecord::AttributeMethods::Write
          #
          add_method(
            klass,
            "#{attribute_name}=",
            methods_to_add,
            parameters: [create_param("value", type: setter_type)],
            return_type: setter_type,
          )

          # Added by ActiveRecord::AttributeMethods::Query
          #
          add_method(
            klass,
            "#{attribute_name}?",
            methods_to_add,
            return_type: "T::Boolean",
          )

          # Added by ActiveRecord::AttributeMethods::Dirty
          #
          add_method(
            klass,
            "#{attribute_name}_before_last_save",
            methods_to_add,
            return_type: as_nilable_type(getter_type),
          )
          add_method(
            klass,
            "#{attribute_name}_change_to_be_saved",
            methods_to_add,
            return_type: "T.nilable([#{getter_type}, #{getter_type}])",
          )
          add_method(
            klass,
            "#{attribute_name}_in_database",
            methods_to_add,
            return_type: as_nilable_type(getter_type),
          )
          add_method(
            klass,
            "saved_change_to_#{attribute_name}",
            methods_to_add,
            return_type: "T.nilable([#{getter_type}, #{getter_type}])",
          )
          add_method(
            klass,
            "saved_change_to_#{attribute_name}?",
            methods_to_add,
            return_type: "T::Boolean",
          )
          add_method(
            klass,
            "will_save_change_to_#{attribute_name}?",
            methods_to_add,
            return_type: "T::Boolean",
          )

          # Added by ActiveModel::Dirty
          #
          add_method(
            klass,
            "#{attribute_name}_change",
            methods_to_add,
            return_type: "T.nilable([#{getter_type}, #{getter_type}])",
          )
          add_method(
            klass,
            "#{attribute_name}_changed?",
            methods_to_add,
            return_type: "T::Boolean",
            parameters: [
              create_kw_opt_param("from", type: setter_type, default: "T.unsafe(nil)"),
              create_kw_opt_param("to", type: setter_type, default: "T.unsafe(nil)"),
            ],
          )
          add_method(
            klass,
            "#{attribute_name}_will_change!",
            methods_to_add,
          )
          add_method(
            klass,
            "#{attribute_name}_was",
            methods_to_add,
            return_type: as_nilable_type(getter_type),
          )
          add_method(
            klass,
            "#{attribute_name}_previous_change",
            methods_to_add,
            return_type: "T.nilable([#{getter_type}, #{getter_type}])",
          )
          add_method(
            klass,
            "#{attribute_name}_previously_changed?",
            methods_to_add,
            return_type: "T::Boolean",
            parameters: [
              create_kw_opt_param("from", type: setter_type, default: "T.unsafe(nil)"),
              create_kw_opt_param("to", type: setter_type, default: "T.unsafe(nil)"),
            ],
          )
          add_method(
            klass,
            "#{attribute_name}_previously_was",
            methods_to_add,
            return_type: as_nilable_type(getter_type),
          )
          add_method(
            klass,
            "restore_#{attribute_name}!",
            methods_to_add,
          )

          # Added by ActiveRecord::AttributeMethods::BeforeTypeCast
          #
          add_method(
            klass,
            "#{attribute_name}_before_type_cast",
            methods_to_add,
            return_type: "T.untyped",
          )
          add_method(
            klass,
            "#{attribute_name}_came_from_user?",
            methods_to_add,
            return_type: "T::Boolean",
          )
        end
      end
    end
  end
end
