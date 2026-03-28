# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "rails"
require "flag_shih_tzu"

module Tapioca
  module Dsl
    module Compilers
      class FlagShihTzuSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::FlagShihTzu" do
          describe "initialize" do
            it "gathers no constants if there are no FlagShihTzu classes" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :flags, default: 0
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
          end

          describe "decorate" do
            it "generates the the instance methods for the flags" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :flags, default: 0
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include FlagShihTzu

                  has_flags(
                    1 => :published,
                    column: 'flags',
                  )
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  include ::FlagShihTzu
                  include FlagShihTzuGeneratedMethods

                  module FlagShihTzuGeneratedMethods
                    sig { returns(T::Boolean) }
                    def has_published?; end

                    sig { returns(T::Boolean) }
                    def not_published; end

                    sig { params(value: T::Boolean).returns(T::Boolean) }
                    def not_published=(value); end

                    sig { returns(T::Boolean) }
                    def not_published?; end

                    sig { returns(T::Boolean) }
                    def published; end

                    sig { params(value: T::Boolean).returns(T::Boolean) }
                    def published=(value); end

                    sig { returns(T::Boolean) }
                    def published?; end

                    sig { returns(T::Boolean) }
                    def published_changed?; end
                  end
                end
              RBI
              assert_equal(rbi_for(:Post), expected)
            end
          end
        end
      end
    end
  end
end
