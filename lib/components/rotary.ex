defmodule HelloScenic.Component.Rotary do
  use Scenic.Component

  require Logger

  alias Scenic.Graph
  #alias Scenic.Components
  alias Scenic.Primitives

  @pi :math.pi()

  defmodule State do
    defstruct graph: nil,
              id: nil
  end

  def verify(d={:fill, val}) when 0 <= val and val <= 1, do: {:ok, d}
  def verify(d={:center, val}) when -0.5 <= val and val <= 0.5, do: {:ok, d}
  def verify(_), do: :invalid_data
  #def verify({:fill, val}), do: {:error, {:not_in_range, val, {0, 1}}}
  #def verify({:center, val}), do: {:error, {:not_in_range, val, {-0.5, 0.5}}}

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

  def init(data, opts) do
    id = opts[:id]
    theme = opts[:styles][:theme]
    #Logger.debug fn -> "Rotary got #{inspect data}" end

    {start, stop} = compute_fill(data)

    graph =
      Graph.build(theme: theme)
      # guide
      |> Primitives.arc({18, (3/4)*@pi, (3/2 + 3/4)*@pi}, stroke: {2, :black})
      # indicator
      |> Primitives.arc({12, start, stop}, stroke: {6, :black})

    state = %State{
      id: id,
      graph: graph
    }

    push_graph(graph)

    {:ok, state}
  end

  def handle_input(msg, _ctx, state) do
    Logger.debug fn -> "Rotary ignoring: #{inspect msg}" end
    {:noreply, state}
  end

  defp compute_fill({:fill, val}) do
    base = (3/4)*@pi
    {base, base + val*(3/4)*@pi}
  end

  defp compute_fill({:center, val}) do
    base = (6/4)*@pi
    {base, base + val*2*(6/4)*@pi}
  end
end
