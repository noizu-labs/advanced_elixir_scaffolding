#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SimpleObject do

  @doc """
  Begin configuring a Simple Object.
  @example ```
  defmodule Container do
    use Noizu.SimpleObject
    Noizu.SimpleObject.noizu_struct() do
      public_field :contents
    end
  end
  ```
  """
  defmacro __using__(options \\ nil) do
    nmid_generator = options[:nmid_generator]
    nmid_sequencer = options[:nmid_sequencer]
    nmid_index = options[:nmid_index]
    auto_generate = options[:auto_generate]
    caller = __CALLER__
    quote do
      require Noizu.SimpleObject
      require Noizu.AdvancedScaffolding.Internal.Helpers

      #-------------------------
      # Declare Annotation Attributes
      #-------------------------
      Module.register_attribute(__MODULE__, :index, accumulate: true)
      Module.register_attribute(__MODULE__, :persistence_layer, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: false)
      Module.register_attribute(__MODULE__, :json_white_list, accumulate: false)
      Module.register_attribute(__MODULE__, :json_format_group, accumulate: true)
      Module.register_attribute(__MODULE__, :json_field_group, accumulate: true)

      #---------------------
      # Insure Single Call
      #---------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__simple_defined, unquote(caller))

      #-----------------
      # Set Annotation fields if caller passed in options
      #-----------------
      if v = unquote(nmid_generator), do: Module.put_attribute(__MODULE__, :nmid_generator, v)
      if v = unquote(nmid_sequencer), do: Module.put_attribute(__MODULE__, :nmid_sequencer, v)
      if v = unquote(nmid_index), do: Module.put_attribute(__MODULE__, :nmid_index, v)
      if unquote(auto_generate) != nil, do: Module.put_attribute(__MODULE__, :auto_generate, unquote(auto_generate))
    end
  end

  @doc """
  Define simple object fields/settings.
  @example ```
  defmodule Container do
    use Noizu.SimpleObject
    Noizu.SimpleObject.noizu_struct() do
      public_field :contents
    end
  end
  ```
  """
  defmacro noizu_struct(options \\ [], [do: block]) do
    Noizu.AdvancedScaffolding.Internal.SimpleObject.Base.__noizu_struct__(__CALLER__, options, block)
  end

end
