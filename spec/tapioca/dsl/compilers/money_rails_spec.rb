# typed: strict

# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "rails"
require "money-rails"
require "money-rails/active_record/monetizable"

module Tapioca
  module Dsl
    module Compilers
      class MoneyRailsSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
          ::MoneyRails::Hooks.init
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::MoneyRails" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_equal(gathered_constants, ["ActiveRecord::Base"])
            end
          end

          describe "decorate" do
            describe "when compiled with the persisted option" do
              it "generates RBI files for classes that use the `monetize` method provided by the `money-rails` gem" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :products do |t|
                        t.integer :price_cents
                        t.string :price_currency
                      end
                    end
                  end
                RUBY

                add_ruby_file("product.rb", <<~RUBY)
                  class Product < ActiveRecord::Base
                    monetize(:price_cents)
                  end
                RUBY

                expected = template(<<~RBI, trim_mode: "-")
                  # typed: strong

                  class Product
                    include MoneyRailsGeneratedMethods

                    module MoneyRailsGeneratedMethods
                      sig { returns(T.nilable(::Money)) }
                      def price; end

                      sig { params(value: T.nilable(::Money)).returns(T.nilable(::Money)) }
                      def price=(value); end
                    end
                  end
                RBI
                assert_equal(rbi_for(:Product, compiler_options: { ActiveRecordColumnTypes: "persisted" }), expected)
              end

              it "generates non-nilable types if the column is non-null" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :products do |t|
                        t.integer :price_cents, null: false
                        t.string :price_currency
                      end
                    end
                  end
                RUBY

                add_ruby_file("product.rb", <<~RUBY)
                  class Product < ActiveRecord::Base
                    monetize(:price_cents)
                  end
                RUBY

                expected = indented(<<~RBI, 2)
                  module MoneyRailsGeneratedMethods
                    sig { returns(::Money) }
                    def price; end

                    sig { params(value: ::Money).returns(::Money) }
                    def price=(value); end
                  end
                RBI
                assert_includes(rbi_for(:Product, compiler_options: { ActiveRecordColumnTypes: "persisted" }), expected)
              end

              it "generates non-nilable types if the attribute has a required presence validator" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :products do |t|
                        t.integer :price_cents
                        t.string :price_currency
                      end
                    end
                  end
                RUBY

                add_ruby_file("product.rb", <<~RUBY)
                  class Product < ActiveRecord::Base
                    monetize(:price_cents)

                    validates :price, presence: true
                  end
                RUBY

                expected = indented(<<~RBI, 2)
                  module MoneyRailsGeneratedMethods
                    sig { returns(::Money) }
                    def price; end

                    sig { params(value: ::Money).returns(::Money) }
                    def price=(value); end
                  end
                RBI
                assert_includes(rbi_for(:Product, compiler_options: { ActiveRecordColumnTypes: "persisted" }), expected)
              end
            end

            describe "when compiled with the nilable option" do
              it "generates RBI files for classes that use the `monetize` method provided by the `money-rails` gem" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :products do |t|
                        t.integer :price_cents
                        t.string :price_currency
                      end
                    end
                  end
                RUBY

                add_ruby_file("product.rb", <<~RUBY)
                  class Product < ActiveRecord::Base
                    monetize(:price_cents)
                  end
                RUBY

                expected = template(<<~RBI, trim_mode: "-")
                  # typed: strong

                  class Product
                    include MoneyRailsGeneratedMethods

                    module MoneyRailsGeneratedMethods
                      sig { returns(T.nilable(::Money)) }
                      def price; end

                      sig { params(value: T.nilable(::Money)).returns(T.nilable(::Money)) }
                      def price=(value); end
                    end
                  end
                RBI
                assert_equal(rbi_for(:Product, compiler_options: { ActiveRecordColumnTypes: "nilable" }), expected)
              end

              it "generates nilable types if the column is non-null" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :products do |t|
                        t.integer :price_cents, null: false
                        t.string :price_currency
                      end
                    end
                  end
                RUBY

                add_ruby_file("product.rb", <<~RUBY)
                  class Product < ActiveRecord::Base
                    monetize(:price_cents)
                  end
                RUBY

                expected = indented(<<~RBI, 2)
                  module MoneyRailsGeneratedMethods
                    sig { returns(T.nilable(::Money)) }
                    def price; end

                    sig { params(value: T.nilable(::Money)).returns(T.nilable(::Money)) }
                    def price=(value); end
                  end
                RBI
                assert_includes(rbi_for(:Product, compiler_options: { ActiveRecordColumnTypes: "nilable" }), expected)
              end

              it "generates nilable types if the attribute has a required presence validator" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :products do |t|
                        t.integer :price_cents
                        t.string :price_currency
                      end
                    end
                  end
                RUBY

                add_ruby_file("product.rb", <<~RUBY)
                  class Product < ActiveRecord::Base
                    monetize(:price_cents)

                    validates :price, presence: true
                  end
                RUBY

                expected = indented(<<~RBI, 2)
                  module MoneyRailsGeneratedMethods
                    sig { returns(T.nilable(::Money)) }
                    def price; end

                    sig { params(value: T.nilable(::Money)).returns(T.nilable(::Money)) }
                    def price=(value); end
                  end
                RBI
                assert_includes(rbi_for(:Product, compiler_options: { ActiveRecordColumnTypes: "nilable" }), expected)
              end
            end
          end
        end
      end
    end
  end
end
