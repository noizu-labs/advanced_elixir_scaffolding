#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Json.Base do
  @moduledoc """
  Base Indexing Functionality
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types
    @callback __json__() :: any
    @callback __json__(any) :: any

    def __configure__(_options) do

    end


    defmacro __before_compile__(_env) do

      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.Json.Base.Behaviour

        #################################################
        # __json__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __json__(), do: __json__(:all)
        def __json__(:all) do
          Enum.map([:provider, :default, :formats, :white_list, :format_groups, :field_groups], &({&1, __json__(&1)}))
        end
        def __json__(:provider), do: @__nzdo__json_provider
        def __json__(:default), do: @__nzdo__json_format
        def __json__(:formats), do: @__nzdo__json_supported_formats
        def __json__(:white_list), do: @__nzdo__json_white_list
        def __json__(:format_groups), do: @__nzdo__json_format_groups
        def __json__(:field_groups), do: @__nzdo__json_field_groups


        @file __ENV__.file
      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end




end
