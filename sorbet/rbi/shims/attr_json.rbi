# typed: true
# frozen_string_literal: true

module AttrJson
  class Record
    class << self
      def attr_json_registry(*args, **kwargs); end
    end
  end

  class Model
    class << self
      def attr_json_registry(*args, **kwargs); end
    end
  end
end
