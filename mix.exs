defmodule FlowMonitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :flow_monitor,
      version: "0.1.2",
      elixir: ">= 1.6.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      name: "Flow Monitor",
      source_url: "https://github.com/mpraski/flow-monitor"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FlowMonitor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:flow, "~> 0.14.2"},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Measure progress of each step in a Flow pipeline."
  end

  defp docs do
    [
      main: "FlowMonitor",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      files: ~w(lib config .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mpraski/flow-monitor"}
    ]
  end
end
