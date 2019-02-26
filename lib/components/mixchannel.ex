defmodule HelloScenic.Component.MixChannel do
  use Scenic.Component

  require Logger

  alias Scenic.Graph
  #alias Scenic.Primitive.Group

  alias Scenic.Components

  defmodule State do
    defstruct graph: nil,
              id: nil
  end

  def verify(data) when is_binary(data) do
    case data do
      "" -> :invalid_data
      _ -> {:ok, data}
    end
  end

  def verify(_), do: :invalid_data

  def init(_, opts) do
    id = opts[:id]
    theme = opts[:styles][:theme]
    #idx = opts[:styles][:idx] || 1

    graph =
      Graph.build(theme: theme)
      |> Components.slider({{0, 1023}, 738},
        id: :fader,
        rotate: -1.57,
        translate: {30, 350},
        theme: theme
      )
      |> Components.checkbox({"", false},
        id: :mute,
        translate: {0, 370},
        theme: %{
          text: :black,
          background: {0xbb, 0x99, 0x99},
          border: {0x33, 0x33, 0x33},
          active: {0x77, 0x77, 0x77},
          thumb: {0x88, 0x33, 0x33}
        }
      )
      |> Components.checkbox({"", false},
        id: :solo,
        translate: {25, 370},
        theme: %{
          text: :black,
          background: {0x99, 0xbb, 0x99},
          border: {0x33, 0x33, 0x33},
          active: {0x77, 0x77, 0x77},
          thumb: {0x33, 0x88, 0x33}
        }
      )

    state = %State{
      id: id,
      graph: graph
    }

    push_graph(graph)

    {:ok, state}
  end

  def handle_input(msg, _ctx, state) do
    Logger.debug fn -> "MixChannel ignoring: #{inspect msg}" end
    {:noreply, state}
  end
end
