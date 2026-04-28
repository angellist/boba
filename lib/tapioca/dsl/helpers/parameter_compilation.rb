# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      # Compiles `Method` / `UnboundMethod#parameters` into the `RBI::TypedParam` array
      # expected by `RBI::Scope#create_method`. Used by compilers that mirror dynamically
      # discovered methods (e.g. `Shrine`, `Draper`).
      #
      # Argument types default to `T.untyped` since the consumer typically has no signature
      # information for the source methods. Anonymous parameter names — including empty
      # names and the special tokens `:*`, `:**`, `:&` — are replaced with `_arg{index}` so
      # the generated RBI is syntactically valid. The leading underscore matches the
      # convention used by Tapioca's own `compile_method_parameters_to_rbi` and signals an
      # unused argument to readers.
      module ParameterCompilation
        include RBIHelper

        #: ((Method | UnboundMethod) method_obj) -> Array[RBI::TypedParam]
        def compile_parameters(method_obj)
          method_obj.parameters.each_with_index.filter_map do |(type, name), index|
            name_str = name.to_s
            name_str = "_arg#{index}" unless name_str.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/)
            case type
            when :req
              create_param(name_str, type: "T.untyped")
            when :opt
              create_opt_param(name_str, type: "T.untyped", default: "T.unsafe(nil)")
            when :rest
              create_rest_param(name_str, type: "T.untyped")
            when :keyreq
              create_kw_param(name_str, type: "T.untyped")
            when :key
              create_kw_opt_param(name_str, type: "T.untyped", default: "T.unsafe(nil)")
            when :keyrest
              create_kw_rest_param(name_str, type: "T.untyped")
            when :block
              create_block_param(name_str, type: "T.untyped")
            end
          end
        end
      end
    end
  end
end
