defmodule GS.Node do

  use Agent

  require Logger

  @moduledoc false

  def start_link(_opts) do
    Logger.debug("Inside " <> inspect(__MODULE__))
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    #TODO: Get/Update bucket to store generic values based on algorithm type, or more specifically algorithm will provide get/update function
    Logger.debug("Inside " <> inspect(__MODULE__))
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def update(bucket, key, value) do
    Logger.debug("Inside " <> inspect(__MODULE__))
    #TODO: Get/Update bucket to store generic values based on algorithm type, or more specifically algorithm will provide get/update function
    Agent.update(bucket, &Map.put(&1, key, value))
  end

end
