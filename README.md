# JwtArmor

JwtArmor wraps the Joken package and make it simpler more secure to use.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jwt_armor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jwt_armor, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/jwt_armor>.

## Usage

#### First: create a config file:

```
config = %JwtArmor.Config{
  signer: %JwtArmor.Config.Signer{
    algorithm: "HS256",
    secret: "a secret key"
  },
  claims: %JwtArmor.Config.Claims{
    exp: 3600,        # token will expire in 3600 seconds (1 hour)
    aud: "my-aud",
    iss: "my-iss"
  }
}
```

#### Second: generate tokens

```
{ok, token, claims} = JwtArmor.generate(config)
```

#### Third: verify tokens

```
{ok, verified_claims} = JwtArmor.verify(token, config.signer)
```

#### Fourth: validate tokens

```
{ok, validated_claims} = JwtArmor.validate(config.claims, verified_claims)
```

#### Fifth: verify and validate tokens

```
{ok, claims} = JwtArmor.verify_and_validate(token, config)
```

## License

JwtArmor is released under the [MIT License](https://opensource.org/licenses/MIT).
