import Config

config :joken, signer_algorithm: "HS256"
config :joken, secret_key_base: "/OX8SrEgcO0VhQ+Sm/Fl7l9CVX6lLB3K4yl4Cv/fkI0k9IzHJGHeO9d3zS6I/fV1"

# config :joken, current_time_adapter: MyTimeMock
# All it needs is to implement the function current_time/0.

config :joken, current_time_adapter: JwtArmor.Clock
