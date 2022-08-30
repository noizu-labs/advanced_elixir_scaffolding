#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Persistence.Repo do
  @moduledoc """
  ERP related DomainObject Implementation and Core Domain Object functionality.
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types

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


    def __configure__(options) do
      poly_support = options[:poly_support]

      quote do

        @behaviour Noizu.AdvancedScaffolding.Internal.Persistence.Repo.Behaviour


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


      end
    end


    def __implement__(_options) do
      quote do
        alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
        @__nzdo__repo_default Noizu.AdvancedScaffolding.Internal.Persistence.Repo.Implementation.Default


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
        def generate_identifier(), do: @__nzdo__repo_default.generate_identifier(__MODULE__)
        def generate_identifier!(), do: @__nzdo__repo_default.generate_identifier!(__MODULE__)

        #=====================================================================
        # Get
        #=====================================================================
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def get(ref, context), do: get(ref, context, [])
        def get(ref, context, options), do: @__nzdo__repo_default.get(__MODULE__, ref, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def get!(ref, context), do: get!(ref, context, [])
        def get!(ref, context, options), do: @__nzdo__repo_default.get!(__MODULE__, ref, context, options)

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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__(layer) do
            @__nzdo__repo_default.layer_get_identifier(__MODULE__, layer, ref, context, options)
          end
        end

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def layer_post_get_callback(%{__struct__: PersistenceLayer} = layer, entity, context, options), do: @__nzdo__repo_default.layer_post_get_callback(__MODULE__, layer, entity, context, options)
        def layer_post_get_callback!(%{__struct__: PersistenceLayer} = layer, entity, context, options) do
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__(layer) do
            @__nzdo__repo_default.layer_post_get_callback(__MODULE__, layer, entity, context, options)
          end
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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__transaction_block__() do
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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__(layer) do
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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__(layer) do
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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__transaction_block__() do
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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__(layer) do
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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__(layer) do
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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__(layer) do
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
          Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__(layer) do
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
      end
    end

    defmacro __before_compile__(_env) do
      quote do


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

      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end




end
