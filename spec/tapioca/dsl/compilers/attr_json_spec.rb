# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "attr_json"

module Tapioca
  module Dsl
    module Compilers
      class AttrJsonSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::AttrJson" do
          describe "decorate" do
            it "types scalar attributes as nilable and array attributes as arrays" do
              add_ruby_file("address.rb", <<~RUBY)
                class Address
                  include AttrJson::Model

                  attr_json :city, :string
                  attr_json :zip_code, :integer, default: 0
                  attr_json :tags, :string, array: true
                  attr_json :aliases, :string, array: true, default: nil
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Address
                  include AttrJsonGeneratedMethods

                  module AttrJsonGeneratedMethods
                    sig { returns(T.nilable(T::Array[::String])) }
                    def aliases; end

                    sig { params(value: T.nilable(T::Array[::String])).returns(T.nilable(T::Array[::String])) }
                    def aliases=(value); end

                    sig { returns(T.nilable(::String)) }
                    def city; end

                    sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                    def city=(value); end

                    sig { returns(T::Array[::String]) }
                    def tags; end

                    sig { params(value: T::Array[::String]).returns(T::Array[::String]) }
                    def tags=(value); end

                    sig { returns(T.nilable(::Integer)) }
                    def zip_code; end

                    sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
                    def zip_code=(value); end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Address))
            end

            it "types attributes with an unconditional presence validator as not nilable" do
              add_ruby_file("address.rb", <<~RUBY)
                class Address
                  include AttrJson::Model

                  attr_json :city, :string
                  attr_json :street, :string
                  attr_json :zip_code, :integer

                  validates :city, presence: true
                  validates :street, presence: true, if: -> { city == "Paris" }
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Address
                  include AttrJsonGeneratedMethods

                  module AttrJsonGeneratedMethods
                    sig { returns(::String) }
                    def city; end

                    sig { params(value: ::String).returns(::String) }
                    def city=(value); end

                    sig { returns(T.nilable(::String)) }
                    def street; end

                    sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                    def street=(value); end

                    sig { returns(T.nilable(::Integer)) }
                    def zip_code; end

                    sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
                    def zip_code=(value); end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:Address))
            end
          end
        end
      end
    end
  end
end
