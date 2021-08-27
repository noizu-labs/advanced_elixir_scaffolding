defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Base do
  @moduledoc """
    Provides scaffolding for domain object top level module which in turn contains the nested Entity, Repo, Index, etc. modules.
  """

  defmacro __using__(options \\ nil) do
    options = Macro.expand(options, __ENV__)

    core_configuration = Noizu.AdvancedScaffolding.Internal.Core.Base.Behaviour.__configure__(options)
    persistence_configuration = Noizu.AdvancedScaffolding.Internal.Persistence.Base.Behaviour.__configure__(options)
    index_configuration = Noizu.AdvancedScaffolding.Internal.Index.Base.Behaviour.__configure__(options)
    json_configuration = Noizu.AdvancedScaffolding.Internal.Json.Base.Behaviour.__configure__(options)


    extension_provider = options[:extension_implementation] || nil
    extension_block_a = extension_provider && quote do
                                                use unquote(extension_provider)
                                                @before_compile unquote(extension_provider)
                                                @after_compile unquote(extension_provider)
                                              end

    quote do
      #---------------------
      # Insure Single Call
      #---------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      require Noizu.AdvancedScaffolding.Internal.Helpers
      Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__base_defined, unquote(__CALLER__))

      #---------------------
      # Config
      #---------------------
      unquote(core_configuration)
      unquote(persistence_configuration)
      unquote(index_configuration)
      unquote(json_configuration)

      #---------------------
      # Compile Hooks
      #---------------------
      @before_compile Noizu.AdvancedScaffolding.Internal.Core.Base.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Core.Base.Behaviour

      @before_compile Noizu.AdvancedScaffolding.Internal.Persistence.Base.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Persistence.Base.Behaviour

      @before_compile Noizu.AdvancedScaffolding.Internal.Index.Base.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Index.Base.Behaviour

      @before_compile Noizu.AdvancedScaffolding.Internal.Json.Base.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Json.Base.Behaviour

      unquote(extension_block_a)

    end
  end


end
