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


  defmacro enum_type(options \\ nil) do
    options = Macro.expand(options, __ENV__)
    Noizu.Ecto.EnumTypeBehaviour.__enum_type__(options)
  end

  def __enum_type__(_options) do
    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      use Ecto.Type

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      domain_object = Module.split(__MODULE__) |> Enum.slice(0 .. -3) |> Module.concat
      @__nzdo__base domain_object
      {values, default_value, ecto_type} = case Module.get_attribute(domain_object, :__nzdo__enum_list) do
                                             {v, o} ->
                                               {
                                                 v,
                                                 o[:default_value] || Module.get_attribute(domain_object , :__nzdo__enum_default_value) || :none,
                                                 o[:ecto_type] || Module.get_attribute(domain_object, :__nzdo__enum_ecto_type) || :integer
                                               }
                                             v when is_list(v) ->
                                               {
                                                 v,
                                                 Module.get_attribute(domain_object, :__nzdo__enum_default_value) || :none,
                                                 Module.get_attribute(domain_object, :__nzdo__enum_ecto_type) || :integer
                                               }
                                             :callback ->
                                               {
                                                 :callback,
                                                 Module.get_attribute(domain_object, :__nzdo__enum_default_value) || :none,
                                                 Module.get_attribute(domain_object, :__nzdo__enum_ecto_type) || :integer
                                               }
                                           end

     @ecto_type ecto_type || :integer
      @default_value default_value || :none

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def default_value(), do: @default_value

      if values == :callback do
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def description(enum), do: @__nzdo__base.description(enum)
        def atom_to_enum(), do: @__nzdo__base.atom_to_enum()
        def atom_to_enum(k), do: @__nzdo__base.atom_to_enum(k)
        def enum_to_atom(), do: @__nzdo__base.enum_to_atom()
        def enum_to_atom(k), do: @__nzdo__base.enum_to_atom(k)
        def json_to_atom(), do: @__nzdo__base.json_to_atom()
        def json_to_atom(k), do: @__nzdo__base.json_to_atom(k)
      else
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        raw_atom_list = (values || [{:none, 0}])
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

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def description(enum) when is_atom(enum) do
          Map.has_key?(@atom_to_enum, enum) && (@atom_descriptions[enum] || "no description") || throw "#{enum} is not a member of #{__MODULE__}"
        end

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def description(enum) when is_integer(enum) do
          enum = @enum_to_atom[enum] || throw "#{enum} enum not found in #{__MODULE__}"
          @atom_descriptions[enum] || "no description"
        end

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def atom_to_enum(), do: @atom_to_enum
        def atom_to_enum(k), do: atom_to_enum()[k]
        def enum_to_atom(), do: @enum_to_atom
        def enum_to_atom(k), do: enum_to_atom()[k]
        def json_to_atom(), do: @json_to_atom
        def json_to_atom(k), do: json_to_atom()[k]
      end





      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc false
      def type, do: @ecto_type

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Casts to Enum.
      """
      def cast(v), do: Noizu.Ecto.EnumTypeBehaviour.Default.cast(__MODULE__, v)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
      """
      def cast!(v), do: Noizu.Ecto.EnumTypeBehaviour.Default.cast!(__MODULE__, v)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def dump(v), do: Noizu.Ecto.EnumTypeBehaviour.Default.dump(__MODULE__, v)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def load(v), do: Noizu.Ecto.EnumTypeBehaviour.Default.load(__MODULE__, v)
    end
  end

  defmacro __using__(options \\ nil) do
    options = Macro.expand(options, __ENV__)
    Noizu.Ecto.EnumTypeBehaviour.__enum_type__(options)
  end
end
