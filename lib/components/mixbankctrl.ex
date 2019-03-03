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
      |> Primitives.group(&(init_bankctrl(&1, "SHIFT", :bank_shift_left, :bank_shift_right)))
      |> Primitives.group(&(init_bankctrl(&1, "BANK", :bank_left, :bank_right)),
        translate: {0, 50})
      |> Components.button("MUTE off", id: :mutes_off, fill: :black, translate: {0, 100}, theme: :secondary)
      |> Components.button("SOLO off", id: :solos_off, fill: :black, translate: {0, 135}, theme: :secondary)
      |> Components.button("Dim -20dB", id: :dim_mix, fill: :black, translate: {0, 180}, theme: :secondary)

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
      translate: {0, 5}, theme: :secondary)
    |> Components.button(">", id: id2, width: @b_w, height: @b_h,
      translate: {@b_w + 3, 5}, theme: :secondary)
  end

end

