defmodule HelloScenic.Scene.Mixer do
  use Scenic.Scene

  require Logger

  alias HelloScenic.Component
  alias Scenic.Graph
  alias Scenic.Primitives

  @pi :math.pi()

  def init(_, opts) do
    Logger.debug fn -> "initialising mixer: #{inspect opts}" end

    graph =
      Graph.build(font: :roboto, font_size: 20, theme: :dark)
      |> Primitives.group(&init_selectors/1, translate: {10, 0})
      |> Primitives.group(&init_strips/1, translate: {105, 0})
      |> Primitives.group(&init_transport/1, translate: {10, 390})
      |> Primitives.group(&init_mainmix/1, translate: {650, 20})

    push_graph(graph)
    {:ok, graph}
  end

  #def handle_input(msg, _ctx, graph) do
  #  Logger.debug fn -> "Mixer ignoring #{inspect msg}" end
  #  {:noreply, graph}
  #end

  def filter_event(e, orig_scene, state) do
    Logger.debug fn -> "Mixer filtering: #{inspect e} from #{inspect orig_scene}" end
    {:continue, e, state}
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

  def init_transport(graph) do
    graph
    |> Component.Transport.add_to_graph(nil, id: :transport)
  end

  def init_mainmix(graph) do
    graph
    |> Primitives.rect({80, 400}, fill: {0x44, 0x11, 0x11})
    |> Component.Slider.add_to_graph({{0, 256}, 128}, id: :control_room,
      width: 50, translate: {15, 0}, mode: :absolute)
    |> Component.Slider.add_to_graph({{0, 1400}, 738}, id: :mainmix, mode: :relative,
      rotate: -@pi/2, translate: {22, 330})
    |> Component.Slider.add_to_graph({[:apple, :banana, :cherrie, :date], :banana}, id: :altmix, mode: :relative,
      rotate: -@pi/2, translate: {50, 330})
  end
end

