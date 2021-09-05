#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


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

  def from_json(m, format, json, context, options) do
    field_types = m.__noizu_info__(:field_types)
    fields = Map.keys(struct(m.__struct__(), [])) -- [:__struct__, :__transient__, :initial]
    full_kind = Atom.to_string(m)
    partial_kind = String.split(full_kind, ".") |> String.slice(-2 .. -1) |> Enum.join(".")
    if json["kind"] == full_kind || json["kind"] == partial_kind do
      # todo if entity identifier is set then we should load the existing entity and only apply the delta here,
      Enum.map(
        fields,
        fn (field) ->
          # @todo check for a json as clause
          v = json[Atom.to_string(field)]
          cond do
            type = field_types[field] ->
              {field, type.handler.from_json(format, v, context, options)}
            :else -> {field, v}
          end
        end
      )
      |> m.__struct__()
    end
  end

end
