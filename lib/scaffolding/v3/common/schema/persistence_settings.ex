defmodule Noizu.Scaffolding.V3.Schema.PersistenceSettings do
  @vsn 1.0
  @type t :: %__MODULE__{
               layers: [Noizu.Scaffolding.V3.Schema.PersistenceLayer.t],
               schemas: Map.t,
               tables: Map.t,
               ecto_entity: true | nil,
               mnesia_backend: nil | Map.t,
               options: nil | Map.t | Keyword.t,
               vsn: float
             }

  defstruct [
    layers: [],
    schemas: %{},
    tables: %{},
    ecto_entity: nil,
    mnesia_backend: nil,
    options: nil,
    vsn: @vsn
  ]
end
