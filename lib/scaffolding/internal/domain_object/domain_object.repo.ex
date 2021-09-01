defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Repo do


  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_repo__(caller, options, block) do
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

    core_configuration = Noizu.AdvancedScaffolding.Internal.Core.Repo.Behaviour.__configure__(options)
    core_implementation = Noizu.AdvancedScaffolding.Internal.Core.Repo.Behaviour.__implement__(options)

    persistence_configuration = Noizu.AdvancedScaffolding.Internal.Persistence.Repo.Behaviour.__configure__(options)
    persistence_implementation = Noizu.AdvancedScaffolding.Internal.Persistence.Repo.Behaviour.__implement__(options)

    index_configuration = Noizu.AdvancedScaffolding.Internal.EntityIndex.Repo.Behaviour.__configure__(options)
    index_implementation = Noizu.AdvancedScaffolding.Internal.EntityIndex.Repo.Behaviour.__implement__(options)

    json_configuration = Noizu.AdvancedScaffolding.Internal.Json.Repo.Behaviour.__configure__(options)
    json_implementation = Noizu.AdvancedScaffolding.Internal.Json.Repo.Behaviour.__implement__(options)

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
                       unquote(core_configuration)
                       unquote(persistence_configuration)
                       unquote(index_configuration)
                       unquote(json_configuration)

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


      unquote(core_implementation)
      unquote(persistence_implementation)
      unquote(index_implementation)
      unquote(json_implementation)

      unquote(extension_block_c)

      # Post User Logic Hook and checks.
      @before_compile Noizu.AdvancedScaffolding.Internal.Core.Repo.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Core.Repo.Behaviour

      @before_compile Noizu.AdvancedScaffolding.Internal.Persistence.Repo.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Persistence.Repo.Behaviour

      @before_compile Noizu.AdvancedScaffolding.Internal.EntityIndex.Repo.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.EntityIndex.Repo.Behaviour

      @before_compile Noizu.AdvancedScaffolding.Internal.Json.Repo.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Json.Repo.Behaviour

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

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __layer_transaction_block__(layer, options \\ [], [do: block]) do
    Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__layer_transaction_block__d(__CALLER__, layer, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
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





    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  def __after_compile__(_env, _bytecode) do

  end
end
