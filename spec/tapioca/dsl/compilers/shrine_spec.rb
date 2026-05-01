# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "active_record"
require "shrine"
require "shrine/plugins/activerecord"

module Tapioca
  module Dsl
    module Compilers
      class ShrineSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::Shrine" do
          describe "gather_constants" do
            it "gathers models that include a Shrine::Attachment module" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :photos do |t|
                      t.text :image_data
                    end
                  end
                end
              RUBY

              add_ruby_file("image_uploader.rb", <<~RUBY)
                class ImageUploader < Shrine
                  plugin :model
                end
              RUBY

              add_ruby_file("photo.rb", <<~RUBY)
                class Photo < ActiveRecord::Base
                  include ImageUploader::Attachment(:image)
                end
              RUBY

              assert_includes(gathered_constants, "Photo")
            end

            it "does not gather models without Shrine attachments" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              refute_includes(gathered_constants, "Post")
            end
          end

          describe "decorate" do
            it "generates instance and class methods for a single attachment" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :photos do |t|
                      t.text :image_data
                    end
                  end
                end
              RUBY

              add_ruby_file("image_uploader.rb", <<~RUBY)
                class ImageUploader < Shrine
                  plugin :model
                end
              RUBY

              add_ruby_file("photo.rb", <<~RUBY)
                class Photo < ActiveRecord::Base
                  include ImageUploader::Attachment(:image)
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

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

                    sig { params(args: T.untyped, options: T.untyped).returns(T.nilable(::String)) }
                    def image_url(*args, **options); end
                  end
                end
              RBI
              assert_equal(rbi_for(:Photo), expected)
            end

            it "generates methods for multiple attachments" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :products do |t|
                      t.text :image_data
                      t.text :video_data
                    end
                  end
                end
              RUBY

              add_ruby_file("image_uploader.rb", <<~RUBY)
                class ImageUploader < Shrine
                  plugin :model
                end
              RUBY

              add_ruby_file("video_uploader.rb", <<~RUBY)
                class VideoUploader < Shrine
                  plugin :model
                end
              RUBY

              add_ruby_file("product.rb", <<~RUBY)
                class Product < ActiveRecord::Base
                  include ImageUploader::Attachment(:image)
                  include VideoUploader::Attachment(:video)
                end
              RUBY

              expected = template(<<~RBI, trim_mode: "-")
                # typed: strong

                class Product
                  include ShrineGeneratedMethods
                  extend ShrineGeneratedClassMethods

                  module ShrineGeneratedClassMethods
                    sig { params(options: T.untyped).returns(::Shrine::Attacher) }
                    def image_attacher(**options); end

                    sig { params(options: T.untyped).returns(::Shrine::Attacher) }
                    def video_attacher(**options); end
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

                    sig { params(args: T.untyped, options: T.untyped).returns(T.nilable(::String)) }
                    def image_url(*args, **options); end

                    sig { returns(T.nilable(::Shrine::UploadedFile)) }
                    def video; end

                    sig { params(value: T.untyped).returns(T.untyped) }
                    def video=(value); end

                    sig { params(options: T.untyped).returns(T.nilable(::Shrine::Attacher)) }
                    def video_attacher(**options); end

                    sig { returns(T::Boolean) }
                    def video_changed?; end

                    sig { params(args: T.untyped, options: T.untyped).returns(T.nilable(::String)) }
                    def video_url(*args, **options); end
                  end
                end
              RBI
              assert_equal(rbi_for(:Product), expected)
            end

            it "dynamically picks up methods from shrine plugins" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :documents do |t|
                      t.text :file_data
                    end
                  end
                end
              RUBY

              add_ruby_file("custom_plugin.rb", <<~RUBY)
                class Shrine
                  module Plugins
                    module CustomTestPlugin
                      module AttachmentMethods
                        private

                        def define_entity_methods(name)
                          super

                          define_method :"\#{name}_custom_meta" do
                            "custom"
                          end
                        end
                      end
                    end

                    register_plugin(:custom_test_plugin, CustomTestPlugin)
                  end
                end
              RUBY

              add_ruby_file("file_uploader.rb", <<~RUBY)
                class FileUploader < Shrine
                  plugin :model
                  plugin :custom_test_plugin
                end
              RUBY

              add_ruby_file("document.rb", <<~RUBY)
                class Document < ActiveRecord::Base
                  include FileUploader::Attachment(:file)
                end
              RUBY

              rbi = rbi_for(:Document)
              assert_includes(rbi, "def file_custom_meta; end")
              assert_includes(rbi, "T.untyped")
            end

            it "synthesizes parameter names for anonymous splat / block parameters" do
              # Anonymous splat parameters (`def m(*, **, &)`) come back from
              # `Method#parameters` as the special symbols `:*`, `:**`, `:&`. Without
              # the indexed fallback in `compile_parameters`, those would be emitted
              # verbatim and produce unparseable RBI (`def file_anon(**, ****, &&)`
              # plus a sig with invalid keyword names).
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :records do |t|
                      t.text :file_data
                    end
                  end
                end
              RUBY

              add_ruby_file("anon_plugin.rb", <<~RUBY)
                class Shrine
                  module Plugins
                    module AnonSplatPlugin
                      module AttachmentMethods
                        private

                        def define_entity_methods(name)
                          super

                          module_eval(<<~METHOD, __FILE__, __LINE__ + 1)
                            def \#{name}_forward(*, **, &)
                              nil
                            end
                          METHOD
                        end
                      end
                    end

                    register_plugin(:anon_splat_plugin, AnonSplatPlugin)
                  end
                end
              RUBY

              add_ruby_file("file_uploader.rb", <<~RUBY)
                class FileUploader < Shrine
                  plugin :model
                  plugin :anon_splat_plugin
                end
              RUBY

              add_ruby_file("record.rb", <<~RUBY)
                class Record < ActiveRecord::Base
                  include FileUploader::Attachment(:file)
                end
              RUBY

              rbi = rbi_for(:Record)
              assert_includes(rbi, "def file_forward(*_arg0, **_arg1, &_arg2); end")
            end
          end
        end
      end
    end
  end
end
