## StateMachinesExtended

`Tapioca::Dsl::Compilers::StateMachinesExtended` extends the default state machines compiler provided by Tapioca
to allow for calling `with_state` and `without_state` on all Active Record relations. This is a temporary fix
until a more durable solution can be found for this type of issue.
See https://github.com/Shopify/tapioca/pull/1994#issuecomment-2302624697.
