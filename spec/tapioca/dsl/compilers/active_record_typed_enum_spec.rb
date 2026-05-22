# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "rails"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordTypedEnumSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::ActiveRecordTypedEnum" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes with enums" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              assert_equal(gathered_constants, [])
            end

            it "gathers ActiveRecord classes with enums" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :status, default: 0
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  enum :status, [:draft, :published, :archived]
                end
              RUBY

              assert_equal(gathered_constants, ["Post"])
            end
          end

          describe "decorate" do
            it "generates typed enum class and typed getter/setter methods" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :status, default: 0
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  enum :status, [:draft, :published, :archived]
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  sig { returns(T.nilable(Post::Status)) }
                  def typed_status; end

                  sig { params(value: T.nilable(Post::Status)).void }
                  def typed_status=(value); end

                  class Status < T::Enum
                    enums do
                      Archived = new('archived')
                      Draft = new('draft')
                      Published = new('published')
                    end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Post))
            end

            it "generates typed enum with hash values" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :status, default: 0
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  enum :status, { draft: 0, published: 1, archived: 2 }
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  sig { returns(T.nilable(Post::Status)) }
                  def typed_status; end

                  sig { params(value: T.nilable(Post::Status)).void }
                  def typed_status=(value); end

                  class Status < T::Enum
                    enums do
                      Archived = new('archived')
                      Draft = new('draft')
                      Published = new('published')
                    end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Post))
            end

            it "generates typed enum with string values" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :status, default: 0
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  enum :status, { draft: "draft", published: "published", archived: "archived" }
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  sig { returns(T.nilable(Post::Status)) }
                  def typed_status; end

                  sig { params(value: T.nilable(Post::Status)).void }
                  def typed_status=(value); end

                  class Status < T::Enum
                    enums do
                      Archived = new('archived')
                      Draft = new('draft')
                      Published = new('published')
                    end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Post))
            end

            it "generates non-nilable types for non-nullable columns" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :status, null: false
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  enum :status, [:draft, :published, :archived]
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  sig { returns(Post::Status) }
                  def typed_status; end

                  sig { params(value: Post::Status).void }
                  def typed_status=(value); end

                  class Status < T::Enum
                    enums do
                      Archived = new('archived')
                      Draft = new('draft')
                      Published = new('published')
                    end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Post))
            end

            it "generates multiple enum classes for multiple enums" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :status, default: 0
                      t.integer :visibility, default: 0
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  enum :status, [:draft, :published, :archived]
                  enum :visibility, [:shared, :personal, :unlisted]
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  sig { returns(T.nilable(Post::Status)) }
                  def typed_status; end

                  sig { params(value: T.nilable(Post::Status)).void }
                  def typed_status=(value); end

                  sig { returns(T.nilable(Post::Visibility)) }
                  def typed_visibility; end

                  sig { params(value: T.nilable(Post::Visibility)).void }
                  def typed_visibility=(value); end

                  class Status < T::Enum
                    enums do
                      Archived = new('archived')
                      Draft = new('draft')
                      Published = new('published')
                    end
                  end

                  class Visibility < T::Enum
                    enums do
                      Personal = new('personal')
                      Shared = new('shared')
                      Unlisted = new('unlisted')
                    end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Post))
            end

            it "handles enum keys with underscores" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :review_status, default: 0
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  enum :review_status, [:pending_review, :under_review, :review_completed]
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  sig { returns(T.nilable(Post::ReviewStatus)) }
                  def typed_review_status; end

                  sig { params(value: T.nilable(Post::ReviewStatus)).void }
                  def typed_review_status=(value); end

                  class ReviewStatus < T::Enum
                    enums do
                      PendingReview = new('pending_review')
                      ReviewCompleted = new('review_completed')
                      UnderReview = new('under_review')
                    end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Post))
            end
          end
        end
      end
    end
  end
end
