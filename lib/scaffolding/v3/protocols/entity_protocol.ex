defprotocol Noizu.V3.EntityProtocol do
  @fallback_to_any true
  def expand!(entity, context, options \\ nil)
end

defimpl Noizu.V3.EntityProtocol, for: Any do
  defmacro __deriving__(module, struct, options) do
    deriving(module, struct, __CALLER__, options)
  end

  def deriving(module, _struct, caller, options) do
    only = options[:only]
    except = options[:except]
    provider = options[:provider] || Noizu.V3.EntityProtocol.Derive.NoizuStruct
    quote do
      defimpl Noizu.V3.EntityProtocol, for: unquote(module) do
        def expand!(entity, context, options) do
          deriving = [only: unquote(only), except: unquote(except), caller: unquote(caller)]
          unquote(provider).expand!(deriving, entity, context, put_in(options || [], :deriving, deriving))
        end
      end
    end
  end

  def expand(entity, _context, _options), do: entity
end

defimpl Noizu.V3.EntityProtocol, for: List do
  def expand!(entity, context, options \\ nil) do
    {max_concurrency, options} = cond do
      options[:sync] -> {1, options}
      is_integer(options[:async]) && length(entity) < options[:async] -> {1, options}
      :else -> Noizu.Scaffolding.V3.Helpers.expand_concurrency(options)
    end
    if max_concurrency == 1 do
      entity
      |> Enum.map(
        fn(v) ->
          cond do
            is_map(v) || is_list(v) || is_tuple(v) -> Noizu.V3.EntityProtocol.expand!(v, context, options)
            :else -> v
          end
        end
      )
    else
      timeout = options[:timeout] || 30_000
      ordered = options[:ordered] || true
      entity
      |> Task.async_stream(
        fn(v) ->
          cond do
            is_map(v) || is_list(v) || is_tuple(v) -> Noizu.V3.EntityProtocol.expand!(v, context, options)
            :else -> v
          end
        end,
        max_concurrency: max_concurrency, timeout: timeout, ordered: ordered
      )
      |> Enum.map(fn({:ok, v}) -> v end)
    end
  end
end

defimpl Noizu.V3.EntityProtocol, for: Tuple do
  def expand!(ref, context, options \\ nil)
  def expand!({:ext_ref, m, _} = ref, context, options) when is_atom(m) do
    cond do
      Noizu.Scaffolding.V3.Helpers.expand_ref?(Noizu.Scaffolding.V3.Helpers.update_expand_options(m, context, options)) ->
        Noizu.V3.EntityProtocol.expand!(m.entity!(ref, options))
      :else -> ref
    end
  end
  def expand!({:ref, m, _} = ref, context,  options) when is_atom(m) do
      cond do
        Noizu.Scaffolding.V3.Helpers.expand_ref?(Noizu.Scaffolding.V3.Helpers.update_expand_options(m, context, options)) ->
            Noizu.V3.EntityProtocol.expand!(m.entity!(ref, options))
        :else -> ref
      end
  end
  def expand!(tuple, _context, _) do
    tuple
  end
end

defimpl Noizu.V3.EntityProtocol, for: Map do
  def expand!(entity, context, options \\ %{})

  def expand!(%{__struct__: m} = entity, context, %{structs: true} = options), do: Noizu.V3.EntityProtocol.Derive.NoizuStruct.expand!(entity, context, options)
  def expand!(%{__struct__: _m} = entity, _context, _options), do: entity
  def expand!(%{} = entity, context,  %{maps: true} = options) do
    {max_concurrency, options} = cond do
      options[:sync] -> {1, options}
      is_integer(options[:async]) && length(Map.keys(entity)) < options[:async] -> {1, options}
      :else -> Noizu.Scaffolding.V3.Helpers.expand_concurrency(options)
    end
    if max_concurrency == 1 do
      entity
      |> Enum.map(
           fn({k,v}) ->
             cond do
               is_map(v) || is_list(v) || is_tuple(v) -> {k, Noizu.V3.EntityProtocol.expand!(v, context, options)}
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
           fn({k,v}) ->
             cond do
               is_map(v) || is_list(v) || is_tuple(v) -> {k, Noizu.V3.EntityProtocol.expand!(v, context, options)}
               :else -> {k, v}
             end
           end,
           max_concurrency: max_concurrency, timeout: timeout, ordered: ordered
         )
      |> Enum.map(fn({:ok, v}) -> v end)
      |> Map.new
    end
  end
  def expand!(entity, _context, _options) do
    entity
  end
end

defmodule Noizu.V3.EntityProtocol.Derive.NoizuStruct do
  def expand!(entity, context, options) do
    {deriving, options} = pop_in(options, [:deriving])
    {json_format, options} = Noizu.Scaffolding.V3.Helpers.update_options(entity, context, options)
    expand_keys = cond do
                    v = deriving[:only] -> v
                    v = deriving[:except] -> Map.keys!(entity) -- v
                    function_exported?(entity.__struct__, :__noizu_info__, 1) ->
                      case entity.__struct__.__noizu_info__(:auto_expand?)[json_format] do
                        v when is_list(v) -> v
                        v = %MapSet{} -> v
                        :all -> Map.keys!(entity)
                        true -> Map.keys!(entity)
                        false -> []
                        _else ->
                          case json_format != :default && entity.__struct__.__noizu_info__(:auto_expand?)[:default] do
                            v when is_list(v) -> v
                            v = %MapSet{} -> v
                            :all -> Map.keys!(entity)
                            true -> Map.keys!(entity)
                            _else -> []
                          end
                      end
                    :else -> Map.keys!(entity)
                  end |> MapSet.new()

    v = Enum.map(
      fn({k,v}) ->
        v = cond do
              is_map(v) && Enum.member?(expand_keys, k) -> Noizu.V3.EntityProtocol.expand!(v, context, options)
              is_list(v) && Enum.member?(expand_keys, k) -> Noizu.V3.EntityProtocol.expand!(v, context, options)
              is_tuple(v) && Enum.member?(expand_keys, k) -> Noizu.V3.EntityProtocol.expand!(v, context, options)
              :else -> v
            end
        {k, v}
      end)
    struct(entity.__struct__, v)
  end
end
