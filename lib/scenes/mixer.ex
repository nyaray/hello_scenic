defmodule HelloScenic.Scene.Mixer do
  use Scenic.Scene

  require Logger

  alias HelloScenic.Component
  alias Scenic.Graph
  alias Scenic.Primitives

  def init(_, opts) do
    Logger.debug fn -> "initialising mixer: #{inspect opts}" end

    graph =
      Graph.build(font: :roboto, font_size: 20, theme: :light)
      |> Primitives.group(&init_strips/1, translate: {70, 0})
      |> Primitives.group(&init_selectors/1, translate: {10, 0})

    push_graph(graph)
    {:ok, graph}
  end

  def handle_input(_msg, _ctx, graph) do
    {:noreply, graph}
  end

  def init_strips(graph) do
    {graph, _} =
      Enum.reduce(1..8, {graph, 1}, fn _i, {g, idx} ->
        label = "chan#{idx}"
        id = String.to_atom(label)
        pos = {60*(idx-1), 0}
        g = Component.MixChannel.add_to_graph(g, label, id: id, idx: idx, translate: pos)
        {g, idx+1}
      end)
    graph
  end

  def init_selectors(graph) do
    graph
    |> Component.MixBankPicker.add_to_graph(1, id: :bankpicker, translate: {0, 25})
    |> Component.MixBankCtrl.add_to_graph(nil, id: :basepicker, translate: {0, 160})
  end
end

