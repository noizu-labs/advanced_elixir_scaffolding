defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.DefaultCrudProvider do
  use Amnesia
  require Amnesia.Fragment

  def generate_identifier!(m) do
    m.__nmid__(:generator).generate!(m.__nmid__(:sequencer))
  end

  def generate_identifier(m) do
    m.__nmid__(:generator).generate(m.__nmid__(:sequencer))
  end

  def get(m, ref, context, options) do
    identifier = m.__entity__().id(ref)
    if identifier do
      Enum.reduce_while(m.__entity__().__persistence__(:layer), nil,
        fn(layer, acc) ->
          cond do
            layer.load_fallback?->
              case layer.type do
                :mnesia ->
                  record = layer.table.read(identifier)
                  entity = record && m.__entity__().__from_record__(layer.table, record, context, options)
                  entity && {:halt, entity} || {:cont, nil}
                :ecto ->
                  record = layer.schema.get(layer.table, identifier)
                  entity = record && m.__entity__().__from_record__(layer.table, record, context, options)
                  entity && {:halt, entity} || {:cont, nil}
                :redis ->
                  {:cont, nil}
                _ ->
                  {:cont, nil}
              end
            :else -> {:cont, nil}
          end
        end
      )
    end
  end
  def get!(m, ref, context, options) do
    identifier = m.__entity__().id(ref)
    if identifier do
      Enum.reduce_while(m.__entity__().__persistence__(:layer), nil,
        fn(layer, acc) ->
          cond do
            layer.load_fallback?->
              case layer.type do
                :mnesia ->
                  record = layer.table.read!(identifier)
                  entity = record && m.__entity__().__from_record__!(layer.table, record, context, options)
                  entity && {:halt, entity} || {:cont, nil}
                :ecto ->
                  record = layer.schema.get(layer.table, identifier)
                  entity = record && m.__entity__().__from_record__!(layer.table, record, context, options)
                  entity && {:halt, entity} || {:cont, nil}
                :redis ->
                  {:cont, nil}
                _ ->
                  {:cont, nil}
              end
            :else -> {:cont, nil}
          end
        end
      )
    end
  end

  def cache(_m, ref, _context, _options) do
    IO.puts "TODO CACHE #{inspect ref}"
  end
  def delete_cache(_m, ref, _context, _options) do
    IO.puts "TODO DELETE_CACHE #{inspect ref}"
  end

  def layer_pre_create_callback(_m, _layer, entity, _context, _options), do: entity

  def layer_create_callback(m, %{type: :mnesia} = layer, entity, context, options) do
    cond do
      record = m.__entity__().__as_record__(layer.table, entity, context, options) ->
        layer.table.write(record)
    end
    entity
  end
  def layer_create_callback(m, %{type: :ecto} = layer, entity, context, options) do
    cond do
      record = m.__entity__().__as_record__(layer.table, entity, context, options) ->
        layer.schema.insert(record)
    end
    entity
  end
  def layer_create_callback(_m, _layer, entity, _context, _options), do: entity

  def layer_create_callback!(m, %{type: :mnesia} = layer, entity, context, options) do
    cond do
      record = m.__entity__().__as_record__!(layer.table, entity, context, options) ->
        layer.table.write!(record)
    end
    entity
  end
  def layer_create_callback!(m, %{type: :ecto} = layer, entity, context, options) do
    cond do
      record = m.__entity__().__as_record__!(layer.table, entity, context, options) ->
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
      m.__persistence__(:auto_generate) ->
        cond do
          entity.identifier && options[:override_identifier] != true -> throw "#{m.__noizu_info__(:entity)} attempted to call create with a preset identifier #{inspect entity.identifier}. If this was intentional set override_identifier option to true "
          :else -> :ok
        end
      :else ->
        cond do
          !entity.identifier && options[:generate_identifier] != true -> throw "#{m.__noizu_info__(:entity)} does not support auto_generate identifiers by default. Include in identifier during creation or pass in generate_identifier: true option "
          :else -> :ok
        end
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
    settings = m.__persistence__()
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
    settings = m.__persistence__()
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
