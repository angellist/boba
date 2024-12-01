# typed: true
# frozen_string_literal: true

module Paperclip
  module Glue; end

  module AttachmentRegistry
    class << self
      def names_for(*args, **kwargs); end
    end
  end
end
