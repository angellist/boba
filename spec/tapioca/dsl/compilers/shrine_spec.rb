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

                  class << self
                    sig { returns(::Shrine::Attacher) }
                    def image_attacher; end
                  end

                  module ShrineGeneratedMethods
                    sig { returns(T.nilable(::Shrine::UploadedFile)) }
                    def image; end

                    sig { params(value: T.untyped).returns(T.untyped) }
                    def image=(value); end

                    sig { returns(T.nilable(::Shrine::Attacher)) }
                    def image_attacher; end

                    sig { returns(T::Boolean) }
                    def image_changed?; end

                    sig { returns(T.nilable(::String)) }
                    def image_url; end
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
                end
              RUBY

              add_ruby_file("video_uploader.rb", <<~RUBY)
                class VideoUploader < Shrine
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

                  class << self
                    sig { returns(::Shrine::Attacher) }
                    def image_attacher; end

                    sig { returns(::Shrine::Attacher) }
                    def video_attacher; end
                  end

                  module ShrineGeneratedMethods
                    sig { returns(T.nilable(::Shrine::UploadedFile)) }
                    def image; end

                    sig { params(value: T.untyped).returns(T.untyped) }
                    def image=(value); end

                    sig { returns(T.nilable(::Shrine::Attacher)) }
                    def image_attacher; end

                    sig { returns(T::Boolean) }
                    def image_changed?; end

                    sig { returns(T.nilable(::String)) }
                    def image_url; end

                    sig { returns(T.nilable(::Shrine::UploadedFile)) }
                    def video; end

                    sig { params(value: T.untyped).returns(T.untyped) }
                    def video=(value); end

                    sig { returns(T.nilable(::Shrine::Attacher)) }
                    def video_attacher; end

                    sig { returns(T::Boolean) }
                    def video_changed?; end

                    sig { returns(T.nilable(::String)) }
                    def video_url; end
                  end
                end
              RBI
              assert_equal(rbi_for(:Product), expected)
            end
          end
        end
      end
    end
  end
end
