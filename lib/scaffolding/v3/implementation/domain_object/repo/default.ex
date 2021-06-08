defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.Default do
  use Amnesia
  require Amnesia.Fragment

  def get(m, ref, context, options) do
    IO.puts "TODO GET #{inspect ref}"
  end
  def get!(m, ref, context, options) do
    IO.puts "TODO GET! #{inspect ref}"
  end

  def cache(m, ref, context, options) do
    IO.puts "TODO CACHE #{inspect ref}"
  end
  def delete_cache(m, ref, context, options) do
    IO.puts "TODO DELETE_CACHE #{inspect ref}"
  end




  def layer_pre_create_callback(_m, _layer, entity, _context, _options), do: entity

  def layer_create_callback!(_m, %{type: :mnesia} = layer, entity, _context, _options) do
    # TODO additional_fields
    record = struct(layer.table, %{identifier: entity.identifier, entity: entity})
    IO.puts "MNESIA CREATE! #{inspect record}"
    layer.table.write!(record)
  end
  def layer_create_callback!(m, layer, entity, context, options), do: m.layer_create_callback(layer, entity, context, options)


  def layer_create_callback(m, %{type: :mnesia} = layer, entity, _context, _options) do
    # TODO additional_fields
    record = struct(layer.table, %{identifier: entity.identifier, entity: entity})
    IO.puts "MNESIA CREATE #{inspect record}"
    layer.table.write(record)
  end
  def layer_create_callback(m, %{type: :ecto} = layer, entity, _context, _options) do
    record = struct(layer.table, %{id: Noizu.MySQL.Entity.mysql_identifier(entity)})
    # TODO inject fields, with mapping logic.
    IO.puts "ECTO CREATE #{inspect record}"
    layer.layer.insert(record)
    # todo extract new identifier
    entity
  end
  def layer_create_callback(m, _layer, entity, _context, _options), do: entity
  def layer_post_create_callback(_m, _layer, entity, _context, _options), do: entity

  def layer_create(m, layer, entity, context, options) do
    entity = m.layer_pre_create_callback(layer, entity, context, options)
    entity = m.layer_create_callback(layer, entity, context, options)
    m.layer_post_create_callback(layer, entity, context, options)
  end
  def layer_create!(m, layer, entity, context, options) do
    cond do
      layer.type != :mnesia -> m.layer_create(layer, entity, context, options)
      layer.require_transaction? ->
          cond do
            layer.fragmented? ->
            Amnesia.Fragment.transaction do
              m.layer_create(layer, entity, context, options)
            end
            :else ->
              Amnesia.transaction do
                m.layer_create(layer, entity, context, options)
              end
          end
      layer.dirty? ->
        cond do
          layer.fragmented? ->
            Amnesia.Fragment.async fn ->
              entity = m.layer_pre_create_callback(layer, entity, context, options)
              entity = m.layer_create_callback!(layer, entity, context, options)
              m.layer_post_create_callback(layer, entity, context, options)
            end
          :else ->
            Amnesia.async fn ->
              entity = m.layer_pre_create_callback(layer, entity, context, options)
              entity = m.layer_create_callback!(layer, entity, context, options)
              m.layer_post_create_callback(layer, entity, context, options)
            end
        end
      :else ->
        cond do
          layer.fragmented? ->
            Amnesia.Fragment.async fn ->
              m.layer_create(layer, entity, context, options)
            end
          :else ->
            Amnesia.async fn ->
              m.layer_create(layer, entity, context, options)
            end
        end
    end
  end

  def pre_create_callback(_m, entity, _context, _options), do: entity
  def post_create_callback(_m, entity, _context, _options), do: entity
  def create(m, entity, context, options) do
    settings = m.entity().persistence_settings()
    entity = m.pre_create_callback(entity, context, options)
    entity = Enum.reduce(
      settings.layers,
      entity,
      fn(layer, entity) ->
        cond do
          layer.cascade_create? ->
            cond do
              layer.cascade_block? -> m.layer_create(layer, entity, context, options)
              :else ->
              spawn fn -> m.layer_create!(layer, entity, context, options) end
              entity
            end
          :else -> entity
        end
      end
    )
    m.post_create_callback(entity, context, options)
  end

  def create!(m, entity, context, options) do
    settings = m.entity().persistence_settings()
    cond do
      settings.mnesia_backend == nil -> m.create(entity, context, options)
      settings.mnesia_backend[:require_transaction?] ->
        cond do
          settings.mnesia_backend[:fragmented?] ->
            Amnesia.Fragment.transaction do
              m.create(entity, context, options)
            end
          :else ->
            Amnesia.transaction do
              m.create(entity, context, options)
            end
        end
      settings.mnesia_backend[:dirty?] ->
        entity = cond do
                   settings.mnesia_backend[:fragmented?] -> Amnesia.Fragment.async(fn -> m.pre_create_callback(entity, context, options) end)
                   :else -> Amnesia.async(fn -> m.pre_create_callback(entity, context, options) end)
                 end
        entity = Enum.reduce(
          settings.layers,
          entity,
          fn(layer, entity) ->
            cond do
              layer.cascade_create? ->
                cond do
                  layer.cascade_block? -> m.layer_create!(layer, entity, context, options)
                  :else ->
                    spawn fn -> m.layer_create!(layer, entity, context, options) end
                    entity
                end
              :else -> entity
            end
          end
        )
        entity = cond do
                   settings.mnesia_backend[:fragmented?] -> Amnesia.Fragment.async(fn -> m.post_create_callback(entity, context, options) end)
                   :else -> Amnesia.async(fn -> m.post_create_callback(entity, context, options) end)
                 end
      :else ->
        cond do
          settings.mnesia_backend[:fragmented?] -> Amnesia.Fragment.async fn -> m.create(entity, context, options) end
          :else -> Amnesia.async fn -> m.create(entity, context, options) end
        end
    end
  end

  def update(m, entity, context, options) do
    IO.puts "TODO UPDATE #{inspect entity}"
  end
  def update!(m, entity, context, options) do
    IO.puts "TODO UPDATE! #{inspect entity}"
  end
  def delete(m, entity, context, options) do
    IO.puts "TODO DELETE #{inspect entity}"
  end
  def delete!(m, entity, context, options) do
    IO.puts "TODO DELETE! #{inspect entity}"
  end

  defmacro __before_compile__(_env) do
    quote do
            def entity(), do: @entity
            def get(ref, context, options \\ []), do: @provider.get(__MODULE__, ref, context, options)
            def get!(ref, context, options \\ []), do: @provider.get!(__MODULE__, ref, context, options)
            def cache(ref, context, options \\ []), do: @provider.cache(__MODULE__, ref, context, options)
            def delete_cache(ref, context, options \\ []), do: @provider.delete_cache(__MODULE__, ref, context, options)

            def pre_create_callback(entity, context, options \\ []), do: @provider.pre_create_callback(__MODULE__, entity, context, options)
            def post_create_callback(entity, context, options \\ []), do: @provider.pre_create_callback(__MODULE__, entity, context, options)
            def create(entity, context, options \\ []), do: @provider.create(__MODULE__, entity, context, options)
            def create!(entity, context, options \\ []), do: @provider.create!(__MODULE__, entity, context, options)

            def layer_pre_create_callback(layer, entity, context, options), do: @provider.layer_pre_create_callback(__MODULE__, layer, entity, context, options)
            def layer_create_callback(layer, entity, context, options), do: @provider.layer_create_callback(__MODULE__, layer, entity, context, options)
            def layer_create_callback!(layer, entity, context, options), do: @provider.layer_create_callback(__MODULE__, layer, entity, context, options)
            def layer_post_create_callback(layer, entity, context, options), do: @provider.layer_post_create_callback(__MODULE__, layer, entity, context, options)
            def layer_create(layer, entity, context, options), do: @provider.layer_create(__MODULE__, layer, entity, context, options)
            def layer_create!(layer, entity, context, options), do: @provider.layer_create!(__MODULE__, layer, entity, context, options)

            def update(entity, context, options \\ []), do: @provider.update(__MODULE__, entity, context, options)
            def update!(entity, context, options \\ []), do: @provider.update!(__MODULE__, entity, context, options)
            def delete(entity, context, options \\ []), do: @provider.delete(__MODULE__, entity, context, options)
            def delete!(entity, context, options \\ []), do: @provider.delete!(__MODULE__, entity, context, options)
    end
  end

  def __after_compile__(env, _bytecode) do
    # Validate Generated Object
    :ok
  end

end
