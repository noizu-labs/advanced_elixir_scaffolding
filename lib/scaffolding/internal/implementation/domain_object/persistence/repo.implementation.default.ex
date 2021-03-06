#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Persistence.Repo.Implementation.Default do

  use Amnesia
  alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer

  require Amnesia.Fragment
  require Logger
  #------------------------------------------
  # generate_identifier
  #------------------------------------------

  def generate_identifier!(m) do
    m.__nmid__(:generator).generate!(m.__nmid__(:sequencer))
  end

  def generate_identifier(m) do
    m.__nmid__(:generator).generate(m.__nmid__(:sequencer))
  end

  #------------------------------------------
  # delete_cache
  #------------------------------------------
  def delete_cache(m, ref, context, options) do
    # @todo use noizu fg cluster
    cond do
      key = m.cache_key(ref, context, options) ->
        spawn fn ->
          (options[:nodes] || Node.list())
          |> Task.async_stream(fn (n) -> :rpc.cast(n, FastGlobal, :delete, [key]) end)
          |> Enum.map(&(&1))
        end
        FastGlobal.delete(key)
      :else -> throw "Invalid Ref #{m}.delete_cache(#{inspect ref})"
    end
  end

  #------------------------------------------
  # cache
  #------------------------------------------
  def cache(_m, nil, _context, _options), do: nil
  def cache(m, ref, context, options) do
    cond do
      cache_key = m.cache_key(ref, context, options) ->
        v = Noizu.FastGlobal.Cluster.get(
          cache_key,
          fn () ->
            cond do
              entity = m.get!(ref, context, options) -> entity
              :else -> {:cache_miss, :os.system_time(:second) + 30 + :rand.uniform(300)}
            end
          end
        )


        case v do
          {:cache_miss, cut_off} ->
            cond do
              options[:cache_second_attempt] -> nil
              (cut_off < :os.system_time(:second)) ->
                FastGlobal.delete(cache_key)
                options = put_in(options || %{}, [:cache_second_attempt], true)
                m.cache(ref, context, options)
              :else -> nil
            end
          _else -> v
        end
      :else -> throw "#{m}.cache invalid ref #{inspect ref}"
    end
  end

  #=====================================================================
  # Get
  #=====================================================================
  def get(m, ref, context, options) do
    ref = m.__entity__().ref(ref)
    if ref do
      Enum.reduce_while(
        m.__entity__().__persistence__(:layers),
        nil,
        fn (layer, _) ->
          cond do
            layer.load_fallback? ->
              cond do
                entity = m.layer_get(layer, ref, context, options) ->
                  {:halt, m.post_get_callback(entity, context, options)}
                :else -> {:cont, nil}
              end
            :else -> {:cont, nil}
          end
        end
      )
    end
  end

  def get!(m, ref, context, options) do
    options = put_in(options || %{}, [:transaction!], true)
    ref = m.__entity__().ref(ref)
    if ref do
      Enum.reduce_while(
        m.__entity__().__persistence__(:layers),
        nil,
        fn (layer, _acc) ->
          cond do
            layer.load_fallback? ->
              cond do
                entity = m.layer_get!(layer, ref, context, options) ->
                  entity = m.post_get_callback!(entity, context, options)
                  entity && {:halt, entity} || {:cont, nil}
                :else -> {:cont, nil}
              end
            :else -> {:cont, nil}
          end
        end
      )
    end
  end

  #------------------------------------------
  # Get - post_get_callback
  #------------------------------------------
  def post_get_callback(_m, nil, _context, _options), do: nil
  def post_get_callback(m, %{vsn: vsn, __struct__: s} = entity, context, options) do
    entity = cond do
               options[:version_change] == :disabled -> entity
               options[:version_change] == false -> entity
               vsn != s.vsn ->
                 update = s.version_change(vsn, entity, context, options)
                 cond do
                   update && update.vsn != vsn ->
                     cond do
                       options[:version_change] == :sync ->
                         m.update(update, Noizu.ElixirCore.CallingContext.system(context), options)
                       :else ->
                         spawn(fn -> m.update!(update, Noizu.ElixirCore.CallingContext.system(context), options) end)
                         update
                     end
                   :else -> update
                 end
               :else -> entity
             end

    # finalize field with post created modifications (i.e update fields)
    Enum.reduce(
      entity.__struct__.__noizu_info__(:field_types), entity,
      fn ({field, type}, entity) ->
        type.handler.post_get_callback(field, entity, context, options)
      end
    )
  end
  def post_get_callback(_m, entity, _context, _options), do: entity

  def post_get_callback!(_m, nil, _context, _options), do: nil
  def post_get_callback!(m, %{vsn: vsn, __struct__: s} = entity, context, options) do
    entity = cond do
               options[:version_change] == :disabled -> entity
               options[:version_change] == false -> entity
               vsn != s.vsn ->
                 update = s.version_change!(vsn, entity, context, options)
                 cond do
                   update && update.vsn != vsn ->
                     cond do
                       options[:version_change] == :sync ->
                         m.update!(update, Noizu.ElixirCore.CallingContext.system(context), options)
                       :else ->
                         spawn(fn -> m.update!(update, Noizu.ElixirCore.CallingContext.system(context), options) end)
                         update
                     end
                   :else -> update
                 end
               :else -> entity
             end

    # finalize field with post created modifications (i.e update fields)
    Enum.reduce(
      s.__noizu_info__(:field_types), entity,
      fn ({field, type}, entity) ->
        type.handler.post_get_callback!(field, entity, context, options)
      end
    )
  end
  def post_get_callback!(_m, entity, _context, _options), do: entity

  #------------------------------------------
  # Get - layer_get
  #------------------------------------------
  def layer_get(m, layer = %{__struct__: PersistenceLayer}, ref, context, options) do
    identifier = m.layer_pre_get_callback(layer, ref, context, options)
    cond do
      identifier == nil -> nil
      entity = m.layer_get_callback(layer, identifier, context, options) -> m.layer_post_get_callback(layer, entity, context, options)
      :else -> nil
    end
  end

  def layer_get!(m, layer = %{__struct__: PersistenceLayer}, ref, context, options) do
    identifier = m.layer_pre_get_callback!(layer, ref, context, options)
    cond do
      identifier == nil -> nil
      entity = m.layer_get_callback!(layer, identifier, context, options) -> m.layer_post_get_callback!(layer, entity, context, options)
      :else -> nil
    end
  end

  #------------------------------------------
  # Get - layer_get_callback
  #------------------------------------------
  def layer_get_callback(m, %{__struct__: PersistenceLayer, type: :mnesia} = layer, ref, context, options) do
    record = layer.table.read(ref)
    record && m.__entity__().__from_record__(layer, record, context, options)
  end

  def layer_get_callback(m, %{__struct__: PersistenceLayer, type: :ecto} = layer, ref, context, options) do
    record = layer.schema.get(layer.table, ref)
    record && m.__entity__().__from_record__(layer, record, context, options)
  end

  def layer_get_callback(_m, _layer, _ref, _context, _options), do: nil


  def layer_get_callback!(m, %{__struct__: PersistenceLayer, type: :mnesia} = layer, ref, context, options) do
    record = layer.table.read!(ref)
    record && m.__entity__().__from_record__!(layer, record, context, options)
  end

  def layer_get_callback!(m, %{type: :ecto} = layer, ref, context, options) do
    record = layer.schema.get(layer.table, ref)
    record && m.__entity__().__from_record__!(layer, record, context, options)
  end

  def layer_get_callback!(_m, _layer, _ref, _context, _options), do: nil

  #------------------------------------------
  # Get - layer_pre_get_callback
  #------------------------------------------
  def layer_pre_get_callback(m, %{__struct__: PersistenceLayer, type: :mnesia}, ref, _context, _options), do: m.__entity__().id(ref)
  def layer_pre_get_callback(_m, %{__struct__: PersistenceLayer, type: :ecto}, ref, _context, _options), do: Noizu.EctoEntity.Protocol.ecto_identifier(ref)
  def layer_pre_get_callback(_m, _layer, ref, _context, _options), do: ref

  #------------------------------------------
  # Get - layer_post_get_callback
  #------------------------------------------
  def layer_post_get_callback(_m, _layer, entity, _context, _options), do: entity

  #=====================================================================
  # Create
  #=====================================================================
  def create(m, entity, context, options) do
    try do
      settings = m.__persistence__()
      entity = m.pre_create_callback(entity, context, options)
      entity = Enum.reduce(
        settings.layers,
        entity,
        fn (layer, entity) ->
          cond do
            options[:cascade?] == false && options[layer.schema][:cascade?] != true -> entity
            options[layer.schema][:cascade?] == false -> entity
            (layer.cascade_create? || options[layer.schema][:cascade?]) && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
              m.layer_create(layer, entity, context, options)
            (layer.cascade_create? || options[layer.schema][:cascade?]) ->
              spawn fn ->
                options = put_in(options || %{}, [:transaction!], true)
                m.layer_create!(layer, entity, context, options)
              end
              entity
            :else -> entity
          end
        end
      )
      m.post_create_callback(entity, context, options)
    rescue e ->
      Logger.error("[#{m}.create] rescue|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
      entity
    catch :exit, e ->
      Logger.error("[#{m}.create] exit|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
      entity
      e ->
        Logger.error("[#{m}.create] catch|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
        entity
    end
  end

  def create!(m, entity, context, options) do
    try do
      options = put_in(options || %{}, [:transaction!], true)
      settings = m.__persistence__()
      entity = m.pre_create_callback!(entity, context, options)
      entity = Enum.reduce(
        settings.layers,
        entity,
        fn (layer, entity) ->
          cond do
            options[:cascade?] == false && options[layer.schema][:cascade?] != true -> entity
            options[layer.schema][:cascade?] == false -> entity
            (layer.cascade_create? || options[layer.schema][:cascade?]) && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
              m.layer_create!(layer, entity, context, options)
            (layer.cascade_create? || options[layer.schema][:cascade?]) ->
              spawn fn -> m.layer_create!(layer, entity, context, options) end
              entity
            :else -> entity
          end
        end
      )
      m.post_create_callback!(entity, context, options)
    rescue e ->
      Logger.error("[#{m}.create!] rescue|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
      entity
    catch :exit, e ->
      Logger.error("[#{m}.create!] exit|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
      entity
      e ->
        Logger.error("[#{m}.create!] catch|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
        entity
    end
  end

  #------------------------------------------
  # Create - pre_create_callback
  #------------------------------------------
  def pre_create_callback(m, entity, context, options) do
    cond do
      entity.__struct__.__persistence__(:auto_generate) ->
        cond do
          entity.identifier && options[:override_identifier] != true ->
            throw "#{m.__noizu_info__(:entity)} attempted to call create with a preset identifier #{
              inspect entity.identifier
            }. If this was intentional set override_identifier option to true "
          :else ->
            :ok
        end
      :else ->
        cond do
          !entity.identifier && options[:generate_identifier] != true ->
            throw "#{
              m.__noizu_info__(:entity)
            } does not support auto_generate identifiers by default. Include in identifier during creation or pass in generate_identifier: true option "
          :else ->
            :ok
        end
    end

    # todo universal lookup logic
    entity = update_in(entity, [Access.key(:identifier)], &(&1 || m.generate_identifier()))

    # prep/load fields so they are insertable
    Enum.reduce(
      entity.__struct__.__noizu_info__(:field_types),
      entity,
      fn ({field, type}, entity) ->
        type.handler.pre_create_callback(field, entity, context, options)
      end
    )
  end

  def pre_create_callback!(m, entity, context, options) do
    cond do
      entity.__struct__.__persistence__(:auto_generate) ->
        cond do
          entity.identifier && options[:override_identifier] != true ->
            throw "#{m.__noizu_info__(:entity)} attempted to call create with a preset identifier #{
              inspect entity.identifier
            }. If this was intentional set override_identifier option to true "
          :else ->
            :ok
        end
      :else ->
        cond do
          !entity.identifier && options[:generate_identifier] != true ->
            throw "#{
              m.__noizu_info__(:entity)
            } does not support auto_generate identifiers by default. Include in identifier during creation or pass in generate_identifier: true option "
          :else ->
            :ok
        end
    end
    # todo universal lookup logic
    entity = update_in(entity, [Access.key(:identifier)], &(&1 || m.generate_identifier!()))

    # prep/load fields so they are insertable
    Enum.reduce(
      entity.__struct__.__noizu_info__(:field_types),
      entity,
      fn ({field, type}, entity) ->
        type.handler.pre_create_callback!(field, entity, context, options)
      end
    )
  end

  #------------------------------------------
  # Create - post_create_callback
  #------------------------------------------
  def post_create_callback(_m, %{__struct__: s} = entity, context, options) do
    # finalize field with post created modifications (i.e update fields)
    entity = Enum.reduce(
      s.__noizu_info__(:field_types),
      entity,
      fn ({field, type}, entity) ->
        type.handler.post_create_callback(field, entity, context, options)
      end
    )

    spawn fn -> s.__write_indexes__(entity, context, options[:indexes]) end
    entity
  end
  def post_create_callback(_m, entity, _context, _options) do
    entity
  end

  #------------------------------------------
  # Create - layer_create
  #------------------------------------------
  def layer_create(m, %{__struct__: PersistenceLayer} = layer, entity, context, options) do
    entity = m.layer_pre_create_callback(layer, entity, context, options)
    entity = m.layer_create_callback(layer, entity, context, options)
    m.layer_post_create_callback(layer, entity, context, options)
  end
  def layer_create(m, layer, entity, _context, _options) do
    Logger.error("Unsupported call to create by #{m} layer unknown #{inspect layer}| #{inspect entity}")
    entity
  end
  def layer_create!(m, %{__struct__: PersistenceLayer} = layer, entity, context, options) do
    entity = m.layer_pre_create_callback!(layer, entity, context, options)
    entity = m.layer_create_callback!(layer, entity, context, options)
    m.layer_post_create_callback!(layer, entity, context, options)
  end
  def layer_create!(m, layer, entity, _context, _options) do
    Logger.error("Unsupported call to create by #{m} layer unknown #{inspect layer}| #{inspect entity}")
    entity
  end
  #------------------------------------------
  # Create - layer_pre_create_callback
  #------------------------------------------
  def layer_pre_create_callback(_m, _layer = %{__struct__: PersistenceLayer}, entity, _context, _options), do: entity

  #------------------------------------------
  #
  #------------------------------------------
  def layer_create_loop(list, %{__struct__: PersistenceLayer, schema: schema} = layer, context, options) do
    case list do
      records when is_list(records) -> Enum.map(records, &(layer_create_loop(&1, layer, context, options)))
      record = %{__struct__: _} ->
        schema.create_handler(record, context, options)
      _ -> :skip # @todo log
    end
  end

  def layer_create_loop!(list, %{__struct__: PersistenceLayer, schema: schema} = layer, context, options) do
    case list do
      records when is_list(records) -> Enum.map(records, &(layer_create_loop!(&1, layer, context, options)))
      record = %{__struct__: _} ->
        schema.create_handler!(record, context, options)
      _ -> :skip # @todo log
    end
  end

  #------------------------------------------
  # Create - layer_create_callback
  #------------------------------------------
  def layer_create_callback(m, %{__struct__: PersistenceLayer} = layer, entity, context, options) do
    record = m.__entity__().__as_record__(layer, entity, context, options)
    try do
      layer_create_loop(record, layer, context, options)
    rescue e ->
      Logger.error("[#{m}.layer_create_callback] rescue|\n--------------------\n#{inspect record}\n--------------------\n#{inspect layer}\n--------------------\n#{inspect entity}\n--------------------\n #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
    catch
      :exit, e ->
        Logger.error("[#{m}.layer_create_callback] exit|\n--------------------\n#{inspect record}\n--------------------\n#{inspect layer}\n--------------------\n#{inspect entity}\n--------------------\n #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
      e ->
        Logger.error("[#{m}.layer_create_callback] catch|\n--------------------\n#{inspect record}\n--------------------\n#{inspect layer}\n--------------------\n#{inspect entity}\n--------------------\n #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
    end
    entity
  end

  def layer_create_callback!(m, %{__struct__: PersistenceLayer} = layer, entity, context, options) do
    record = m.__entity__().__as_record__!(layer, entity, context, options)
    try do
      layer_create_loop!(record, layer, context, options)
    rescue e ->
      Logger.error("[#{m}.layer_create_callback] rescue|\n--------------------\n#{inspect record}\n--------------------\n#{inspect layer}\n--------------------\n#{inspect entity}\n--------------------\n #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
    catch
      :exit, e ->
        Logger.error("[#{m}.layer_create_callback] exit|\n--------------------\n#{inspect record}\n--------------------\n#{inspect layer}\n--------------------\n#{inspect entity}\n--------------------\n #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
      e ->
        Logger.error("[#{m}.layer_create_callback] catch|\n--------------------\n#{inspect record}\n--------------------\n#{inspect layer}\n--------------------\n#{inspect entity}\n--------------------\n #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
    end
    entity
  end

  #------------------------------------------
  # Create - layer_post_create_callback
  #------------------------------------------
  def layer_post_create_callback(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity

  #=====================================================================
  # Update
  #=====================================================================
  def update(m, entity, context, options) do
    settings = m.__persistence__()
    entity = m.pre_update_callback(entity, context, options)
    entity = Enum.reduce(
      settings.layers,
      entity,
      fn (layer, entity) ->
        cond do
          options[:cascade?] == false && options[layer.schema][:cascade?] != true -> entity
          options[layer.schema][:cascade?] == false -> entity
          (layer.cascade_update? || options[layer.schema][:cascade?]) && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
            m.layer_update(layer, entity, context, options)
          (layer.cascade_update? || options[layer.schema][:cascade?]) ->
            spawn fn ->
              options = put_in(options || %{}, [:transaction!], true)
              m.layer_update!(layer, entity, context, options)
            end
            entity
          :else -> entity
        end
      end
    )
    m.post_update_callback(entity, context, options)
  end

  def update!(m, entity, context, options) do
    options = put_in(options || %{}, [:transaction!], true)
    settings = m.__persistence__()
    entity = m.pre_update_callback!(entity, context, options)
    entity = Enum.reduce(
      settings.layers,
      entity,
      fn (layer, entity) ->
        cond do
          options[:cascade?] == false && options[layer.schema][:cascade?] != true -> entity
          options[layer.schema][:cascade?] == false -> entity
          (layer.cascade_update? || options[layer.schema][:cascade?]) && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
            m.layer_update!(layer, entity, context, options)
          (layer.cascade_update? || options[layer.schema][:cascade?]) ->
            spawn fn ->
              m.layer_update!(layer, entity, context, options)
            end
            entity
          :else -> entity
        end
      end
    )
    m.post_update_callback!(entity, context, options)
  end

  #------------------------------------------
  # Update - pre_update_callback
  #------------------------------------------
  def pre_update_callback(m, entity, context, options) do
    entity.identifier == nil && throw "#{m.__entity__} attempted to call update with nil identifier"

    # prep/load fields so they are insertable
    Enum.reduce(
      m.__noizu_info__(:field_types),
      entity,
      fn ({field, type}, entity) ->
        type.handler.pre_update_callback(field, entity, context, options)
      end
    )
  end

  def pre_update_callback!(m, entity, context, options) do
    entity.identifier == nil && throw "#{m.__entity__} attempted to call update! with nil identifier"

    # prep/load fields so they are insertable
    Enum.reduce(
      m.__noizu_info__(:field_types),
      entity,
      fn ({field, type}, entity) ->
        type.handler.pre_update_callback!(field, entity, context, options)
      end
    )
  end

  #------------------------------------------
  # Update - post_update_callback
  #------------------------------------------
  def post_update_callback(_m, %{__struct__: s} = entity, context, options) do

    # finalize field with post created modifications (i.e update fields)
    entity = Enum.reduce(
      s.__noizu_info__(:field_types), entity,
      fn ({field, type}, entity) ->
        type.handler.post_update_callback(field, entity, context, options)
      end
    )

    spawn fn -> s.__update_indexes__(entity, context, options[:indexes]) end
    entity
  end
  def post_update_callback(_m, entity, _context, _options) do
    entity
  end

  #------------------------------------------
  # Update - layer_update
  #------------------------------------------
  def layer_update(m, %{__struct__: PersistenceLayer} = layer, entity, context, options) do
    entity = m.layer_pre_update_callback(layer, entity, context, options)
    entity = m.layer_update_callback(layer, entity, context, options)
    m.layer_post_update_callback(layer, entity, context, options)
  end
  def layer_update!(m, %{__struct__: PersistenceLayer} = layer, entity, context, options) do
    entity = m.layer_pre_update_callback!(layer, entity, context, options)
    entity = m.layer_update_callback!(layer, entity, context, options)
    m.layer_post_update_callback!(layer, entity, context, options)
  end

  #------------------------------------------
  # Update - layer_pre_update_callback
  #------------------------------------------
  def layer_pre_update_callback(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity

  #------------------------------------------
  #
  #------------------------------------------
  def layer_update_loop(list, %{__struct__: PersistenceLayer, schema: schema} = layer, context, options) do
    case list do
      records when is_list(records) -> Enum.map(records, &(layer_update_loop(&1, layer, context, options)))
      record = %{__struct__: _} -> schema.update_handler(record, context, options)
      _ -> :skip # @todo log
    end
  end

  def layer_update_loop!(list, %{__struct__: PersistenceLayer, schema: schema} = layer, context, options) do
    case list do
      records when is_list(records) -> Enum.map(records, &(layer_update_loop!(&1, layer, context, options)))
      record = %{__struct__: _} -> schema.update_handler!(record, context, options)
      _ -> :skip # @todo log
    end
  end

  #------------------------------------------
  # Update - layer_update_callback
  #------------------------------------------
  def layer_update_callback(m, %{__struct__: PersistenceLayer, type: type} = layer, entity, context, options) when type == :mnesia or type == :ecto do
    m.__entity__().__as_record__(layer, entity, context, options)
    |> layer_update_loop(layer, context, options)
    entity
  end
  def layer_update_callback(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity

  def layer_update_callback!(m, %{__struct__: PersistenceLayer, type: type} = layer, entity, context, options) when type == :mnesia or type == :ecto do
    m.__entity__().__as_record__!(layer, entity, context, options)
    |> layer_update_loop!(layer, context, options)
    entity
  end
  def layer_update_callback!(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity

  #------------------------------------------
  # Update - layer_post_update_callback
  #------------------------------------------
  def layer_post_update_callback(_m, _layer, entity, _context, _options), do: entity

  #=====================================================================
  # Delete
  #=====================================================================
  def delete(m, entity, context, options) do
    settings = m.__persistence__()
    entity = m.pre_delete_callback(entity, context, options)
    entity = Enum.reduce(
      settings.layers,
      entity,
      fn (layer, entity) ->
        cond do
          options[:cascade?] == false && options[layer.schema][:cascade?] != true -> entity
          options[layer.schema][:cascade?] == false -> entity
          (layer.cascade_delete? || options[layer.schema][:cascade?]) && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
            m.layer_delete(layer, entity, context, options)
          (layer.cascade_delete? || options[layer.schema][:cascade?]) ->
            spawn fn ->
              options = put_in(options || %{}, [:transaction!], true)
              m.layer_delete!(layer, entity, context, options)
            end
            entity
          :else -> entity
        end
      end
    )
    m.post_delete_callback(entity, context, options)
  end

  def delete!(m, entity, context, options) do
    options = put_in(options || %{}, [:transaction!], true)
    settings = m.__persistence__()
    entity = m.pre_delete_callback!(entity, context, options)
    entity = Enum.reduce(
      settings.layers,
      entity,
      fn (layer, entity) ->
        cond do
          options[:cascade?] == false && options[layer.schema][:cascade?] != true -> entity
          options[layer.schema][:cascade?] == false -> entity
          (layer.cascade_delete? || options[layer.schema][:cascade?]) && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
            m.layer_delete!(layer, entity, context, options)
          (layer.cascade_delete? || options[layer.schema][:cascade?]) ->
            spawn fn ->
              m.layer_delete!(layer, entity, context, options)
            end
            entity
          :else -> entity
        end
      end
    )
    m.post_delete_callback!(entity, context, options)
  end

  #------------------------------------------
  # Delete - pre_delete_callback
  #------------------------------------------
  def pre_delete_callback(m, ref, context, options) do
    # we attempt to load the entity so we can properly wipe any nested elements
    cond do
      entity = m.__entity__.entity(ref) ->

        # finalize field with post created modifications (i.e update fields)
        entity = Enum.reduce(
          entity.__struct__.__noizu_info__(:field_types), entity,
          fn ({field, type}, entity) ->
            type.handler.pre_delete_callback(field, entity, context, options)
          end
        )

        spawn fn -> m.__entity__.__delete_indexes__(entity, context, options[:indexes]) end
        entity
      :else -> ref
    end
  end

  def pre_delete_callback!(m, ref, context, options) do
    # we attempt to load the entity so we can properly wipe any nested elements
    cond do
      entity = m.__entity__.entity!(ref) ->
        # finalize field with post created modifications (i.e update fields)
        entity = Enum.reduce(
          entity.__struct__.__noizu_info__(:field_types), entity,
          fn ({field, type}, entity) ->
            type.handler.pre_delete_callback(field, entity, context, options)
          end
        )

        spawn fn -> m.__entity__.__delete_indexes__(entity, context, options[:indexes]) end
        entity
      :else -> ref
    end
  end

  #------------------------------------------
  # Delete - post_delete_callback
  #------------------------------------------
  def post_delete_callback(_m, %{__struct__: s} = entity, context, options) do
    # Delete nested components
    Enum.reduce(
      s.__noizu_info__(:field_types),
      entity,
      fn ({field, type}, entity) ->
        type.handler.post_delete_callback(field, entity, context, options)
      end
    )
  end
  def post_delete_callback(_m, entity, _context, _options) do
    entity
  end

  def post_delete_callback!(_m, %{__struct__: s} = entity, context, options) do
    # Delete nested components
    Enum.reduce(
      s.__noizu_info__(:field_types),
      entity,
      fn ({field, type}, entity) ->
        type.handler.post_delete_callback!(field, entity, context, options)
      end
    )
  end
  def post_delete_callback!(_m, entity, _context, _options) do
    entity
  end
  #------------------------------------------
  # Delete - layer_delete
  #------------------------------------------
  def layer_delete(m, %{__struct__: PersistenceLayer} = layer, entity, context, options) do
    entity = m.layer_pre_delete_callback(layer, entity, context, options)
    entity = m.layer_delete_callback(layer, entity, context, options)
    m.layer_post_delete_callback(layer, entity, context, options)
  end
  def layer_delete!(m, %{__struct__: PersistenceLayer} = layer, entity, context, options) do
    entity = m.layer_pre_delete_callback!(layer, entity, context, options)
    entity = m.layer_delete_callback!(layer, entity, context, options)
    m.layer_post_delete_callback!(layer, entity, context, options)
  end

  #------------------------------------------
  # Delete - layer_pre_delete_callback
  #------------------------------------------
  def layer_pre_delete_callback(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity

  #------------------------------------------
  # Delete - layer_delete_callback
  #------------------------------------------
  def layer_delete_callback(_m, %{__struct__: PersistenceLayer, type: :mnesia} = layer, entity, _context, _options) do
    layer.table.delete(entity.identifier)
    entity
  end
  def layer_delete_callback(_m, %{__struct__: PersistenceLayer, type: :ecto} = layer, entity, _context, _options) do
    layer.schema.delete(layer.table, entity.identifier)
    entity
  end
  def layer_delete_callback(_m, _layer, entity, _context, _options), do: entity

  def layer_delete_callback!(_m, %{__struct__: PersistenceLayer, type: :mnesia} = layer, entity, _context, _options) do
    layer.table.delete!(entity.identifier)
    entity
  end
  def layer_delete_callback!(_m, %{type: :ecto} = layer, entity, _context, _options) do
    layer.schema.delete(layer.table, entity.identifier)
    entity
  end
  def layer_delete_callback!(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity

  #------------------------------------------
  # Delete - layer_post_delete_callback
  #------------------------------------------
  def layer_post_delete_callback(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity



  #-----------------
  # has_permission
  #-------------------
  def has_permission?(_m, _repo, _permission, %{auth: auth}, _options) do
    auth[:permissions][:admin] || auth[:permissions][:system] || false
  end
  def has_permission?(_m, _repo, _permission, _context, _options), do: false

  #-----------------
  # has_permission!
  #-------------------
  def has_permission!(_m, _repo, _permission, %{auth: auth}, _options) do
    auth[:permissions][:admin] || auth[:permissions][:system] || false
  end
  def has_permission!(_m, _repo, _permission, _context, _options), do: false

  #-----------------
  # list
  #-------------------
  def list(m, pagination, filter, _context, _options) do
    # @todo generic logic to query mnesia or ecto, including pagination
    struct(m, [pagination: pagination, filter: filter, entities: [], length: 0, retrieved_on: DateTime.utc_now()])
  end

  #-----------------
  #
  #-------------------
  def list!(m, pagination, filter, _context, _options) do
    # @todo generic logic to query mnesia or ecto, including pagination
    struct(m, [pagination: pagination, filter: filter, entities: [], length: 0, retrieved_on: DateTime.utc_now()])
  end

  def list_cache!(m, pagination, filter, context, options) do
    # @todo retrieve cached list results. If no cache query all records and cache paginaation results. Return requested page and async process remaining.
    # Cache may be redis set of ids, or fastglobal depending on (future) entity annotation/options.
    m.list!(pagination, filter, context, options)
  end


  def clear_list_cache!(_m, _filter, _context, _options) do
    # @todo clear all cache records for this filter
    :ok
  end

end