#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.IdentifierTypeBehaviour do
  @moduledoc """
  IdentifierType Behavior
  ====================

  The `Noizu.DomainObject.IdentifierTypeBehaviour` module defines the behaviour for identifier types used in the
  Noizu.DomainObject framework. It provides functions for encoding, decoding, validating, and preparing regex patterns
  for identifier types.

  # Callbacks
  - `type/0`: Returns the type of the identifier.
  - `__valid_identifier__/2`: Checks if a provided value is correct for the identifier type.
  - `__sref_section_regex__/1`: Prepares a regex snippet for matching the identifier.
  - `__id_to_string__/2`: Encodes a valid identifier into a string for sref encoding.
  - `__string_to_id__/2`: Decodes a string into the identifier type.

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
  defmodule MyDomainObject do
  defmodule Entity do
    @behaviour Noizu.DomainObject.IdentifierTypeBehaviour

    @impl true
    def type, do: :atom

    @impl true
    def __valid_identifier__(identifier, configuration) do
      # Implementation logic
    end

    @impl true
    def __sref_section_regex__(configuration) do
      # Implementation logic
    end

    @impl true
    def __id_to_string__(identifier, configuration) do
      # Implementation logic
    end

    @impl true
    def __string_to_id__(string, configuration) do
      # Implementation logic
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
