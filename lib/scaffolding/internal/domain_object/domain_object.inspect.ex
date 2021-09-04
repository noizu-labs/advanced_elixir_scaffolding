#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Inspect do
  import Inspect.Algebra

  def inspect(entity, opts) do
    cond do
      is_integer(opts.limit) && opts.limit < 10 && entity.identifier -> Inspect.inspect(entity.__struct__.sref(entity), opts)
      is_integer(opts.limit) && opts.limit < 10 -> Inspect.inspect("ref.#{entity.__struct__.__sref__}.(NEW)", opts)
      :else ->
        kind = String.replace_leading("#{entity.__struct__}", "Elixir.", "")
        entity
        |> entity.__struct__.__strip_pii__(opts.custom_options[:pii] || :level_3)
        |> entity.__struct__.__strip_inspect__(opts)
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
