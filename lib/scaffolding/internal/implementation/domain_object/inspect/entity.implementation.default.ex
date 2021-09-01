defmodule Noizu.AdvancedScaffolding.Internal.Inspect.Entity.Implementation.Default do
  @moduledoc """
  Default Implementation.
  """


  def __strip_inspect__(_m, entity, opts) do
    field_types = entity.__struct__.__noizu_info__(:field_types)
    Enum.map(
      Map.from_struct(entity),
      fn ({field, value}) ->
        cond do
          value == :"*RESTRICTED*" -> {field, value}
          entity.__struct__.__noizu_info__(:field_attributes)[field][:inspect][:ignore] -> nil
          type = field_types[field] -> type.handler.__strip_inspect__(field, value, opts)
          entity.__struct__.__noizu_info__(:field_attributes)[field][:inspect][:ref] -> {field, Noizu.ERP.ref(value)}
          entity.__struct__.__noizu_info__(:field_attributes)[field][:inspect][:sref] -> {field, Noizu.ERP.sref(value)}
          :else -> {field, value}
        end
      end
    )
    |> Enum.filter(&(&1))
    |> Map.new()
  end


end
