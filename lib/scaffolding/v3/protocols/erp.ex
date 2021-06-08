#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------



defimpl Noizu.ERP, for: Any do
  def id(_), do: nil
  def ref(_), do: nil
  def sref(_), do: nil
  def record(entity, options \\ nil)
  def record(_entity, _options), do: nil
  def record!(entity, options \\ nil)
  def record!(_entity, _options), do: nil
  def entity(entity, options \\ nil)
  def entity(_entity, _options), do: nil
  def entity!(entity, options \\ nil)
  def entity!(_entity, _options), do: nil
end # end defimpl EntityReferenceProtocol, for: Map


defimpl Noizu.ERP, for: Map do
  def id(_), do: nil
  def ref(_), do: nil
  def sref(_), do: nil
  def record(entity, options \\ nil)
  def record(_entity, _options), do: nil
  def record!(entity, options \\ nil)
  def record!(_entity, _options), do: nil
  def entity(entity, options \\ nil)
  def entity(_entity, _options), do: nil
  def entity!(entity, options \\ nil)
  def entity!(_entity, _options), do: nil
end # end defimpl EntityReferenceProtocol, for: Map
