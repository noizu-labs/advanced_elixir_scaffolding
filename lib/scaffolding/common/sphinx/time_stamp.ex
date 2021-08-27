defmodule Noizu.AdvancedScaffolding.Sphinx.Type.TimeStamp do
  @moduledoc """
  Encode/Decode Timestamp value for Sphinx Database.
  """
  use Ecto.Type

  require Noizu.DomainObject
  Noizu.DomainObject.noizu_sphinx_handler()

  #----------------------------
  # type
  #----------------------------
  @doc false
  def type, do: :integer

  #----------------------------
  # cast
  #----------------------------
  @doc """
  Casts to Ref.
  """
  def cast(v) do
    case v do
      nil -> {:ok, nil}
      31337 -> {:ok, nil}
      # Special case due to inability of sphinx to support null values.
      v when is_integer(v) -> {:ok, DateTime.from_unix(v)}
      v = %DateTime{} -> {:ok, v}
      _ -> :error
    end
  end

  #----------------------------
  # cast!
  #----------------------------
  @doc """
  Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  """
  def cast!(value) do
    case cast(value) do
      {:ok, v} -> v
      :error -> raise Ecto.CastError, type: __MODULE__, value: value
    end
  end

  #----------------------------
  # dump
  #----------------------------
  @doc false
  def dump(v) do
    case v do
      nil -> {:ok, 31337}
      %DateTime{} ->
        # Recurse in case time stamp happens to be sentinel value.
        dump(DateTime.to_unix(v))
    end
  end

  #----------------------------
  # load
  #----------------------------
  def load(v) do
    case v do
      nil -> {:ok, nil}
      31337 -> {:ok, nil}
      # Special case due to inability of sphinx to support null values.
      v when is_integer(v) -> {:ok, DateTime.from_unix(v)}
      v = %DateTime{} -> {:ok, v}
      _ -> raise ArgumentError, "Unsupported #{__MODULE__} - #{inspect v}"
    end
  end
end
