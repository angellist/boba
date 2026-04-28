# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "draper"

module Tapioca
  module Dsl
    module Compilers
      class DraperSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::Draper" do
          describe "gather_constants" do
            it "gathers Draper::Decorator subclasses" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title, limit: 100
                      t.text :body
                      t.integer :body_length
                      t.boolean :hidden
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include Draper::Decoratable
                end
              RUBY

              add_ruby_file("post_decorator.rb", <<~RUBY)
                class PostDecorator < Draper::Decorator
                end
              RUBY

              assert_includes(gathered_constants, "PostDecorator")
            end

            it "does not gather classes that are not Draper::Decorator subclasses" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title, limit: 100
                      t.text :body
                      t.integer :body_length
                      t.boolean :hidden
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include Draper::Decoratable
                end
              RUBY

              refute_includes(gathered_constants, "Post")
            end
          end

          describe "decorate" do
            it "generates typed object/model accessors and a source-name alias" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title, limit: 100
                      t.text :body
                      t.integer :body_length
                      t.boolean :hidden
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include Draper::Decoratable
                end
              RUBY

              add_ruby_file("post_decorator.rb", <<~RUBY)
                class PostDecorator < Draper::Decorator
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class PostDecorator
                  include DraperGeneratedInstanceMethods

                  module DraperGeneratedInstanceMethods
                    sig { returns(::Post) }
                    def model; end

                    sig { returns(::Post) }
                    def object; end

                    sig { returns(::Post) }
                    def post; end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:PostDecorator))
            end

            it "generates the decorate instance method on the source class" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title, limit: 100
                      t.text :body
                      t.integer :body_length
                      t.boolean :hidden
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include Draper::Decoratable
                end
              RUBY

              add_ruby_file("post_decorator.rb", <<~RUBY)
                class PostDecorator < Draper::Decorator
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Post
                  include DraperGeneratedDecoratableMethods

                  module DraperGeneratedDecoratableMethods
                    sig { params(options: T.untyped).returns(::PostDecorator) }
                    def decorate(options = T.unsafe(nil)); end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Post))
            end

            it "does not emit a delegation module even when delegate_all is set" do
              # `delegate_all` is intentionally not reflected — see the compiler
              # docstring for the reasoning.
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title, limit: 100
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include Draper::Decoratable
                end
              RUBY

              add_ruby_file("post_decorator.rb", <<~RUBY)
                class PostDecorator < Draper::Decorator
                  delegate_all
                end
              RUBY

              rbi = rbi_for(:PostDecorator)
              refute_includes(rbi, "DraperGeneratedDelegationMethods")
              refute_includes(rbi, "def title; end")
              refute_includes(rbi, "def save")
            end

            it "respects the explicit object class set via decorates" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :articles do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("article.rb", <<~RUBY)
                class Article < ActiveRecord::Base
                  include Draper::Decoratable
                end
              RUBY

              add_ruby_file("custom_article_decorator.rb", <<~RUBY)
                class CustomArticleDecorator < Draper::Decorator
                  decorates Article
                end
              RUBY

              rbi = rbi_for(:CustomArticleDecorator)
              assert_includes(rbi, "def article; end")
              assert_includes(rbi, "returns(::Article)")
            end

            it "skips decorators with an uninferable object class" do
              add_ruby_file("application_decorator.rb", <<~RUBY)
                class ApplicationDecorator < Draper::Decorator
                end
              RUBY

              refute_includes(gathered_constants, "ApplicationDecorator")
            end

            it "does not emit decorate on the source class when the decorator is not the inferred one" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :widgets do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("widget.rb", <<~RUBY)
                class Widget < ActiveRecord::Base
                  include Draper::Decoratable
                end
              RUBY

              # Inferred decorator name "WidgetDecorator" does not exist; CustomWidgetDecorator
              # explicitly decorates Widget but is not the one Draper would infer.
              add_ruby_file("custom_widget_decorator.rb", <<~RUBY)
                class CustomWidgetDecorator < Draper::Decorator
                  decorates Widget
                end
              RUBY

              refute_includes(gathered_constants, "Widget")
            end
          end
        end
      end
    end
  end
end
