#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.IdentifierTypeBehaviour do
  @moduledoc """
  IdentifierType Behavior
  ====================
  
  Entity handlers for ecto/identifier keys, specified with the DomainObject.Entity identifier macro.
  - sref encoding,
  - validation
  - casting to redis/rdms appropriate format
  - etc.
  
  ## Example
  ```elixir
  defmodule DomainObject do
    defmodule Entity do
      Noizu.DomainObject.noizu_entity() do
        identifier :atom, constraint: [:foo, :bar, :bop]
        public_field :content
      end
    end
  end
  ```
  
  ## Example
  ```elixir
  defmodule DomainObject do
    defmodule Entity do
      Noizu.DomainObject.noizu_entity() do
        identifier My.CustomIdentifierType
        public_field :content
      end
    end
  end
  ```
  
  
  
  """
  
  @callback type() :: atom
  
  @doc """
  Check if provided value is correct for identifier type.
  """
  @callback __valid_identifier__(identifier :: any, configuration :: any) :: :ok | {:error, any}
  
  @doc """
  Prepare regex snippet for matching identifier
  """
  @callback __sref_section_regex__(configuration :: any) :: {:ok, String.t} | {:error, any}
  
  @doc """
  Encode valid identifier in string form for sref encoding.
  """
  @callback __id_to_string__(identifier :: any, configuration :: any) :: {:ok, String.t} | {:error, any}
  
  @doc """
  Decode string into identifier type.
  """
  @callback __string_to_id__(String.t, configuration :: any) :: {:ok, identifier :: any} | {:error, any}
end
