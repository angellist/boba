# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "rails"
require "paper_trail"
require "paper_trail/has_paper_trail"
require "paper_trail/version_concern"

ActiveRecord::Base.include(PaperTrail::Model)

module Tapioca
  module Dsl
    module Compilers
      class PaperTrailSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::PaperTrail" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only versioned models" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts
                    create_table :comments
                    create_table :versions do |t|
                      t.string :item_type, null: false
                      t.integer :item_id, null: false
                      t.string :event, null: false
                      t.string :whodunnit
                      t.text :object
                      t.datetime :created_at
                    end
                  end
                end
              RUBY

              add_ruby_file("version.rb", <<~RUBY)
                module PaperTrail
                  class Version < ActiveRecord::Base
                    include PaperTrail::VersionConcern
                  end
                end
              RUBY

              add_ruby_file("models.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_paper_trail
                end

                class Comment < ActiveRecord::Base
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end
          end

          describe "decorate" do
            it "declares what has_paper_trail adds to the model" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts
                    create_table :versions do |t|
                      t.string :item_type, null: false
                      t.integer :item_id, null: false
                      t.string :event, null: false
                      t.string :whodunnit
                      t.text :object
                      t.datetime :created_at
                    end
                  end
                end
              RUBY

              add_ruby_file("version.rb", <<~RUBY)
                module PaperTrail
                  class Version < ActiveRecord::Base
                    include PaperTrail::VersionConcern
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_paper_trail
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  include PaperTrail::Model::InstanceMethods

                  sig { returns(T.nilable(::String)) }
                  def paper_trail_event; end

                  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                  def paper_trail_event=(value); end

                  sig { returns(T.nilable(::Post)) }
                  def version; end

                  sig { params(value: T.nilable(::Post)).returns(T.nilable(::Post)) }
                  def version=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "names the reified accessor after the :version option" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts
                    create_table :versions do |t|
                      t.string :item_type, null: false
                      t.integer :item_id, null: false
                      t.string :event, null: false
                      t.string :whodunnit
                      t.text :object
                      t.datetime :created_at
                    end
                  end
                end
              RUBY

              add_ruby_file("version.rb", <<~RUBY)
                module PaperTrail
                  class Version < ActiveRecord::Base
                    include PaperTrail::VersionConcern
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_paper_trail version: :revision
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  include PaperTrail::Model::InstanceMethods

                  sig { returns(T.nilable(::String)) }
                  def paper_trail_event; end

                  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                  def paper_trail_event=(value); end

                  sig { returns(T.nilable(::Post)) }
                  def revision; end

                  sig { params(value: T.nilable(::Post)).returns(T.nilable(::Post)) }
                  def revision=(value); end
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
