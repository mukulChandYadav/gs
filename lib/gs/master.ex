defmodule GS.Master do
  @moduledoc false

  require Logger

  use GenServer

  def start_link(opts) do
    Logger.debug("Inside start_link " <> inspect(__MODULE__) <> " " <> "with options: " <> inspect(opts))
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Logger.debug("Inside init " <> inspect(__MODULE__) <> " " <> "with options: " <> inspect(opts))
    commandline_arg = opts[:args]

    Logger.debug("commmand line_arg" <> inspect(commandline_arg))
    [head|tail] = commandline_arg
    num_nodes = String.to_integer(head)
    [head|tail] = tail
    topology = head
    [head|tail] = tail
    algorithm = head
    Logger.debug("commmand line_arg nodes - " <> inspect(num_nodes) <> " topology - " <> inspect(topology) <> " algo - "<> inspect(algorithm))

    # Create node registry <node_id, node_info>
    Registry.start_link(keys: :unique, name: GS.Registry.NodeInfo)

    # Populate neighbor registry
    GS.Neighbors.main(topology, num_nodes)
    node_ids = Registry.keys(Registry.NeighReg, self())
    Logger.debug("Prepared node_ids" <> inspect(node_ids))

    node_list = Enum.map( node_ids, fn x ->
      {:ok, pid} = GS.Node.start_link([topology, algorithm])
      Registry.register(GS.Registry.NodeInfo, x, %GS.NodeInfo{node_id: x, termination_timestamp: 0, node_state: %{}, node_pid: pid})
      pid
    end)

    Logger.debug("node_list" <> inspect(node_list))

    self_pid = self()
    # Send message to random node
    case algorithm do
      :gossip ->
        Logger.debug("In gossip")

      :push_sum ->
        Logger.debug("In push sum")

      _ ->

      Logger.debug("Calling random node")
      #TODO: Capture current start timestamp
      [head|tail] = node_list
      GS.Node.send_msg(head, self_pid, "abc")

    end

    {:ok, %{}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end