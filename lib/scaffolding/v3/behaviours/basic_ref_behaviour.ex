defmodule Noizu.BasicRefBehaviour do

  defmodule Default do

    def cast(m, v) do
      e = m.__entity__
      case v do
        true -> {:ok, nil}
        false -> {:ok, nil}
        nil -> {:ok, nil}
        0 -> {:ok, nil}
        {:ref, ^e, _id} -> {:ok, v}
        %{__struct__: ^e} -> {:ok, v}
        v when is_integer(v) ->
          ref = e.ref({:ecto_identifier, e, v})
          ref && {:ok, ref} || :error
        _ -> :error
      end
    end

    def cast!(m, value) do
      case m.cast(value) do
        {:ok, v} -> v
        :error -> raise Ecto.CastError, type: m, value: value
      end
    end

    def dump(_m, v) do
      cond do
        v == nil -> {:ok, 0}
        v = Noizu.Ecto.Entity.ecto_identifier(v) -> {:ok, v}
        :else -> {:ok, 0}
      end
    end

    def load(m, v) do
      e = m.__entity__
      case v do
        true -> {:ok, nil}
        false -> {:ok, nil}
        nil -> {:ok, nil}
        0 -> {:ok, nil}
        {:ref, ^e, _id} -> {:ok, v}
        %{__struct__: ^e} -> {:ok, v}
        v when is_integer(v) ->
          ref = e.ref({:ecto_identifier, e, v})
          ref && {:ok, ref} || raise ArgumentError, "Unsupported #{m} - #{inspect v}"
        _ -> raise ArgumentError, "Unsupported #{m} - #{inspect v}"
      end
    end

  end



  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    entity = options[:entity]
    ecto_type = options[:ecto_type] || :integer
    quote do
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      use Ecto.Type
      @ref_entity unquote(entity)
      @ecto_type unquote(ecto_type)

      #----------------------------
      # type
      #----------------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def type, do: @ecto_type

      #----------------------------
      # __entity__
      #----------------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def __entity__, do: @ref_entity

      #----------------------------
      # cast
      #----------------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      @doc """
      Casts to Ref.
      """
      def cast(v), do: Noizu.BasicRefBehaviour.Default.cast(__MODULE__, v)

      #----------------------------
      # cast!
      #----------------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      @doc """
      Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
      """
      def cast!(v), do: Noizu.BasicRefBehaviour.Default.cast!(__MODULE__, v)

      #----------------------------
      # dump
      #----------------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      @doc false
      def dump(v), do: Noizu.BasicRefBehaviour.Default.dump(__MODULE__, v)

      #----------------------------
      # load
      #----------------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def load(v), do: Noizu.BasicRefBehaviour.Default.load(__MODULE__, v)
    end
  end

end
