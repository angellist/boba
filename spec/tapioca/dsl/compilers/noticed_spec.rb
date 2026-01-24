# typed: strict
# frozen_string_literal: true

require "spec_helper"

# Define stub classes for Noticed before requiring the compiler.
# The real Noticed::Event and Noticed::Ephemeral require a full Rails boot,
# but for testing the compiler we just need classes that can be inherited from.
module Noticed
  class Event
  end

  class Ephemeral
  end
end

module Tapioca
  module Dsl
    module Compilers
      class NoticedSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::Noticed" do
          describe "initialize" do
            it "gathers no constants if there are no Noticed classes" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post
                end
              RUBY

              assert_equal(gathered_constants, [])
            end

            it "gathers Noticed::Event subclasses" do
              add_ruby_file("new_comment_notifier.rb", <<~RUBY)
                class NewCommentNotifier < Noticed::Event
                end
              RUBY

              assert_equal(["NewCommentNotifier"], gathered_constants)
            end

            it "gathers Noticed::Ephemeral subclasses" do
              add_ruby_file("welcome_notifier.rb", <<~RUBY)
                class WelcomeNotifier < Noticed::Ephemeral
                end
              RUBY

              assert_equal(["WelcomeNotifier"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates RBI for Noticed::Event subclass" do
              add_ruby_file("new_comment_notifier.rb", <<~RUBY)
                class NewCommentNotifier < Noticed::Event
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class NewCommentNotifier
                  class << self
                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).void }
                    def deliver(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).void }
                    def deliver_later(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(params: T::Hash[Symbol, T.untyped]).returns(T.class_of(::NewCommentNotifier)) }
                    def with(params); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:NewCommentNotifier))
            end

            it "generates RBI for Noticed::Ephemeral subclass" do
              add_ruby_file("welcome_notifier.rb", <<~RUBY)
                class WelcomeNotifier < Noticed::Ephemeral
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class WelcomeNotifier
                  class << self
                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).void }
                    def deliver(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).void }
                    def deliver_later(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(params: T::Hash[Symbol, T.untyped]).returns(T.class_of(::WelcomeNotifier)) }
                    def with(params); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:WelcomeNotifier))
            end

            it "generates RBI for nested notifier classes" do
              add_ruby_file("admin/alert_notifier.rb", <<~RUBY)
                module Admin
                  class AlertNotifier < Noticed::Event
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Admin::AlertNotifier
                  class << self
                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).void }
                    def deliver(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).void }
                    def deliver_later(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(params: T::Hash[Symbol, T.untyped]).returns(T.class_of(::Admin::AlertNotifier)) }
                    def with(params); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for("Admin::AlertNotifier"))
            end
          end
        end
      end
    end
  end
end
