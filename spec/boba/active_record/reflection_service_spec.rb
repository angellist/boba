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

        add_ruby_file("schema.rb", <<~RUBY)
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
        RUBY
      end

      after do
        ::ActiveRecord::Base.connection.disconnect!
      end

      describe "Boba::ActiveRecord::ReflectionService" do
        describe "required_reflection?" do
          describe "with has_one associations" do
            it "returns false if it is not a has_one association" do
              add_ruby_file("author.rb", <<~RUBY)
                class AuthorWithManyPosts < ::ActiveRecord::Base
                  self.table_name = "authors"

                  has_many :posts
                end
              RUBY

              reflection = "AuthorWithManyPosts".constantize.reflect_on_association(:posts)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns false if the association is not required" do
              add_ruby_file("author.rb", <<~RUBY)
                class AuthorWithOneOptionalPost < ::ActiveRecord::Base
                  self.table_name = "authors"

                  has_one :post
                end
              RUBY

              reflection = "AuthorWithOneOptionalPost".constantize.reflect_on_association(:post)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if the association is required" do
              add_ruby_file("author.rb", <<~RUBY)
                class AuthorWithRequiredPost < ::ActiveRecord::Base
                  self.table_name = "authors"

                  has_one :post, required: true
                end
              RUBY

              reflection = "AuthorWithRequiredPost".constantize.reflect_on_association(:post)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if the attribute has a presence validation" do
              add_ruby_file("author.rb", <<~RUBY)
                class AuthorWithPresenceValidatedPost < ::ActiveRecord::Base
                  self.table_name = "authors"

                  has_one :post, foreign_key: :author_id

                  validates :post, presence: true
                end
              RUBY

              reflection = "AuthorWithPresenceValidatedPost".constantize.reflect_on_association(:post)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end
          end

          describe "with belongs_to associations" do
            it "returns false if it is not a belongs_to association" do
              add_ruby_file("post.rb", <<~RUBY)
                class PostWithComment < ::ActiveRecord::Base
                  self.table_name = "posts"

                  has_one :comment
                end
              RUBY

              reflection = "PostWithComment".constantize.reflect_on_association(:comment)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns false if the association is optional" do
              add_ruby_file("post.rb", <<~RUBY)
                class PostWithNonRequiredAuthor < ::ActiveRecord::Base
                  self.table_name = "posts"

                  has_one :comment, required: false
                end
              RUBY

              reflection = "PostWithNonRequiredAuthor".constantize.reflect_on_association(:comment)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if the association is not optional" do
              add_ruby_file("post.rb", <<~RUBY)
                class PostWithRequiredAuthor < ::ActiveRecord::Base
                  self.table_name = "posts"

                  has_one :comment, required: true
                end
              RUBY

              reflection = "PostWithRequiredAuthor".constantize.reflect_on_association(:comment)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if there is a non-null constraint on the fk" do
              add_ruby_file("comment.rb", <<~RUBY)
                class CommentWithNonNullAuthorFK < ::ActiveRecord::Base
                  self.table_name = "comments"

                  belongs_to :author
                end
              RUBY

              reflection = "CommentWithNonNullAuthorFK".constantize.reflect_on_association(:author)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "returns true if there is a presence validation on the attribute" do
              add_ruby_file("post.rb", <<~RUBY)
                class PostWithValidatedAuthor < ::ActiveRecord::Base
                  self.table_name = "posts"

                  belongs_to :author

                  validates :author, presence: true
                end
              RUBY

              reflection = "PostWithValidatedAuthor".constantize.reflect_on_association(:author)
              assert_equal(
                true,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )
            end

            it "falls back to the default active record config if nothing is defined" do
              add_ruby_file("post.rb", <<~RUBY)
                  class PostWithOptionalDefault < ::ActiveRecord::Base
                    class << self
                      extend T::Sig

                      sig { returns(T::Boolean) }
                      def belongs_to_required_by_default = false
                    end

                    self.table_name = "posts"

                    belongs_to :author
                  end

                  class PostWithRequiredDefault < ::ActiveRecord::Base
                  class << self
                    extend T::Sig

                    sig { returns(T::Boolean) }
                    def belongs_to_required_by_default = true
                  end

                  self.table_name = "posts"

                  belongs_to :author
                end
              RUBY

              reflection = "PostWithOptionalDefault".constantize.reflect_on_association(:author)
              assert_equal(
                false,
                Boba::ActiveRecord::ReflectionService.required_reflection?(reflection),
              )

              reflection = "PostWithRequiredDefault".constantize.reflect_on_association(:author)
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
