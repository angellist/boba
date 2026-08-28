# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "rails"
require "acts-as-taggable-on"

module Tapioca
  module Dsl
    module Compilers
      class ActsAsTaggableOnSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::ActsAsTaggableOn" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only taggable models" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts
                    create_table :comments
                  end
                end
              RUBY

              add_ruby_file("models.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  acts_as_taggable_on :tags
                end

                class Comment < ActiveRecord::Base
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates methods for every tag context" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  acts_as_taggable_on :skills
                end
              RUBY

              rbi = rbi_for(:Post)

              assert_includes(rbi, "include ActsAsTaggableOn::Taggable::Core")
              assert_includes(rbi, "extend ActsAsTaggableOn::Taggable")
              assert_includes(rbi, "def skill_list; end")
              assert_includes(rbi, "def skill_list=(new_tags); end")
              assert_includes(rbi, "def all_skills_list; end")
              assert_includes(rbi, "def skills_from(owner); end")
              assert_includes(rbi, "def skill_counts(options = {}); end")
              assert_includes(rbi, "class << self")
              assert_equal(2, rbi.scan("def top_skills(limit = 10); end").size)
            end
          end
        end
      end
    end
  end
end
