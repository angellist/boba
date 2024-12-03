# typed: strict
# frozen_string_literal: true

module ActiveRecord
  class Schema
    class << self
      sig { params(info: T.untyped, block: T.proc.bind(ActiveRecord::ConnectionAdapters::SchemaStatements).void).void }
      def define(info = T.unsafe(nil), &block); end
    end
  end

  class Migration
    class << self
      def suppress_messages(&block); end
    end
  end
end
