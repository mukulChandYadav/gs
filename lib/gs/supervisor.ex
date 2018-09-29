defmodule GS.Supervisor do
  @moduledoc false
  


  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  def init(arg) do
    children = [
      {GS.Master, name: GS.Master}
    ]
    Supervisor.init(children, strategy: :one_for_one)
    #supervise(children, strategy: :one_for_one)
  end
end