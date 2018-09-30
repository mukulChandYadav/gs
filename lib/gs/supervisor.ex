defmodule GS.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(arg) do
    Logger.debug("Inside start_link " <> inspect(__MODULE__) <> " " <> "with args: " <> inspect(arg))
    Supervisor.start_link(__MODULE__, arg, [])
  end

  def init(arg) do
    Logger.debug("Inside init " <> inspect(__MODULE__) <> " " <> "with args: " <> inspect(arg))
    children = [
      {GS.Master, name: GS.Master, args: arg}
    ]
    Supervisor.init(children, strategy: :one_for_one)
    #supervise(children, strategy: :one_for_one)
  end
end