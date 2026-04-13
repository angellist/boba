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

  module ShrineGeneratedMethods
    sig { returns(T.nilable(::Shrine::UploadedFile)) }
    def image; end

    sig { params(value: T.untyped).returns(T.untyped) }
    def image=(value); end

    sig { returns(T.nilable(::Shrine::Attacher)) }
    def image_attacher; end

    sig { returns(T::Boolean) }
    def image_changed?; end

    sig { returns(T.nilable(String)) }
    def image_url; end
  end

  class << self
    sig { returns(::Shrine::Attacher) }
    def image_attacher; end
  end
end
~~~
