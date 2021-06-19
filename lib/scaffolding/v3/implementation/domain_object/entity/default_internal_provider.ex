defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider do

  defmodule Default do

    @pii_levels %{
      level_0: 0,
      level_1: 1,
      level_2: 2,
      level_3: 3,
      level_4: 4,
      level_5: 5,
      level_6: 6,
    }

    def strip_pii(entity, max_level) do
      max_level = @pii_levels[max_level] || @pii_levels[:level_3]
      v = Enum.map(Map.from_struct(entity), fn({field, value}) ->
        cond do
          (@pii_levels[entity.__struct__.__noizu_info__(:field_attributes)[field][:pii]] || @pii_levels[:level_6]) >= max_level -> {field, value}
          :else -> {field, :"*RESTRICTED*"}
        end
      end)
      struct(entity.__struct__, v)
    end

  end

  defmacro __before_compile__(_env) do
    quote do
      defdelegate strip_pii(entity, level), to:  Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider.Default
    end
  end

  def __after_compile__(_env, _bytecode) do
    # Validate Generated Object
    :ok
  end

end
