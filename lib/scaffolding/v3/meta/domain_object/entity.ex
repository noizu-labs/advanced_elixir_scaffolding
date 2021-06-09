#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity do
  alias Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity, as: EntityMeta


  #--------------------------
  #
  #--------------------------
  defmacro identifier(type \\ :integer, opts \\ []) do
    quote do
      EntityMeta.__identifier__(__MODULE__, unquote(type), unquote(opts))
    end
  end

  def __identifier__(mod, type, _opts) do
    Module.put_attribute(mod, :__nzdo__identifier_type, type)
    __public_field__(mod, :identifier, nil, [])
  end


  #--------------------------
  #
  #--------------------------
  defmacro mysql_identifier(type \\ :integer, opts \\ []) do
    quote do
      EntityMeta.__mysql_identifier__(__MODULE__, unquote(type), unquote(opts))
    end
  end

  def __mysql_identifier__(mod, _type, _opts) do
    Module.put_attribute(mod, :__nzdo__has_mysql_field, true)
    __public_field__(mod, :mysql_identifier, nil, [])
  end


  #--------------------------
  #
  #--------------------------
  defmacro public_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__public_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __public_field__(mod, field, default, opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :public})
    if (opts[:type]), do: Module.put_attribute(mod, :__nzdo__field_types, {field, opts[:type]})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro public_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__public_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __public_fields__(mod, fields, default, opts) do
    Enum.map(fields, fn(field) ->
      __public_field__(mod, field, default, opts)
    end)
  end

  #--------------------------
  #
  #--------------------------
  defmacro private_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__private_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __private_field__(mod, field, default, opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :private})
    if (opts[:type]), do: Module.put_attribute(mod, :__nzdo__field_types, {field, opts[:type]})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro private_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__private_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __private_fields__(mod, fields, default, opts) do
    Enum.map(fields, fn(field) ->
      __private_field__(mod, field, default, opts)
    end)
  end

  #--------------------------
  #
  #--------------------------
  defmacro internal_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__internal_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __internal_field__(mod, field, default, opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :internal})
    if (opts[:type]), do: Module.put_attribute(mod, :__nzdo__field_types, {field, opts[:type]})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro internal_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__internal_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __internal_fields__(mod, fields, default, opts) do
    Enum.map(fields, fn(field) ->
      __internal_field__(mod, field, default, opts)
    end)
  end

end
