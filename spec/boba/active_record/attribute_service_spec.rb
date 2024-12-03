# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "active_record"
require "boba/active_record/attribute_service"

module Boba
  module ActiveRecord
    class AttributeServiceSpec < ::Minitest::Spec
      extend T::Sig
      include Tapioca::Helpers::Test::Content
      include Tapioca::Helpers::Test::Isolation

      before do
        ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        ::ActiveRecord::Migration.suppress_messages do
          ::ActiveRecord::Schema.define do
            create_table(:posts) do |t|
              t.integer(:author_id, null: false)
              t.string(:title)
              t.string(:subject)
              t.string(:body)
            end
            create_table(:author) do |t|
            end
          end
        end
      end

      after do
        ::ActiveRecord::Base.connection.disconnect!
      end

      describe "Boba::ActiveRecord::AttributeService" do
        describe "nilable_attribute?" do
          it "returns true if column is virtual" do
            class Author < ::ActiveRecord::Base; end

            assert_equal(
              true,
              Boba::ActiveRecord::AttributeService.nilable_attribute?(Author, "name"),
            )
          end

          it "returns true if no constraints or validators" do
            class Post < ::ActiveRecord::Base; end

            assert_equal(
              true,
              Boba::ActiveRecord::AttributeService.nilable_attribute?(Post, "body"),
            )
          end

          it "returns false if non-null constraint on column" do
            class Post < ::ActiveRecord::Base; end

            assert_equal(
              false,
              Boba::ActiveRecord::AttributeService.nilable_attribute?(Post, "author_id"),
            )
          end

          it "returns true if presence validator on column" do
            class Post < ::ActiveRecord::Base
              validates :title, presence: true
            end

            assert_equal(
              false,
              Boba::ActiveRecord::AttributeService.nilable_attribute?(Post, "title"),
            )
          end

          it "returns true if presence validator on column is conditional" do
            class Post < ::ActiveRecord::Base
              validates :subject, presence: true, if: ->() { true }
            end

            assert_equal(
              true,
              Boba::ActiveRecord::AttributeService.nilable_attribute?(Post, "subject"),
            )
          end
        end
      end
    end
  end
end
