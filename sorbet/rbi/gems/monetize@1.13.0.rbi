# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `monetize` gem.
# Please instead update this file by running `bin/tapioca gem monetize`.


# source://monetize//lib/monetize/core_extensions/hash.rb#3
class Hash
  include ::Enumerable

  # source://monetize//lib/monetize/core_extensions/hash.rb#4
  def to_money(currency = T.unsafe(nil)); end
end

# source://monetize//lib/monetize/errors.rb#1
module Monetize
  class << self
    # Returns the value of attribute assume_from_symbol.
    #
    # source://monetize//lib/monetize.rb#15
    def assume_from_symbol; end

    # Sets the attribute assume_from_symbol
    #
    # @param value the value to set the attribute assume_from_symbol to.
    #
    # source://monetize//lib/monetize.rb#15
    def assume_from_symbol=(_arg0); end

    # Monetize uses the delimiters set in the currency to separate integers from
    # decimals, and to ignore thousands separators. In some corner cases,
    # though, it will try to determine the correct separator by itself. Set this
    # to true to enforce the delimiters set in the currency all the time.
    #
    # source://monetize//lib/monetize.rb#21
    def enforce_currency_delimiters; end

    # Monetize uses the delimiters set in the currency to separate integers from
    # decimals, and to ignore thousands separators. In some corner cases,
    # though, it will try to determine the correct separator by itself. Set this
    # to true to enforce the delimiters set in the currency all the time.
    #
    # source://monetize//lib/monetize.rb#21
    def enforce_currency_delimiters=(_arg0); end

    # Where this set to true, the behavior for parsing thousands separators is changed to
    # expect that eg. €10.000 is EUR 10 000 and not EUR 10.000 - it's incredibly rare when parsing
    # human text that we're dealing with fractions of cents.
    #
    # source://monetize//lib/monetize.rb#27
    def expect_whole_subunits; end

    # Where this set to true, the behavior for parsing thousands separators is changed to
    # expect that eg. €10.000 is EUR 10 000 and not EUR 10.000 - it's incredibly rare when parsing
    # human text that we're dealing with fractions of cents.
    #
    # source://monetize//lib/monetize.rb#27
    def expect_whole_subunits=(_arg0); end

    # source://monetize//lib/monetize.rb#74
    def extract_cents(input, currency = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#65
    def from_bigdecimal(value, currency = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#56
    def from_fixnum(value, currency = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#61
    def from_float(value, currency = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#56
    def from_integer(value, currency = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#69
    def from_numeric(value, currency = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#51
    def from_string(value, currency = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#29
    def parse(input, currency = T.unsafe(nil), options = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#35
    def parse!(input, currency = T.unsafe(nil), options = T.unsafe(nil)); end

    # source://monetize//lib/monetize.rb#47
    def parse_collection(input, currency = T.unsafe(nil), options = T.unsafe(nil)); end
  end
end

# source://monetize//lib/monetize/errors.rb#5
class Monetize::ArgumentError < ::Monetize::Error; end

# source://monetize//lib/monetize/collection.rb#6
class Monetize::Collection
  include ::Enumerable
  extend ::Forwardable

  # @return [Collection] a new instance of Collection
  #
  # source://monetize//lib/monetize/collection.rb#17
  def initialize(input, currency = T.unsafe(nil), options = T.unsafe(nil)); end

  # source://forwardable/1.3.3/forwardable.rb#231
  def [](*args, **_arg1, &block); end

  # Returns the value of attribute currency.
  #
  # source://monetize//lib/monetize/collection.rb#11
  def currency; end

  # source://forwardable/1.3.3/forwardable.rb#231
  def each(*args, **_arg1, &block); end

  # Returns the value of attribute input.
  #
  # source://monetize//lib/monetize/collection.rb#11
  def input; end

  # source://forwardable/1.3.3/forwardable.rb#231
  def last(*args, **_arg1, &block); end

  # Returns the value of attribute options.
  #
  # source://monetize//lib/monetize/collection.rb#11
  def options; end

  # source://monetize//lib/monetize/collection.rb#29
  def parse; end

  # @return [Boolean]
  #
  # source://monetize//lib/monetize/collection.rb#39
  def range?; end

  private

  # source://monetize//lib/monetize/collection.rb#48
  def split_list; end

  # source://monetize//lib/monetize/collection.rb#52
  def split_range; end

  class << self
    # source://monetize//lib/monetize/collection.rb#13
    def parse(input, currency = T.unsafe(nil), options = T.unsafe(nil)); end
  end
end

# source://monetize//lib/monetize/collection.rb#45
Monetize::Collection::LIST_SPLIT = T.let(T.unsafe(nil), Regexp)

# source://monetize//lib/monetize/collection.rb#46
Monetize::Collection::RANGE_SPLIT = T.let(T.unsafe(nil), Regexp)

# source://monetize//lib/monetize/errors.rb#2
class Monetize::Error < ::StandardError; end

# source://monetize//lib/monetize/errors.rb#4
class Monetize::ParseError < ::Monetize::Error; end

# source://monetize//lib/monetize/parser.rb#4
class Monetize::Parser
  # @return [Parser] a new instance of Parser
  #
  # source://monetize//lib/monetize/parser.rb#40
  def initialize(input, fallback_currency = T.unsafe(nil), options = T.unsafe(nil)); end

  # source://monetize//lib/monetize/parser.rb#46
  def parse; end

  private

  # source://monetize//lib/monetize/parser.rb#94
  def apply_multiplier(multiplier_exp, amount); end

  # source://monetize//lib/monetize/parser.rb#98
  def apply_sign(negative, amount); end

  # @return [Boolean]
  #
  # source://monetize//lib/monetize/parser.rb#86
  def assume_from_symbol?; end

  # source://monetize//lib/monetize/parser.rb#102
  def compute_currency; end

  # source://monetize//lib/monetize/parser.rb#191
  def currency_symbol_regex; end

  # @return [Boolean]
  #
  # source://monetize//lib/monetize/parser.rb#90
  def expect_whole_subunits?; end

  # source://monetize//lib/monetize/parser.rb#107
  def extract_major_minor(num, currency); end

  # source://monetize//lib/monetize/parser.rb#127
  def extract_major_minor_with_single_delimiter(num, currency, delimiter); end

  # source://monetize//lib/monetize/parser.rb#146
  def extract_major_minor_with_tentative_delimiter(num, delimiter); end

  # source://monetize//lib/monetize/parser.rb#167
  def extract_multiplier; end

  # source://monetize//lib/monetize/parser.rb#176
  def extract_sign(input); end

  # Returns the value of attribute fallback_currency.
  #
  # source://monetize//lib/monetize/parser.rb#74
  def fallback_currency; end

  # Returns the value of attribute input.
  #
  # source://monetize//lib/monetize/parser.rb#74
  def input; end

  # @return [Boolean]
  #
  # source://monetize//lib/monetize/parser.rb#123
  def minor_has_correct_dp_for_currency_subunit?(minor, currency); end

  # Returns the value of attribute options.
  #
  # source://monetize//lib/monetize/parser.rb#74
  def options; end

  # source://monetize//lib/monetize/parser.rb#76
  def parse_currency; end

  # source://monetize//lib/monetize/parser.rb#182
  def regex_safe_symbols; end

  # source://monetize//lib/monetize/parser.rb#186
  def split_major_minor(num, delimiter); end

  # source://monetize//lib/monetize/parser.rb#68
  def to_big_decimal(value); end
end

# source://monetize//lib/monetize/parser.rb#5
Monetize::Parser::CURRENCY_SYMBOLS = T.let(T.unsafe(nil), Hash)

# source://monetize//lib/monetize/parser.rb#38
Monetize::Parser::DEFAULT_DECIMAL_MARK = T.let(T.unsafe(nil), String)

# source://monetize//lib/monetize/parser.rb#36
Monetize::Parser::MULTIPLIER_REGEXP = T.let(T.unsafe(nil), Regexp)

# source://monetize//lib/monetize/parser.rb#34
Monetize::Parser::MULTIPLIER_SUFFIXES = T.let(T.unsafe(nil), Hash)

# source://monetize//lib/monetize/version.rb#4
Monetize::VERSION = T.let(T.unsafe(nil), String)

# source://monetize//lib/monetize/core_extensions/nil_class.rb#1
class NilClass
  # source://monetize//lib/monetize/core_extensions/nil_class.rb#2
  def to_money(currency = T.unsafe(nil)); end
end

# source://monetize//lib/monetize/core_extensions/numeric.rb#3
class Numeric
  include ::Comparable

  # source://monetize//lib/monetize/core_extensions/numeric.rb#4
  def to_money(currency = T.unsafe(nil)); end
end

# source://monetize//lib/monetize/core_extensions/string.rb#3
class String
  include ::Comparable

  # source://monetize//lib/monetize/core_extensions/string.rb#8
  def to_currency; end

  # source://monetize//lib/monetize/core_extensions/string.rb#4
  def to_money(currency = T.unsafe(nil)); end
end

# source://monetize//lib/monetize/core_extensions/symbol.rb#3
class Symbol
  include ::Comparable

  # source://monetize//lib/monetize/core_extensions/symbol.rb#4
  def to_currency; end
end