# Boba

> :warning: This gem is in pre-release and is not ready for use.

Boba is a collection of compilers for Sorbet & Tapioca.

Tapioca is very opinionated about what types of compilers or changes are accepted into the repository. See
[here](https://github.com/Shopify/tapioca?tab=readme-ov-file#dsl-compilers). Boba come in all
different shapes, sizes, consistencies, etc, and is much less opinionated about what is or is not accepted. Think of
Boba like a collection of compilers that you can pick and choose from.

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

## Todo

1. Contributing Section
2. Specs & spec harness
3. Docs & doc harness
