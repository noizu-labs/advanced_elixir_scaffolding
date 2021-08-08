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
    extension_provider = options[:extension_imp] || nil
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
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.DomainObject.__prepare__base__macro__(unquote(options))

                       # Push details to Base, and read in required settings.
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
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
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.DomainObject.__prepare__json_settings__macro__(unquote(options))

                       # Prep attributes for loading individual fields.
                       require Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__register__field_attributes__macro__(unquote(options))

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                         @implement Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                         unquote(extension_block_a)


                         unquote(block)

                         unquote(extension_block_b)

                         if @__nzdo__fields == [] do
                           @ref @__nzdo__allowed_refs
                           public_field :entities
                           public_field :length
                           @inspect [ignore: true]
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
      unquote(extension_block_c)

      # Post User Logic Hook and checks.
      @before_compile unquote(internal_provider)
      @before_compile Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
      @after_compile unquote(internal_provider)
      unquote(extension_block_d)
      @file __ENV__.file
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __transaction_block__(_options \\ [], [do: block]) do
    quote do
      #@file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
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
      #@file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
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
      def vsn(), do: @__nzdo__base.vsn()
      def __base__(), do: @__nzdo__base
      def __poly_base__(), do: @__nzdo__poly_base
      def __entity__(), do: @__nzdo__base.__entity__()
      def __repo__(), do: __MODULE__
      def __sref__(), do: @__nzdo__base.__sref__()
      def __erp__(), do: @__nzdo__base.__erp__()
      def id(ref), do: @__nzdo__base.id(ref)
      def ref(ref), do: @__nzdo__base.ref(ref)
      def sref(ref), do: @__nzdo__base.sref(ref)

      def entity(ref, options \\ nil), do: @__nzdo__base.entity(ref, options)
      def entity!(ref, options \\ nil), do: @__nzdo__base.entity!(ref, options)

      def record(ref, options \\ nil), do: @__nzdo__base.record(ref, options)
      def record!(ref, options \\ nil), do: @__nzdo__base.record!(ref, options)

      #################################################
      # __indexing__
      #################################################
      def __indexing__(), do: @__nzdo__base.__indexing__()
      def __indexing__(setting), do: @__nzdo__base.__indexing__(setting)

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

      #################################################
      # __noizu_info__
      #################################################
      def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :repo)
      def __noizu_info__(:type), do: :repo
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

      #################################################
      # __json__
      #################################################
      def __json__(), do: @__nzdo__base.__json__()
      def __json__(property), do: @__nzdo__base.__json__(property)




    end
  end

end
