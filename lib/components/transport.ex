defmodule HelloScenic.Component.Transport do
  use Scenic.Component

  require Logger

  alias Scenic.Graph
  alias Scenic.Components

  @b_thin_w 45
  @b_wide_w 70
  @b_h 65
  @b_margin 3

  defmodule State do
    defstruct graph: nil,
              id: nil
  end

  def verify(data), do: {:ok, data}

  def init(_, opts) do
    id = opts[:id]
    theme = opts[:styles][:theme]

    graph =
      Graph.build(theme: theme)
      |> Components.button("<<", fill: :black, width: @b_thin_w, height: @b_h)
      |> Components.button(">>", fill: :black, width: @b_thin_w, height: @b_h,
        translate: {@b_thin_w + @b_margin, 0})
      |> Components.button("[   ]", fill: :black, width: @b_wide_w, height: @b_h,
        translate: {@b_thin_w*2 + @b_margin*2, 0})
      |> Components.button("|>", fill: :black, width: @b_wide_w, height: @b_h,
        translate: {@b_thin_w*2 + @b_wide_w + @b_margin*3, 0})
      |> Components.button("Rec", fill: :black, width: @b_thin_w, height: @b_h,
        translate: {@b_thin_w*2 + @b_wide_w*2 + @b_margin*4, 0})
      |> Components.button("Loop", fill: :black, width: @b_thin_w, height: @b_h,
        translate: {@b_thin_w*3 + @b_wide_w*2 + @b_margin*5, 0})

    state = %State{
      id: id,
      graph: graph
    }

    push_graph(graph)

    {:ok, state}
  end

end
