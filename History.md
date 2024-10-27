# Boba History

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
