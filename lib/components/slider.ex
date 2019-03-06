defmodule HelloScenic.Component.Slider do
  @moduledoc """
  Add a slider to a graph

  ## Data

  `{ extents, initial_value}`

  * `extents` gives the range of values. It can take several forms...
    * `{min, max}` If `min` and `max` are integers, then the slider value will
    be an integer.
    * `{min, max}` If `min` and `max` are floats, then the slider value will be
    an float.
    * `[a, b, c]` A list of terms. The value will be one of the terms
  * `initial_value` Sets the initial value (and position) of the slider. It
  must make sense with the extents you passed in.

  ## Messages

  When the state of the slider changes, it sends an event message to the host
  scene in the form of:

  `{:value_changed, id, value}`

  ### Options

  Sliders honor the following list of options.

  ## Styles

  Sliders honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ## Theme

  Sliders work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:border` - the color of the slider line
  * `:thumb` - the color of slider thumb

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#slider/3)

  ## Examples

  The following example creates a numeric slider and positions it on the screen.

      graph
      |> slider({{0,100}, 0}, id: :num_slider, translate: {20,20})

  The following example creates a list slider and positions it on the screen.

      graph
      |> slider({[
          :white,
          :cornflower_blue,
          :green,
          :chartreuse
        ], :cornflower_blue}, id: :slider_id, translate: {20,20})
  """

  use Scenic.Component, has_children: false

  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives, only: [{:rect, 3}, {:line, 3}, {:rrect, 3}, {:update_opts, 2}]

  # import IEx

  @height 18
  @mid_height trunc(@height / 2)
  @radius 5
  @btn_size 16
  @line_width 4

  @default_width 300

  # ============================================================================
  # setup

  # --------------------------------------------------------
  @doc false
  def info(data) do
    """
    #{IO.ANSI.red()}Slider data must be: {extents, initial_value}
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    The initial_value must make sense with the extents

    Examples:
    {{0,100}, 0}
    {{0.0, 1.57}, 0.3}
    {[:red, :green, :blue, :orange], :green}

    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @doc false
  def verify({ext, initial} = data) do
    verify_initial(ext, initial)
    |> case do
      true -> {:ok, data}
      _ -> :invalid_data
    end
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  defp verify_initial({min, max}, init)
       when is_integer(min) and is_integer(max) and is_integer(init) and init >= min and
              init <= max,
       do: true

  defp verify_initial({min, max}, init)
       when is_float(min) and is_float(max) and is_number(init) and init >= min and init <= max,
       do: true

  defp verify_initial(list_ext, init) when is_list(list_ext), do: Enum.member?(list_ext, init)
  defp verify_initial(_, _), do: false

  # --------------------------------------------------------
  @doc false
  def init({extents, value}, opts) do
    id = opts[:id]
    styles = opts[:styles]
    mode = styles[:mode]
    Logger.debug fn -> "init: #{inspect mode}" end

    # theme is passed in as an inherited style
    theme =
      (styles[:theme] || Theme.preset(:primary))
      |> Theme.normalize()

    # get button specific styles
    width = styles[:width] || @default_width

    graph =
      Graph.build()
      |> rect({width, @height}, fill: :clear, t: {0, -1})
      |> line({{0, @mid_height}, {width, @mid_height}}, stroke: {@line_width, theme.border})
      |> rrect({@btn_size, @btn_size, @radius}, fill: theme.thumb, id: :thumb, t: {0, 1})
      |> update_slider_position(value, extents, width)

    state = %{
      graph: graph,
      value: value,
      extents: extents,
      width: width,
      id: id,
      tracking: false,
      tracking_mode: mode,
      tracking_base: nil,
      tracking_value: nil
    }

    push_graph(graph)

    {:ok, state}
  end

  # ============================================================================

  # --------------------------------------------------------
  @doc false
  def handle_input({:cursor_button, {:left, :press, _, {x, _}}}, context, state) do
    state = start_tracking(state, x)
    state =
      case state.tracking_mode do
        :absolute -> update_slider(state, x)
        :relative -> state
      end

    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])
    Logger.debug fn -> "press: #{inspect [state.tracking_base, state.tracking_value]}" end

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_button, {:left, :release, _, _}}, context, state) do
    state = stop_tracking(state) #Map.put(state, :tracking, false)

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])
    Logger.debug fn -> "release: #{inspect [state.value, state.tracking_value]}" end

    # %{state | graph: graph}}
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_pos, {x, _}}, _context, %{tracking: true} = state) do
    state = update_slider(state, x)
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  # ============================================================================
  # internal utilities

  defp start_tracking(state, x) do
    case state.tracking_mode do
      :absolute -> %{state | tracking: true}
      :relative -> %{state |
          tracking: true,
          tracking_base: x,
          tracking_value: state.value
      }
    end
  end

  defp stop_tracking(state) do
    case state.tracking_mode do
      :absolute -> %{state | tracking: false}
      :relative -> %{state |
          tracking: false,
          value: state.tracking_value
      }
    end
  end

  defp update_slider(
         %{
           graph: graph,
           value: old_value,
           extents: extents,
           width: width,
           id: id,
           tracking: true,
           tracking_mode: :absolute
         } = state,
         x
       ) do
    x = trim_position(x, width)
    new_value = calc_value_by_percent(extents, x / width)

    graph =
      graph
      |> update_slider_position(new_value, extents, width)
      |> push_graph()

    if new_value != old_value, do: send_event({:value_changed, id, new_value})

    %{state | graph: graph, value: new_value}
  end

  defp update_slider(
         %{
           graph: graph,
           value: old_value,
           extents: extents,
           width: width,
           id: id,
           tracking: true,
           tracking_mode: :relative,
           tracking_base: tracking_base
         } = state,
         x
       ) do
    old_x = calc_slider_position(width, extents, old_value)
    delta = x - tracking_base
    x = old_x + delta
    x = trim_position(x, width)
    new_value = calc_value_by_percent(extents, (x + @btn_size) / width)

    # update the slider position and push the graph
    graph =
      graph
      |> update_slider_position(new_value, extents, width)
      |> push_graph()

    if new_value != state.tracking_value do
      send_event({:value_changed, id, new_value})
    end

    %{state |
      graph: graph,
      tracking_value: new_value
    }
  end

  # --------------------------------------------------------
  defp update_slider_position(graph, new_value, extents, width) do
    # calculate the slider position
    new_x = calc_slider_position(width, extents, new_value)

    # apply the x position
    Graph.modify(graph, :thumb, fn p ->
      update_opts(p, translate: {new_x, 0})
    end)
  end

  # --------------------------------------------------------
  defp trim_position(x, width) do
    cond do
      x < 0 -> 0
      x > width -> width
      true -> x
    end
  end

  # --------------------------------------------------------
  # calculate the position if the extents are numeric
  defp calc_slider_position(width, extents, value)

  defp calc_slider_position(width, {min, max}, value) when value < min do
    calc_slider_position(width, {min, max}, min)
  end

  defp calc_slider_position(width, {min, max}, value) when value > max do
    calc_slider_position(width, {min, max}, max)
  end

  defp calc_slider_position(width, {min, max}, value) do
    width = width - @btn_size
    percent = (value - min) / (max - min)
    trunc(width * percent)
  end

  # --------------------------------------------------------
  # calculate the position if the extents is a list of arbitrary values
  defp calc_slider_position(width, extents, value)

  defp calc_slider_position(width, ext, value) when is_list(ext) do
    max_index = Enum.count(ext) - 1

    index =
      case Enum.find_index(ext, fn v -> v == value end) do
        nil -> raise "Slider value not in extents list"
        index -> index
      end

    # calc position of slider
    width = width - @btn_size
    percent = index / max_index
    round(width * percent)
  end

  # --------------------------------------------------------
  defp calc_value_by_percent({min, max}, percent) when is_integer(min) and is_integer(max) do
    round((max - min) * percent) + min
  end

  defp calc_value_by_percent({min, max}, percent) when is_float(min) and is_float(max) do
    (max - min) * percent + min
  end

  defp calc_value_by_percent(extents, percent) when is_list(extents) do
    max_index = Enum.count(extents) - 1
    index = round(max_index * percent)
    Enum.at(extents, index)
  end
end
