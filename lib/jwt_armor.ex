defmodule JwtArmor do
  @moduledoc """
  Documentation for `JwtArmor`.

  JwtArmor wraps the Joken package to make it simpler to use with the security best practices.
  """

  @doc """
  Generate the token for a given config and any extra info you need.

  ```
  config = %JwtArmor.Config{
    signer: %JwtArmor.Config.Signer{
      algorithm: "HS256",
      secret: "my secret key"
    },
    claims: %JwtArmor.Config.Claims{
      exp: 60 * 60, # 1 hour
      aud: "the-audience",
      iss: "the-issuser"
    }
  }

  {ok, token, claims} = JwtArmor.generate(config, %{"extra_id" => "any id"})
  ```
  """
  def generate(%JwtArmor.Config{} = config, %{} = extras \\ %{}) do
    Joken.generate_and_sign(token_config(config.claims), extras, signer(config.signer), [])
  end

  defp token_config(%JwtArmor.Config.Claims{} = claims_config) do
    Joken.Config.default_claims()
    |> Map.merge(%{
        "exp" => handle_claim_exp(claims_config.exp),
        "aud" => handle_claim_aud(claims_config.aud),
        "iss" => handle_claim_iss(claims_config.iss)
      })
  end

  defp signer(%JwtArmor.Config.Signer{} = signer_config) do
    Joken.Signer.create(signer_config.algorithm, signer_config.secret)
  end

  defp handle_claim_exp(expiry_in_seconds) do
    extra_seconds =
      case expiry_in_seconds do
        nil ->
          0
        _ ->
          expiry_in_seconds
      end

    %Joken.Claim{
      generate: fn -> Joken.current_time() + extra_seconds end,
      validate: fn val, _claims, _context -> val > Joken.current_time() end
    }
  end

  defp handle_claim_aud(audience) do
    %Joken.Claim{
      generate: fn -> audience end,
      validate: fn val, _claims, _context -> val == audience end
    }
  end

  defp handle_claim_iss(issuer) do
    %Joken.Claim{
      generate: fn -> issuer end,
      validate: fn val, _claims, _context -> val == issuer end
    }
  end

  @doc """
  Verify the token by a given signer.

  ```
  token = "a token example"

  signer = %JwtArmor.Config.Signer{
    algorithm: "HS256",
    secret: "my secret key"
  }

  {ok, claims} = JwtArmor.verify(token, signer)
  # if "ok" is an :error the "claims" contains the error message
  ```
  """
  def verify(token, %JwtArmor.Config.Signer{} = signer_config) do
    Joken.verify(token, signer(signer_config))
  end

  @doc """
  Validate the token by a given signer.

  ```
  token = "a token example"

  claims = %JwtArmor.Config.Claims{
    exp: 60 * 60, # 1 hour
    aud: "the-audience",
    iss: "the-issuser"
  }

  {ok, claim_maps} = JwtArmor.validate(token, claims)
  # if "ok" is an :error the "claim_maps" contains the error message
  ```
  """
  def validate(%JwtArmor.Config.Claims{} = claims_config, verified_claims) do
    token_config(claims_config)
    |> Joken.validate(verified_claims)
  end

  @doc """
  Verify and validate the token by a given config.

  ```
  token = "a token example"

  config = %JwtArmor.Config{
    signer: %JwtArmor.Config.Signer{
      algorithm: "HS256",
      secret: "my secret key"
    },
    claims: %JwtArmor.Config.Claims{
      exp: 60 * 60, # 1 hour
      aud: "the-audience",
      iss: "the-issuser"
    }
  }

  {ok, claims} = JwtArmor.verify_and_validate(token, config)
  # if "ok" is an :error the "claims" contains the error message
  ```
  """
  def verify_and_validate(token, %JwtArmor.Config{} = config) do
    token_config(config.claims)
    |> Joken.verify_and_validate(token, signer(config.signer))
  end
end
