#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Mixfile do
  use Mix.Project

  @version "1.0.7"
  @source_url "https://github.com/noizu-labs/advanced_elixir_scaffolding"

  def project do
    [
      app: :noizu_advanced_scaffolding,
      version: @version,
      elixir: "~> 1.10",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env),
      source_url: @source_url,
      name: "Noizu.AdvancedScaffolding",
      description: "Version 3 of our Elixir Scaffolding framework",
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
      links: %{"GitHub" => @source_url}
    ]
  end # end package

  def application do
    [
      applications: [:logger],
      extra_applications: [:fastglobal, :noizu_core, :poison, :amnesia, :noizu_mnesia_versioning, :decimal, :timex]
    ]
  end # end application

  def deps do
    [
      {:ecto_sql, "~> 3.4"},
      {:amnesia, git: "https://github.com/noizu/amnesia.git", ref: "9266002", optional: true}, # Mnesia Wrapper
      {:elixir_uuid, "~> 1.2" },
      {:ex_doc, "~> 0.25.1", only: [:test, :dev], optional: true}, # Documentation Provider
      {:markdown, github: "devinus/markdown", optional: true}, # Markdown processor for ex_doc
      {:noizu_core, github: "noizu/ElixirCore", tag: "1.0.13"},
      {:noizu_mnesia_versioning, github: "noizu/MnesiaVersioning", tag: "0.1.9", override: true},
      {:redix, github: "whatyouhide/redix", tag: "v0.7.0", optional: true},
      {:poison, "~> 3.1.0", optional: true},
      {:plug, "~> 1.0", optional: true},
      {:fastglobal, "~> 1.0"},
      {:timex, "~> 3.7"},
      {:decimal, "~> 2.0.0"},
    ]
  end # end deps

  defp docs do
    [
      source_url_pattern: "https://github.com/noizu-lab/advanced_elixir_scaffolding/blob/master/%{path}#L%{line}",
      main: "readme",
      extras: ["README.md", "TODO.md", "COPYRIGHT", "markdown/sample_conventions_doc.md"],
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_modules: [
        "Behaviours": [
          Noizu.DomainObject,
          Noizu.SimpleObject,
        ],
        "Internals": [
          Noizu.AdvancedScaffolding.Internal
        ],
        "Type Handlers": [
          Noizu.DomainObject.DateTime,
          Noizu.DomainObject.TimeStamp.Millisecond,
          Noizu.DomainObject.TimeStamp.Second,
          Noizu.DomainObject.UniversalLink,
        ],
        "Protocols": [
          Noizu.EctoEntity.Protocol,
          Noizu.Entity.Protocol,
          Noizu.ERP,
          Noizu.Permission.Protocol,
          Noizu.RestrictedAccess.Protocol,
        ],
        "Schema": [
          Noizu.AdvancedScaffolding.Database,
          Noizu.AdvancedScaffolding.Support.TopologyProvider,
          Noizu.AdvancedScaffolding.Support.SchemaProvider,
          Noizu.AdvancedScaffolding.Support.Schema
        ],
      "Tasks": [
          Mix.Tasks.Scaffolding
        ]
      ],
      nest_modules_by_prefix: [
        Mix.Tasks.Scaffolding,
        Noizu,
        Noizu.DomainObject,
        Noizu.SimpleObject,
        Noizu.AdvancedScaffolding,
        Noizu.AdvancedScaffolding.Database,
        Noizu.AdvancedScaffolding.Sphinx,
        Noizu.AdvancedScaffolding.Schema,
        Noizu.AdvancedScaffolding.Internal,
        Noizu.AdvancedScaffolding.Internal.Core,
        Noizu.AdvancedScaffolding.Internal.EntityIndex,
        Noizu.AdvancedScaffolding.Internal.Index,
        Noizu.AdvancedScaffolding.Internal.Inspect,
        Noizu.AdvancedScaffolding.Internal.Json,
        Noizu.AdvancedScaffolding.Internal.Persistence,
        Noizu.AdvancedScaffolding.Internal.SimpleObject,
        Noizu.AdvancedScaffolding.Support,
      ]
    ]
  end # end docs

end # end defmodule
