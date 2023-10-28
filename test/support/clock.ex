defmodule JwtArmor.Clock do
  def current_time do
    Process.get(:mock_utc_now) || :os.system_time(:second)
  end

  def freeze do
    Process.put(:mock_utc_now, current_time())
  end

  def freeze(time_in_seconds) do
    Process.put(:mock_utc_now, time_in_seconds)
  end

  def unfreeze do
    Process.delete(:mock_utc_now)
  end
end
