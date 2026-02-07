# typed: strict
# frozen_string_literal: true

require "spec_helper"

# Stub classes for the Noticed gem.
#
# Unlike gems like FlagShihTzu or MoneyRails which just extend ActiveRecord,
# Noticed is a Rails Engine that requires a full Rails boot. The real
# Noticed::Event and Noticed::Ephemeral classes:
#   - Are in `app/models/` (Rails autoloading)
#   - Include `Rails.application.routes.url_helpers`
#   - Require `ApplicationRecord` to exist
#
# For testing the compiler, we define stub base classes that notifiers can
# inherit from. Test notifier classes are created using `add_ruby_file` for
# proper isolation (same pattern as the AR service specs).
module Noticed
  class Event; end
  class Ephemeral; end
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
                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).returns(::NewCommentNotifier) }
                    def deliver(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).returns(::NewCommentNotifier) }
                    def deliver_later(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(params: T::Hash[Symbol, T.untyped]).returns(::NewCommentNotifier) }
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
                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).returns(::WelcomeNotifier) }
                    def deliver(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).returns(::WelcomeNotifier) }
                    def deliver_later(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(params: T::Hash[Symbol, T.untyped]).returns(::WelcomeNotifier) }
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
                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).returns(::Admin::AlertNotifier) }
                    def deliver(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).returns(::Admin::AlertNotifier) }
                    def deliver_later(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

                    sig { params(params: T::Hash[Symbol, T.untyped]).returns(::Admin::AlertNotifier) }
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
