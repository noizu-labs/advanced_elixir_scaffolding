#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Poison.Encoder do
  @moduledoc """
  Custom Poison Encoder Implementation, it handles stripping PII, formatting, etc.
  """

  @doc """
  Convert struct into json string.
  """
  def encode(noizu_entity, options \\ nil) do
    context = options[:context]
    {json_format, options} = Noizu.AdvancedScaffolding.Helpers.__update_options__(noizu_entity, context, options)
    {entity, options} = cond do
                          options[:__nzdo__restricted?] && options[:__nzdo__expanded?] -> {noizu_entity, options}
                          !options[:__nzdo__restricted?] ->
                            {Noizu.RestrictedAccess.Protocol.restricted_view(noizu_entity, context, options[:restricted_view]), options}
                          !options[:__nzdo__expanded?] ->
                            {_, options} = pop_in(options, [:__nzdo__restricted?])
                            {_, options} = pop_in(options, [:__nzdo__expanded?])
                            {Noizu.Entity.Protocol.expand!(noizu_entity, context, options), options}
                        end

    # @todo implment DO annotation support to feed in this option in entity.
    if noizu_entity.__struct__.__noizu_info__(:json_configuration)[:format_settings][json_format][:__suppress_meta__] do
      Map.from_struct(entity)
      |> Enum.map(&(encode_field(noizu_entity.__struct__, json_format, &1, context, options)))
      |> Enum.filter(&(&1 != nil))
      |> List.flatten()
      |> Enum.filter(fn ({_, v}) -> v != nil end)
      |> Map.new()
      |> Poison.Encoder.encode(options)
    else
      Map.from_struct(entity)
      |> Enum.map(&(encode_field(noizu_entity.__struct__, json_format, &1, context, options)))
      |> Enum.filter(&(&1 != nil))
      |> List.flatten()
      |> Enum.filter(fn ({_, v}) -> v != nil end)
      |> Map.new()
      |> put_in([:kind], noizu_entity.__struct__.__kind__())
      |> put_in([:json_format], json_format)
      |> Poison.Encoder.encode(options)
    end
  end

  defp encode_field(mod, json_format, {field, value}, context, options) do
    white_list = mod.__noizu_info__(:json_configuration)[:white_list]
    field_settings = mod.__noizu_info__(:json_configuration)[:format_settings][json_format][field]

    # Include?
    include = cond do
                field_settings[:include] == false -> false
                field_settings[:include] == true -> true
                white_list == true -> false
                is_list(white_list) && !Enum.member?(white_list, field) -> false
                :else -> true
              end

    if include do
      {expanded, v} = cond do
                        field_settings[:sref] -> {false, Noizu.ERP.sref(value)}
                        options[:__nzdo__expanded?] -> {true, value}
                        field_settings[:expand] -> {true, Noizu.Entity.Protocol.expand!(value, context, options)}
                        :else -> {false, value}
                      end

      cond do
        embed = field_settings[:embed] ->
          if (v) do
            v = cond do
                  expanded -> v
                  :else -> Noizu.Entity.Protocol.expand!(value, context, options) # switch back to value not v incase sref was used.
                end

            Enum.map(
              embed,
              fn (e) ->
                case e do
                  {f, true} -> {f, get_in(v, [Access.key(f)])}
                  {f, c} ->
                    as = c[:as] || f
                    v2 = get_in(v, [Access.key(f)])
                    v2 = cond do
                           c[:sref] -> Noizu.ERP.sref(v2)
                           # @todo allow explicit override by caller options
                           c[:expand] -> Noizu.Entity.Protocol.expand!(v2, context, options)
                           c[:format] ->
                             case c[:format] do
                               :iso8601 ->
                                 case v2 do
                                   %DateTime{} -> DateTime.to_iso8601(v2)
                                   _ -> v2
                                 end
                               _ -> v2
                             end
                           :else -> v2
                         end
                    {as, v2}
                end
              end
            )
          end
        :else ->
          as = field_settings[:as] || field
          cond do
            field_settings[:format] ->
              case field_settings[:format] do
                :iso8601 ->
                  v = case v do
                    %DateTime{} -> DateTime.to_iso8601(v)
                    _ -> v
                  end
                  {as, v}
                format ->
                  cond do
                    is_atom(format) && function_exported?(format, :to_json, 6) -> format.to_json(json_format, as, v, field_settings, context, options)
                    is_function(format, 6) -> format.(json_format, as, v, field_settings, context, options)
                    ft = mod.__noizu_info__(:field_types)[field] ->
                      cond do
                        ft.handler && function_exported?(ft.handler, :to_json, 6) -> ft.handler.to_json(json_format, as, v, field_settings, context, options)
                        :else -> {as, v}
                      end
                    :else -> {as, v}
                  end
              end
            field_settings[:format] == false -> {as, v}
            ft = mod.__noizu_info__(:field_types)[field] ->
              cond do
                ft.handler && function_exported?(ft.handler, :to_json, 6) -> ft.handler.to_json(json_format, as, v, field_settings, context, options)
                :else -> {as, v}
              end
            :else -> {as, v}
          end
      end
    end
  end
end