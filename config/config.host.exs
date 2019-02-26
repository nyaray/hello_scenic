use Mix.Config

config :hello_scenic, :viewport, %{
  name: :main_viewport,
  default_scene: {HelloScenic.Scene.Mixer, nil},
  #default_scene: {HelloScenic.Scene.Crosshair, nil},
  #default_scene: {HelloScenic.Scene.SysInfo, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :hello_scenic"]
    }
  ]
}
