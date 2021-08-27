defmodule Noizu.AdvancedScaffolding.Implementation.DomainObject.Repo.DefaultCrudProvider do

  defmodule Default do
    use Amnesia
    alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
    require  Noizu.AdvancedScaffolding.Meta.DomainObject.Repo
    require Amnesia.Fragment

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
            :else -> v
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
    def layer_get(m, layer = %PersistenceLayer{}, ref, context, options) do
      identifier = m.layer_pre_get_callback(layer, ref, context, options)
      cond do
        identifier == nil -> nil
        entity = m.layer_get_callback(layer, identifier, context, options) -> m.layer_post_get_callback(layer, entity, context, options)
        :else -> nil
      end
    end

    def layer_get!(m, layer = %PersistenceLayer{}, ref, context, options) do
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
    def layer_get_callback(m, %PersistenceLayer{type: :mnesia} = layer, ref, context, options) do
      record = layer.table.read(ref)
      record && m.__entity__().__from_record__(layer, record, context, options)
    end

    def layer_get_callback(m, %PersistenceLayer{type: :ecto} = layer, ref, context, options) do
      record = layer.schema.get(layer.table, ref)
      record && m.__entity__().__from_record__(layer, record, context, options)
    end

    def layer_get_callback(_m, _layer, _ref, _context, _options), do: nil


    def layer_get_callback!(m, %PersistenceLayer{type: :mnesia} = layer, ref, context, options) do
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
    def layer_pre_get_callback(m, %PersistenceLayer{type: :mnesia}, ref, _context, _options), do: m.__entity__().id(ref)
    def layer_pre_get_callback(_m, %PersistenceLayer{type: :ecto}, ref, _context, _options), do: Noizu.AdvancedScaffolding.EctoEntity.Protocol.ecto_identifier(ref)
    def layer_pre_get_callback(_m, _layer, ref, _context, _options), do: ref

    #------------------------------------------
    # Get - layer_post_get_callback
    #------------------------------------------
    def layer_post_get_callback(_m, _layer, entity, _context, _options), do: entity

    #=====================================================================
    # Create
    #=====================================================================
    def create(m, entity, context, options) do
      settings = m.__persistence__()
      entity = m.pre_create_callback(entity, context, options)
      entity = Enum.reduce(
        settings.layers,
        entity,
        fn (layer, entity) ->
          cond do
            layer.cascade_create? && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
              m.layer_create(layer, entity, context, options)
            layer.cascade_create? ->
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
    end

    def create!(m, entity, context, options) do
      options = put_in(options || %{}, [:transaction!], true)
      settings = m.__persistence__()
      entity = m.pre_create_callback!(entity, context, options)
      entity = Enum.reduce(
        settings.layers,
        entity,
        fn (layer, entity) ->
          cond do
            layer.cascade_create? && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
              m.layer_create!(layer, entity, context, options)
            layer.cascade_create? ->
              spawn fn -> m.layer_create!(layer, entity, context, options) end
              entity
            :else -> entity
          end
        end
      )
      m.post_create_callback!(entity, context, options)
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
    def layer_create(m, %PersistenceLayer{} = layer, entity, context, options) do
      entity = m.layer_pre_create_callback(layer, entity, context, options)
      entity = m.layer_create_callback(layer, entity, context, options)
      m.layer_post_create_callback(layer, entity, context, options)
    end
    def layer_create!(m, %PersistenceLayer{} = layer, entity, context, options) do
      entity = m.layer_pre_create_callback!(layer, entity, context, options)
      entity = m.layer_create_callback!(layer, entity, context, options)
      m.layer_post_create_callback!(layer, entity, context, options)
    end

    #------------------------------------------
    # Create - layer_pre_create_callback
    #------------------------------------------
    def layer_pre_create_callback(_m, _layer = %PersistenceLayer{}, entity, _context, _options), do: entity

    #------------------------------------------
    #
    #------------------------------------------
    def layer_create_loop(list, %PersistenceLayer{schema: schema} = layer, context, options) do
      case list do
        records when is_list(records) -> Enum.map(records, &(layer_create_loop(&1, layer, context, options)))
        record = %{__struct__: _} ->
          schema.create_handler(record, context, options)
        _ -> :skip # @todo log
      end
    end

    def layer_create_loop!(list, %PersistenceLayer{schema: schema} = layer, context, options) do
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
    def layer_create_callback(m, %PersistenceLayer{} = layer, entity, context, options) do
      m.__entity__().__as_record__(layer, entity, context, options)
      |> layer_create_loop(layer, context, options)
      entity
    end

    def layer_create_callback!(m, %PersistenceLayer{} = layer, entity, context, options) do
      m.__entity__().__as_record__!(layer, entity, context, options)
      |> layer_create_loop!(layer, context, options)
      entity
    end

    #------------------------------------------
    # Create - layer_post_create_callback
    #------------------------------------------
    def layer_post_create_callback(_m, %PersistenceLayer{} = _layer, entity, _context, _options), do: entity

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
            layer.cascade_update? && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) -> m.layer_update(layer, entity, context, options)
            layer.cascade_update? ->
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
            layer.cascade_update? && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
              m.layer_update!(layer, entity, context, options)
            layer.cascade_update? ->
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
    def layer_update(m, %PersistenceLayer{} = layer, entity, context, options) do
      entity = m.layer_pre_update_callback(layer, entity, context, options)
      entity = m.layer_update_callback(layer, entity, context, options)
      m.layer_post_update_callback(layer, entity, context, options)
    end
    def layer_update!(m, %PersistenceLayer{} = layer, entity, context, options) do
      entity = m.layer_pre_update_callback!(layer, entity, context, options)
      entity = m.layer_update_callback!(layer, entity, context, options)
      m.layer_post_update_callback!(layer, entity, context, options)
    end

    #------------------------------------------
    # Update - layer_pre_update_callback
    #------------------------------------------
    def layer_pre_update_callback(_m, %PersistenceLayer{} = _layer, entity, _context, _options), do: entity

    #------------------------------------------
    #
    #------------------------------------------
    def layer_update_loop(list, %PersistenceLayer{schema: schema} = layer, context, options) do
      case list do
        records when is_list(records) -> Enum.map(records, &(layer_update_loop(&1, layer, context, options)))
        record = %{__struct__: _} -> schema.update_handler(record, context, options)
        _ -> :skip # @todo log
      end
    end

    def layer_update_loop!(list, %PersistenceLayer{schema: schema} = layer, context, options) do
      case list do
        records when is_list(records) -> Enum.map(records, &(layer_update_loop!(&1, layer, context, options)))
        record = %{__struct__: _} -> schema.update_handler!(record, context, options)
        _ -> :skip # @todo log
      end
    end

    #------------------------------------------
    # Update - layer_update_callback
    #------------------------------------------
    def layer_update_callback(m, %PersistenceLayer{type: type} = layer, entity, context, options) when type == :mnesia or type == :ecto do
      m.__entity__().__as_record__(layer, entity, context, options)
      |> layer_update_loop(layer, context, options)
      entity
    end
    def layer_update_callback(_m, %PersistenceLayer{} = _layer, entity, _context, _options), do: entity

    def layer_update_callback!(m, %PersistenceLayer{type: type} = layer, entity, context, options) when type == :mnesia or type == :ecto do
      m.__entity__().__as_record__!(layer, entity, context, options)
      |> layer_update_loop!(layer, context, options)
      entity
    end
    def layer_update_callback!(_m, %PersistenceLayer{} = _layer, entity, _context, _options), do: entity

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
            layer.cascade_delete? && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
              m.layer_delete(layer, entity, context, options)
            layer.cascade_delete? ->
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
            layer.cascade_delete? && (options[:cascade_block?] || options[layer.schema][:cascade_block?] || layer.cascade_block?) ->
              m.layer_delete!(layer, entity, context, options)
            layer.cascade_delete? ->
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
    def layer_delete(m, %PersistenceLayer{} = layer, entity, context, options) do
      entity = m.layer_pre_delete_callback(layer, entity, context, options)
      entity = m.layer_delete_callback(layer, entity, context, options)
      m.layer_post_delete_callback(layer, entity, context, options)
    end
    def layer_delete!(m, %PersistenceLayer{} = layer, entity, context, options) do
      entity = m.layer_pre_delete_callback!(layer, entity, context, options)
      entity = m.layer_delete_callback!(layer, entity, context, options)
      m.layer_post_delete_callback!(layer, entity, context, options)
    end

    #------------------------------------------
    # Delete - layer_pre_delete_callback
    #------------------------------------------
    def layer_pre_delete_callback(_m, %PersistenceLayer{} = _layer, entity, _context, _options), do: entity

    #------------------------------------------
    # Delete - layer_delete_callback
    #------------------------------------------
    def layer_delete_callback(_m, %PersistenceLayer{type: :mnesia} = layer, entity, _context, _options) do
      layer.table.delete(entity.identifier)
      entity
    end
    def layer_delete_callback(_m, %PersistenceLayer{type: :ecto} = layer, entity, _context, _options) do
      layer.schema.delete(layer.table, entity.identifier)
      entity
    end
    def layer_delete_callback(_m, _layer, entity, _context, _options), do: entity

    def layer_delete_callback!(_m, %PersistenceLayer{type: :mnesia} = layer, entity, _context, _options) do
      layer.table.delete!(entity.identifier)
      entity
    end
    def layer_delete_callback!(_m, %{type: :ecto} = layer, entity, _context, _options) do
      layer.schema.delete(layer.table, entity.identifier)
      entity
    end
    def layer_delete_callback!(_m, %PersistenceLayer{} = _layer, entity, _context, _options), do: entity

    #------------------------------------------
    # Delete - layer_post_delete_callback
    #------------------------------------------
    def layer_post_delete_callback(_m, %PersistenceLayer{} = _layer, entity, _context, _options), do: entity



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
  end

  defmacro __using__(_options \\ nil) do
    # caller = __CALLER__
    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
      @__nzdo__crud_imp Noizu.AdvancedScaffolding.Implementation.DomainObject.Repo.DefaultCrudProvider.Default


      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def cache_key(ref, context, options) do
        sref = __MODULE__.__entity__.sref(ref)
        sref && :"e_c:#{sref}"
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def cached(ref, context), do: cached(ref, context, [])
      def cached(ref, context, options), do: cache(ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def cache(ref, context), do: cache(ref, context, [])
      def cache(ref, context, options), do: @__nzdo__crud_imp.cache(__MODULE__, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete_cache(ref, context), do: delete_cache(ref, context, [])
      def delete_cache(ref, context, options), do: @__nzdo__crud_imp.delete_cache(__MODULE__, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def generate_identifier(), do: @__nzdo__crud_imp.generate_identifier(__MODULE__)
      def generate_identifier!(), do: @__nzdo__crud_imp.generate_identifier!(__MODULE__)

      #=====================================================================
      # Get
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def get(ref, context), do: get(ref, context, [])
      def get(ref, context, options), do: @__nzdo__crud_imp.get(__MODULE__, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def get!(ref, context), do: get!(ref, context, [])
      def get!(ref, context, options), do: @__nzdo__crud_imp.get!(__MODULE__, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def post_get_callback(ref, context, options), do: @__nzdo__crud_imp.post_get_callback(__MODULE__, ref, context, options)
      def post_get_callback!(ref, context, options), do: @__nzdo__crud_imp.post_get_callback!(__MODULE__, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_get(%PersistenceLayer{} = layer, ref, context, options), do: @__nzdo__crud_imp.layer_get(__MODULE__, layer, ref, context, options)
      def layer_get!(%PersistenceLayer{} = layer, ref, context, options), do: @__nzdo__crud_imp.layer_get!(__MODULE__, layer, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_get_callback(%PersistenceLayer{} = layer, ref, context, options), do: @__nzdo__crud_imp.layer_get_callback(__MODULE__, layer, ref, context, options)
      def layer_get_callback!(%PersistenceLayer{} = layer, ref, context, options), do: @__nzdo__crud_imp.layer_get_callback!(__MODULE__, layer, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_pre_get_callback(%PersistenceLayer{} = layer, ref, context, options), do: @__nzdo__crud_imp.layer_pre_get_callback(__MODULE__, layer, ref, context, options)
      def layer_pre_get_callback!(%PersistenceLayer{} = layer, ref, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__layer_transaction_block__(layer) do
          layer_pre_get_callback(layer, ref, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_post_get_callback(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_post_get_callback(__MODULE__, layer, entity, context, options)
      def layer_post_get_callback!(%PersistenceLayer{} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__layer_transaction_block__(layer) do
          layer_post_get_callback(layer, entity, context, options)
        end
      end

      #=====================================================================
      # Create
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def create(entity, context), do: create(entity, context, [])
      def create(entity, context, options), do: @__nzdo__crud_imp.create(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def create!(entity, context), do: create!(entity, context, [])
      def create!(entity, context, options), do: @__nzdo__crud_imp.create!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def pre_create_callback(entity, context, options), do: @__nzdo__crud_imp.pre_create_callback(__MODULE__, entity, context, options)
      def pre_create_callback!(entity, context, options), do: @__nzdo__crud_imp.pre_create_callback!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def post_create_callback(entity, context, options), do: @__nzdo__crud_imp.post_create_callback(__MODULE__, entity, context, options)
      def post_create_callback!(entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__transaction_block__() do
          post_create_callback(entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_create(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_create(__MODULE__, layer, entity, context, options)
      def layer_create!(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_create!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_pre_create_callback(%PersistenceLayer{} = layer, entity, context, options),
          do: @__nzdo__crud_imp.layer_pre_create_callback(__MODULE__, layer, entity, context, options)
      def layer_pre_create_callback!(%PersistenceLayer{} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__layer_transaction_block__(layer) do
          layer_pre_create_callback(layer, entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_create_callback(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_create_callback(__MODULE__, layer, entity, context, options)
      def layer_create_callback!(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_create_callback!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_post_create_callback(%PersistenceLayer{} = layer, entity, context, options),
          do: @__nzdo__crud_imp.layer_post_create_callback(__MODULE__, layer, entity, context, options)
      def layer_post_create_callback!(%PersistenceLayer{} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__layer_transaction_block__(layer) do
          layer_post_create_callback(layer, entity, context, options)
        end
      end


      #=====================================================================
      # Update
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def update(entity, context), do: update(entity, context, [])
      def update(entity, context, options), do: @__nzdo__crud_imp.update(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def update!(entity, context), do: update!(entity, context, [])
      def update!(entity, context, options), do: @__nzdo__crud_imp.update!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def pre_update_callback(entity, context, options), do: @__nzdo__crud_imp.pre_update_callback(__MODULE__, entity, context, options)
      def pre_update_callback!(entity, context, options), do: @__nzdo__crud_imp.pre_update_callback!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def post_update_callback(entity, context, options), do: @__nzdo__crud_imp.post_update_callback(__MODULE__, entity, context, options)
      def post_update_callback!(entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__transaction_block__() do
          post_update_callback(entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_update(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_update(__MODULE__, layer, entity, context, options)
      def layer_update!(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_update!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_pre_update_callback(%PersistenceLayer{} = layer, entity, context, options),
          do: @__nzdo__crud_imp.layer_pre_update_callback(__MODULE__, layer, entity, context, options)
      def layer_pre_update_callback!(%PersistenceLayer{} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__layer_transaction_block__(layer) do
          layer_pre_update_callback(layer, entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_update_callback(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_update_callback(__MODULE__, layer, entity, context, options)
      def layer_update_callback!(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_update_callback!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_post_update_callback(%PersistenceLayer{} = layer, entity, context, options),
          do: @__nzdo__crud_imp.layer_post_update_callback(__MODULE__, layer, entity, context, options)
      def layer_post_update_callback!(%PersistenceLayer{} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__layer_transaction_block__(layer) do
          layer_post_update_callback(layer, entity, context, options)
        end
      end


      #=====================================================================
      # Delete
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete(entity, context), do: delete(entity, context, [])
      def delete(entity, context, options), do: @__nzdo__crud_imp.delete(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete!(entity, context), do: delete!(entity, context, [])
      def delete!(entity, context, options), do: @__nzdo__crud_imp.delete!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def pre_delete_callback(ref, context, options), do: @__nzdo__crud_imp.pre_delete_callback(__MODULE__, ref, context, options)
      def pre_delete_callback!(entity, context, options), do: @__nzdo__crud_imp.pre_delete_callback!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def post_delete_callback(entity, context, options), do: @__nzdo__crud_imp.post_delete_callback(__MODULE__, entity, context, options)
      def post_delete_callback!(entity, context, options), do: @__nzdo__crud_imp.post_delete_callback!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_delete(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_delete(__MODULE__, layer, entity, context, options)
      def layer_delete!(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_delete!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_pre_delete_callback(%PersistenceLayer{} = layer, entity, context, options),
          do: @__nzdo__crud_imp.layer_pre_delete_callback(__MODULE__, layer, entity, context, options)
      def layer_pre_delete_callback!(%PersistenceLayer{} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__layer_transaction_block__(layer) do
          layer_pre_delete_callback(layer, entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_delete_callback(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_delete_callback(__MODULE__, layer, entity, context, options)
      def layer_delete_callback!(%PersistenceLayer{} = layer, entity, context, options), do: @__nzdo__crud_imp.layer_delete_callback!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_post_delete_callback(%PersistenceLayer{} = layer, entity, context, options),
          do: @__nzdo__crud_imp.layer_post_delete_callback(__MODULE__, layer, entity, context, options)
      def layer_post_delete_callback!(%PersistenceLayer{} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Meta.DomainObject.Repo.__layer_transaction_block__(layer) do
          layer_post_delete_callback(layer, entity, context, options)
        end
      end

      #---------------------
      #
      #---------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def has_permission?(ref, permission, context, options \\ []), do: @__nzdo__crud_imp.has_permission?(__MODULE__, ref, permission, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def has_permission!(ref, permission, context, options \\ []), do: @__nzdo__crud_imp.has_permission!(__MODULE__, ref, permission, context, options)

      #---------------------
      #
      #---------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
        generate_identifier: 0,
        generate_identifier!: 0,

        cache_key: 3,
        cache: 2,
        cache: 3,
        delete_cache: 2,
        delete_cache: 3,

        get: 2,
        get: 3,
        get!: 2,
        get!: 3,
        post_get_callback: 3,
        post_get_callback!: 3,
        layer_get: 4,
        layer_get!: 4,
        layer_get_callback: 4,
        layer_get_callback!: 4,
        layer_pre_get_callback: 4,
        layer_pre_get_callback!: 4,
        layer_post_get_callback: 4,
        layer_post_get_callback!: 4,

        create: 2,
        create: 3,
        create!: 2,
        create!: 3,
        pre_create_callback: 3,
        pre_create_callback!: 3,
        post_create_callback: 3,
        post_create_callback!: 3,
        layer_create: 4,
        layer_create!: 4,
        layer_pre_create_callback: 4,
        layer_pre_create_callback!: 4,
        layer_create_callback: 4,
        layer_create_callback!: 4,
        layer_post_create_callback: 4,
        layer_post_create_callback!: 4,

        update: 2,
        update: 3,
        update!: 2,
        update!: 3,
        pre_update_callback: 3,
        pre_update_callback!: 3,
        post_update_callback: 3,
        post_update_callback!: 3,
        layer_update: 4,
        layer_update!: 4,
        layer_pre_update_callback: 4,
        layer_pre_update_callback!: 4,
        layer_update_callback: 4,
        layer_update_callback!: 4,
        layer_post_update_callback: 4,
        layer_post_update_callback!: 4,

        delete: 2,
        delete: 3,
        delete!: 2,
        delete!: 3,
        pre_delete_callback: 3,
        pre_delete_callback!: 3,
        post_delete_callback: 3,
        post_delete_callback!: 3,
        layer_delete: 4,
        layer_delete!: 4,
        layer_pre_delete_callback: 4,
        layer_pre_delete_callback!: 4,
        layer_delete_callback: 4,
        layer_delete_callback!: 4,
        layer_post_delete_callback: 4,
        layer_post_delete_callback!: 4,



        has_permission?: 3,
        has_permission?: 4,
        has_permission!: 3,
        has_permission!: 4,
      ]
    end
  end

end
