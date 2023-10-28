defmodule JwtArmorTest do
  use ExUnit.Case
  doctest JwtArmor

  alias JwtArmor.Clock

  test "JwtArmor.generate(%{})" do
    config = generate_config 1000

    {ok, token, claims} = JwtArmor.generate(config, %{"user_id" => "any id"})

    assert claims["exp"] < Joken.CurrentTime.OS.current_time() + 1002
    assert claims["exp"] > Joken.CurrentTime.OS.current_time() + 998
    assert claims["exp"] - claims["iat"] == 1000
    assert claims["exp"] - claims["nbf"] == 1000
    assert claims["aud"] == "aud-test"
    assert claims["iss"] == "iss-test"
    assert claims["user_id"] == "any id"
    assert String.length(claims["jti"]) > 0
    assert ok == :ok
    assert String.length(token) > 0
  end


  test "JwtArmor.verify(string, %JwtArmor.Config.Signer{}) success" do
    config = generate_config 10

    {_ok, token, _claims} = JwtArmor.generate(config)
    {ok, _claims} = JwtArmor.verify(token, config.signer)
    assert ok == :ok
  end

  test "JwtArmor.verify(string, %JwtArmor.Config.Signer{}) signature_error" do
    config = generate_config 10

    {_ok, _token, _claims} = JwtArmor.generate(config)
    {ok, error} = JwtArmor.verify("wrong", config.signer)
    assert ok == :error
    assert error == :signature_error
  end

  test "JwtArmor.validate(%JwtArmor.Config.Claims{}, claims_map) success" do
    config = generate_config 3600

    {_ok, token, _claims} = JwtArmor.generate(config)
    {_ok, claims} = JwtArmor.verify(token, config.signer)
    {ok, _claims_map} = JwtArmor.validate(config.claims, claims)

    assert ok == :ok
  end

  test "JwtArmor.validate(%JwtArmor.Config{}, claims_map) error on exp" do
    config = generate_config 3600

    {_ok, token, _claims} = JwtArmor.generate(config)
    {_ok, claims} = JwtArmor.verify(token, config.signer)

    exp_claim_val = :os.system_time(:second) + (60 * 60 * 5)
    Clock.freeze exp_claim_val
    {ok, claims_map} = JwtArmor.validate(config.claims, claims)

    assert ok == :error
    assert claims_map[:message] == "Invalid token"
    assert claims_map[:claim] == "exp"
    assert claims_map[:claim_val] < exp_claim_val

    Clock.unfreeze
  end

  test "JwtArmor.validate(%JwtArmor.Config{}, claims_map) error on nbf" do
    config = generate_config 3600

    {_ok, token, _claims} = JwtArmor.generate(config)
    {_ok, claims} = JwtArmor.verify(token, config.signer)

    exp_claim_val = :os.system_time(:second) - (60 * 60 * 5)
    Clock.freeze exp_claim_val
    {ok, claims_map} = JwtArmor.validate(config.claims, claims)

    assert ok == :error
    assert claims_map[:message] == "Invalid token"
    assert claims_map[:claim] == "nbf"
    assert claims_map[:claim_val] > exp_claim_val

    Clock.unfreeze
  end

  test "JwtArmor.validate(%JwtArmor.Config{}, claims_map) error on aud" do
    config = generate_config 3600

    {_ok, token, _claims} = JwtArmor.generate(config)
    {_ok, claims} = JwtArmor.verify(token, config.signer)

    config = update_aud_config(config, "different-aud")
    {ok, claims_map} = JwtArmor.validate(config.claims, claims)

    assert ok == :error
    assert claims_map[:message] == "Invalid token"
    assert claims_map[:claim] == "aud"
  end

  test "JwtArmor.verify_and_validate(token, %JwtArmor.Config{}) success" do
    config = generate_config 3600

    {_ok, token, _claims} = JwtArmor.generate(config)
    {ok, _claims} = JwtArmor.verify_and_validate(token, config)

    assert ok == :ok
  end

  test "JwtArmor.verify_and_validate(token, %JwtArmor.Config{}) error" do
    config = generate_config 3600

    {_ok, token, _claims} = JwtArmor.generate(config)

    exp_claim_val = :os.system_time(:second) + (60 * 60 * 5)
    Clock.freeze exp_claim_val
    {ok, claims} = JwtArmor.verify_and_validate(token, config)

    assert ok == :error
    assert claims[:message] == "Invalid token"
    assert claims[:claim] == "exp"
    assert claims[:claim_val] < exp_claim_val

    Clock.unfreeze
  end


  defp generate_config(exp) do
    %JwtArmor.Config{
      signer: %JwtArmor.Config.Signer{
        algorithm: Application.fetch_env!(:joken, :signer_algorithm),
        secret: Application.fetch_env!(:joken, :secret_key_base)
      },
      claims: %JwtArmor.Config.Claims{
        exp: exp,
        aud: "aud-test",
        iss: "iss-test"
      }
    }
  end

  defp update_aud_config(config, aud) do
    config_claim = config.claims

    Map.merge(config,
      %JwtArmor.Config{
        signer: config.signer,
        claims: Map.merge(config_claim, %JwtArmor.Config.Claims{aud: aud})
      }
    )
  end
end
