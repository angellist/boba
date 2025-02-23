# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "devise"

module Tapioca
  module Dsl
    module Compilers
      class DeviseSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::Devise" do
          describe "decorate" do
            it "adds Devise's helper methods to ApplicationController" do
              add_ruby_file("user.rb", <<~RUBY)
                module ApplicationController
                end
                module ActiveRecord
                  class Base; end
                end
                class User < ActiveRecord::Base
                end
              RUBY
              FakeMapping = Struct.new(:class_name)
              ::Devise.mappings[:user] = FakeMapping.new("User")
              assert_equal(rbi_for(:User), <<~RBI)
                # typed: strong

                module ApplicationController
                  sig { void }
                  def authenticate_user!; end

                  sig { returns(T.nilable(User)) }
                  def current_user; end

                  sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
                  def user_session; end

                  sig { returns(T::Boolean) }
                  def user_signed_in?; end
                end
              RBI
            end
          end
        end
      end
    end
  end
end
