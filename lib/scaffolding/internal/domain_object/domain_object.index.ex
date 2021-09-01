defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Index do

  defmacro noizu_index(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Index.__noizu_index__(__CALLER__, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_index__(caller, options, block) do
    options = Macro.expand(options, __ENV__)
    core_configuration = Noizu.AdvancedScaffolding.Internal.Index.Behaviour.__configure__(options)
    core_implementation = Noizu.AdvancedScaffolding.Internal.Index.Behaviour.__implement__(options)

    #===----
    # Extension
    #===----
    extension_provider = options[:extension_implementation] || nil
    extension_block_a = extension_provider && quote do: (use unquote(extension_provider), unquote(options))
    extension_block_b = extension_provider && extension_provider.pre_defstruct(options)
    extension_block_c = extension_provider && extension_provider.post_defstruct(options)
    extension_block_d = extension_provider && quote do
                                                @before_compile unquote(extension_provider)
                                                @after_compile  unquote(extension_provider)
                                              end
    #===----
    # Process Config
    #===----
    process_config = quote do
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       import Noizu.ElixirCore.Guards

                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__index_defined, unquote(caller))

                       #---------------------
                       # Configure
                       #----------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       unquote(core_configuration)
                     end

    #===----
    # Implementation
    #===----
    quote do

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(process_config)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(core_implementation)

      #----------------------
      # User block section (define, fields, constraints, json_mapping rules, etc.)
      #----------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      try do
        unquote(extension_block_a)
        unquote(extension_block_b)
        unquote(block)
      after
        :ok
      end

      unquote(extension_block_c)

      # Post User Logic Hook and checks.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @before_compile Noizu.AdvancedScaffolding.Internal.Index.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Index.Behaviour

      unquote(extension_block_d)

      @file __ENV__.file
    end
  end
end
