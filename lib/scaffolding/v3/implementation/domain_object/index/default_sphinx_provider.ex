defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Index.DefaultSphinxProvider do

  defmodule Default do

    #----------------------------
    # schema_open/1
    #----------------------------
    @doc """
      Output opening xml snippet for record set.
    """
    def schema_open() do
      """
      <?xml version="1.0" encoding="utf-8"?>
      <sphinx:docset>
      """
    end

    #----------------------------
    # schema_close/0
    #----------------------------
    @doc """
      Output closing xml snippet for record set.
    """
    def schema_close() do
      "</sphinx:docset>"
    end


    def extract_field(mod, field, entity, context, options), do: nil
    def fields(mod, context, options), do: nil
    def build(mod, type, context, options), do: nil


    def __schema_common__(mod, context, options) do
      settings = mod.__indexing__()[mod]
      field_options = Enum.map(settings[:fields], fn({field, indexing}) ->
        {field, indexing} = cond do
                              as = indexing[:as] -> {field, update_in(indexing, [:from], &(&1 || field))}
                              :else -> {field, indexing}
                            end
        cond do
          provider = indexing[:with] -> provider.__expand_fields__(field, indexing)
          :else -> {field, indexing}
        end
      end) |> List.flatten()

      Enum.map(field_options, fn({field,indexing}) ->
        encoding = indexing[:encoding] || settings[:options][:default][:encoding] || :attr_bigint
        bits = cond do
                 Map.has_key?(indexing, :bits) -> indexing[:bits]
                 Map.has_key?(settings[:options][:default][encoding] || %{}, :bits) -> settings[:options][:default][encoding][:bits]
                 bits = indexing[:with] && indexing[:with].__bits__(field, indexing, settings) ->
                   cond do
                     bits == :auto ->
                       case encoding do
                         :attr_uint -> 32
                         :attr_int -> 32
                         :attr_bigint -> 64
                         _ -> nil
                       end
                     :else -> bits
                   end
                 :else ->
                   case encoding do
                     :attr_uint -> 32
                     :attr_int -> 32
                     :attr_bigint -> 64
                     _ -> nil
                   end
               end
        {has_default?, default} = cond do
                                    Map.has_key?(indexing, :default) -> {true, indexing[:default]}
                                    indexing[:with] && indexing[:with].__has_default__(field, indexing, settings) -> {true, indexing[:with].__default__(field, indexing, settings)}
                                    :else -> {false, nil}
                                  end
        {field, encoding, bits, {has_default?, default}}
      end)
    end

    def schema(mod, :xml, context, options) do
      fields = mod.__schema_common__(context, options)
            |> Enum.map(fn({field, encoding, bits, {has_default?, default}}) ->
        bit_section = bits && " bits=\"#{bits}\" "
        default_section = has_default? && " default=\"#{default}\" "

        case encoding do
          :id -> nil
          :field -> "<sphinx:field name=\"#{field}\"/>"
          :attr_uint -> "<sphinx:attr name=\"#{field}\" type=\"bigint\" #{bit_section} #{default_section}  />"
          :attr_int -> "<sphinx:attr name=\"#{field}\" type=\"int\" #{bit_section} #{default_section}  />"
          :attr_bigint -> "<sphinx:attr name=\"#{field}\" type=\"bigint\" #{bit_section} #{default_section}  />"
          :attr_bool -> "<sphinx:attr name=\"#{field}\" type=\"bool\" #{default}  />"
          :attr_multi -> "<sphinx:attr name=\"#{field}\" type=\"multi\" #{default}  />"
          :attr_multi64 -> "<sphinx:attr name=\"#{field}\" type=\"multi\" #{default}  />"
          :attr_timestamp -> "<sphinx:attr name=\"#{field}\" type=\"timestamp\" #{default}  />"
          :attr_float -> "<sphinx:attr name=\"#{field}\" type=\"float\" #{default}  />"
          _ -> raise "#{mod}.#{field} has invalid encoding type #{inspect encoding}"
        end
      end) |> Enum.filter(&(&1))

      "<sphinx:schema>\n\t" <> Enum.join(fields, "\n\t") <> "\n</sphinx:schema>"
    end

    def update_index(mod, entity, context, options), do: nil
    def delete_index(mod, entity, context, options), do: nil

  end

  defmacro __using__(_options) do
    quote do
      alias Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Index.DefaultSphinxProvider.Default, as: SphinxProvider
      def extract_field(field, entity, context, options), do: SphinxProvider.extract_field(__MODULE__, field, entity, context, options)
      def fields(context, options), do: SphinxProvider.fields(__MODULE__, context, options)
      def build(type, context, options), do: SphinxProvider.build(__MODULE__, type, context, options)
      def __schema_common__(context, options), do: SphinxProvider.__schema_common__(__MODULE__, context, options)
      def schema(type, context, options), do: SphinxProvider.schema(__MODULE__, type, context, options)
      def update_index(entity, context, options), do: SphinxProvider.update_index(__MODULE__, entity, context, options)
      def delete_index(entity, context, options), do: SphinxProvider.delete_index(__MODULE__, entity, context, options)
    end
  end

  def __after_compile__(_env, _bytecode) do
    # Validate Generated Object
    :ok
  end

end
