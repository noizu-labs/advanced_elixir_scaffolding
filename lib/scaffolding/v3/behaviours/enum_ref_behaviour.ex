defmodule Noizu.EnumRefBehaviour do

  defmodule Default do

    def cast(m, v) do
      e = m.__entity__
      case v do
        true -> {:ok, nil}
        false ->{:ok, nil}
        nil -> {:ok, nil}
        0 -> {:ok, nil}
        v when is_atom(v) ->
          en = m.__ecto_type__
          identifier = en.atom_to_enum()[v]
          ref = identifier && e.ref(identifier)
          ref && {:ok, ref} || :error
        {:ref, ^e, _id} -> {:ok, v}
        %{__struct__: ^e} -> {:ok, v}
        v when is_integer(v) ->
          ref = e.ref(v)
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
        v when is_atom(v) ->
          en = m.__ecto_type__
          identifier = en.atom_to_enum()[v]
          ref = identifier && e.ref(identifier)
          ref && {:ok, ref} || raise ArgumentError, "Unsupported #{m} - #{inspect v}"
        {:ref, ^e, _id} -> {:ok, v}
        %{__struct__: ^e} -> {:ok, v}
        v when is_integer(v) ->
          ref = e.ref(v)
          ref && {:ok, ref} || raise ArgumentError, "Unsupported #{m} - #{inspect v}"
        _ -> raise ArgumentError, "Unsupported #{m} - #{inspect v}"
      end
    end

  end



  defmacro __using__(options) do
    entity = options[:entity]
    base = options[:base]
    ecto_type = options[:ecto_type] || :integer

    quote do
      use Ecto.Type
      @ref_entity unquote(entity)
      @enum_mod (case unquote(base) do
                   false -> Module.concat((Module.split(@ref_entity) |> Enum.slice(0..-2))  ++ ["Ecto.EnumType"])
                   nil -> Module.concat((Module.split(@ref_entity) |> Enum.slice(0..-2))  ++ ["Ecto.EnumType"])
                   :auto -> Module.concat((Module.split(@ref_entity) |> Enum.slice(0..-2))  ++ ["Ecto.EnumType"])
                   v when is_atom(v) -> Module.concat([v, "Ecto.EnumType"])
                   _ -> raise "#{__MODULE__} invalid base option"
                 end)

      @ecto_type unquote(ecto_type)

      #----------------------------
      # type
      #----------------------------
      def type, do: @ecto_type

      #----------------------------
      # __entity__
      #----------------------------
      def __entity__, do: @ref_entity
      def __ecto_type__, do: @enum_mod
      #----------------------------
      # cast
      #----------------------------
      @doc """
      Casts to Ref.
      """
      def cast(v), do: Noizu.EnumRefBehaviour.Default.cast(__MODULE__, v)

      #----------------------------
      # cast!
      #----------------------------
      @doc """
      Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
      """
      def cast!(v), do: Noizu.EnumRefBehaviour.Default.cast!(__MODULE__, v)

      #----------------------------
      # dump
      #----------------------------
      @doc false
      def dump(v), do: Noizu.EnumRefBehaviour.Default.dump(__MODULE__, v)

      #----------------------------
      # load
      #----------------------------
      def load(v), do: Noizu.EnumRefBehaviour.Default.load(__MODULE__, v)
    end
  end

end
