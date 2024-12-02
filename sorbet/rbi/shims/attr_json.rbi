# typed: true
# frozen_string_literal: true

module AttrJson
  module Record
    class << self
      def attr_json_registry(*args, **kwargs); end
    end
  end

  module Model
    class << self
      def attr_json_registry(*args, **kwargs); end
    end
  end
end
