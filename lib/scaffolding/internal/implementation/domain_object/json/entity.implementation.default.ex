defmodule Noizu.AdvancedScaffolding.Internal.Json.Entity.Implementation.Default do
  @moduledoc """
  Default Implementation.
  """

  @pii_levels %{
    level_0: 0,
    level_1: 1,
    level_2: 2,
    level_3: 3,
    level_4: 4,
    level_5: 5,
    level_6: 6,
  }

  def __strip_pii__(_m, entity, max_level) do
    max_level = @pii_levels[max_level] || @pii_levels[:level_3]
    v = Enum.map(
      Map.from_struct(entity),
      fn ({field, value}) ->
        cond do
          (@pii_levels[entity.__struct__.__noizu_info__(:field_attributes)[field][:pii]] || @pii_levels[:level_6]) >= max_level -> {field, value}
          :else -> {field, :"*RESTRICTED*"}
        end
      end
    )
    struct(entity.__struct__, v)
  end


end
