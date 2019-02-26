defmodule HelloScenic.Component.MixBankCtrl do
  use Scenic.Component

  require Logger

  alias Scenic.Graph
  alias Scenic.Primitives

  defmodule State do
    defstruct id: nil,
              graph: nil
  end

  def verify(data), do: {:ok, data}

  def init(_data, opts) do
    id = opts[:id]

    graph =
      Graph.build()
      |> Primitives.text("BASE", fill: :black)
      |> Primitives.text("8", fill: :black, translate: {0, 25})

    state = %State{
      id: id,
      graph: graph
    }

    push_graph(graph)

    {:ok, state}
  end

  def handle_input(_msg, _ctx, state) do
    {:noreply, state}
  end
end

