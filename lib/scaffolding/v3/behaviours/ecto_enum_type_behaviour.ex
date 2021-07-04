defmodule Noizu.Ecto.EnumTypeBehaviour do
  defmodule Default do



    @doc """
    Casts to Enum.
    """
    def cast(m, v) when is_atom(v) do
      cond do
        v == nil -> {:ok, m.enum_to_atom(m.default_value())}
        m.atom_to_enum(v) -> {:ok, v}
        true -> :error
      end
    end
    def cast(m, v) when is_integer(v) do
      cond do
        a = m.enum_to_atom(v) -> {:ok, a}
        :else -> :error
      end
    end
    def cast(_m, _), do: :error

    @doc """
    Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
    """
    def cast!(m, value) do
      case m.cast(value) do
        {:ok, v} -> v
        :error -> raise Ecto.CastError, type: m, value: value
      end
    end


    def dump(m, v) when is_atom(v) do
      cond do
        v == nil -> {:ok, m.atom_to_enum(m.default_value())}
        e = m.atom_to_enum(v) -> {:ok, e}
        :else -> :error
      end
    end
    def dump(m, v) when is_integer(v) do
      cond do
        m.enum_to_atom(v) -> {:ok, v}
        true -> :error
      end
    end
    def dump(_m, _), do: :error

    def load(m, v) when is_integer(v) do
      cond do
        a = m.enum_to_atom(v) -> {:ok, a}
        true -> raise ArgumentError, "Unsupported #{m} Enum #{inspect v}"
      end
    end
    def load(m, v) when is_atom(v) do
      cond do
        v == nil -> {:ok, m.enum_to_atom(m.default_value())}
        m.atom_to_enum(v) -> {:ok, v}
        true -> raise ArgumentError, "Unsupported #{m} Enum #{inspect v}"
      end
    end
    def load(m, v) do
      raise ArgumentError, "Unsupported #{m} Enum #{inspect v}"
    end


  end

  defmacro __using__(options) do
    quote do
      use Ecto.Type
      @ecto_type (unquote(options[:ecto_type]) || :integer)
      @default_value (unquote(options[:default]) || :none)


      raw_atom_list = (unquote(options[:values]) || [{:none, 0}])
                      |> Enum.map(
                           fn
                             ({k,{v,d}}) -> {k, v, "#{d}"}
                             ({k,v}) -> {k, v, nil}
                           end
                         )
      @atom_to_enum Enum.map(raw_atom_list, fn({k,v,_}) -> {k,v} end) |> Map.new()
      @atom_descriptions Enum.map(raw_atom_list, fn({k,_,d}) -> d && {k,d} end) |> Enum.filter(&(&1)) |> Map.new()

      @enum_to_atom Enum.map(@atom_to_enum, fn ({a, e}) -> {e, a} end)
                    |> Map.new()
      @json_to_atom Enum.map(@atom_to_enum, fn ({a, _e}) -> {"#{a}", a} end)
                    |> Map.new()


      def value_description(enum) when is_atom(enum) do
        Map.has_key?(@atom_to_enum, enum) && (@atom_descriptions[enum] || "no description") || throw "#{enum} is not a member of #{__MODULE__}"
      end
      def value_description(enum) when is_integer(enum) do
        enum = @enum_to_atom[enum] || throw "#{enum} enum not found in #{__MODULE__}"
        @atom_descriptions[enum] || "no description"
      end

      def default_value(), do: @default_value
      def atom_to_enum(), do: @atom_to_enum
      def atom_to_enum(k), do: atom_to_enum()[k]
      def enum_to_atom(), do: @enum_to_atom
      def enum_to_atom(k), do: enum_to_atom()[k]
      def json_to_atom(), do: @json_to_atom
      def json_to_atom(k), do: json_to_atom()[k]

      @doc false
      def type, do: @ecto_type

      @doc """
      Casts to Enum.
      """
      def cast(v), do: Noizu.Ecto.EnumTypeBehaviour.Default.cast(__MODULE__, v)

      @doc """
      Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
      """
      def cast!(v), do: Noizu.Ecto.EnumTypeBehaviour.Default.cast!(__MODULE__, v)

      def dump(v), do: Noizu.Ecto.EnumTypeBehaviour.Default.dump(__MODULE__, v)

      def load(v), do: Noizu.Ecto.EnumTypeBehaviour.Default.load(__MODULE__, v)

    end
  end
end
