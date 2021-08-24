#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Mixfile do
  use Mix.Project

  def project do
    [
      app: :noizu_advanced_scaffolding,
      version: "1.0.0",
      elixir: "~> 1.10",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env),

      name: "Noizu.AdvancedScaffolding",
      description: "Noizu.AdvancedScaffolding",
      package: package(),
      docs: docs(),
      xref: [exclude: [Phoenix.HTML, UUID, XmlBuilder, HtmlSanitizeEx, Ecto.CastError, Redix, Ecto.Type, Plug.Conn, Poison, Poison.Encoder, Noizu.FastGlobal.Cluster, Giza.SphinxQL]]
    ]
  end # end project

  # Specifies which paths to compile per environment.
  def elixirc_paths(:test), do: ["lib", "test/fixtures"]
  def elixirc_paths(_),     do: ["lib"]

  def package do
    [
      maintainers: ["noizu"],
      copyright: ["Noizu Labs, Inc. 2021"],
      license: ["GPL"],
      links: %{"GitHub" => "https://github.com/noizu-labs/advanced_elixir_scaffolding"}
    ]
  end # end package

  def application do
    [
      applications: [:logger],
      extra_applications: [:fastglobal, :noizu_core, :poison, :amnesia, :noizu_mnesia_versioning, :decimal]
    ]
  end # end application

  def deps do
    [
      {:ecto_sql, "~> 3.4"},
      {:amnesia, git: "https://github.com/noizu/amnesia.git", ref: "9266002", optional: true}, # Mnesia Wrapper
      {:uuid, "~> 1.1" },
      {:ex_doc, "~> 0.24", only: [:test, :dev], optional: true}, # Documentation Provider
      {:markdown, github: "devinus/markdown", optional: true}, # Markdown processor for ex_doc
      {:noizu_core, github: "noizu/ElixirCore", tag: "1.0.10"},
      {:noizu_mnesia_versioning, github: "noizu/MnesiaVersioning", tag: "0.1.9", override: true},
      {:redix, github: "whatyouhide/redix", tag: "v0.7.0", optional: true},
      {:poison, "~> 3.1.0", optional: true},
      {:plug, "~> 1.0", optional: true},
      {:fastglobal, "~> 1.0"},
      {:decimal, "~> 2.0.0"},
    ]
  end # end deps

  def docs do
    [
      source_url_pattern: "https://github.com/noizu-lab/advanced_elixir_scaffolding/blob/master/%{path}#L%{line}",
      extras: ["README.md", "markdown/sample_conventions_doc.md"]
    ]
  end # end docs

end # end defmodule
