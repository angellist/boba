## Noticed

`Tapioca::Dsl::Compilers::Noticed` decorates RBI files for subclasses
of `Noticed::Event` and `Noticed::Ephemeral`.

For example, with the following notifier class:

~~~rb
class NewCommentNotifier < Noticed::Event
  required_params :comment
  deliver_by :email
end
~~~

This compiler will produce the RBI file `new_comment_notifier.rbi` with the following content:

~~~rbi
# new_comment_notifier.rbi
# typed: true
class NewCommentNotifier
  class << self
    sig { params(params: T::Hash[Symbol, T.untyped]).returns(NewCommentNotifier) }
    def with(params); end

    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).returns(NewCommentNotifier) }
    def deliver(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end

    sig { params(recipients: T.untyped, enqueue_job: T.nilable(T::Boolean), options: T.untyped).returns(NewCommentNotifier) }
    def deliver_later(recipients = T.unsafe(nil), enqueue_job: T.unsafe(nil), **options); end
  end
end
~~~
