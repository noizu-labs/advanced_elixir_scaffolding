#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Index.Implementation.Default do
  @moduledoc """
  Default Implementation.
  """
  require Logger
  alias Giza.SphinxQL

  @doc """
    Maximum search results to index for query.
  """
  def __search_max_results__(m, conn, params, _context, options) do
    max_results = case Noizu.AdvancedScaffolding.Helpers.extract_setting(:positive_integer, "max_results", conn, params, nil, options) do
      {_, v} when is_integer(v) -> v
      _ -> m.__indexing__()[:options][:max_results]
    end
    max_results = min(max_results, m.__indexing__()[:max_result_limit])
    {:max_results, "option max_matches=#{max_results}"}
  end

  @doc """
  Query offset/limit pagination.
  """
  def __search_limit__(m, conn, params, _context, options) do
    page = Noizu.AdvancedScaffolding.Helpers.extract_setting(:positive_integer, "page", conn, params, 1, options) |> elem(1)
    rpp = Noizu.AdvancedScaffolding.Helpers.extract_setting(:positive_integer, "rpp", conn, params, m.__indexing__()[:rpp], options) |> elem(1)
    limit = Noizu.AdvancedScaffolding.Helpers.extract_setting(:positive_integer, "limit", conn, params, rpp, options) |> elem(1)
    skip = Noizu.AdvancedScaffolding.Helpers.extract_setting(:positive_integer, "offset", conn, params, 0, options) |> elem(1)

    clause = cond do
               page > 1 -> "LIMIT #{((page - 1) * rpp) + skip}, #{limit}"
               skip > 0 -> "LIMIT #{skip}, #{limit}"
               :else -> "LIMIT #{limit}"
             end
    {:limit, clause}
  end

  @doc """
  Text Match Search
  """
  def __search_content__(m, conn, params, _context, options) do
    case Noizu.AdvancedScaffolding.Helpers.extract_setting(:extract, "query", conn, params, nil, options)  do
      {_, v} when is_bitstring(v) -> {:match, m.sql_escape_string(v)}
      _ -> nil
    end
  end

  @doc """
  Search Order By
  """
  def __search_order_by__(_m, conn, params, indexes, _context, options) do
    indexes = Enum.map(indexes, fn(i) ->
      case i do
        {:field, {field, _query}} -> field
        {:field, field} -> field
        {:where, {field, _query}} -> field
        _ -> nil
      end
    end) |> Enum.filter(&(&1))

    indexes = MapSet.new(indexes ++["weight"])
    case Noizu.AdvancedScaffolding.Helpers.extract_setting(:extract, "order_by", conn, params, nil, options)  do
      {_, v} when is_bitstring(v) ->
        o = Enum.map(String.split(v, ","),
              fn(entry) ->
                case Regex.run(~r/^([a-zA-Z_0-9]*) *(ASC|DESC)?$/, String.trim(entry)) do
                  [_, ""] -> nil
                  [_, "", _d] -> nil
                  [_, v] -> Enum.member?(indexes, v) && {v, "#{v} DESC"} || nil
                  [_, v, "ASC"] -> Enum.member?(indexes, v) && {v, "#{v} ASC"} || nil
                  [_, v, "DESC"] -> Enum.member?(indexes, v) && {v, "#{v} DESC"} || nil
                  _ -> nil
                end
              end)  |> Enum.filter(&(&1))
        case o do
          [] -> nil
          _ ->
            a = Enum.map(o, fn({v,_}) -> v end) -- ["weight"]
            o = Enum.map(o, fn({_,v}) -> v end)
            {:order_by, {a, "ORDER BY " <> Enum.join(o, ", ")}}
        end
      _ -> nil
    end
  end

  def __search_indexes__(m, conn, params, context, options) do
    Enum.map(m.__indexing__.fields, fn({field, field_options}) ->
      cond do
        handler = field_options[:with] ->
          cond do
            {:__search_clauses__, 6} in handler.module_info(:exports) -> handler.__search_clauses__(m, {field, field_options}, conn, params, context, options)
            :else -> []
         end
        :else -> []
      end
    end) |> List.flatten() |> Enum.filter(&(&1))
  end

  def search_query(m, conn, params, context, options) do
    limit = m.__search_limit__(conn, params, context, options)
    max = m.__search_max_results__(conn, params, context, options)
    content = m.__search_content__(conn, params, context, options)
    fields = m.__search_indexes__(conn, params, context, options)
    order_by = m.__search_order_by__(conn, params, fields, context, options)
    m.__build_search_query__([limit, max, content, order_by], fields, context, options)
  end
  def __build_search_query__(m, index_clauses, field_clauses, _context, options) do
    index_clauses |> Enum.filter(&(&1)) |> List.flatten() |> Enum.filter(&(&1))
    field_clauses |> Enum.filter(&(&1)) |> List.flatten() |> Enum.filter(&(&1))


    #===---
    # order_by, additional_fields
    #===---
    {additional_fields, order_by} = Enum.find(index_clauses, fn(v) ->
      case v do
        {:order_by, _} -> true
        _ -> false
      end
    end) |> case do
              {:order_by, c} -> c
              _ -> {[], nil}
            end
    order_by = case(order_by) do
                 v when is_bitstring(v) -> v
                 _ -> "ORDER BY weight DESC"
               end

    #===---
    # fields
    #===---
    fields = Enum.map([{:field, "id"}, {:field, "WEIGHT() as weight"}] ++ field_clauses, fn(v) ->
      case v do
        {:field, {_, c}} -> c
        {:field, c} -> c
        _ -> nil
      end
    end) |> Enum.filter(&(&1))
    fields = (fields ++ additional_fields) |> Enum.map(&(String.replace(&1, ".", "_"))) |> Enum.uniq() |> Enum.join(", ")

    #===---
    # where
    #===---
    join = case options[:join_with] do
             :and -> " AND "
             :or -> " OR "
             _ -> " AND "
           end
    where = Enum.map(field_clauses, fn(v) ->
      case v do
        {:where, {_,c}} -> c
        {:where, c} -> c
        _ -> nil
      end
    end) |> Enum.filter(&(&1)) |> case do
                 [] -> ""
                 v -> "WHERE " <> Enum.join(v, join)
               end

    #===---
    # limit
    #===---
    limit = Enum.find(index_clauses, fn(v) ->
      case v do
        {:limit, _} -> true
        _ -> false
      end
    end) |> case() do
                 {:limit, c} -> c
                 _ -> ""
               end

    #===---
    # max_results
    #===---
    max_results = Enum.find(index_clauses, fn(v) ->
      case v do
        {:max_results, _} -> true
        _ -> false
      end
    end) |> case() do
              {:max_results, c} -> c
              _ -> "LIMIT 250"
            end


    #===---
    # indexes
    #===---
    indexes = [m.__rt_index__(), m.__delta_index__(), m.__primary_index__()] |> Enum.filter(&(&1)) |> Enum.join(", ")

    "SELECT #{fields} FROM #{indexes} #{where} #{order_by} #{limit} #{max_results}"
  end

  def search(m, conn, params, context, options) do
    query = m.search_query(conn, params, context, options) |> IO.inspect
    results = case SphinxQL.new() |> SphinxQL.raw(query) |> SphinxQL.send() |> IO.inspect do
                {:ok, response} ->
                  fields = Enum.zip(response.fields, 0..length(response.fields)) |> Map.new()
                  field_map = %{"id" => :identifier, "weight" => :weight}
                  response.matches
                  |> Task.async_stream(
                       fn(record) ->
                         universal_identifier = List.first(record)
                         entity = {:todo, :load, {:universal, universal_identifier}}
                         (Enum.map(0..(length(fields) - 1), fn(index) ->
                                                              f = fields[index]
                                                              {field_map[f] || f, Enum.at(record, index + 1)}
                         end) ++ [{:record, entity}]) |> Map.new()
                       end, max_concurrency: 32, limit: 60_000
                     )
                  |> Enum.map(fn({:ok, v}) -> v end)
                  |> Enum.filter(&(&1))
                _ ->
                  []
              end
    # todo search result entity
    %{results: results}
  end





  def update_index(_mod, _entity, _context, _options), do: nil
  def delete_index(_mod, _entity, _context, _options), do: nil
  def fields(_mod, _context, _options), do: nil
  def build(_mod, _type, _context, _options), do: nil

  def sql_escape_string(nil), do: ""
  def sql_escape_string(value) when is_bitstring(value) do
    value
    |> HtmlSanitizeEx.strip_tags()
    |> Phoenix.HTML.javascript_escape()
  end

  #----------------------------
  # schema_open/1
  #----------------------------
  @doc """
    Output opening xml snippet for record set.
  """
  def __schema_open__() do
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
  def __schema_close__() do
    "</sphinx:docset>"
  end

  def __extract_field__(_mod, _field, _entity, _context, _options), do: nil

  def __index_schema_fields__(mod, _context, options) do
    settings = mod.__indexing__()[mod]
    expanded_fields = Enum.map(
                        settings[:fields] || [],
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
                      |> Enum.sort_by(&(elem(&1, 0)))
    fields = Enum.map(
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
    cond do
      options[:ordered] ->
        # Groups of multiple fields we can compact into a single blob field. Default :json
        blobs = fields
                |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
                |> Enum.map(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
                |> Enum.uniq()
                |> Enum.sort_by(&(&1))
        base = fields
               |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob == nil end)
               |> Enum.map(fn ({field, _provider, _blob, _encoding, _bits, _indexing, _default}) -> field end)
               |> Enum.sort_by(&(&1))
        base ++ blobs

      :else -> fields
    end

  end

  def __index_supported__?(mod, _type, _context, _options) do
    fields = mod.__indexing__()[mod][:fields]
    (is_list(fields) && length(fields) > 0) && true || false
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

    cond do
      options[:raw] -> fields
      :else -> "<sphinx:schema>\n\t" <> Enum.join(fields, "\n\t") <> "\n</sphinx:schema>"
    end
  end
  def __index_header__(mod, :real_time, context, options) do
    index = mod.__rt_index__()
    fields = mod.__index_schema_fields__(context, put_in(options || [], [:ordered], true))
             |> Enum.map(&(Atom.to_string(&1)))
             |> Enum.join(", ")
    cond do
      options[:raw] -> fields
      :else -> "REPLACE INTO #{index} (#{fields}) VALUES"
    end
  end

  def __index_record__(mod, record_type, entity, context, options) do
    uid = Noizu.EctoEntity.Protocol.universal_identifier(entity)
    settings = mod.__indexing__()[mod]
    raw = mod.__index_schema_fields__(context, options)

    # Obtain Base and ob Fields
    base_fields = raw
                  |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob == nil end)
                  |> Enum.sort_by(&(elem(&1,0)))
    blob_fields = raw
                  |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
                  |> Enum.map(fn (field = {_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> {blob, field} end)
    blobs = Keyword.keys(blob_fields) |> Enum.uniq |> Enum.sort_by(&(&1))


    # Prepare Base Fields
    base = base_fields
           |> Enum.map(
                fn ({field, provider, _blob, encoding, _bits, indexing, _default}) ->
                  value = cond do
                            provider -> provider.__sphinx_encoded__(field, entity, indexing, settings)
                            :else -> get_in(entity, [Access.key(indexing[:from] || field)])
                          end
                  {field, %{value: value, encoding: encoding}}
                end
              )

    # Prepare Blobs
    blobs = Enum.map(
      blobs,
      fn (for_blob) ->

        contents = Keyword.get_values(blob_fields, for_blob)
                   |> Enum.map(
                        fn ({field, provider, _blob, _encoding, _bits, indexing, _default}) ->
                          value = cond do
                                    provider = (provider || indexing[:with]) -> provider.__sphinx_encoded__(field, entity, indexing, settings)
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
                                :else -> Enum.join(v.value || [], ",")
                              end
                            v.encoding == :attr_float ->
                              case Noizu.AdvancedScaffolding.Sphinx.Type.Float.dump(v.value) do
                                {:ok, v} -> v
                                :error ->
                                  Logger.warn("Sphinx: #{entity && entity.__struct__} unable to cast as #{inspect v.encoding} - #{inspect f} - [#{inspect v.value}]")
                                  {:ok, v} = Noizu.AdvancedScaffolding.Sphinx.Type.Float.dump(nil)
                                  v
                              end
                            v.encoding == :attr_bool ->
                              case Noizu.AdvancedScaffolding.Sphinx.Type.Bool.dump(v.value) do
                                {:ok, true} -> 1
                                {:ok, false} -> 0
                                {:ok, v} -> v
                                :error ->
                                  Logger.warn("Sphinx: #{entity && entity.__struct__} unable to cast as #{inspect v.encoding} - #{inspect f} - [#{inspect v.value}]")
                                  {:ok, v} = Noizu.AdvancedScaffolding.Sphinx.Type.Bool.dump(nil)
                                  v
                              end
                            v.encoding == :attr_timestamp ->
                              v.value
                            Enum.member?([:attr_uint, :attr_bigint, :attr_int], v.encoding) ->
                              case Noizu.AdvancedScaffolding.Sphinx.Type.Integer.dump(v.value) do
                                {:ok, v} -> v
                                :error ->
                                  Logger.warn("Sphinx: #{entity && entity.__struct__} unable to cast as #{inspect v.encoding} - #{inspect f} - [#{inspect v.value}]")
                                  {:ok, v} = Noizu.AdvancedScaffolding.Sphinx.Type.Integer.dump(nil)
                                  v
                              end
                            :else -> throw "Invalid encoding for #{mod}.#{f}"
                          end
        cond do
          options[:debug] -> {f, formatted_value}
          record_type == :real_time -> formatted_value
          :else -> {f, nil, formatted_value}
        end
      end
    )

    cond do
      options[:debug] -> Map.new([{:identifier, uid}] ++ i_fields)
      record_type == :real_time ->
        [uid] ++ i_fields
      :else ->
        {:"sphinx:document", %{id: uid}, i_fields}
        |> XmlBuilder.generate
    end

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





  #===---------
  # __expand_indexes__
  #===---------
  def __expand_indexes__(nil, base), do: __expand_indexes__(%{}, base)
  def __expand_indexes__([], base), do: __expand_indexes__(%{}, base)
  def __expand_indexes__(indexes, base) do
    Enum.map(indexes, &(__expand_index__(&1, base)))
    |> Enum.filter(&(&1))
    |> Map.new()
  end


  @default_rpp 250
  @default_max_results 25_000
  @default_max_result_limit 1_000_000_000
  #===---------
  # __expand_index__
  #===---------
  def __expand_index__(l, base) do
    {indexer, options} = case l do
      {{:inline, type}, options} when is_list(options) or is_map(options) -> __inline_indexer__(base, type, options)
      {[{:inline, type}], options} when is_list(options) or is_map(options) -> __inline_indexer__(base, type, options)
      [{:inline, type}] when is_atom(type) -> __inline_indexer__(base, type, [])
      {:inline, type} when is_atom(type) -> __inline_indexer__(base, type, [])
      {indexer, options} when is_atom(indexer) and is_map(options) ->
        {indexer, %{options: options, fields: %{}}}
      {indexer, options} when is_atom(indexer) and is_list(options) ->
        {indexer, %{options: Map.new(options), fields: %{}}}
      indexer when is_atom(indexer) ->
        {indexer, %{options: %{}, fields: %{}}}
      _ -> raise "Invalid @index annotation #{inspect l}"
    end
    options = options
              |> update_in([:rpp], &(&1 || @default_rpp))
              |> update_in([:max_results], &(&1 || @default_max_results))
              |> update_in([:max_result_limit], &(&1 || @default_max_result_limit))
    {indexer, options}
  end

  #===---------
  # __inline_indexer__
  #===---------
  def __inline_indexer__(base, type, options) when is_list(options) do
    indexer = __domain_object_indexer__(base)
    cond do
      Module.open?(base) -> Module.put_attribute(base, :__nzdo__inline_index, true)
      :else -> raise "Inline Index not possible when base Module is closed"
    end
    {indexer, %{options: Map.new(put_in(options, [:indexer], type)), fields: %{}}}
  end
  def __inline_indexer__(base, type, options) when is_map(options) do
    indexer = __domain_object_indexer__(base)
    cond do
      Module.open?(base) -> Module.put_attribute(base, :__nzdo__inline_index, true)
      :else -> raise "Inline Index not possible when base Module is closed"
    end
    {indexer, %{options: Map.new(put_in(options, [:indexer], type)), fields: %{}}}
  end

  #===---------
  # __domain_object_indexer__
  #===---------
  def __domain_object_indexer__(base) when is_atom(base) do
    Module.concat([base, "Index"])
  end




end

