defmodule ExLink.MixProject do
  use Mix.Project

  @vsn "0.1.0"
  @name :ex_link

  def project() do
    [
      app: @name,
      version: @vsn,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      name: "ExLink",
      homepage_url: "https://github.com/SpaceEEC/#{@name}/",
      source_url: "https://github.com/SpaceEEC/#{@name}/"
    ]
  end

  def application() do
    [extra_applications: [:logger]]
  end

  def package() do
    [
      name: @name,
      license: ["MIT"],
      maintainers: ["SpaceEEC"],
      links: %{
        "GitHub" => "https://github.com/SpaceEEC/#{@name}/",
        "Changelog" => "https://github.com/SpaceEEC/#{@name}/releases/tag/#{@vsn}",
        "Documentation" => "https://hexdocs.pm/#{@name}/#{@vsn}",
        "Development Documentation" => "https://#{@name}.randomly.space/"
      }
    ]
  end

  defp deps() do
    [
      {:websockex, "~> 0.4.2"},
      {:poison, ">= 0.0.0"},
      {:ex_doc, "~> 0.21.1", only: :dev, runtime: false}
    ]
  end
end
