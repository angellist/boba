## Shrine

`Tapioca::Dsl::Compilers::Shrine` decorates RBI files for classes that include
a `Shrine::Attachment` module provided by the `shrine` gem.
https://github.com/shrinerb/shrine

For example, with the following model:
~~~rb
class Photo < ActiveRecord::Base
  include ImageUploader::Attachment(:image)
end
~~~

This compiler will generate the following RBI:
~~~rbi
class Photo
  include ShrineGeneratedMethods
  extend ShrineGeneratedClassMethods

  module ShrineGeneratedClassMethods
    sig { params(options: T.untyped).returns(::Shrine::Attacher) }
    def image_attacher(**options); end
  end

  module ShrineGeneratedMethods
    sig { returns(T.nilable(::Shrine::UploadedFile)) }
    def image; end

    sig { params(value: T.untyped).returns(T.untyped) }
    def image=(value); end

    sig { params(options: T.untyped).returns(T.nilable(::Shrine::Attacher)) }
    def image_attacher(**options); end

    sig { returns(T::Boolean) }
    def image_changed?; end

    sig { params(args: T.untyped, options: T.untyped).returns(T.nilable(String)) }
    def image_url(*args, **options); end
  end
end
~~~
