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


  #-----------------------------------
  #
  #-----------------------------------
  def __unroll_field_types__(layer, field_type_map) do
    Enum.map(
      field_type_map || [],
      fn({field, type} = entry) ->
        cond do
          function_exported?(type.handler, :__unroll__, 2) -> type.__unroll__(entry, layer)
          :else -> {field, [source: field]}
        end
      end)
    |> Enum.filter(&(&1))
    |> List.flatten()
    |> Map.new()
  end

  def update_schema_fields(%__MODULE__{} = this, field_type_map) do
    layers = Enum.map(this.layers, fn(layer) ->
      put_in(layer, [Access.key(:schema_fields)], __unroll_field_types__(layer, field_type_map))
    end)
    %__MODULE__{this|
      layers: layers,
      schemas: Enum.map(layers || [], &({&1.schema, &1})) |> Map.new(),
      tables: Enum.map(layers || [], &({&1.table, &1})) |> Map.new()
    }
  end
end
