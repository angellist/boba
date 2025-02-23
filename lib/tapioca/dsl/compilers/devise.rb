# typed: true
# frozen_string_literal: true

return unless defined?(Devise)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Devise` generates RBI files for `ApplicationController``
      #
      # For example, with the following routes configuration:
      #
      # ~~~rb
      # Rails.application.routes.draw do
      #   devise_for :users
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `user.rbi` with the following content:
      #
      # ~~~rbi
      # # user.rbi
      # # typed: true
      # class ApplicationController
      #   sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
      #   def user_session; end
      #
      #   sig { returns(T::Boolean) }
      #   def user_signed_in?; end
      #
      #   sig { void }
      #   def authenticate_user!; end
      #
      #   sig { returns(T.nilable(User)) }
      #   def current_user; end
      # end
      # ~~~
      class Devise < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { upper: ActiveRecord::Base } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            ::Devise.mappings.values.map(&:class_name).map(&:constantize)
          end
        end

        sig { override.void }
        def decorate
          ::Devise.mappings.each do |key, mapping|
            root.create_path(ApplicationController) do |klass|
              klass.create_method("current_#{key}", return_type: "T.nilable(#{mapping.class_name})")
              klass.create_method("authenticate_#{key}!", return_type: "void")
              klass.create_method("#{key}_session", return_type: "T.nilable(T::Hash[T.untyped, T.untyped])")
              klass.create_method("#{key}_signed_in?", return_type: "T::Boolean")
            end
          end
        end
      end
    end
  end
end
