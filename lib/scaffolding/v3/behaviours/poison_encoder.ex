

defmodule Noizu.Scaffolding.V3.Poison.Encoder do
  def encode(noizu_entity, options \\ nil) do
    {json_format, options} = Noizu.Scaffolding.Helpers.update_options(noizu_entity, options)
    context = options[:context]

    {entity, options}  = cond do
                           options[:__nzdo__restricted?] && options[:__nzdo__expanded?] -> {noizu_entity, options}
                           !options[:__nzdo__restricted?] ->
                             {Noizu.V3.RestrictedProtocol.restricted_view(noizu_entity, context, options[:restricted_view]), options}
                           !options[:__nzdo__expanded?] ->
                             {_, options} = pop_in(options, [:__nzdo__restricted?])
                             {_, options} = pop_in(options, [:__nzdo__expanded?])
                             {Noizu.V3.EntityProtocol.expand!(noizu_entity, context, options), options}
                         end

    fields = Map.from_struct(entity)
             |> Enum.map(&(encode_field(noizu_entity.__struct__, json_format, &1, context, options)))
             |> Enum.filter(&(&1))
             |> List.flatten()
             |> Enum.filter(fn({_,v}) -> v && true end)
             |> Map.new()
             |> put_in([:kind], entity.__struct__)
             |> put_in([:json_format], json_format)
             |> Poison.Encoder.encode(options)
  end

  def encode_field(mod, json_format, {field, value}, context, options) do
    white_list = mod.__noizu_info__(:json_configuration)[:white_list]
    field_settings = mod.__noizu_info__(:json_configuration)[:format_settings][json_format][field]

    # Include?
    include = cond do
                field_settings[:include] == false -> false
                field_settings[:include] == true -> true
                white_list == true -> false
                is_list(white_list) && Enum.member?(white_list, field) -> true
                :else -> true
              end

    if include do
      # - Embed
      # - Format
      value = field_settings[:expand] && Noizu.V3.EntityProtocol.expand!(value, context, options) || value

      cond do
        embed = field_settings[:embed] ->
          if (value) do
              Enum.map(embed, fn(e) ->
                case e do
                  {f, true} -> {f, get_in(value, [Access.key(f)])}
                  {f, c} ->
                    as = c[:as] || f
                    v = get_in(value, [Access.key(f)])
                    v = case c[:format] do
                          :iso8601 -> v && DateTime.to_iso8601(v)
                          _ -> v
                        end
                    {as, v}
                end
              end)
          end
        format = field_settings[:format] ->
            case format do
              :iso8601 -> value && DateTime.to_iso8601(value)
              _ -> {field, value}
            end
        :else -> {field, value}
      end
    end
  end
end
