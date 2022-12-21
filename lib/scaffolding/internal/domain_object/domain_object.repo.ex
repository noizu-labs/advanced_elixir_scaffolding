#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Repo do
  
  defmodule Behaviour do
    alias Noizu.AdvancedScaffolding.Types
  
    #-----------------------------------------------------------------------------------------------
    # Core
    #-----------------------------------------------------------------------------------------------
    @callback vsn() :: float
    @callback __entity__() :: module
    @callback __base__() :: module
    @callback __poly_base__() :: module
    @callback __repo__() :: module
    @callback __sref__() :: String.t
    @callback __erp__() :: module
  
    @callback id(Types.entity_or_ref) :: Types.entity_identifier
    @callback ref(Types.entity_or_ref) :: Types.ref
    @callback sref(Types.entity_or_ref) :: Types.sref
    @callback entity(Types.entity_or_ref) :: map() | nil
    @callback entity(Types.entity_or_ref, Types.options) :: map() | nil
    @callback entity!(Types.entity_or_ref) :: map() | nil
    @callback entity!(Types.entity_or_ref, Types.options) :: map() | nil
  
    @callback __noizu_info__() :: any
    @callback __noizu_info__(any) :: any
  
    @callback __fields__() :: any
    @callback __fields__(any) :: any
  
    @callback __enum__() :: any
    @callback __enum__(any) :: any
  
  
    @callback has_permission?(any, any, any, any) :: boolean
    @callback has_permission!(any, any, any, any) :: boolean


    #-----------------------------------------------------------------------------------------------
    # Persistence
    #-----------------------------------------------------------------------------------------------

    @type entity :: map()
    @type ref :: {:ref, atom, any}
    @type sref :: String.t()
    @type layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t
    @type entity_reference :: ref | sref | entity | nil
    @type opts :: Keyword.t() | map() | nil

    @callback cache(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback delete_cache(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback list(pagination :: any, filter :: any, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: map() | {:error, atom | tuple}
    @callback list!(pagination :: any, filter :: any, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: map() | {:error, atom | tuple}
    @callback list_cache!(pagination :: any, filter :: any, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: map() | {:error, atom | tuple}
    @callback clear_list_cache!(filter :: any, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: :ok | {:error, atom | tuple}

    @callback get(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback post_get_callback(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_get(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_get_identifier(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity_reference | entity | nil
    @callback layer_post_get_callback(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback get!(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback post_get_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_get!(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_get_identifier!(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity_reference | entity | nil
    @callback layer_post_get_callback!(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback create(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback pre_create_callback(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback post_create_callback(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_create(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_pre_create_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_create_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_post_create_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback create!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback pre_create_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback post_create_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_create!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_pre_create_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_create_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_post_create_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback update(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback pre_update_callback(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback post_update_callback(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_update(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_pre_update_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_update_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_post_update_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback update!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback pre_update_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback post_update_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_update!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_pre_update_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_update_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_post_update_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback delete(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback pre_delete_callback(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback post_delete_callback(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_delete(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_pre_delete_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_delete_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_post_delete_callback(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback delete!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback pre_delete_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback post_delete_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_delete!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_pre_delete_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_delete_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
    @callback layer_post_delete_callback!(layer :: layer, entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

    @callback generate_identifier() :: integer | any
    @callback generate_identifier!() :: integer | any
  
  
    #-----------------------------------------------------------------------------------------------
    # Index
    #-----------------------------------------------------------------------------------------------
    @callback __indexing__() :: any
    @callback __indexing__(any) :: any
    
    #-----------------------------------------------------------------------------------------------
    # Json
    #-----------------------------------------------------------------------------------------------
    @callback __json__() :: any
    @callback __json__(any) :: any


  end

  defmodule Default do
  
  
    use Amnesia
    alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
  
    require Amnesia.Fragment
    require Logger


    @universal_lookup Application.get_env(:noizu_advanced_scaffolding, :universal_lookup, Noizu.DomainObject.UniversalLookup)


    #-----------------------------------------------------------------------------------------------
    # Core
    #-----------------------------------------------------------------------------------------------
  
    #-----------------
    # has_permission
    #-------------------
    def has_permission?(_m, _repo, _permission, %{__struct__: Noizu.ElixirCore.CallingContext, auth: auth}, _options) do
      auth[:permissions][:admin] || auth[:permissions][:system] || false
    end
    def has_permission?(_m, _repo, _permission, _context, _options), do: false
  
    #-----------------
    # has_permission!
    #-------------------
    def has_permission!(_m, _repo, _permission, %{__struct__: Noizu.ElixirCore.CallingContext, auth: auth}, _options) do
      auth[:permissions][:admin] || auth[:permissions][:system] || false
    end
    def has_permission!(_m, _repo, _permission, _context, _options), do: false
  
  
  
    #-----------------
    # has_permission
    #-------------------
    def has_permission?(_m, _permission, %{__struct__: Noizu.ElixirCore.CallingContext, auth: auth}, _options) do
      auth[:permissions][:admin] || auth[:permissions][:system] || false
    end
    def has_permission?(_m, _permission, _context, _options), do: false
  
    #-----------------
    # has_permission!
    #-------------------
    def has_permission!(_m, _permission, %{__struct__: Noizu.ElixirCore.CallingContext, auth: auth}, _options) do
      auth[:permissions][:admin] || auth[:permissions][:system] || false
    end
    def has_permission!(_m, _permission, _context, _options), do: false
  
  
  
    
    #-----------------------------------------------------------------------------------------------
    # Persistence
    #-----------------------------------------------------------------------------------------------


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
        emit = m.emit_telemetry?(:get, ref, context, options)
        emit && :telemetry.execute(m.telemetry_event(:get, ref, context, options), %{count: 1}, %{mod: m})
        Enum.reduce_while(
          m.__entity__().__persistence__(:layers),
          nil,
          fn (layer, _) ->
            cond do
              options[layer.schema][:fallback?] == false -> {:cont, nil}
              layer.load_fallback? ->
                cond do
                  entity = m.layer_get(layer, ref, context, options) ->
                    {:halt, m.post_get_callback(entity, context, options)}
                  :else -> {:cont, nil}
                end
              :else -> {:cont, nil}
            end
          end
        ) || m.miss_cb(ref, context, options)
      end
      |> tap(
           fn(o) ->
             emit = m.emit_telemetry?(:get, ref, context, options)
             emit && :telemetry.execute(m.telemetry_event(:get, ref, context, options), %{count: emit}, %{mod: m, miss: !o || false })
           end)
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
              options[layer.schema][:fallback?] == false -> {:cont, nil}
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
        ) || m.miss_cb!(ref, context, options)
      end
      |> tap(
           fn(o) ->
             emit = m.emit_telemetry?(:get!, ref, context, options)
             emit && :telemetry.execute(m.telemetry_event(:get!, ref, context, options), %{count: emit}, %{mod: m, miss: !o || false })
           end)
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
      identifier = m.layer_get_identifier(layer, ref, context, options)
      cond do
        identifier == nil -> nil
        entity = m.layer_get_callback(layer, identifier, context, options) -> m.layer_post_get_callback(layer, entity, context, options)
        :else -> nil
      end
    end

    def layer_get!(m, layer = %{__struct__: PersistenceLayer}, ref, context, options) do
      identifier = m.layer_get_identifier!(layer, ref, context, options)
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

    def layer_get_callback(m, %{__struct__: PersistenceLayer, type: :ecto} = layer, ref, context, options) when is_list(ref) do
      record = layer.schema.get_by(layer.table, ref)
      record && m.__entity__().__from_record__(layer, record, context, options)
    end

    def layer_get_callback(m, %{__struct__: PersistenceLayer, type: :ecto} = layer, ref, context, options) do
      record = layer.schema.get(layer.table, ref)
      record && m.__entity__().__from_record__(layer, record, context, options)
    end

    def layer_get_callback(m, %{__struct__: PersistenceLayer, type: :redis} = layer, ref, context, options) when is_bitstring(ref) do
      case layer.schema.get_handler(ref, context, options) do
        {:ok, record} -> m.__entity__().__from_record__(layer, record, context, options)
        _ -> nil
      end
    end

    def layer_get_callback(_m, _layer, _ref, _context, _options), do: nil


    def layer_get_callback!(m, %{__struct__: PersistenceLayer, type: :mnesia} = layer, ref, context, options) do
      record = layer.table.read!(ref)
      record && m.__entity__().__from_record__!(layer, record, context, options)
    end

    def layer_get_callback!(m, %{type: :ecto} = layer, ref, context, options) when is_list(ref) do
      record = layer.schema.get_by(layer.table, ref)
      record && m.__entity__().__from_record__!(layer, record, context, options)
    end

    def layer_get_callback!(m, %{type: :ecto} = layer, ref, context, options) do
      record = layer.schema.get(layer.table, ref)
      record && m.__entity__().__from_record__!(layer, record, context, options)
    end

    def layer_get_callback!(m, %{__struct__: PersistenceLayer, type: :redis} = layer, ref, context, options) when is_bitstring(ref) do
      case layer.schema.get_handler!(ref, context, options) do
        {:ok, record} -> m.__entity__().__from_record__!(layer, record, context, options)
        _ -> nil
      end
    end

    def layer_get_callback!(_m, _layer, _ref, _context, _options), do: nil

    #------------------------------------------
    # Get - layer_get_identifier
    #------------------------------------------
    def layer_get_identifier(m, %{__struct__: PersistenceLayer, type: :mnesia}, ref, _context, _options), do: m.__entity__().id(ref)
    def layer_get_identifier(_m, %{__struct__: PersistenceLayer, type: :ecto}, ref, _context, _options), do: Noizu.EctoEntity.Protocol.ecto_identifier(ref)
    def layer_get_identifier(m, %{__struct__: PersistenceLayer, type: :redis}, ref, _context, _options), do: m.__entity__().sref(ref)
    def layer_get_identifier(_m, _layer, ref, _context, _options), do: ref

    #------------------------------------------
    # Get - layer_post_get_callback
    #------------------------------------------
    def layer_post_get_callback(_m, _layer, entity, _context, _options), do: entity

    #=====================================================================
    # Create
    #=====================================================================
    def create(m, entity, context, options) do
      emit = m.emit_telemetry?(:create, entity, context, options)
      try do
        emit && :telemetry.execute(m.telemetry_event(:create, entity, context, options), %{count: emit}, %{mod: m})
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
        Logger.warn("[#{m}.create] rescue|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
        entity
      catch :exit, e ->
        Logger.warn("[#{m}.create] exit|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
        entity
        e ->
          Logger.warn("[#{m}.create] catch|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
          entity
      end
    end

    def create!(m, entity, context, options) do
      emit = m.emit_telemetry?(:create!, entity, context, options)
      try do
        emit && :telemetry.execute(m.telemetry_event(:create!, entity, context, options), %{count: emit}, %{mod: m})
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
        Logger.warn("[#{m}.create!] rescue|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
        entity
      catch :exit, e ->
        Logger.warn("[#{m}.create!] exit|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
        entity
        e ->
          Logger.warn("[#{m}.create!] catch|\n#{inspect entity}\n---- #{Exception.format(:error, e, __STACKTRACE__)}\n-------------------------")
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
      entity = cond do
                 entity.identifier == nil ->
                   put_in(entity, [Access.key(:identifier)], m.generate_identifier())
                 :else -> entity
               end
  
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
  
      entity = cond do
                 entity.identifier == nil ->
                   put_in(entity, [Access.key(:identifier)], m.generate_identifier!())
                 :else -> entity
               end
  
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
    def post_create_callback(m, %{__struct__: s} = entity, context, options) do
      # finalize field with post created modifications (i.e update fields)
      entity = Enum.reduce(
        s.__noizu_info__(:field_types),
        entity,
        fn ({field, type}, entity) ->
          type.handler.post_create_callback(field, entity, context, options)
        end
      )
  
      register__uid(m, entity, context, options)
      spawn fn -> s.__write_indexes__(entity, context, options[:indexes]) end
      entity
    end
    def post_create_callback(_m, entity, _context, _options) do
      entity
    end

    #------------------------------------------
    # Universal Lookup
    #------------------------------------------
    def register__uid(_, entity, _context, _options) do
      if entity.__struct__.__persistence__(:universal_identifier) do
        # Todo we need to know if system is using int or uuid universals.
        case Noizu.EctoEntity.Protocol.universal_identifier(entity) do
          v when is_integer(v) -> @universal_lookup.register(Noizu.ERP.ref(entity), v)
          <<uuid::binary-size(16)>> -> @universal_lookup.register(Noizu.ERP.ref(entity), uuid)
          <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = uuid -> @universal_lookup.register(Noizu.ERP.ref(entity), uuid)
          _ -> :error
        end
      end
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
      emit = m.emit_telemetry?(:update, entity, context, options)
      emit && :telemetry.execute(m.telemetry_event(:update, entity, context, options), %{count: emit}, %{mod: m})
  
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
      emit = m.emit_telemetry?(:update!, entity, context, options)
      emit && :telemetry.execute(m.telemetry_event(:update!, entity, context, options), %{count: emit}, %{mod: m})
  
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
    def post_update_callback(m, %{__struct__: s} = entity, context, options) do
  
      # finalize field with post created modifications (i.e update fields)
      entity = Enum.reduce(
        s.__noizu_info__(:field_types), entity,
        fn ({field, type}, entity) ->
          type.handler.post_update_callback(field, entity, context, options)
        end
      )
  
      register__uid(m, entity, context, options)
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
        {:with_previous, record, previous} ->
          options = (options || %{})
                    |> put_in([:__previous_record__], previous)
          schema.update_handler(record, previous, context, options)
        record = %{__struct__: _} -> schema.update_handler(record, context, options)
        _ -> :skip # @todo log
      end
    end

    def layer_update_loop!(list, %{__struct__: PersistenceLayer, schema: schema} = layer, context, options) do
      case list do
        records when is_list(records) -> Enum.map(records, &(layer_update_loop!(&1, layer, context, options)))
        {:with_previous, record, previous} ->
          options = (options || %{})
                    |> put_in([:__previous_record__], previous)
          schema.update_handler!(record, previous, context, options)
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
      emit = m.emit_telemetry?(:delete, entity, context, options)
      emit && :telemetry.execute(m.telemetry_event(:delete, entity, context, options), %{count: emit}, %{mod: m})
  
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
      emit = m.emit_telemetry?(:delete!, entity, context, options)
      emit && :telemetry.execute(m.telemetry_event(:delete!, entity, context, options), %{count: emit}, %{mod: m})
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
    def layer_delete_callback(m, %{__struct__: PersistenceLayer, type: :ecto} = layer, entity, context, options) do
      primary_key = m.layer_get_identifier(layer, entity, context, options)
      layer.schema.delete_handler(layer.table, primary_key, context, options)
      #layer.schema.delete(layer.table, entity.identifier)
      entity
    end
    def layer_delete_callback(_m, %{__struct__: PersistenceLayer, type: :redis} = layer, entity, context, options) do
      layer.schema.delete_handler(entity, context, options)
      entity
    end
    def layer_delete_callback(_m, _layer, entity, _context, _options), do: entity

    def layer_delete_callback!(_m, %{__struct__: PersistenceLayer, type: :mnesia} = layer, entity, _context, _options) do
      layer.table.delete!(entity.identifier)
      entity
    end
    def layer_delete_callback!(m, %{type: :ecto} = layer, entity, context, options) do
      primary_key = m.layer_get_identifier(layer, entity, context, options)
      layer.schema.delete_handler!(layer.table, primary_key, context, options)
      #layer.schema.delete(layer.table, entity.identifier)
      entity
    end
    def layer_delete_callback!(_m, %{__struct__: PersistenceLayer, type: :redis} = layer, entity, context, options) do
      layer.schema.delete_handler!(entity, context, options)
      entity
    end
    def layer_delete_callback!(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity

    #------------------------------------------
    # Delete - layer_post_delete_callback
    #------------------------------------------
    def layer_post_delete_callback(_m, %{__struct__: PersistenceLayer} = _layer, entity, _context, _options), do: entity

    #-----------------
    # list
    #-------------------
    def list(m, pagination, filter, context, options) do
      # @todo generic logic to query mnesia or ecto, including pagination
      emit = m.emit_telemetry?(:list, nil, context, options)
      emit && :telemetry.execute(m.telemetry_event(:list, nil, context, options), %{count: emit}, %{mod: m})
  
      struct(m, [pagination: pagination, filter: filter, entities: [], length: 0, retrieved_on: DateTime.utc_now()])
    end

    #-----------------
    #
    #-------------------
    def list!(m, pagination, filter, context, options) do
      # @todo generic logic to query mnesia or ecto, including pagination
      emit = m.emit_telemetry?(:list!, nil, context, options)
      emit && :telemetry.execute(m.telemetry_event(:list!, nil, context, options), %{count: emit}, %{mod: m})
  
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
    
    #-----------------------------------------------------------------------------------------------
    # Index
    #-----------------------------------------------------------------------------------------------
  
    #-----------------------------------------------------------------------------------------------
    # Json
    #-----------------------------------------------------------------------------------------------

  end
  
  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_repo__(caller, options, block) do
    extension_provider = options[:extension_implementation] || nil
    has_extension = extension_provider && true || false
    options = put_in(options || [], [:for_repo], true)

    extension_block_a = extension_provider && quote do
                                                use unquote(extension_provider), unquote(options)
                                              end
    extension_block_b = has_extension && extension_provider.pre_defstruct(options)
    extension_block_c = has_extension && extension_provider.post_defstruct(options)
    extension_block_d = extension_provider && quote do
                                                @before_compile unquote(extension_provider)
                                                @after_compile  unquote(extension_provider)
                                              end

    configuration = Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__configure__(options)
    implementation = Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__implement__(options)
    
    process_config = quote do
                       @options unquote(options)
                       require Amnesia
                       require Logger
                       require Amnesia.Helper
                       require Amnesia.Fragment
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Repo
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros
                       require Noizu.AdvancedScaffolding.Internal.Helpers
                       import Noizu.ElixirCore.Guards

                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__repo_defined, unquote(caller))

                       #--------------------
                       # Extract configuration details from provided options/set attributes/base attributes/config methods.
                       #--------------------
                       unquote(configuration)

                       # Prep attributes for loading individual fields.
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros.__register__field_attributes__macro__(unquote(options))

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         import Noizu.AdvancedScaffolding.Internal.DomainObject.Repo
                         import Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros
                         @implement Noizu.AdvancedScaffolding.Internal.DomainObject.Repo
                         unquote(extension_block_a)
                         unquote(block)
                         unquote(extension_block_b)

                         if @__nzdo__fields == [] do
                           @ref @__nzdo__allowed_refs
                           public_field :entities
                           public_field :length
                           transient_field :filter
                           transient_field :retrieved_on, nil, Noizu.DomainObject.DateTime.Millisecond.TypeHandler
                           transient_field :pagination

                           @inspect [ignore: true]
                           transient_field :__transient__, []
                         end

                       after
                         :ok
                       end
                     end


    generate = quote unquote: false do
                 @derive @__nzdo__derive
                 defstruct @__nzdo__fields
               end

    quote do
      unquote(process_config)
      unquote(generate)


      unquote(implementation)

      unquote(extension_block_c)

      # Post User Logic Hook and checks.
      @before_compile Noizu.AdvancedScaffolding.Internal.DomainObject.Repo
      @after_compile Noizu.AdvancedScaffolding.Internal.DomainObject.Repo

      unquote(extension_block_d)
      @file __ENV__.file
    end
  end






  def __configure__(options) do
    poly_support = options[:poly_support]
  
    
    quote do
      @behaviour Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.Behaviour
  
      #-----------------------------------------------------------------------------------------------
      # Core
      #-----------------------------------------------------------------------------------------------
  
      #-----------------------------------------------------------------------------------------------
      # Persistence
      #-----------------------------------------------------------------------------------------------

      # Extract Base Fields fields since SimbpleObjects are at the same level as their base.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__base__macro__(unquote(options))

      # Push details to Base, and read in required settings.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__poly__macro__(unquote(options))


      #---------------------
      # Insure sref set
      #---------------------
      if !Module.get_attribute(@__nzdo__base, :sref) do
        raise "@sref must be defined in base module #{@__ndzo__base} before calling defentity in submodule #{__MODULE__}"
      end

      #---------------------
      # Push details to Base, and read in required settings.
      #---------------------
      Module.put_attribute(@__nzdo__base, :__nzdo__repo, __MODULE__)
      @__nzdo__entity Module.concat([@__nzdo__base, "Entity"])
      @__nzdo__sref Module.get_attribute(@__nzdo__base, :sref)
      @__nzdo_persistence Module.get_attribute(@__nzdo__base, :__nzdo_persistence)

      @__nzdo_top_layer List.first(@__nzdo_persistence && @__nzdo_persistence.layers || [])
      @__nzdo_top_layer_tx_block @__nzdo_top_layer && @__nzdo_top_layer.tx_block

      @vsn (Module.get_attribute(@__nzdo__base, :vsn) || 1.0)


      # Json Settings
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__json_settings__macro__(unquote(options))


      #----------------------
      # Derives
      #----------------------
      @__nzdo__derive Noizu.Entity.Protocol
      @__nzdo__derive Noizu.RestrictedAccess.Protocol


      @__nzdo__allowed_refs (case (unquote(poly_support) || Noizu.AdvancedScaffolding.Internal.Helpers.extract_attribute(:poly_support, nil)) do
                               v  when is_list(v) -> Enum.uniq(v ++ [@__nzdo__entity])
                               _ -> [@__nzdo__entity]
                             end)
  
      
      #-----------------------------------------------------------------------------------------------
      # Index
      #-----------------------------------------------------------------------------------------------
  
      
      #-----------------------------------------------------------------------------------------------
      # Json
      #-----------------------------------------------------------------------------------------------


    end
  end

  def __implement__(options) do
    json_provider = options[:json_provider]
    disable_json_imp = (json_provider == false)
 
    quote do
    
      @__nzdo__repo_default Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.Default
      alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer




      #-----------------------------------------------------------------------------------------------
      # Core
      #-----------------------------------------------------------------------------------------------
      
      #################################################
      #
      #################################################
      def vsn(), do: @__nzdo__base.vsn()
      def __base__(), do: @__nzdo__base
      def __poly_base__(), do: @__nzdo__poly_base
      def __entity__(), do: @__nzdo__base.__entity__()
      def __repo__(), do: __MODULE__
      def __sref__(), do: @__nzdo__base.__sref__()
      def __kind__(), do: @__nzdo__base.__repo_kind__()
      def __erp__(), do: @__nzdo__base.__erp__()
      def id(ref), do: @__nzdo__base.id(ref)
      def ref(ref), do: @__nzdo__base.ref(ref)
      def sref(ref), do: @__nzdo__base.sref(ref)
    
      def entity(ref, options \\ nil), do: @__nzdo__base.entity(ref, options)
      def entity!(ref, options \\ nil), do: @__nzdo__base.entity!(ref, options)
    
      def record(ref, options \\ nil), do: @__nzdo__base.record(ref, options)
      def record!(ref, options \\ nil), do: @__nzdo__base.record!(ref, options)
    
      #---------------------
      #
      #---------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def has_permission?(permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context), do: @__nzdo__repo_default.has_permission?(__MODULE__, permission, context, nil)
      def has_permission?(permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context, options), do: @__nzdo__repo_default.has_permission?(__MODULE__, permission, context, options)
      def has_permission?(ref, permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context), do: @__nzdo__repo_default.has_permission?(__MODULE__, ref, permission, context, nil)
      def has_permission?(ref, permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context, options), do: @__nzdo__repo_default.has_permission?(__MODULE__, ref, permission, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def has_permission!(permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context), do: @__nzdo__repo_default.has_permission!(__MODULE__, permission, context, nil)
      def has_permission!(permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context, options), do: @__nzdo__repo_default.has_permission!(__MODULE__, permission, context, options)
      def has_permission!(ref, permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context), do: @__nzdo__repo_default.has_permission!(__MODULE__, ref, permission, context, nil)
      def has_permission!(ref, permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context, options), do: @__nzdo__repo_default.has_permission!(__MODULE__, ref, permission, context, options)
    
    
    
    
      defoverridable [
      
      
        vsn: 0,
        __entity__: 0,
        __base__: 0,
        __poly_base__: 0,
        __repo__: 0,
        __sref__: 0,
        __kind__: 0,
        __erp__: 0,
      
        id: 1,
        ref: 1,
        sref: 1,
        entity: 1,
        entity: 2,
        entity!: 1,
        entity!: 2,
        record: 1,
        record: 2,
        record!: 1,
        record!: 2,
      
        has_permission?: 2,
        has_permission?: 3,
        has_permission?: 4,
      
        has_permission!: 2,
        has_permission!: 3,
        has_permission!: 4,
      ]
  
  
  
  
  
      #-----------------------------------------------------------------------------------------------
      # Persistence
      #-----------------------------------------------------------------------------------------------

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def cache_key(ref, context, options) do
        h = __MODULE__.__entity__.__noizu_info__(:cache)[:type]
        h.cache_key(__MODULE__, ref, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def pre_cache(ref, context), do: pre_cache(ref, context, [])
      def pre_cache(ref, context, options) do
        #, do: @__nzdo__repo_default.cache(__MODULE__, ref, context, options)
        h = __MODULE__.__entity__.__noizu_info__(:cache)[:type]
        h.pre_cache(__MODULE__, ref, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def cached(ref, context), do: cached(ref, context, [])
      def cached(ref, context, options), do: cache(ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def cache(ref, context), do: cache(ref, context, [])
      def cache(ref, context, options) do
        #, do: @__nzdo__repo_default.cache(__MODULE__, ref, context, options)
        h = __MODULE__.__entity__.__noizu_info__(:cache)[:type]
        h.get_cache(__MODULE__, ref, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete_cache(ref, context), do: delete_cache(ref, context, [])
      #def delete_cache(ref, context, options), do: @__nzdo__repo_default.delete_cache(__MODULE__, ref, context, options)
      def delete_cache(ref, context, options) do
        h = __MODULE__.__entity__.__noizu_info__(:cache)[:type]
        h.delete_cache(__MODULE__, ref, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def generate_identifier() do
        case __noizu_info__(:identifier_type) do
          :uuid ->
            sref = __noizu_info__(:sref)
            id = @__nzdo__repo_default.generate_identifier(__MODULE__)
            UUID.uuid5(:url, "ref.#{sref}.#{id}", :raw)
          _ -> @__nzdo__repo_default.generate_identifier(__MODULE__)
        end
      end
      def generate_identifier!() do
        case __noizu_info__(:identifier_type) do
          :uuid ->
            sref = __noizu_info__(:sref)
            id = @__nzdo__repo_default.generate_identifier!(__MODULE__)
            UUID.uuid5(:url, "ref.#{sref}.#{id}", :raw)
          _ -> @__nzdo__repo_default.generate_identifier!(__MODULE__)
        end
      end

      #=====================================================================
      # Get
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def get(ref, context), do: get(ref, context, [])
      def get(ref, context, options), do: @__nzdo__repo_default.get(__MODULE__, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def get!(ref, context), do: get!(ref, context, [])
      def get!(ref, context, options), do: @__nzdo__repo_default.get!(__MODULE__, ref, context, options)

      def miss_cb(_ref, _context, _options), do: nil
      def miss_cb!(_ref, _context, _options), do: nil

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def post_get_callback(ref, context, options), do: @__nzdo__repo_default.post_get_callback(__MODULE__, ref, context, options)
      def post_get_callback!(ref, context, options), do: @__nzdo__repo_default.post_get_callback!(__MODULE__, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_get(%{__struct__: PersistenceLayer} = layer, ref, context, options), do: @__nzdo__repo_default.layer_get(__MODULE__, layer, ref, context, options)
      def layer_get!(%{__struct__: PersistenceLayer} = layer, ref, context, options), do: @__nzdo__repo_default.layer_get!(__MODULE__, layer, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_get_callback(%{__struct__: PersistenceLayer} = layer, ref, context, options), do: @__nzdo__repo_default.layer_get_callback(__MODULE__, layer, ref, context, options)
      def layer_get_callback!(%{__struct__: PersistenceLayer} = layer, ref, context, options), do: @__nzdo__repo_default.layer_get_callback!(__MODULE__, layer, ref, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_get_identifier(%{__struct__: PersistenceLayer} = layer, ref, context, options), do: @__nzdo__repo_default.layer_get_identifier(__MODULE__, layer, ref, context, options)
      def layer_get_identifier!(%{__struct__: PersistenceLayer} = layer, ref, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__(layer) do
          @__nzdo__repo_default.layer_get_identifier(__MODULE__, layer, ref, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_post_get_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_post_get_callback(__MODULE__, layer, entity, context, options)
      def layer_post_get_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__(layer) do
          @__nzdo__repo_default.layer_post_get_callback(__MODULE__, layer, entity, context, options)
        end
      end

      #=====================================================================
      # Telemetry
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def emit_telemetry?(type, _, context, options) do
        cond do
          get_in(options || [], [:emit_telemtry?]) != nil -> options[:emit_telemtry?]
          get_in(context && context.options || [], [:emit_telemtry?]) != nil -> options[:emit_telemtry?]
          :else ->
            c = __persistence__(:telemetry)
            cond do
              c[:enabled] in [true, :enabled] ->
                case c[:events][type] do
                  false -> false
                  true -> c[:sample_rate]
                  v when is_integer(v) -> v
                  _ -> c[:sample_rate]
                end
              :else -> false
            end
        end |> case do
                 false -> false
                 :disabled -> false
                 true -> 1
                 :enabled -> 1
                 v when is_integer(v) ->
                   cond do
                     v >= 1000 -> 1
                     :rand.uniform(1000) <= v ->
                       r = rem(1000, v)
                       a = cond do
                             r == 0 -> 0
                             :rand.uniform(100) <= ((1000*r)/v) -> 1
                             :else -> 0
                           end
                       div(1000, v) + a
                     :else -> false
                   end
               end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def telemetry_event(type, _, _, _) do
        [:persistence, :event, type]
      end
      #=====================================================================
      # Create
      #=====================================================================

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def create(entity, context), do: create(entity, context, [])
      def create(entity, context, options), do: @__nzdo__repo_default.create(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def create!(entity, context), do: create!(entity, context, [])
      def create!(entity, context, options), do: @__nzdo__repo_default.create!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def pre_create_callback(entity, context, options), do: @__nzdo__repo_default.pre_create_callback(__MODULE__, entity, context, options)
      def pre_create_callback!(entity, context, options), do: @__nzdo__repo_default.pre_create_callback!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def post_create_callback(entity, context, options), do: @__nzdo__repo_default.post_create_callback(__MODULE__, entity, context, options)
      def post_create_callback!(entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__transaction_block__() do
          @__nzdo__repo_default.post_create_callback(__MODULE__, entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_create(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_create(__MODULE__, layer, entity, context, options)
      def layer_create(nil, entity, context, options), do: @__nzdo__repo_default.layer_create(__MODULE__, nil, entity, context, options)
      def layer_create!(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_create!(__MODULE__, layer, entity, context, options)
      def layer_create!(nil, entity, context, options), do: @__nzdo__repo_default.layer_create!(__MODULE__, nil, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_pre_create_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options),
          do: @__nzdo__repo_default.layer_pre_create_callback(__MODULE__, layer, entity, context, options)
      def layer_pre_create_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__(layer) do
          @__nzdo__repo_default.layer_pre_create_callback(__MODULE__, layer, entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_create_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_create_callback(__MODULE__, layer, entity, context, options)
      def layer_create_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_create_callback!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_post_create_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options),
          do: @__nzdo__repo_default.layer_post_create_callback(__MODULE__, layer, entity, context, options)
      def layer_post_create_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__(layer) do
          @__nzdo__repo_default.layer_post_create_callback(__MODULE__, layer, entity, context, options)
        end
      end


      #=====================================================================
      # Update
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def update(entity, context), do: update(entity, context, [])
      def update(entity, context, options), do: @__nzdo__repo_default.update(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def update!(entity, context), do: update!(entity, context, [])
      def update!(entity, context, options), do: @__nzdo__repo_default.update!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def pre_update_callback(entity, context, options), do: @__nzdo__repo_default.pre_update_callback(__MODULE__, entity, context, options)
      def pre_update_callback!(entity, context, options), do: @__nzdo__repo_default.pre_update_callback!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def post_update_callback(entity, context, options), do: @__nzdo__repo_default.post_update_callback(__MODULE__, entity, context, options)
      def post_update_callback!(entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__transaction_block__() do
          @__nzdo__repo_default.post_update_callback(__MODULE__, entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_update(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_update(__MODULE__, layer, entity, context, options)
      def layer_update!(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_update!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_pre_update_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options),
          do: @__nzdo__repo_default.layer_pre_update_callback(__MODULE__, layer, entity, context, options)
      def layer_pre_update_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__(layer) do
          @__nzdo__repo_default.layer_pre_update_callback(__MODULE__, layer, entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_update_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_update_callback(__MODULE__, layer, entity, context, options)
      def layer_update_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_update_callback!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_post_update_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options),
          do: @__nzdo__repo_default.layer_post_update_callback(__MODULE__, layer, entity, context, options)
      def layer_post_update_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__(layer) do
          @__nzdo__repo_default.layer_post_update_callback(__MODULE__, layer, entity, context, options)
        end
      end


      #=====================================================================
      # Delete
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete(entity, context), do: delete(entity, context, [])
      def delete(entity, context, options), do: @__nzdo__repo_default.delete(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete!(entity, context), do: delete!(entity, context, [])
      def delete!(entity, context, options), do: @__nzdo__repo_default.delete!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def pre_delete_callback(ref, context, options), do: @__nzdo__repo_default.pre_delete_callback(__MODULE__, ref, context, options)
      def pre_delete_callback!(entity, context, options), do: @__nzdo__repo_default.pre_delete_callback!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def post_delete_callback(entity, context, options), do: @__nzdo__repo_default.post_delete_callback(__MODULE__, entity, context, options)
      def post_delete_callback!(entity, context, options), do: @__nzdo__repo_default.post_delete_callback!(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_delete(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_delete(__MODULE__, layer, entity, context, options)
      def layer_delete!(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_delete!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_pre_delete_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options),
          do: @__nzdo__repo_default.layer_pre_delete_callback(__MODULE__, layer, entity, context, options)
      def layer_pre_delete_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__(layer) do
          @__nzdo__repo_default.layer_pre_delete_callback(__MODULE__, layer, entity, context, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_delete_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_delete_callback(__MODULE__, layer, entity, context, options)
      def layer_delete_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_delete_callback!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def layer_post_delete_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options),
          do: @__nzdo__repo_default.layer_post_delete_callback(__MODULE__, layer, entity, context, options)
      def layer_post_delete_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options) do
        Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__(layer) do
          @__nzdo__repo_default.layer_post_delete_callback(__MODULE__, layer, entity, context, options)
        end
      end


      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def list(pagination, filter, context, options \\ nil), do: @__nzdo__repo_default.list(__MODULE__, pagination, filter, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def list!(pagination, filter, context, options \\ nil), do: @__nzdo__repo_default.list!(__MODULE__, pagination, filter, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def list_cache!(pagination, filter, context, options \\ nil), do: @__nzdo__repo_default.list_cache!(__MODULE__, pagination, filter, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def clear_list_cache!(filter, context, options \\ nil), do: @__nzdo__repo_default.clear_list_cache!(__MODULE__, filter, context, options)

      #---------------------
      #
      #---------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
        generate_identifier: 0,
        generate_identifier!: 0,
  
        emit_telemetry?: 4,
        telemetry_event: 4,
  
        cache_key: 3,
        cache: 2,
        cache: 3,
        delete_cache: 2,
        delete_cache: 3,
  
        get: 2,
        get: 3,
        get!: 2,
        get!: 3,
        miss_cb: 3,
        miss_cb!: 3,
        post_get_callback: 3,
        post_get_callback!: 3,
        layer_get: 4,
        layer_get!: 4,
        layer_get_callback: 4,
        layer_get_callback!: 4,
        layer_get_identifier: 4,
        layer_get_identifier!: 4,
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
  
        list: 3,
        list: 4,
        list!: 3,
        list!: 4,
  
        list_cache!: 3,
        list_cache!: 4,
  
        clear_list_cache!: 2,
        clear_list_cache!: 3,
      ]
      
      
      #-----------------------------------------------------------------------------------------------
      # Index
      #-----------------------------------------------------------------------------------------------
  
      
      
      #-----------------------------------------------------------------------------------------------
      # Json
      #-----------------------------------------------------------------------------------------------
      jp = Module.get_attribute(__MODULE__, :json_provider, nil)
      djp = (jp == false)
      @__nzdo__repo_json_provider (!(djp || unquote(disable_json_imp))) && (unquote(json_provider) || Module.get_attribute(__MODULE__, :json_provider, Noizu.Poison.RepoEncoder))

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      if (__nzdo__json_provider = @__nzdo__repo_json_provider) do
        defimpl Poison.Encoder  do
          @__nzdo__repo_json_provider __nzdo__json_provider
          def encode(entity, options \\ nil), do: @__nzdo__repo_json_provider.encode(entity, options)
        end
      end





    end
  end



  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __before_compile__(_) do
    quote do
  
  
      #-----------------------------------------------------------------------------------------------
      # Core
      #-----------------------------------------------------------------------------------------------
  
  
      #################################################
      # __noizu_info__
      #################################################
      def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :repo)
      def __noizu_info__(:type), do: :repo
      def __noizu_info__(:kind), do: __kind__() # this is a gotcha since unlike most methods besides type the response is entity/repo dependent.
      def __noizu_info__(report), do: @__nzdo__base.__noizu_info__(report)
  
      #################################################
      # __fields__
      #################################################
      def __fields__, do: @__nzdo__base.__fields__
      def __fields__(setting), do: @__nzdo__base.__fields__(setting)
  
      #################################################
      # __enum__
      #################################################
      def __enum__(), do: @__nzdo__base.__enum__()
      def __enum__(property), do: @__nzdo__base.__enum__(property)
  
  
  
      defoverridable [
        __noizu_info__: 0,
        __noizu_info__: 1,
        __fields__: 0,
        __fields__: 1,
        __enum__: 0,
        __enum__: 1,
      ]
      
      #-----------------------------------------------------------------------------------------------
      # Persistence
      #-----------------------------------------------------------------------------------------------
      #################################################
      # __persistence__
      #################################################
      def __persistence__(), do: @__nzdo__base.__persistence__()
      def __persistence__(setting), do: @__nzdo__base.__persistence__(setting)
      def __persistence__(selector, setting), do: @__nzdo__base.__persistence__(selector, setting)

      #################################################
      # __nmid__
      #################################################
      def __nmid__(), do: @__nzdo__base.__nmid__()
      def __nmid__(setting), do: @__nzdo__base.__nmid__(setting)
  
  
  
      #-----------------------------------------------------------------------------------------------
      # Index
      #-----------------------------------------------------------------------------------------------
      #################################################
      # __indexing__
      #################################################
      def __indexing__(), do: @__nzdo__base.__indexing__()
      def __indexing__(setting), do: @__nzdo__base.__indexing__(setting)

      defoverridable [
        __indexing__: 0,
        __indexing__: 1
      ]
      
      #-----------------------------------------------------------------------------------------------
      # Json
      #-----------------------------------------------------------------------------------------------

      #################################################
      # __json__
      #################################################
      def __json__(), do: @__nzdo__base.__json__()
      def __json__(property), do: @__nzdo__base.__json__(property)

      defoverridable [
        __json__: 0,
        __json__: 1
      ]


    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  def __after_compile__(_env, _bytecode) do
    :ok
  end
end
