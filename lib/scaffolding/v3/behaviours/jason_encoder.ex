

defmodule Noizu.Scaffolding.V3.Jason.Encoder do
  def encode(noizu_entity, options \\ nil) do
    {json_format, options} = Noizu.Scaffolding.Helpers.update_options(noizu_entity, options)
    context = options[:context]
    view = options[:json_template] || :standard
    field_attributes = noizu_entity.__struct__.__noizu_info__(:field_attributes)
    white_list? = noizu_entity.__struct__.__noizu_info__(:json_template)

    {entity, options}  = cond do
                           options[:__nzdo__restricted?] && options[:__nzdo__expanded?] -> {noizu_entity, options}
                           !options[:__nzdo__restricted?] ->
                             {Noizu.V3.RestrictedProtocol.restricted_view(noizu_entity, context, options[:restricted_view]), options}
                           !options[:__nzdo__expanded?] ->
                             {_, options} = pop_in(options, [:__nzdo__restricted?])
                             {_, options} = pop_in(options, [:__nzdo__expanded?])
                             {Noizu.V3.EntityProtocol.expand!(noizu_entity, context, options), options}
                         end

    # todo logic for compressing/etc fields based on template.
    Map.from_struct(entity)
    |> put_in([:kind], entity.__struct__)
    |> Jason.Encoder.encode(options)
  end
end
