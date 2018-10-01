defmodule GS.NodeInfo do
  @moduledoc false

  '''
    node_state should be provided by implementing algorithm
  '''

  defstruct node_id: -1, termination_timestamp: 0, node_state: %{}, node_pid: nil

end
