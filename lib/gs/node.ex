defmodule GS.Node do

  use Agent

  require Logger

  @moduledoc false

  def start_link(_opts) do
    Logger.debug("Inside start_link " <> inspect(__MODULE__))
    Agent.start_link(fn -> %{} end)
  end

  def send_msg(agent, master, algorithm, msg) do
    Logger.debug("Received msg: " <> msg <> " for " <> inspect(agent) <> " from master : " <> inspect(self()))

    #TODO: Get neighbors
    node_ids = Registry.keys(Registry.NeighReg, master)
    Logger.debug("Node ids: " <> inspect(node_ids))
    [head | tail] = node_ids

    should_terminate =
    case algorithm do
      :gossip ->
        Logger.debug("In gossip")

      :push_sum ->
        Logger.debug("In push sum")

      _ ->

        false
    end

    GS.Node.send_msg(head, master, algorithm, "abc")

    if should_terminate do
      Process.exit(
        agent,
        :normal
      )
    end
 
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
