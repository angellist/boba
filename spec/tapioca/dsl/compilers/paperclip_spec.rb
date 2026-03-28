# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "rails"
require "paperclip"

module Tapioca
  module Dsl
    module Compilers
      class PaperclipSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
          ::Paperclip::Railtie.insert
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::Paperclip" do
          describe "initialize" do
            it "gathers ActiveRecord models which include Paperclip::Glue" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              assert_equal(gathered_constants, ["ActiveRecord::Base", "Post"])
            end
          end

          describe "decorate" do
            it "generates the the instance methods for the flags" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :attached_file_content_type
                      t.string :attached_file_file_name
                      t.bigint :attached_file_file_size
                      t.datetime :attached_file_updated_at
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_attached_file 'attached_file'
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  include ::Paperclip::Glue
                  include PaperclipGeneratedMethods

                  module PaperclipGeneratedMethods
                    sig { returns(::Paperclip::Attachment) }
                    def attached_file; end

                    sig { params(value: T.untyped).returns(T.untyped) }
                    def attached_file=(value); end
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
