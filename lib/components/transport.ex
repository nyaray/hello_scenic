defmodule HelloScenic.Component.Transport do
  use Scenic.Component

  require Logger

  alias Scenic.Graph
  alias Scenic.Components

  @b_thin_w 45
  @b_wide_w 70
  @b_h 65
  @b_margin 3

  @buttons [
    %{id: :rewind, label: "<<", width: @b_thin_w},
    %{id: :fast_forward, label: ">>", width: @b_thin_w},
    %{id: :stop, label: "[   ]", width: @b_wide_w},
    %{id: :play, label: "|>", width: @b_wide_w, theme: :success},
    %{id: :record, label: "(   )", width: @b_thin_w, theme: :danger},
    %{id: :loop, label: "Loop", width: @b_thin_w, theme: :warning}
  ]

  defmodule State do
    defstruct graph: nil,
              id: nil
  end

  def verify(data), do: {:ok, data}

  def init(_, opts) do
    id = opts[:id]
    theme = opts[:styles][:theme]

    graph = init_buttons(Graph.build(theme: theme))
    state = %State{
      id: id,
      graph: graph
    }
    push_graph(graph)

    {:ok, state}
  end

  defp init_buttons(graph) do
    {graph, _} =
      Enum.reduce(@buttons, {graph, 0}, fn spec, {g, l_margin} ->
        width = spec.width
        b_opts = [id: spec.id, width: width, height: @b_h, translate: {l_margin, 0}, theme: spec[:theme] || :secondary ]
        {Components.button(g, spec.label, b_opts), l_margin + width + @b_margin}
      end)

    graph
  end
end
