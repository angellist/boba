# Boba History

## 0.1.1

- Add a compiler for `FlagShihTsu`.
- Bump Tapioca to v0.16.11.

### Breaking Changes

- `MoneyRails` compiler now creates an extend to `MoneyRails::ActiveRecord::Monetizable::ClassMethods`. By default, this may not be included in your `MoneyRails` gem RBI, and you will need to add a `require` to `tapioca/require.rb` and regenerate the gem RBI in order for it to work.

## 0.0.17

- Bump Tapioca

## 0.0.16

- Bump Tapioca

## 0.0.15

- Bump Tapioca & Ruby Versions

## 0.0.14

- Add test harness, CI, and a bunch of specs. Thanks @rzane!
- Add `Kaminari` compiler. (@rzane)
- Update `MoneyRails` to respect `ActiveRecordColumnTypes` setting, so it generates non-nilable types only in persisted mode.

## 0.0.13

- Add `RelationType` alias to railtie as well as `ActiveRecordRelationTypes` compiler to generate it into RBI files. Fix railtie constants.

## 0.0.12

- Rename `StateMachines` compiler back to `StateMachinesExtended` to avoid load order nonsense with Tapioca.
- Add all base relation types used to the AR railtie so they're all defined at runtime.
- Make Tapioca version more conservative, since we're overriding compiler internals and incremental bumps could break them.

## 0.0.11

- Dupe Tapioca `StateMachines` compiler and fix bug with abstract classes and preloading instance methods.
- Fix sorting bug in `Paperclip` compiler.

## 0.0.10

- Handle abstract classes in `StateMachinesExtended` better

## 0.0.9

- Added `AttrJson` compiler
- Added `Paperclip` compiler
- Fixed a bug in `StateMachinesExtended` compiler where isntance methods were undefined.
- Bump tapioca dependency to latest (16.4)

## 0.0.8

- `ActiveRecordAssocationsPersisted` generate non-nilable types when there's an unconditional validation on the association, an unconditional validation on the foreign key for the association, or when there's a non-`null` db constraint on the foreign key.

## 0.0.7

- Fix bug in `ActiveRecordColumnsPersisted` where `@column_type_option` can be `nil`.

## 0.0.6

- Fix a bug inheriting from default Tapioca compilers if corresponding Tapioca default compilers don't exist because
  the project does not actually use the corresponding DSL or gem.
  - Fixes `StateMachinesExtended`, `ActiveRecordAssocationsPersisted`, `ActiveRecordColumnsPersisted`

## 0.0.5

- Add extended state machines compiler to fix typing on state machines class methods

## 0.0.4

- Add railtie to make `PrivateRelation` type available at runtime

## 0.0.3

- Add extended versions of AR default column and association compilers, general cleanup

## 0.0.2

- Clean up gem setup, add more to gemspec

## 0.0.1

- Add `MoneyRails` compiler

## 0.0.0

- Initial Commit
