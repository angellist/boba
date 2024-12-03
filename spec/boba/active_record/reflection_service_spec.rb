# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "active_record"
require "boba/active_record/reflection_service"

module Boba
  module ActiveRecord
    class ReflectionServiceSpec < ::Minitest::Spec
      extend T::Sig
      include Tapioca::Helpers::Test::Content
      include Tapioca::Helpers::Test::Isolation

      before do
        ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

        ::ActiveRecord::Migration.suppress_messages do
          ::ActiveRecord::Schema.define do
            create_table(:posts) do |t|
              t.integer(:author_id)
            end
            create_table(:comments) do |t|
              t.integer(:author_id, null: false)
            end
            create_table(:author) do |t|
            end
          end
        end
      end

      after do
        ::ActiveRecord::Base.connection.disconnect!
      end

      describe "Boba::ActiveRecord::ReflectionService" do
        describe "required_reflection?" do
          describe "with has_one associations" do
            it "returns false if it is not a has_one association" do
              class Author < ::ActiveRecord::Base
                has_many :posts
              end

              reflection = Author.reflect_on_association(:posts)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns false if the association is not required" do
              class Author < ::ActiveRecord::Base
                has_one :post
              end

              reflection = Author.reflect_on_association(:post)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if the association is required" do
              class Author < ::ActiveRecord::Base
                has_one :post, required: true
              end

              reflection = Author.reflect_on_association(:post)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if the attribute has a presence validation" do
              class Author < ::ActiveRecord::Base
                has_one :post, foreign_key: :author_id

                validates :post, presence: true
              end

              reflection = Author.reflect_on_association(:post)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end
          end

          describe "with belongs_to associations" do
            it "returns false if it is not a belongs_to association" do
              class Post < ::ActiveRecord::Base
                has_one :comment
              end

              reflection = Post.reflect_on_association(:comment)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns false if the association is optional" do
              class Post < ::ActiveRecord::Base
                has_one :comment, required: false
              end

              reflection = Post.reflect_on_association(:comment)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if the association is not optional" do
              class Post < ::ActiveRecord::Base
                has_one :comment, required: true
              end

              reflection = Post.reflect_on_association(:comment)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if there is a non-null constraint on the fk" do
              class Comment < ::ActiveRecord::Base
                belongs_to :author
              end

              reflection = Comment.reflect_on_association(:author)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if there is a presence validation on the attribute" do
              class Post < ::ActiveRecord::Base
                belongs_to :author

                validates :author, presence: true
              end

              reflection = Post.reflect_on_association(:author)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if there is a presence validation on the foreign key" do
              class Post < ::ActiveRecord::Base
                belongs_to :author

                validates :author_id, presence: true
              end

              reflection = Post.reflect_on_association(:author)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "falls back to the default active record config if nothing is defined" do
              class Post < ::ActiveRecord::Base
                class << self
                  extend T::Sig

                  sig { returns(T::Boolean) }
                  def belongs_to_required_by_default = false
                end

                belongs_to :author
              end

              reflection = Post.reflect_on_association(:author)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )

              class Post < ::ActiveRecord::Base
                class << self
                  extend T::Sig

                  sig { returns(T::Boolean) }
                  def belongs_to_required_by_default = true
                end
              end

              reflection = Post.reflect_on_association(:author)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end
          end
        end
      end
    end
  end
end
