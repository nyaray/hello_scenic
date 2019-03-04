defmodule HelloScenic.Component.MixChannel do
  use Scenic.Component

  require Logger

  alias HelloScenic.Component
  alias Scenic.Graph
  alias Scenic.Components
  alias Scenic.Primitives

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
    styles = opts[:styles]

    theme = styles[:theme]
    idx = styles[:idx]

    r_conf = if rem(idx, 2) === 0, do: {:fill, 0.5}, else: {:center, -0.25}
    graph =
      Graph.build(theme: theme)
    #|> Primitives.rrect({44, 380, 3}, fill: :green)
      |> Component.Rotary.add_to_graph(r_conf, id: {id, :pan}, translate: {22, 20})
      |> Primitives.rrect({15, 300, 3}, fill: :white, stroke: {2, :light_gray},
        translate: {3, 50})
      |> Components.slider({{0, 1023}, 738},
        id: {id, :fader},
        rotate: -1.57,
        translate: {27, 350},
        theme: theme
      )
      |> Components.checkbox({"", false},
        id: {id, :mute},
        translate: {4, 370},
        theme: :danger
      )
      |> Components.checkbox({"", false},
        id: {id, :solo},
        translate: {29, 370},
        theme: :success
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

  #def filter_event({:value_changed, widget, value}, orig_scene, state) do
  #  #Logger.debug fn ->
  #  #  "MixChannel filtering: #{inspect {widget, value}} from #{inspect orig_scene}"
  #  #end

  #  send_event({state.id, {:value_changed, widget, value}})
  #  {:stop, state}
  #end

  def filter_event(e, _orig_scene, state), do: {:continue, e, state}
end
