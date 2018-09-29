defmodule GS do
  use Application

  @moduledoc """
  Documentation for GS.
  """

  def start(_type, _args) do
    GS.Supervisor.start_link(name: Supervisor)
  end

end
