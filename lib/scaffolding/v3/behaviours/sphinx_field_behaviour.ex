defmodule Noizu.Scaffolding.V3.SphinxFieldBehaviour do
  @callback __sphinx_field__() :: true
  @callback __sphinx_expand_field__(field :: atom, indexing :: Map.t, settings :: Map.t) :: any
  @callback __sphinx_has_default__(field :: atom, indexing :: Map.t, settings :: Map.t) :: boolean
  @callback __sphinx_default__(field :: atom, indexing :: Map.t, settings :: Map.t) :: any
  @callback __sphinx_bits__(field :: atom, indexing :: Map.t, settings :: Map.t) :: nil | integer
  @callback __sphinx_encoding__(field :: atom, indexing :: Map.t, settings :: Map.t) :: atom
  @callback __sphinx_encoded__(field :: atom, entity :: any, indexing :: Map.t, settings :: Map.t) :: any
end
