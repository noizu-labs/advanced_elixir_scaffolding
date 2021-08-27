defprotocol Noizu.Entity.Protocol do
  @fallback_to_any true
  def expand!(entity, context, options \\ nil)
end

defimpl Noizu.Entity.Protocol, for: Any do
  defmacro __deriving__(module, struct, options) do
    deriving(module, struct, options)
  end

  def deriving(module, _struct, options) do
    only = options[:only]
    except = options[:except]
    provider = options[:provider] || Noizu.Entity.Protocol.Derive.NoizuStruct
    quote do
      defimpl Noizu.Entity.Protocol, for: unquote(module) do
        def expand!(entity, context, options) do
          deriving = [only: unquote(only), except: unquote(except)]
          unquote(provider).expand!(entity, context, put_in(options || [], [:deriving], deriving))
        end
      end
    end
  end

  def expand!(entity, _context, _options), do: entity
end

defimpl Noizu.Entity.Protocol, for: List do
  def expand!(entity, context, options \\ nil) do
    {max_concurrency, options} = cond do
                                   options[:sync] -> {1, options}
                                   is_integer(options[:async]) && length(entity) < options[:async] -> {1, options}
                                   :else -> Noizu.AdvancedScaffolding.Helpers.expand_concurrency(options)
                                 end
    if max_concurrency == 1 do
      entity
      |> Enum.map(
           fn (v) ->
             cond do
               is_map(v) || is_list(v) || is_tuple(v) -> Noizu.Entity.Protocol.expand!(v, context, options)
               :else -> v
             end
           end
         )
    else
      timeout = options[:timeout] || 30_000
      ordered = options[:ordered] || true
      entity
      |> Task.async_stream(
           fn (v) ->
             cond do
               is_map(v) || is_list(v) || is_tuple(v) -> Noizu.Entity.Protocol.expand!(v, context, options)
               :else -> v
             end
           end,
           max_concurrency: max_concurrency,
           timeout: timeout,
           ordered: ordered
         )
      |> Enum.map(fn ({:ok, v}) -> v end)
    end
  end
end

defimpl Noizu.Entity.Protocol, for: Tuple do
  def expand!(ref, context, options \\ nil)
  def expand!({:ext_ref, m, _} = ref, _context, options) when is_atom(m) do
    cond do
      Noizu.AdvancedScaffolding.Helpers.expand_ref?(Noizu.AdvancedScaffolding.Helpers.__update_expand_options__(m, options)) ->
        Noizu.Entity.Protocol.expand!(m.entity!(ref, options))
      :else -> ref
    end
  end
  def expand!({:ref, m, _} = ref, _context, options) when is_atom(m) do
    cond do
      Noizu.AdvancedScaffolding.Helpers.expand_ref?(Noizu.AdvancedScaffolding.Helpers.__update_expand_options__(m, options)) ->
        Noizu.Entity.Protocol.expand!(m.entity!(ref, options))
      :else -> ref
    end
  end
  def expand!(tuple, _context, _) do
    tuple
  end
end

defimpl Noizu.Entity.Protocol, for: Map do
  def expand!(entity, context, options \\ %{})

  def expand!(%{__struct__: _m} = entity, context, %{structs: true} = options), do: Noizu.Entity.Protocol.Derive.NoizuStruct.expand!(entity, context, options)
  def expand!(%{__struct__: _m} = entity, _context, _options), do: entity
  def expand!(%{} = entity, context, %{maps: true} = options) do
    {max_concurrency, options} = cond do
                                   options[:sync] -> {1, options}
                                   is_integer(options[:async]) && length(Map.keys(entity)) < options[:async] -> {1, options}
                                   :else -> Noizu.AdvancedScaffolding.Helpers.expand_concurrency(options)
                                 end
    if max_concurrency == 1 do
      entity
      |> Enum.map(
           fn ({k, v}) ->
             cond do
               is_map(v) || is_list(v) || is_tuple(v) -> {k, Noizu.Entity.Protocol.expand!(v, context, options)}
               :else -> {k, v}
             end
           end
         )
      |> Map.new
    else
      max_concurrency = options[:max_concurrency] || System.schedulers_online()
      timeout = options[:timeout] || 30_000
      ordered = options[:ordered] || true
      entity
      |> Task.async_stream(
           fn ({k, v}) ->
             cond do
               is_map(v) || is_list(v) || is_tuple(v) -> {k, Noizu.Entity.Protocol.expand!(v, context, options)}
               :else -> {k, v}
             end
           end,
           max_concurrency: max_concurrency,
           timeout: timeout,
           ordered: ordered
         )
      |> Enum.map(fn ({:ok, v}) -> v end)
      |> Map.new
    end
  end
  def expand!(entity, _context, _options) do
    entity
  end
end

defmodule Noizu.Entity.Protocol.Derive.NoizuStruct do

  def expand_field?(field, mod, json_format, deriving) do
    cond do
      is_list(deriving[:only]) -> Enum.member?(deriving[:only], field)
      is_list(deriving[:except]) -> !Enum.member?(deriving[:except], field)
      function_exported?(mod, :__noizu_info__, 1) -> mod.__noizu_info__(:json_configuration)[:format_settings][json_format][field][:expand]
      :else -> true
    end
  end

  def expand!(entity, context, options) do
    {deriving, options} = pop_in(options, [:deriving])
    {json_format, options} = Noizu.AdvancedScaffolding.Helpers.__update_options__(entity, context, options)
    v = Enum.map(
      Map.from_struct(entity),
      fn ({k, v}) ->
        v = cond do
              is_map(v) && expand_field?(k, entity.__struct__, json_format, deriving) -> Noizu.Entity.Protocol.expand!(v, context, options)
              is_list(v) && expand_field?(k, entity.__struct__, json_format, deriving) -> Noizu.Entity.Protocol.expand!(v, context, options)
              is_tuple(v) && expand_field?(k, entity.__struct__, json_format, deriving) -> Noizu.Entity.Protocol.expand!(v, context, options)
              :else -> v
            end
        {k, v}
      end
    )
    struct(entity.__struct__, v)
  end
end
