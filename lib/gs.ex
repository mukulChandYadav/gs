defmodule GS do
  use Application

  require Logger

  @moduledoc """
  Documentation for GS.
  """

  def start(_type, _args) do
    Logger.debug("Inside start " <> inspect(__MODULE__) <> " " <> "with args: " <> inspect(_args) <> "and type: " <> inspect(_type))
    GS.Supervisor.start_link(_args)
  end

end
