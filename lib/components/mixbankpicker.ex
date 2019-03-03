defmodule HelloScenic.Component.MixBankPicker do
  use Scenic.Component

  require Logger

  alias Scenic.Components
  alias Scenic.Graph
  alias Scenic.Primitives

  defmodule State do
    defstruct id: nil,
              graph: nil
  end

  def verify(data) when is_integer(data) do
    if Enum.member?(1..4, data), do: {:ok, data}, else: :invalid_data
  end

  def verify(_), do: :invalid_data

  def init(default_bank, opts) do
    Logger.debug fn -> "initialising mixer bank: #{inspect default_bank} #{inspect opts}" end
    id = opts[:id]
    theme = opts[:styles][:theme]

    graph =
      Graph.build()
      |> Primitives.text("BANK", fill: :black)
      |> Components.radio_group([
        {"01-08", :bank1, true},
        {"09-16", :bank2},
        {"17-24", :bank3},
        {"25-32", :bank4},
      ], id: :channelbank, translate: {0, 25}, theme: theme)

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
