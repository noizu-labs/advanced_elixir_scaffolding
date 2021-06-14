defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.DefaultCrudProvider do
  use Amnesia
  require Amnesia.Fragment

  def generate_identifier!(m) do
    m.__noizu_info__(:nmid_generator).generate!(m.__noizu_info__(:nmid_sequencer))
  end

  def generate_identifier(m) do
    m.__noizu_info__(:nmid_generator).generate(m.__noizu_info__(:nmid_sequencer))
  end

  def get(_m, _ref, _context, _options) do
    IO.puts "TODO table or mnesia query - get"
  end
  def get!(_m, _ref, _context, _options) do
    IO.puts "TODO table or mnesia query - get!"
  end

  def cache(_m, ref, _context, _options) do
    IO.puts "TODO CACHE #{inspect ref}"
  end
  def delete_cache(_m, ref, _context, _options) do
    IO.puts "TODO DELETE_CACHE #{inspect ref}"
  end

  def layer_pre_create_callback(_m, _layer, entity, _context, _options), do: entity

  def layer_create_callback(m, %{type: :mnesia} = layer, entity, _context, options) do
    cond do
      record = m.__entity__().__as_record__(layer.table, entity, options) ->
        layer.table.write(record)
    end
    entity
  end
  def layer_create_callback(m, %{type: :ecto} = layer, entity, _context, options) do
    cond do
      record = m.__entity__().__as_record__(layer.table, entity, options) ->
        layer.schema.insert(record)
    end
    entity
  end
  def layer_create_callback(_m, _layer, entity, _context, _options), do: entity

  def layer_create_callback!(m, %{type: :mnesia} = layer, entity, _context, options) do
    cond do
      record = m.__entity__().__as_record__!(layer.table, entity, options) ->
        layer.table.write!(record)
    end
    entity
  end
  def layer_create_callback!(m, %{type: :ecto} = layer, entity, _context, options) do
    cond do
      record = m.__entity__().__as_record__!(layer.table, entity, options) ->
        layer.schema.insert(record)
    end
    entity
  end
  def layer_create_callback!(_m, _layer, entity, _context, _options), do: entity

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

  def pre_create_callback(m, entity, context, options) do
    cond do
      entity.identifier && options[:override_identifier] != true -> throw "#{m.__noizu_info__(:entity)} attempted to call create with a preset identifier #{inspect entity.identifier}. If this was intentional set override_identifier option to true "
      :else -> :ok
    end

    # todo unviersal lookup logic
    identifier = entity.identifier || m.generate_identifier()
    entity = %{entity|identifier: identifier}

    # preprocess
    Enum.reduce(m.__noizu_info__(:field_types), entity,
      fn({field, type}, acc) ->
        type.handler.pre_create_callback(field, acc, context, options)
      end)
  end

  def post_create_callback(_m, entity, _context, _options), do: entity
  def create(m, entity, context, options) do
    settings = m.__noizu_info__(:persistence)
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
    settings = m.__noizu_info__(:persistence)
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
      cond do
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

  def update(_m, entity, _context, _options) do
    IO.puts "TODO UPDATE #{inspect entity}"
  end
  def update!(_m, entity, _context, _options) do
    IO.puts "TODO UPDATE! #{inspect entity}"
  end
  def delete(_m, entity, _context, _options) do
    IO.puts "TODO DELETE #{inspect entity}"
  end
  def delete!(_m, entity, _context, _options) do
    IO.puts "TODO DELETE! #{inspect entity}"
  end


  defmacro __using__(_options \\ nil) do
    quote do
      @__nzdo__crud_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.DefaultCrudProvider

            def get(ref, context, options \\ []), do: @__nzdo__crud_imp.get(__MODULE__, ref, context, options)
            def get!(ref, context, options \\ []), do: @__nzdo__crud_imp.get!(__MODULE__, ref, context, options)
            def cache(ref, context, options \\ []), do: @__nzdo__crud_imp.cache(__MODULE__, ref, context, options)
            def delete_cache(ref, context, options \\ []), do: @__nzdo__crud_imp.delete_cache(__MODULE__, ref, context, options)

            def pre_create_callback(entity, context, options \\ []), do: @__nzdo__crud_imp.pre_create_callback(__MODULE__, entity, context, options)
            def post_create_callback(entity, context, options \\ []), do: @__nzdo__crud_imp.post_create_callback(__MODULE__, entity, context, options)
            def create(entity, context, options \\ []), do: @__nzdo__crud_imp.create(__MODULE__, entity, context, options)
            def create!(entity, context, options \\ []), do: @__nzdo__crud_imp.create!(__MODULE__, entity, context, options)

            def layer_pre_create_callback(layer, entity, context, options), do: @__nzdo__crud_imp.layer_pre_create_callback(__MODULE__, layer, entity, context, options)
            def layer_create_callback(layer, entity, context, options), do: @__nzdo__crud_imp.layer_create_callback(__MODULE__, layer, entity, context, options)
            def layer_create_callback!(layer, entity, context, options), do: @__nzdo__crud_imp.layer_create_callback(__MODULE__, layer, entity, context, options)
            def layer_post_create_callback(layer, entity, context, options), do: @__nzdo__crud_imp.layer_post_create_callback(__MODULE__, layer, entity, context, options)
            def layer_create(layer, entity, context, options), do: @__nzdo__crud_imp.layer_create(__MODULE__, layer, entity, context, options)
            def layer_create!(layer, entity, context, options), do: @__nzdo__crud_imp.layer_create!(__MODULE__, layer, entity, context, options)

            def update(entity, context, options \\ []), do: @__nzdo__crud_imp.update(__MODULE__, entity, context, options)
            def update!(entity, context, options \\ []), do: @__nzdo__crud_imp.update!(__MODULE__, entity, context, options)
            def delete(entity, context, options \\ []), do: @__nzdo__crud_imp.delete(__MODULE__, entity, context, options)
            def delete!(entity, context, options \\ []), do: @__nzdo__crud_imp.delete!(__MODULE__, entity, context, options)

            def generate_identifier(), do: @__nzdo__crud_imp.generate_identifier(__MODULE__)
            def generate_identifier!(), do: @__nzdo__crud_imp.generate_identifier!(__MODULE__)
    end
  end

end
