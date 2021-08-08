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


    def extract_field(_mod, _field, _entity, _context, _options), do: nil
    def fields(_mod, _context, _options), do: nil
    def build(_mod, _type, _context, _options), do: nil


    def __index_schema_fields__(mod, _context, _options) do
      settings = mod.__indexing__()[mod]
      expanded_fields = Enum.map(
                          settings[:fields],
                          fn ({field, indexing}) ->
                            field_type = mod.__noizu_info__(:field_types)[field]
                            {field, indexing} = cond do
                                                  indexing[:as] -> {field, update_in(indexing, [:from], &(&1 || field))}
                                                  :else -> {field, indexing}
                                                end
                            cond do
                              provider = indexing[:with] && Kernel.function_exported?(indexing[:with], :__sphinx_field__, 0) && indexing[:with] ->
                                provider.__sphinx_expand_field__(field, indexing, settings)
                              provider = field_type[:handler] && Kernel.function_exported?(field_type[:handler], :__sphinx_field__, 0) && field_type[:handler] ->
                                provider.__sphinx_expand_field__(field, indexing, settings)
                              :else ->
                                {field, nil, indexing}
                            end
                          end
                        )
                        |> List.flatten()

      Enum.map(
        expanded_fields,
        fn ({field, provider, indexing}) ->
          provider_encoding_default = provider && provider.__sphinx_encoding__(field, indexing, settings)
          provider_bits_default = provider && provider.__sphinx_bits__(field, indexing, settings)
          encoding = cond do
                       v = indexing[:encoding] -> v
                       provider_encoding_default && provider_encoding_default != :auto -> provider_encoding_default
                       v = settings[:options][:default][:encoding] -> v
                       :else -> :attr_bigint
                     end
          bits = cond do
                   Map.has_key?(indexing, :bits) -> indexing[:bits]
                   provider && provider_bits_default != :auto -> provider_bits_default
                   Map.has_key?(settings[:options][:default][encoding] || %{}, :bits) -> settings[:options][:default][encoding][:bits]
                   encoding == :attr_uint -> 32
                   encoding == :attr_int -> 32
                   encoding == :attr_bigint -> 64
                   :else -> nil
                 end
          blob = cond do
                   indexing[:blob] == true -> :json
                   v = indexing[:blob] -> v
                   :else -> nil
                 end
          {has_default?, default} = cond do
                                      indexing[:no_default] -> {false, nil}
                                      Map.has_key?(indexing, :default) -> {true, indexing[:default]}
                                      provider && provider.__sphinx_has_default__(field, indexing, settings) -> {true, provider.__sphinx_default__(field, indexing, settings)}
                                      :else -> {false, nil}
                                    end
          {field, provider, blob, encoding, bits, indexing, {has_default?, default}}
        end
      )
    end

    def __index_header__(mod, :xml, context, options) do
      # strip down blob entries
      fields = mod.__index_schema_fields__(context, options)
               |> Enum.uniq_by(fn ({field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob && blob || field end)
               |> Enum.map(
                    fn ({field, _provider, blob, encoding, bits, _indexing, {has_default?, default}}) ->
                      cond do
                        blob ->
                          "<sphinx:field name=\"#{blob}\"/>"
                        :else ->
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
                      end
                    end
                  )
               |> Enum.filter(&(&1))

      "<sphinx:schema>\n\t" <> Enum.join(fields, "\n\t") <> "\n</sphinx:schema>"
    end



    def __index_header__(mod, :real_time, context, options) do
      index = mod.__rt_index__()
      raw = mod.__index_schema_fields__(context, options)
      blobs = raw
              |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
              |> Enum.map(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
              |> Enum.uniq
      base = raw
             |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob == nil end)
             |> Enum.map(fn ({field, _provider, _blob, _encoding, _bits, _indexing, _default}) -> field end)

      fields = Enum.map(base ++ blobs, &(Atom.to_string(&1)))
               |> Enum.join(", ")

      "REPLACE INTO #{index} (#{fields}) VALUES"
    end




    def __index_record__(mod, record_type, entity, context, options) do
      uid = Noizu.Ecto.Entity.universal_identifier(entity)
      settings = mod.__indexing__()[mod]
      raw = mod.__index_schema_fields__(context, options)
      blobs = raw
              |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
              |> Enum.map(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
              |> Enum.uniq
      base = raw
             |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob == nil end)
      base = base
             |> Enum.map(
                  fn ({field, provider, _blob, encoding, _bits, indexing, _default}) ->
                    value = cond do
                              provider -> provider.__sphinx_encoded__(field, entity, indexing, settings)
                              :else -> get_in(entity, [Access.key(indexing[:from] || field)])
                            end
                    {field, %{value: value, encoding: encoding}}
                  end
                )

      blobs = Enum.map(
        blobs,
        fn (for_blob) ->
          contents = raw
                     |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob == for_blob end)
                     |> Enum.map(
                          fn ({field, provider, _blob, _encoding, _bits, indexing, _default}) ->
                            value = cond do
                                      provider -> provider.__sphinx_encoded__(field, entity, indexing, settings)
                                      :else -> get_in(entity, [Access.key(indexing[:from] || field)])
                                    end
                            {field, value}
                          end
                        )
                     |> Map.new()
          case Poison.encode!(contents) do
            {:ok, json} -> {for_blob, %{value: json, encoding: :field}}
            _ -> {for_blob, %{value: "", encoding: :field}}
          end
        end
      )

      core = Map.new(base ++ blobs)
      i_fields = Enum.map(
        core,
        fn ({f, v}) ->


          formatted_value = cond do
            # Text Field
                              v.encoding == :field ->
                                cond do
                                  record_type == :real_time ->
                                    "'" <> mod.sql_escape_string(v.value) <> "'"
                                  :else ->
                                    cond do
                                      is_bitstring(v.value) -> v.value
                                      :else -> nil
                                    end
                                end

                              # Multi Part Attribute
                              (v.encoding == :attr_multi || v.encoding == :attr_multi64) ->
                                cond do
                                  record_type == :real_time -> "(" <> Enum.join(v.value || [], ",") <> ")"
                                  true -> Enum.join(v.value || [], ",")
                                end
                              v.encoding == :attr_float ->
                                case Noizu.Scaffolding.V3.Sphinx.Float.dump(v.value) do
                                  {:ok, v} -> v
                                end
                              v.encoding == :attr_bool ->
                                case Noizu.Scaffolding.V3.Sphinx.Bool.dump(v.value) do
                                  {:ok, true} -> 1
                                  {:ok, false} -> 0
                                  {:ok, v} -> v
                                end
                              v.encoding == :attr_timestamp -> v.value
                              Enum.member?([:attr_uint, :attr_bigint, :attr_int], v.encoding) ->
                                case Noizu.Scaffolding.V3.Sphinx.Integer.dump(v.value) do
                                  {:ok, v} -> v
                                end
                              :else -> throw "Invalid encoding for #{mod}.#{f}"
                            end
          cond do
            record_type == :real_time -> formatted_value
            :else -> {f, nil, formatted_value}
          end
        end
      )

      cond do
        record_type == :real_time ->
          [uid] ++ i_fields
        :else ->
          {:"sphinx:document", %{id: uid}, i_fields}
          |> XmlBuilder.generate
      end

    end

    def update_index(_mod, _entity, _context, _options), do: nil
    def delete_index(_mod, _entity, _context, _options), do: nil


    def sql_escape_string(nil), do: ""
    def sql_escape_string(value) when is_bitstring(value) do
      value
      |> HtmlSanitizeEx.strip_tags()
      |> Phoenix.HTML.javascript_escape()
    end

    def __config__(mod, context, options) do
      raw = mod.__index_schema_fields__(context, options)
      blobs = raw
              |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
              |> Enum.map(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> {blob, :field} end)
              |> Enum.uniq
      base = raw
             |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob == nil end)
             |> Enum.map(fn ({field, _provider, _blob, encoding, _bits, _indexing, _default}) -> {field, encoding} end)

      rt_fields = Enum.map(base ++ blobs, fn ({field, encoding}) -> "rt_#{encoding} = #{field}" end)
                  |> Enum.join("\n      ")

      """
      # =====================================================================
      # #{mod} : #{mod.__index_stem__()}
      # Generated Index Definition
      # =====================================================================
      source #{mod.__primary_source__()} : primary_source__base
      {
            xmlpipe_command = sphinx_xml_pipe primary #{mod.__index_stem__()}
      }

      source #{mod.__delta_source__()} : primary_source__base
      {
            xmlpipe_command = sphinx_xml_pipe delta #{mod.__index_stem__()}
      }

      index #{mod.__primary_index__()} : index__base
      {
            source = #{mod.__primary_source__()}
            path = #{mod.__data_dir__()}/#{mod.__primary_index__()}
      }
      index #{mod.__delta_index__()} : index__base
      {
            source = #{mod.__delta_source__()}
            path = #{mod.__data_dir__()}/#{mod.__delta_index__()}
      }

      index #{mod.__rt_index__()}
      {
            # @todo - make these settings in elixir indexing annotation
            type = rt
            dict = keywords
            morphology = stem_en
            min_stemming_len = 3
            min_word_len = 3
            html_strip = 1
            path = #{mod.__data_dir__()}/#{mod.__rt_index__()}

          #{rt_fields}
      }

      """

    end

  end

  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    index_stem = options[:index_stem]
    source_dir = options[:source_dir] || Application.get_env(:noizu_scaffolding, :sphinx_data_dir, "/sphinx/data")

    rt_index = options[:rt_index]
    delta_index = options[:delta_index]
    primary_index = options[:primary_index]

    rt_source = options[:rt_source]
    delta_source = options[:delta_source]
    primary_source = options[:primary_source]


    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      alias Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Index.DefaultSphinxProvider.Default, as: SphinxProvider

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def extract_field(field, entity, context, options), do: SphinxProvider.extract_field(__MODULE__, field, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def fields(context, options), do: SphinxProvider.fields(__MODULE__, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def build(type, context, options), do: SphinxProvider.build(__MODULE__, type, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __index_schema_fields__(context, options), do: SphinxProvider.__index_schema_fields__(__MODULE__, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __index_header__(type, context, options), do: SphinxProvider.__index_header__(__MODULE__, type, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __index_record__(type, entity, context, options), do: SphinxProvider.__index_record__(__MODULE__, type, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def update_index(entity, context, options), do: SphinxProvider.update_index(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete_index(entity, context, options), do: SphinxProvider.delete_index(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo__sref Module.get_attribute(@__nzdo__base, :__nzdo__sref)
      @index_stem unquote(index_stem) || @__nzdo__sref
      @rt_index unquote(rt_index) || :"rt_index__#{@index_stem}"
      @delta_index unquote(delta_index) || :"delta_index__#{@index_stem}"
      @primary_index unquote(primary_index) || :"primary_index__#{@index_stem}"
      @rt_source unquote(rt_source) || :"rt_source__#{@index_stem}"
      @delta_source unquote(delta_source) || :"delta_source__#{@index_stem}"
      @primary_source unquote(primary_source) || :"primary_source__#{@index_stem}"
      @data_dir unquote(source_dir)

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def __index_stem__(), do: @index_stem
      def __rt_index__(), do: @rt_index
      def __delta_index__(), do: @delta_index
      def __primary_index__(), do: @primary_index
      def __rt_source__(), do: @rt_source
      def __delta_source__(), do: @delta_source
      def __primary_source__(), do: @primary_source
      def __data_dir__(), do: @data_dir

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def sql_escape_string(v), do: SphinxProvider.sql_escape_string(v)
      def __config__(context, options), do: SphinxProvider.__config__(__MODULE__, context, options)

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      defoverridable [
        extract_field: 4,
        fields: 2,
        build: 3,
        __config__: 2,
        __index_schema_fields__: 2,
        __index_header__: 3,
        __index_record__: 4,
        update_index: 3,
        delete_index: 3,
        sql_escape_string: 1
      ]

    end
  end

  def __after_compile__(_env, _bytecode) do
    # Validate Generated Object
    :ok
  end

end
