defmodule Noizu.AdvancedScaffolding.SphinxFieldBehaviour do
  @callback __sphinx_field__() :: true
  @callback __sphinx_expand_field__(field :: atom, indexing :: map(), settings :: map()) :: any
  @callback __sphinx_has_default__(field :: atom, indexing :: map(), settings :: map()) :: boolean
  @callback __sphinx_default__(field :: atom, indexing :: map(), settings :: map()) :: any
  @callback __sphinx_bits__(field :: atom, indexing :: map(), settings :: map()) :: nil | integer
  @callback __sphinx_encoding__(field :: atom, indexing :: map(), settings :: map()) :: atom
  @callback __sphinx_encoded__(field :: atom, entity :: any, indexing :: map(), settings :: map()) :: any
end
