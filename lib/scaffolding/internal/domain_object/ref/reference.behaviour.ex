defmodule Noizu.AdvancedScaffolding.Internal.Ecto.Reference.Behaviour do
  @moduledoc """
  Behavior definition for Ecto Type handlers that support switching between a domain object entity ref/atom and their relation database's equivalent.
  """


  @callback type() :: any
  @callback __entity__() :: any
  @callback cast(any) :: any
  @callback cast!(any) :: any
  @callback dump(any) :: any
  @callback load(any) :: any
end
