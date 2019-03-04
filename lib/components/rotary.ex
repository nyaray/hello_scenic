defmodule HelloScenic.Component.Rotary do
  use Scenic.Component

  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Primitives

  @pi :math.pi()

  @bbox_w 36
  @bbox_h @bbox_w + 14

  @outline_s 2
  @outline_r @bbox_w/2 - @outline_s/2

  @indicator_s 10
  @indicator_r @indicator_s - 0.5
  @indicator_opts [id: :indicator, stroke: {@indicator_s, :cornflower_blue}]
  @indicator_resolution_ppv 128

  @label_opts [id: :label, fill: :white, font_size: 16, translate: {-14, 24}]

  defmodule State do
    defstruct graph: nil,
              id: nil,
              mode: :fill,
              value: 0,
              tracking: false,
              tracking_value: nil,
              tracking_base: 0,
              tracking_delta: 0
  end

  def verify(d={:fill, val}) when 0 <= val and val <= 1, do: {:ok, d}
  def verify(d={:center, val}) when -0.5 <= val and val <= 0.5, do: {:ok, d}
  def verify(_), do: :invalid_data

  def info({:fill, val}), do: """
    #{IO.ANSI.red()}#{__MODULE__} fill data must be a float in [0,1]
    #{IO.ANSI.yellow()}Received: #{inspect(val)}
    #{IO.ANSI.default_color()}
  """

  def info({:center, val}), do: """
    #{IO.ANSI.red()}#{__MODULE__} center data must be an float in [0,1]
    #{IO.ANSI.yellow()}Received: #{inspect(val)}
    #{IO.ANSI.default_color()}
  """

  def info(data), do: """
    #{IO.ANSI.red()}#{__MODULE__} data must be {:center, [-0.5,0.5]} or {:fill, [0,1]}
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
  """

  def init({mode, value}, opts) do
    id = opts[:id]
    theme = opts[:styles][:theme]

    {start, stop} = compute_fill(value, mode)

    graph =
      Graph.build(theme: theme)
      # bounding box
      |> Primitives.rect({@bbox_w, @bbox_h}, #fill: :red,#{0x33, 0x33, 0x33},
        translate: {-@bbox_w/2, -@bbox_h/2})
      # label
      |> Primitives.text(:erlang.float_to_binary(value, decimals: 2),
        @label_opts)
      # outline
      |> Primitives.arc({@outline_r, (3/4)*@pi, (3/2 + 3/4)*@pi},
        stroke: {@outline_s, :light_gray})
      # background fill
      |> Primitives.arc({@indicator_r, (3/4)*@pi, (9/4)*@pi},
        stroke: {@indicator_s, :white})
      # filler
      |> Primitives.arc({@indicator_r, start, stop},
        @indicator_opts)

    state = %State{
      graph: graph,
      id: id,
      mode: mode,
      value: value
    }

    push_graph(graph)

    {:ok, state}
  end

  #
  # input capturing/releasing on cursor press/release
  #

  def handle_input({:cursor_button, {:left, :press, _,  {x, _y}}}, ctx, state) do
    ViewPort.capture_input(ctx, [:cursor_button, :cursor_pos])

    state = %State{state |
      :tracking => true,
      :tracking_base => x,
      :tracking_value => state.value
    }

    # TODO: send a z-touch event
    {:noreply, state}
  end

  def handle_input({:cursor_button, {:left, :release, _, {_x, _y}}}, ctx, state) do
    ViewPort.release_input(ctx, [:cursor_button, :cursor_pos])

    state = %State{state |
      :tracking => false,
      :value => state.tracking_value
    }

    # TODO: send a z-release event
    {:noreply, state}
  end

  def handle_input({:cursor_pos, {x, _y}}, _ctx, state=%State{:tracking => true}) do
    tracking_value =
      x
      |> compute_value(state)
      |> gate_value(state.mode)

    graph =
      tracking_value
      |> compute_fill(state.mode)
      |> update_graph(tracking_value, state.graph)

    push_graph(graph)

    state = %State{state |
      :graph => graph,
      :tracking_value => tracking_value
    }

    # TODO send a change event
    {:noreply, state}
  end

  def handle_input(_msg, _ctx, state) do
    #Logger.debug fn -> "Rotary ignoring: #{inspect msg}" end
    {:noreply, state}
  end

  defp compute_value(x, state) do
    delta = x - state.tracking_base
    normalised_delta = delta / @indicator_resolution_ppv
    state.value + normalised_delta
  end

  defp gate_value(tracking_value, :fill) do
    case tracking_value do
      v when v < 0.0 -> 0.0
      v when v > 1.0 -> 1.0
      v -> v
    end
  end

  defp gate_value(tracking_value, :center) do
    case tracking_value do
      v when v < -0.5 -> -0.5
      v when v > 0.5 -> 0.5
      v -> v
    end
  end

  defp compute_fill(val, :fill),   do: {(3/4)*@pi, (3/4)*@pi + val*(6/4)*@pi}
  defp compute_fill(val, :center), do: {(6/4)*@pi, (6/4)*@pi + val*(6/4)*@pi}

  def update_graph({start, stop}, value, graph) do
    graph
    |> Graph.modify(:indicator, fn p ->
      Primitives.arc(p, {@indicator_r, start, stop}, @indicator_opts)
    end)
    |> Graph.modify(:label, fn p ->
      Primitives.text(p, :erlang.float_to_binary(value, decimals: 2), @label_opts)
    end)
  end

end

