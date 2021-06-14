defprotocol Noizu.V3.RestrictedProtocol do
  @fallback_to_any true
  def restricted_view(entity, context, options \\ nil)
  def restricted_update(entity, current, context, options \\ nil)
  def restricted_create(entity, context, options \\ nil)
end

defimpl Noizu.V3.RestrictedProtocol, for: List do
  def restricted_view(entity, context, options \\ nil) do
    {max_concurrency, options} = cond do
                                   options[:sync] -> {1, options}
                                   is_integer(options[:async]) && length(entity) < options[:async] -> {1, options}
                                   :else -> Noizu.Scaffolding.V3.Helpers.expand_concurrency(options)
                                 end
    if max_concurrency == 1 do
      entity
      |> Enum.map(
           fn(v) ->
             Noizu.V3.RestrictedProtocol.restricted_view(v, context, options)
           end
         )
    else
      timeout = options[:timeout] || 30_000
      ordered = options[:ordered] || true
      entity
      |> Task.async_stream(
           fn(v) ->
             Noizu.V3.RestrictedProtocol.restricted_view(v, context, options)
           end,
           max_concurrency: max_concurrency, timeout: timeout, ordered: ordered
         )
      |> Enum.map(fn({:ok, v}) -> v end)
    end
  end

  def restricted_update(_entity, _current, _context, _options \\ nil) do
    throw :not_supported
  end

  def restricted_create(entity, context, options \\ nil) do
    {max_concurrency, options} = cond do
                                   options[:sync] -> {1, options}
                                   is_integer(options[:async]) && length(entity) < options[:async] -> {1, options}
                                   :else -> Noizu.Scaffolding.V3.Helpers.expand_concurrency(options)
                                 end
    if max_concurrency == 1 do
      entity
      |> Enum.map(
           fn(v) ->
             Noizu.V3.RestrictedProtocol.restricted_create(v, context, options)
           end
         )
    else
      timeout = options[:timeout] || 30_000
      ordered = options[:ordered] || true
      entity
      |> Task.async_stream(
           fn(v) ->
             Noizu.V3.RestrictedProtocol.restricted_create(v, context, options)
           end,
           max_concurrency: max_concurrency, timeout: timeout, ordered: ordered
         )
      |> Enum.map(fn({:ok, v}) -> v end)
    end
  end
end

defimpl Noizu.V3.RestrictedProtocol, for: Any do
  defmacro __deriving__(module, _struct, options) do
    provider = options[:with] || Noizu.V3.RestrictedProtocol.Derive.NoizuStruct
    quote do
      defimpl Noizu.V3.RestrictedProtocol, for: unquote(module) do
        defdelegate restricted_view(entity, context, options), to: unquote(provider)
        defdelegate restricted_edit(entity, current, context, options), to: unquote(provider)
        defdelegate restricted_create(entity, context, options), to: unquote(provider)
      end
    end
  end

  def restricted_view(%{__struct__: _} = entity, context, options), do: Noizu.V3.RestrictedProtocol.Derive.Struct.restricted_view(entity, context, options)
  def restricted_view(entity, _context, _options), do: entity

  def restricted_edit(%{__struct__: _} = entity, current, context, options), do: Noizu.V3.RestrictedProtocol.Derive.Struct.restricted_edit(entity, current, context, options)
  def restricted_edit(entity, _current, _context, _options), do: entity

  def restricted_create(%{__struct__: _} = entity, context, options), do: Noizu.V3.RestrictedProtocol.Derive.Struct.restricted_create(entity, context, options)
  def restricted_create(entity, _context, _options), do: entity
end


defmodule Noizu.V3.RestrictedProtocol.Derive.Struct do
  def restricted_view(entity, context, options) do
    cond do
      !function_exported?(entity.__struct__, :__noizu_info__, 1) -> entity
      m = entity.__struct__.__noizu_info__(:restrict_provider) -> m.restricted_view(entity, context, options)
      :else -> Noizu.V3.RestrictedProtocol.Derive.NoizuStruct.restricted_view(entity, context, options)
    end
  end

  def restricted_edit(entity, current, context, options) do
    cond do
      !function_exported?(entity.__struct__, :__noizu_info__, 1) -> entity
      m = entity.__struct__.__noizu_info__(:restrict_provider) -> m.restricted_view(entity, current, context, options)
      :else -> Noizu.V3.RestrictedProtocol.Derive.NoizuStruct.restricted_view(entity, current, context, options)
    end
  end

  def restricted_create(entity, context, options) do
    cond do
      !function_exported?(entity.__struct__, :__noizu_info__, 1) -> entity
      m = entity.__struct__.__noizu_info__(:restrict_provider) -> m.restricted_create(entity, context, options)
      :else -> Noizu.V3.RestrictedProtocol.Derive.NoizuStruct.restricted_create(entity, context, options)
    end
  end
end

defmodule Noizu.V3.RestrictedProtocol.Derive.NoizuStruct do
  def restricted_view(entity, _context, _options), do: entity
  def restricted_edit(entity, _current, _context, _options), do: entity
  def restricted_create(entity, _context, _options), do: entity
end
