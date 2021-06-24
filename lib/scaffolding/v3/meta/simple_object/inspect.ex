defmodule Noizu.ElixirScaffolding.V3.Meta.SimpleObject.Inspect do
  import Inspect.Algebra

  def inspect(entity, opts) do
    kind = String.replace_leading("#{entity.__struct__}", "Elixir.", "")
    cond do
      opts.limit < 10 -> Inspect.inspect("<#{kind}>", opts)
      :else ->
        entity.__struct__.strip_pii(entity, opts.custom_options[:pii] || :level_3)
        |> Map.from_struct()
        |> inspect("#{kind}", opts)
    end
  end

  def inspect(map, name, opts) do
    map = Map.to_list(map)
    map = cond do
            opts.limit == :infinity -> map
            length(map) > opts.limit -> Enum.slice(map, 0..opts.limit) ++ [:...]
            :else -> map
          end
    open = color("%" <> name <> "{", :map, opts)
    sep = color(",", :map, opts)
    close = color("}", :map, opts)

    fun = fn
      {key, value}, opts -> Inspect.List.keyword({key, value}, opts)
      :..., _opts -> "..."
    end

    container_doc(open, map, close, opts, fun, separator: sep, break: :strict)
  end

end
