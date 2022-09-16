#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Poison.Encoder do
  @moduledoc """
  Custom Poison Encoder Implementation, it handles stripping PII, formatting, etc.
  """
  require Logger

  @doc """
  Convert struct into json string.
  """
  def encode(noizu_entity, options \\ nil) do
    context = options[:context]
    {json_format, options} = Noizu.AdvancedScaffolding.Helpers.__update_options__(noizu_entity, context, options)
    {entity, options} = cond do
                          options[:__nzdo__restricted?] && options[:__nzdo__expanded?] ->
                            {noizu_entity, options}
                          !options[:__nzdo__restricted?] && options[:__nzdo__expanded?] ->
                            options_b = options
                                      |> put_in([:__nzdo__restricted?], true)
                            {Noizu.RestrictedAccess.Protocol.restricted_view(noizu_entity, context, options), options_b}
                          :else ->
                            options_b = options
                                        |> put_in([:__nzdo__restricted?], false)
                                        |> put_in([:__nzdo__expanded?], false)
                            expanded = Noizu.Entity.Protocol.expand!(noizu_entity, context, options_b)

                            options_c = options_b
                                      |> put_in([:__nzdo__expanded?], true)
                            restricted = Noizu.RestrictedAccess.Protocol.restricted_view(expanded, context, options)
                            options = options_c
                                      |> put_in([:__nzdo__restricted?], true)

                            {restricted, options}
                        end
    # @todo implment DO annotation support to feed in this option in entity.
    if noizu_entity.__struct__.__noizu_info__(:json_configuration)[:format_settings][json_format][:__suppress_meta__] do
      case Map.from_struct(entity) do
        v = %{identifier: <<uuid::binary-size(16)>>} ->
          # uuid work around.
          %{v| identifier: UUID.binary_to_string!(uuid)}
        v -> v
      end
      |> Enum.map(&(encode_field(noizu_entity.__struct__, json_format, &1, context, options)))
      |> Enum.filter(&(&1 != nil))
      |> List.flatten()
      |> Enum.filter(fn({_, v}) -> v != nil end)
      |> Map.new()
      |> Poison.Encoder.encode(options)
    else
      json_meta = %{
        prepared_on: options[:current_time] || DateTime.utc_now(),
        kind: json_format == :redis && noizu_entity.__struct__ || noizu_entity.__struct__.__kind__(),
        format: json_format,
      }


      case Map.from_struct(entity) do
        v = %{identifier: <<uuid::binary-size(16)>>} ->
          # uuid work around.
          %{v| identifier: UUID.binary_to_string!(uuid)}
        v -> v
      end
      |> Enum.map(&(encode_field(noizu_entity.__struct__, json_format, &1, context, options)))
      |> Enum.filter(&(&1 != nil))
      |> List.flatten()
      |> Enum.filter(fn({_, v}) -> v != nil end)
      |> Map.new()
      |> put_in([:json_meta], json_meta)
      |> Poison.Encoder.encode(options)
    end

  rescue e ->
    Logger.error("[JSON] ", Exception.format(:error, e, __STACKTRACE__))
    Exception.format(:error, e, __STACKTRACE__) |> Poison.Encoder.encode(options)
  end

  defp encode_field(mod, json_format, {field, value}, context, options) do
    white_list = mod.__noizu_info__(:json_configuration)[:white_list]
    jf = mod.__noizu_info__(:json_configuration)[:format_settings][json_format]
    jf = jf || mod.__noizu_info__(:json_configuration)[:format_settings][mod.__fields__(:json)[:default_format] || :standard]
    
    field_settings = jf[field]
    field_attr = mod.__fields__(:attributes)[field]
    # Include?
    include = cond do
                field_settings[:include] == false -> false
                field_settings[:include] == true -> true
                white_list == true -> false
                is_list(white_list) && !Enum.member?(white_list, field) -> false
                field_attr[:transient] == true -> false
                :else -> true
              end

    if include do
      {expanded, v} = cond do
                        field_settings[:sref] ->
                          {false, Noizu.ERP.sref(value)}
                        options[:__nzdo__expanded?] ->
                          {true, value}
                        field_settings[:expand] ->
                          {true, Noizu.Entity.Protocol.expand!(value, context, options)}
                        :else ->
                          {false, value}
                      end
      cond do
        embed = field_settings[:embed] ->
          if (v) do
            v = cond do
                  expanded ->
                    v
                  :else ->
                    Noizu.Entity.Protocol.expand!(value, context, options) # switch back to value not v incase sref was used.
                end

            v && Enum.map(
              embed,
              fn (e) ->
                case e do
                  {f, true} ->
                    {f, get_in(v, [Access.key(f)])}
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
                    is_atom(format) && ({:to_json, 6} in format.module_info(:exports)) ->
                      format.to_json(json_format, as, v, field_settings, context, options)
                    is_function(format, 6) ->
                      format.(json_format, as, v, field_settings, context, options)
                    ft = mod.__noizu_info__(:field_types)[field] ->
                      cond do
                        ft.handler && ({:to_json, 6} in ft.handler.module_info(:exports)) ->
                          ft.handler.to_json(json_format, as, v, field_settings, context, options)
                        :else ->
                          {as, v}
                      end
                    :else ->
                      {as, v}
                  end
              end
            field_settings[:format] == false ->
              {as, v}
            ft = mod.__noizu_info__(:field_types)[field] ->
              cond do
                ft.handler && ({:to_json, 6} in ft.handler.module_info(:exports)) ->
                  ft.handler.to_json(json_format, as, v, field_settings, context, options)
                :else ->
                  {as, v}
              end
            :else ->
              {as, v}
          end
      end
    end
  end
end
