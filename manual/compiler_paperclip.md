## Paperclip

`Tapioca::Dsl::Compilers::Paperclip` decorates RBI files for classes that use the `has_attached_file` method
provided by the `paperclip` gem.
https://github.com/thoughtbot/paperclip

For example, with the following ActiveRecord model:
~~~rb
class Product < ActiveRecord::Base
  has_attached_file(:marketing_image)
end
~~~

This compiler will generate the following RBI:
~~~rbi
class Product
 include PaperclipGeneratedMethods

 module PaperclipGeneratedMethods
   sig { returns(::Paperclip::Attachment) }
   def marketing_image; end

   sig { params(value: T.untyped).void }
   def marketing_image=(value); end
 end
end
~~~
