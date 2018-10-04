defmodule GS do
  use Application

  require Logger

  @moduledoc """
  Documentation for GS.
  """

  def start(type, args) do
    #Logger.debug("Inside start " <> inspect(__MODULE__) <> " " <> "with args: " <> inspect(args) <> "and type: " <> inspect(type))
    GS.Supervisor.start_link(args)
    GenServer.call(GS.Master, {:process, args}, :infinity)
  end

end
