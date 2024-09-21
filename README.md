# Boba

> :warning: This gem is in pre-release and is not ready for use.

Boba is a collection of compilers for Sorbet & Tapioca.

Tapioca is very opinionated about what types of compilers or changes are accepted into the repository. See
[here](https://github.com/Shopify/tapioca?tab=readme-ov-file#dsl-compilers). Boba come in all
different shapes, sizes, consistencies, etc, and is much less opinionated about what is or is not accepted. Boba is a collection of optional compilers that you can pick and choose from.

### Available Compilers

See [the compilers manual](https://github.com/angellist/boba/blob/main/manual/compilers.md) for a list of available compilers.

## Usage

Add Boba to your development dependencies in your gemfile:
```ruby
group :development do
  gem 'boba', require: false
end
```

We recommend you also use the `only` configuration option in your Tapioca config (typically `sorbet/tapioca/config.yml`)
to specify only the Tapioca compilers you wish to use.
```yml
dsl:
  only:
    Compiler1
    Compiler2
```
This makes it easy to selectively enable only the compilers you want to use in your project.

## Contributing

Bugs and feature requests are welcome and should be [filed as issues on github](https://github.com/angellist/boba/issues).

### New Compilers

Compilers for any commonly used Ruby or Rails gems are welcome to be contributed. See the [Writing New Compilers section of the Tapioca docs](https://github.com/Shopify/tapioca?tab=readme-ov-file#writing-custom-dsl-compilers) for an introduction to writing compilers.

Since Boba is intended to be used alongside Tapioca and the compilers provided by Boba are intended to be fully optional,
we will not accept compilers which overwrite the Tapioca default compilers. See the [Tapioca Manual](https://github.com/Shopify/tapioca/blob/main/manual/compilers.md) for a list of these
compilers. Instead, compilers which extend or overwrite the default Tapioca compilers should be given unique names.

Contributed compilers should be well documented, and named after and include a link or reference to the Gem, DSL, or other module they implement RBIs for.

Compilers for Gems, DSLs, or modules that are not publicly available will not be accepted.

## Todo

1. Specs & spec harness
