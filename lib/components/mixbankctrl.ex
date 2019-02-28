defmodule HelloScenic.Component.MixBankCtrl do
  use Scenic.Component

  require Logger

  alias Scenic.Components
  alias Scenic.Graph
  alias Scenic.Primitives

  @b_w 35
  @b_h 20

  defmodule State do
    defstruct id: nil,
              graph: nil
  end

  def verify(data), do: {:ok, data}

  def init(_data, opts) do
    id = opts[:id]

    graph =
      Graph.build()
      |> Primitives.group(&(init_bankctrl(&1, "SHIFT", :shiftleft, :shiftright)))
      |> Primitives.group(&(init_bankctrl(&1, "BANK", :bankleft, :bankright)),
        translate: {0, 50})
      |> Components.button("MUTES", fill: :black, translate: {0, 100})
      |> Components.button("SOLOS", fill: :black, translate: {0, 135})
      |> Components.button("DIM", fill: :black, translate: {0, 180})

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

  def init_bankctrl(graph, label, id1, id2) do
    graph
    |> Primitives.text(label, fill: :black)
    |> Components.button("<", id: id1, width: @b_w, height: @b_h,
      translate: {0, 5})
    |> Components.button(">", id: id2, width: @b_w, height: @b_h,
      translate: {@b_w + 3, 5})
  end

  #def init_bankshift(graph) do
  #  graph
  #  |> Primitives.text("SHIFT", fill: :black)
  #  |> Components.button("<", id: :shiftleft, width: @b_w, height: @b_h,
  #    translate: {0, 5})
  #  |> Components.button(">", id: :shiftright, width: @b_w, height: @b_h,
  #    translate: {28, 5})
  #end

  #def init_bankselect(graph) do
  #  graph
  #  |> Primitives.text("BANK", fill: :black)
  #  |> Components.button("<", id: :bankleft, width: @b_w, height: @b_h,
  #    translate: {0, 5})
  #  |> Components.button(">", id: :bankright, width: @b_w, height: @b_h,
  #    translate: {28, 5})
  #end
end

