#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.UnsupportedModule do
  @type t :: %__MODULE__{
               reference: any,
             }

  defstruct [
    reference: nil,
  ]

  def id(item), do: throw "UnsupportedModule #{inspect item}"
  def ref(item), do: throw "UnsupportedModule #{inspect item}"
  def sref(item), do: throw "UnsupportedModule #{inspect item}"
  def entity(item, _options), do: throw "UnsupportedModule #{inspect item}"
  def entity!(item, _options), do: throw "UnsupportedModule #{inspect item}"
  def record(item, _options), do: throw "UnsupportedModule #{inspect item}"
  def record!(item, _options), do: throw "UnsupportedModule #{inspect item}"
  def as_record(item, _options), do: throw "UnsupportedModule #{inspect item}"
  def sref_module(), do: "unsupported-module"
  def has_permission(_, _, _, _), do: false
  def has_permission!(_, _, _, _), do: false
  def compress(entity), do: entity
  def compress(entity, _options), do: entity
  def expand(entity), do: entity
  def expand(entity, _options), do: entity
  def from_json(json, _options), do: throw "UnsupportedModule #{inspect json}"
  def repo(), do: __MODULE__
end

defimpl Noizu.ERP, for: Noizu.DomainObject.UnsupportedModule do
  def id(_item), do: throw "UnsupportedModule"
  def ref(_item), do: throw "UnsupportedModule"
  def sref(_item), do: throw "UnsupportedModule"
  def entity(_item, _options \\ nil), do: throw "UnsupportedModule"
  def entity!(_item, _options \\ nil), do: throw "UnsupportedModule"
  def record(_item, _options \\ nil), do: throw "UnsupportedModule"
  def record!(_item, _options \\ nil), do: throw "UnsupportedModule"
end
