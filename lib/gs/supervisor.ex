defmodule GS.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(arg) do
    #Logger.debug("Inside start_link " <> inspect(__MODULE__) <> " " <> "with args: " <> inspect(arg))
    Supervisor.start_link(__MODULE__, arg, [])
  end

  def init(args) do
    #Logger.debug("Inside init " <> inspect(__MODULE__) <> " " <> "with args: " <> inspect(args))
    children = [
      #supervisor(Registry, :unique, GS.Registry.NodeInfo),
      #supervisor(Registry, :unique, GS.Registry.NodeIdToPid),
      #supervisor(Registry, :unique, GS.Registry.Beacon),
      {GS.Beacon, name: GS.Beacon},
      {GS.Master, name: GS.Master, args: args},

      #{GS.Node_failure_instrumentor, name: GS.Node_failure_instrumentor}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end