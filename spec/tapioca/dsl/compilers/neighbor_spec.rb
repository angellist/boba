# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "rails"
require "neighbor"

module Tapioca
  module Dsl
    module Compilers
      class NeighborSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
          ::ActiveRecord::Base.extend(::Neighbor::Model)
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::Neighbor" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers non-abstract ActiveRecord classes" do
              add_ruby_file("models.rb", <<~RUBY)
                class Document < ActiveRecord::Base
                end

                class AbstractDocument < ActiveRecord::Base
                  self.abstract_class = true
                end
              RUBY

              assert_equal(["Document"], gathered_constants)
            end
          end

          describe "decorate" do
            it "declares the module carrying has_neighbors" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :documents do |t|
                      t.binary :embedding
                    end
                  end
                end
              RUBY

              add_ruby_file("document.rb", <<~RUBY)
                class Document < ActiveRecord::Base
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Document
                  extend Neighbor::Model
                end
              RBI

              assert_equal(expected, rbi_for(:Document))
            end
          end
        end
      end
    end
  end
end
