## Devise

`Tapioca::Dsl::Compilers::Devise` generates RBI files for `ApplicationController``

For example, with the following routes configuration:

~~~rb
Rails.application.routes.draw do
  devise_for :users
end
~~~

this compiler will produce the RBI file `user.rbi` with the following content:

~~~rbi
# user.rbi
# typed: true
class ApplicationController
  sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
  def user_session; end

  sig { returns(T::Boolean) }
  def user_signed_in?; end

  sig { void }
  def authenticate_user!; end

  sig { returns(T.nilable(User)) }
  def current_user; end
end
~~~
