#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.RestrictedAccess.Protocol do
  @fallback_to_any true
  def restricted_view(entity, context, options \\ nil)
  def restricted_update(entity, current, context, options \\ nil)
  def restricted_create(entity, context, options \\ nil)
end

defimpl Noizu.RestrictedAccess.Protocol, for: List do
  def restricted_view(entity, context, options \\ nil) do
    {max_concurrency, options} = cond do
                                   options[:sync] -> {1, options}
                                   is_integer(options[:async]) && length(entity) < options[:async] -> {1, options}
                                   :else -> Noizu.AdvancedScaffolding.Helpers.expand_concurrency(options)
                                 end
    if max_concurrency == 1 do
      entity
      |> Enum.map(
           fn (v) ->
             Noizu.RestrictedAccess.Protocol.restricted_view(v, context, options)
           end
         )
    else
      timeout = options[:timeout] || 30_000
      ordered = options[:ordered] || true
      entity
      |> Task.async_stream(
           fn (v) ->
             Noizu.RestrictedAccess.Protocol.restricted_view(v, context, options)
           end,
           max_concurrency: max_concurrency,
           timeout: timeout,
           ordered: ordered
         )
      |> Enum.map(fn ({:ok, v}) -> v end)
    end
  end

  def restricted_update(_entity, _current, _context, _options \\ nil) do
    throw :not_supported
  end

  def restricted_create(entity, context, options \\ nil) do
    {max_concurrency, options} = cond do
                                   options[:sync] -> {1, options}
                                   is_integer(options[:async]) && length(entity) < options[:async] -> {1, options}
                                   :else -> Noizu.AdvancedScaffolding.Helpers.expand_concurrency(options)
                                 end
    if max_concurrency == 1 do
      entity
      |> Enum.map(
           fn (v) ->
             Noizu.RestrictedAccess.Protocol.restricted_create(v, context, options)
           end
         )
    else
      timeout = options[:timeout] || 30_000
      ordered = options[:ordered] || true
      entity
      |> Task.async_stream(
           fn (v) ->
             Noizu.RestrictedAccess.Protocol.restricted_create(v, context, options)
           end,
           max_concurrency: max_concurrency,
           timeout: timeout,
           ordered: ordered
         )
      |> Enum.map(fn ({:ok, v}) -> v end)
    end
  end
end

defimpl Noizu.RestrictedAccess.Protocol, for: Any do
  defmacro __deriving__(module, _struct, options) do
    provider = options[:with] || Noizu.RestrictedAccess.Protocol.Derive.NoizuStruct
    quote do
      defimpl Noizu.RestrictedAccess.Protocol, for: unquote(module) do
        def restricted_view(entity, context, options), do: unquote(provider).restricted_view(entity, context, options)
        def restricted_update(entity, current, context, options), do: unquote(provider).restricted_update(entity, current, context, options)
        def restricted_create(entity, context, options), do: unquote(provider).restricted_create(entity, context, options)
      end
    end
  end

  def restricted_view(%{__struct__: _} = entity, context, options), do: Noizu.RestrictedAccess.Protocol.Derive.Struct.restricted_view(entity, context, options)
  def restricted_view(entity, _context, _options), do: entity

  def restricted_update(%{__struct__: _} = entity, current, context, options), do: Noizu.RestrictedAccess.Protocol.Derive.Struct.restricted_update(entity, current, context, options)
  def restricted_update(entity, _current, _context, _options), do: entity

  def restricted_create(%{__struct__: _} = entity, context, options), do: Noizu.RestrictedAccess.Protocol.Derive.Struct.restricted_create(entity, context, options)
  def restricted_create(entity, _context, _options), do: entity
end


defmodule Noizu.RestrictedAccess.Protocol.Derive.Struct do
  def restricted_view(entity, context, options) do
    cond do
      !({:__noizu_info__, 1} in entity.__struct__.module_info(:exports)) -> entity
      m = entity.__struct__.__noizu_info__(:restrict_provider) -> m.restricted_view(entity, context, options)
      :else -> Noizu.RestrictedAccess.Protocol.Derive.NoizuStruct.restricted_view(entity, context, options)
    end
  end

  def restricted_update(entity, current, context, options) do
    cond do
      !({:__noizu_info__, 1} in entity.__struct__.module_info(:exports)) -> entity
      m = entity.__struct__.__noizu_info__(:restrict_provider) -> m.restricted_update(entity, current, context, options)
      :else -> Noizu.RestrictedAccess.Protocol.Derive.NoizuStruct.restricted_update(entity, current, context, options)
    end
  end

  def restricted_create(entity, context, options) do
    cond do
      !({:__noizu_info__, 1} in entity.__struct__.module_info(:exports)) -> entity
      m = entity.__struct__.__noizu_info__(:restrict_provider) -> m.restricted_create(entity, context, options)
      :else -> Noizu.RestrictedAccess.Protocol.Derive.NoizuStruct.restricted_create(entity, context, options)
    end
  end
end

defmodule Noizu.RestrictedAccess.Protocol.Derive.NoizuStruct do
  def restricted_view(entity, _context, _options), do: entity
  def restricted_update(entity, _current, _context, _options), do: entity
  def restricted_create(entity, _context, _options), do: entity
end
