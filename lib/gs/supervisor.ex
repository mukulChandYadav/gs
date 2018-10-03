defmodule GS.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, [])
  end

  def init(args) do
    #Logger.debug("Inside init " <> inspect(__MODULE__) <> " " <> "with args: " <> inspect(args))
    children = [
      {Registry, keys: :unique, name: GS.Registry.NodeInfo},
      {Registry, keys: :unique, name: GS.Registry.NodeIdToPid},
      {Registry, keys: :unique, name: GS.Registry.Beacon},
      {Registry, keys: :unique, name: Registry.NeighReg},
      {GS.Beacon, name: GS.Beacon},
      {GS.Master, name: GS.Master, args: args},
      {DynamicSupervisor, name: GS.NodeSupervisor, strategy: :one_for_one},

      {GS.Node_failure_instrumentor, name: GS.Node_failure_instrumentor}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end