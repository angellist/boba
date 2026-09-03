# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "rails"
require "friendly_id"

module Tapioca
  module Dsl
    module Compilers
      class FriendlyIdSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::FriendlyId" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only models extending FriendlyId" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title
                      t.string :slug
                    end

                    create_table :comments do |t|
                      t.string :body
                    end
                  end
                end
              RUBY

              add_ruby_file("models.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  extend FriendlyId

                  friendly_id :title, use: :slugged
                end

                class Comment < ActiveRecord::Base
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates the configured FriendlyId mixins and the friendly relation method" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title
                      t.string :slug
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  extend FriendlyId

                  friendly_id :title, use: :slugged
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  include FriendlyId::Slugged
                  include FriendlyId::Model
                  include FriendlyId::Reserved
                  include FriendlyId::UnfriendlyUtils
                  extend FriendlyId::Base

                  module GeneratedRelationMethods
                    sig { returns(T.untyped) }
                    def friendly; end
                  end
                end
              RBI

              assert_equal(rbi_for(:Post), expected)
            end

            it "types the friendly relation method when the relations compiler is enabled" do
              require "tapioca/dsl/compilers/active_record_relations"
              activate_other_dsl_compilers(ActiveRecordRelations)

              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title
                      t.string :slug
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  extend FriendlyId

                  friendly_id :title, use: :slugged
                end
              RUBY

              rbi = rbi_for(:Post)

              assert_includes(rbi, "sig { returns(PrivateRelation) }")
              assert_includes(rbi, "sig { returns(PrivateAssociationRelation) }")
            end
          end
        end
      end
    end
  end
end
