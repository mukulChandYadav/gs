defmodule GS.Master do
  @moduledoc false

  require Logger

  use GenServer

  def start_link( opts) do
    Logger.debug("Inside start_link " <> inspect(__MODULE__) <> " " <> "with options: " <> inspect(opts))
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Logger.debug("Inside init " <> inspect(__MODULE__) <> " " <> "with options: " <> inspect(opts))
    commandline_arg = opts[:args]

    Logger.debug("commmand line_arg" <> inspect(commandline_arg))
    [head|tail] = commandline_arg
    num_nodes = String.to_integer(head)
    [head|tail] = commandline_arg
    topology = head
    [head|tail] = commandline_arg
    algorithm = head
    Logger.debug("commmand line_arg nodes - " <> inspect(num_nodes) <> " topology - " <> inspect(topology) <> " algo - "<> inspect(algorithm))

    node_list = Enum.map( 1..num_nodes, fn _x ->
      Logger.debug("commmand line_arg" <> inspect(commandline_arg))
      abc = GS.Node.start_link([topology, algorithm])
    end)
    Logger.debug("node_list" <> inspect(node_list))

    {:ok, %{}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end