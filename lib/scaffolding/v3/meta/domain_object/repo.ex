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
  @callback layer_pre_get_callback(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity_reference | entity | nil
  @callback layer_post_get_callback(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil

  @callback get!(ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback post_get_callback!(entity :: entity, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback layer_get!(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity | nil
  @callback layer_pre_get_callback!(layer :: layer, ref :: entity_reference, context :: Noizu.ElixirCore.CallingContext.t, options :: opts) :: entity_reference | entity | nil
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
    macro_file = __ENV__.file
    options = put_in(options || [], [:for_repo], true)
    process_config = quote do
                       poly_support = unquote(options[:poly_support])
                       @options unquote(options)

                       import Noizu.DomainObject, only: [file_rel_dir: 1]
                       require Amnesia
                       require Logger
                       require Amnesia.Helper
                       require Amnesia.Fragment
                       require Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                       import Noizu.ElixirCore.Guards
                       #---------------------
                       # Insure Single Call
                       #---------------------
                       if line = Module.get_attribute(__MODULE__, :__nzdo__repo_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_repo first defined on #{elem(line, 0)}:#{
                           elem(line, 1)
                         }"
                       end
                       @__nzdo__repo_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       # Extract Base Fields fields since SimbpleObjects are at the same level as their base.
                       @file unquote(macro_file) <> "<__prepare__base__macro__>"
                       Noizu.DomainObject.__prepare__base__macro__(unquote(options))

                       # Push details to Base, and read in required settings.
                       @file unquote(macro_file) <> "<__prepare__poly__macro__>"
                       Noizu.DomainObject.__prepare__poly__macro__(unquote(options))


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
                       # Derives
                       #----------------------
                       @__nzdo__derive Noizu.V3.EntityProtocol
                       @__nzdo__derive Noizu.V3.RestrictedProtocol


                       @__nzdo__allowed_refs (case (poly_support || Noizu.DomainObject.extract_attribute(:poly_support, nil)) do
                                                v  when is_list(v) -> Enum.uniq(v ++ [@__nzdo__entity])
                                                _ -> [@__nzdo__entity]
                                              end)

                       # Json Settings
                       @file unquote(macro_file) <> "<__prepare__json_settings__macro__>"
                       Noizu.DomainObject.__prepare__json_settings__macro__(unquote(options))

                       # Prep attributes for loading individual fields.
                       require Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                       @file unquote(macro_file) <> "<__register__field_attributes__macro__>"
                       Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__register__field_attributes__macro__(unquote(options))


                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                         @implement Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                         unquote(block)

                         if @__nzdo__fields == [] do
                           @ref @__nzdo__allowed_refs
                           public_field :entities
                           public_field :length
                           public_field :__transient__
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
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :async ->
          Amnesia.async do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :sync ->
          Amnesia.sync do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_tx ->
          Amnesia.Fragment.transaction do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_async ->
          Amnesia.Fragment.async do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_sync ->
          Amnesia.Fragment.sync do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        _ ->
          unquote(block)
      end
    end
  end

  defmacro __layer_transaction_block__(layer, options \\ [], [do: block]) do
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo.__layer_transaction_block__d(__CALLER__, layer, options, block)
  end

  def __layer_transaction_block__d(_caller, layer, _options, block) do
    quote do
      case is_map(unquote(layer)) && unquote(layer).tx_block do
        :none ->
          unquote(block)
        :tx ->
          Amnesia.transaction do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :async ->
          Amnesia.async do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :sync ->
          Amnesia.sync do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_tx ->
          Amnesia.Fragment.transaction do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_async ->
          Amnesia.Fragment.async do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_sync ->
          Amnesia.Fragment.sync do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
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

      #################################################
      #
      #################################################
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

      #################################################
      # __indexing__
      #################################################
      defdelegate __indexing__(), to: @__nzdo__base
      defdelegate __indexing__(setting), to: @__nzdo__base

      #################################################
      # __persistence__
      #################################################
      defdelegate __persistence__(), to: @__nzdo__base
      defdelegate __persistence__(setting), to: @__nzdo__base
      defdelegate __persistence__(selector, setting), to: @__nzdo__base

      #################################################
      # __nmid__
      #################################################
      defdelegate __nmid__(), to: @__nzdo__base
      defdelegate __nmid__(setting), to: @__nzdo__base

      #################################################
      # __noizu_info__
      #################################################
      def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :repo)
      def __noizu_info__(:type), do: :repo
      defdelegate __noizu_info__(report), to: @__nzdo__base

      #################################################
      # __fields__
      #################################################
      defdelegate __fields__, to: @__nzdo__base
      defdelegate __fields__(setting), to: @__nzdo__base

      #################################################
      # __enum__
      #################################################
      defdelegate __enum__(), to: @__nzdo__base
      defdelegate __enum__(property), to: @__nzdo__base

      #################################################
      # __json__
      #################################################
      defdelegate __json__(), to: @__nzdo__base
      defdelegate __json__(property), to: @__nzdo__base




    end
  end

end
