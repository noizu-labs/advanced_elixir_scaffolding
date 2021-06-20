#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo do
  #alias Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo, as: RepoMeta

  @type entity :: Map.t
  @type ref :: {:ref, atom, any}
  @type sref :: String.t
  @type layer :: Noizu.Scaffolding.V3.Schema.PersistenceLayer.t
  @type entity_reference :: ref | sref | entity | nil
  @type opts :: Keyword.t | Map.t | nil

  @callback cache(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback delete_cache(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

  @callback get(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback post_get_callback(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback layer_get(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback layer_pre_get_callback(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity_reference | entity |nil
  @callback layer_post_get_callback(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

  @callback get!(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback post_get_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback layer_get!(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback layer_pre_get_callback!(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity_reference | entity |nil
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

  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_repo__(caller, options, block) do
    crud_provider = options[:erp_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.DefaultCrudProvider
    internal_provider = options[:internal_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.DefaultInternalProvider
    process_config = quote do
                       import Noizu.DomainObject, only: [file_rel_dir: 1]
                       require Amnesia
                       require Amnesia.Helper
                       require Amnesia.Fragment
                       require Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                       #---------------------
                       # Insure Single Call
                       #---------------------
                       if line = Module.get_attribute(__MODULE__, :__nzdo__repo_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_repo first defined on #{elem(line,0)}:#{elem(line,1)}"
                       end
                       @__nzdo__repo_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       #---------------------
                       # Find Base
                       #---------------------
                       @__nzdo__base Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
                       if !Module.get_attribute(@__nzdo__base, :__nzdo__base_definied) do
                         raise "#{@__nzdo__base} must include use Noizu.DomainObject call."
                       end

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

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                         @implement Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                         unquote(block)
                       after
                         :ok
                       end





                     end

    quote do
      unquote(process_config)
      use unquote(crud_provider)

      # Post User Logic Hook and checks.
      @before_compile unquote(internal_provider)
      @before_compile Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
      @after_compile unquote(internal_provider)
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __transaction_block__(_options \\ [], [do: block]) do
    quote do
      case @__nzdo_top_layer_tx_block do
        :none ->
          unquote(block)
        :tx ->
          Amnesia.transaction do
            unquote(block)
          end
        :async ->
          Amnesia.async do
            unquote(block)
          end
        :sync ->
          Amnesia.sync do
            unquote(block)
          end
        :fragment_tx ->
          Amnesia.Fragment.transaction do
            unquote(block)
          end
        :fragment_async ->
          Amnesia.Fragment.async do
            unquote(block)
          end
        :fragment_sync ->
          Amnesia.Fragment.sync do
            unquote(block)
          end
        _ ->
          unquote(block)
      end
    end
  end

  defmacro __layer_transaction_block__(layer, _options \\ [], [do: block]) do
    quote do
      case unquote(is_map(layer) && layer.tx_block) do
        :none ->
          unquote(block)
        :tx ->
          Amnesia.transaction do
            unquote(block)
          end
        :async ->
          Amnesia.async do
            unquote(block)
          end
        :sync ->
          Amnesia.sync do
            unquote(block)
          end
        :fragment_tx ->
          Amnesia.Fragment.transaction do
            unquote(block)
          end
        :fragment_async ->
          Amnesia.Fragment.async do
            unquote(block)
          end
        :fragment_sync ->
          Amnesia.Fragment.sync do
            unquote(block)
          end
        _ ->
          unquote(block)
      end
    end
  end
  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __before_compile__(_) do
    quote do

      defdelegate vsn(), to: @__nzdo__base
      def __base__(), do: @__nzdo__base
      defdelegate __entity__(), to: @__nzdo__base
      def __repo__(), do: __MODULE__
      defdelegate __sref__(), to: @__nzdo__base
      defdelegate __erp__(), to: @__nzdo__base

      defdelegate id(ref), to: @__nzdo__base
      defdelegate ref(ref), to: @__nzdo__base
      defdelegate sref(ref), to: @__nzdo__base
      defdelegate entity(ref, options \\ nil), to: @__nzdo__base
      defdelegate entity!(ref, options \\ nil), to: @__nzdo__base
      defdelegate record(ref, options \\ nil), to: @__nzdo__base
      defdelegate record!(ref, options \\ nil), to: @__nzdo__base

      defdelegate __indexing__(), to: @__nzdo__base
      defdelegate __indexing__(setting), to: @__nzdo__base

      defdelegate __persistence__(setting \\ :all), to:  @__nzdo__base
      defdelegate __persistence__(selector, setting), to:  @__nzdo__base
      defdelegate __nmid__(), to: @__nzdo__base
      defdelegate __nmid__(setting), to: @__nzdo__base
      defdelegate __noizu_record__(type, ref, options \\ nil), to: @__nzdo__base

      def __noizu_info__(:type), do: :repo
      defdelegate __noizu_info__(report), to: @__nzdo__base
    end
  end

end
