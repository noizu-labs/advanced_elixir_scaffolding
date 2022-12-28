#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Index do
  
  defmodule Behaviour do
    alias Noizu.AdvancedScaffolding.Types
    alias Noizu.ElixirCore.CallingContext
    
    alias Noizu.AdvancedScaffolding.Types, as: T
    
    @callback has_query_permission?(field :: atom, filter :: atom | tuple, context :: CallingContext.t, options :: list | map()) :: true | false | :inherit
    
    @callback __indexing__() :: any
    @callback __indexing__(any) :: any
    
    @callback __search_clause__(seach_clause :: T.search_clauses,  conn :: Plug.Conn.t, params :: map(), context :: CallingContext.t, options :: list | map()) :: T.index_query_clause | T.error
    
    @callback __search_max_results__(conn :: Plug.Conn.t, params :: map(), context :: CallingContext.t, options :: list | map()) :: T.index_query_clause | T.error
    @callback __search_limit__(conn :: Plug.Conn.t, params :: map(), context :: CallingContext.t, options :: list | map()) :: T.index_query_clause | T.error
    @callback __search_content__(conn :: Plug.Conn.t, params :: map(), context :: CallingContext.t, options :: list | map()) :: T.index_query_clause | T.error
    @callback __search_order_by__(conn :: Plug.Conn.t, params :: map(), indexes :: [T.index_query_clause],  context :: CallingContext.t, options :: list | map()) :: T.index_query_clause | T.error
    @callback __search_indexes__(conn :: Plug.Conn.t, params :: map(), context :: CallingContext.t, options :: list | map()) :: T.index_query_clause | T.error
    
    @callback search_query(conn :: Plug.Conn.t, params :: map(), context :: CallingContext.t, options :: list | map()) :: T.query_snippet
    @callback __build_search_query__(index_clauses :: [T.index_query_clause], filter_clauses :: [T.field_query_clause], context :: CallingContext.t, options :: list | map()) :: T.query_snippet
    
    @callback search(conn :: Plug.Conn.t, params :: map(), context :: CallingContext.t, options :: list | map()) :: T.search_results
    
    
    
    
    @callback fields(any, any) :: any
    @callback build(any, any, any) :: any
    
    @callback update_index(any, any, any) :: any
    @callback delete_index(any, any, any) :: any
    
    @callback sql_escape_string(String.t) :: String.t
    
    
    @callback __extract_field__(any, any, any, any) :: any
    @callback __index_schema_fields__(any, any) :: any
    @callback __index_header__(any, any, any) :: any
    @callback __index_record__(any, any, any, any) ::any
    @callback __index_supported__?(any, any, any) :: any
    
    
    @callback __schema_open__() :: String.t
    @callback __schema_close__() :: String.t
    @callback __index_stem__() :: atom
    @callback __rt_index__() :: atom
    @callback __delta_index__() :: atom
    @callback __primary_index__() :: atom
    @callback __rt_source__() :: atom
    @callback __delta_source__() :: atom
    @callback __primary_source__() :: atom
    @callback __data_dir__() :: String.t
    
    @callback __noizu_info__() :: Keyword.t
    @callback __noizu_info__(Types.index_noizu_info_settings) :: any
    
    @callback __config__(any, any) :: any
  end
  
  defmodule Default do
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
      Enum.map(m.__indexing__()[:fields], fn({field, field_options}) ->
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
      settings = mod.__indexing__()
      expanded_fields = Enum.map(
                          settings[:fields] || [],
                          fn ({field, indexing}) ->
                            field_type = mod.__noizu_info__(:field_types)[field]
                            {field, indexing} = cond do
                                                  indexing[:as] -> {field, update_in(indexing, [:from], &(&1 || field))}
                                                  :else -> {field, indexing}
                                                end
                            indexing[:with] && Code.ensure_loaded(indexing[:with])
                            field_type[:handler] && Code.ensure_loaded(field_type[:handler])
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
  
    def __index_supported__?(mod, type, _context, _options) do
      cond do
        type != :real_time -> true
        mod.__indexing__()[:options][:type] == type -> true
        :else -> false
      end
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
                            :attr_multi_64 -> "<sphinx:attr name=\"#{field}\" type=\"multi\" #{default}  />"
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
        :else -> "REPLACE INTO #{index} (id, #{fields}) VALUES"
      end
    end
  
    def __index_record__(mod, record_type, entity, context, options) do
      uid = Noizu.EctoEntity.Protocol.universal_identifier(entity)
      settings = mod.__indexing__()
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
                              (v.encoding == :attr_multi || v.encoding == :attr_multi_64) ->
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
  
    def rt_attr(encoding), do: "rt_#{encoding}"
  
  
    def __config__(mod, context, options) do
      raw = mod.__index_schema_fields__(context, options)
      blobs = raw
              |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob end)
              |> Enum.map(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> {blob, :field} end)
              |> Enum.uniq
      base = raw
             |> Enum.filter(fn ({_field, _provider, blob, _encoding, _bits, _indexing, _default}) -> blob == nil end)
             |> Enum.map(fn ({field, _provider, _blob, encoding, _bits, _indexing, _default}) -> {field, encoding} end)
    
      rt_fields = Enum.map(base ++ blobs, fn ({field, encoding}) -> "#{rt_attr(encoding)} = #{field}" end)
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
  
  defmacro __using__(options) do
    options = Macro.expand(options, __CALLER__)
    configuration = Noizu.AdvancedScaffolding.Internal.DomainObject.Index.__configure__(options)
    implementation = Noizu.AdvancedScaffolding.Internal.DomainObject.Index.__implement__(options)
  
    #===----
    # Extension
    #===----
    extension_provider = options[:extension_implementation] || nil
    extension_block_a = extension_provider && quote do: (use unquote(extension_provider), unquote(options))
    extension_block_b = extension_provider && extension_provider.pre_defstruct(options)
    extension_block_c = extension_provider && extension_provider.post_defstruct(options)
    extension_block_d = extension_provider && quote do
                                                @before_compile unquote(extension_provider)
                                                @after_compile  unquote(extension_provider)
                                              end
    #===----
    # Process Config
    #===----
    process_config = quote do
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       import Noizu.ElixirCore.Guards
    
                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__index_defined, unquote(__CALLER__))
    
                       #---------------------
                       # Configure
                       #----------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       unquote(configuration)
                     end
  
    #===----
    # Implementation
    #===----
    quote do
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(process_config)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(implementation)
    
      #----------------------
      # User block section (define, fields, constraints, json_mapping rules, etc.)
      #----------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      try do
        unquote(extension_block_a)
        unquote(extension_block_b)
        #unquote(block)
      after
        :ok
      end
    
      unquote(extension_block_c)
    
      # Post User Logic Hook and checks.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @before_compile Noizu.AdvancedScaffolding.Internal.DomainObject.Index
      @after_compile Noizu.AdvancedScaffolding.Internal.DomainObject.Index
    
      unquote(extension_block_d)
    
      @file __ENV__.file
    end
  end


  def __configure__(options) do
    options = Macro.expand(options, __ENV__)
    base = options[:stand_alone]
    inline_source = options[:inline] && options[:entity]
    index_stem = options[:index_stem]
    source_dir = options[:source_dir] || Application.get_env(:noizu_advanced_scaffolding, :sphinx_data_dir, "/sphinx/data")
  
    rt_index = options[:rt_index]
    delta_index = options[:delta_index]
    primary_index = options[:primary_index]
  
    rt_source = options[:rt_source]
    delta_source = options[:delta_source]
    primary_source = options[:primary_source]
  
    quote do
      #---------------------
      # Find Base
      #---------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo__base  (unquote(base) && __MODULE__) || (Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat())
      @__nzdo__indexing_source unquote(inline_source) || __MODULE__
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo__sref Module.get_attribute(@__nzdo__base, :__nzdo__sref) || Module.get_attribute(__MODULE__, :sref)
    
      @index_stem unquote(index_stem) || @__nzdo__sref && String.replace("#{@__nzdo__sref}", "-", "_")
      @rt_index unquote(rt_index) || :"rt_index__#{@index_stem}"
      @delta_index unquote(delta_index) || :"delta_index__#{@index_stem}"
      @primary_index unquote(primary_index) || :"primary_index__#{@index_stem}"
      @rt_source unquote(rt_source) || :"rt_source__#{@index_stem}"
      @delta_source unquote(delta_source) || :"delta_source__#{@index_stem}"
      @primary_source unquote(primary_source) || :"primary_source__#{@index_stem}"
      @data_dir unquote(source_dir)
  
    end
  end

  def __implement__(options) do
    implementation = options[:index_implementation] || Noizu.AdvancedScaffolding.Internal.DomainObject.Index.Default
    quote do
      @behaviour Noizu.AdvancedScaffolding.Internal.DomainObject.Index.Behaviour
      @__nzdo__index_implementation unquote(implementation)
    
    
      if @__nzdo__indexing_source == __MODULE__ do
        def __indexing__(), do: {:error, {:nyi, :stand_alone_indexing}}
        def __indexing__(p), do: {:error, {:nyi, :stand_alone_indexing}}
      else
        def __indexing__(), do: @__nzdo__indexing_source.__indexing__()[__MODULE__]
        def __indexing__(p), do: __indexing__()[p]
      end
    
      def has_query_permission?(_field, _filter, _context, _options), do: :inherit
    
      def __search_clause__(:max_results, conn, params, context, options), do: __search_max_results__(conn, params, context, options)
      def __search_clause__(:limit, conn, params, context, options), do: __search_limit__(conn, params, context, options)
      def __search_clause__(:content, conn, params, context, options), do: __search_content__(conn, params, context, options)
    
    
      def __search_max_results__(conn, params, context, options), do: @__nzdo__index_implementation.__search_max_results__(__MODULE__, conn, params, context, options)
      def __search_limit__(conn, params, context, options), do: @__nzdo__index_implementation.__search_limit__(__MODULE__, conn, params, context, options)
      def __search_content__(conn, params, context, options), do: @__nzdo__index_implementation.__search_content__(__MODULE__, conn, params, context, options)
      def __search_order_by__(conn, params, indexes, context, options), do: @__nzdo__index_implementation.__search_order_by__(__MODULE__, conn, params, indexes, context, options)
      def __search_indexes__(conn, params, context, options), do: @__nzdo__index_implementation.__search_indexes__(__MODULE__, conn, params, context, options)
    
      def search_query(conn, params, context, options), do: @__nzdo__index_implementation.search_query(__MODULE__, conn, params, context, options)
      def __build_search_query__(index_clauses, field_clauses, context, options), do: @__nzdo__index_implementation.__build_search_query__(__MODULE__, index_clauses, field_clauses, context, options)
      def search(conn, params, context, options), do: @__nzdo__index_implementation.search(__MODULE__, conn, params, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def fields(context, options), do: @__nzdo__index_implementation.fields(__MODULE__, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def build(type, context, options), do: @__nzdo__index_implementation.build(__MODULE__, type, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def update_index(entity, context, options), do: @__nzdo__index_implementation.update_index(__MODULE__, entity, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete_index(entity, context, options), do: @__nzdo__index_implementation.delete_index(__MODULE__, entity, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def sql_escape_string(v), do: @__nzdo__index_implementation.sql_escape_string(v)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __schema_open__(), do: @__nzdo__index_implementation.__schema_open__()
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __schema_close__(), do: @__nzdo__index_implementation.__schema_close__()
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __extract_field__(field, entity, context, options), do: @__nzdo__index_implementation.__extract_field__(__MODULE__, field, entity, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __index_schema_fields__(context, options), do: @__nzdo__index_implementation.__index_schema_fields__(__MODULE__, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __index_header__(type, context, options), do: @__nzdo__index_implementation.__index_header__(__MODULE__, type, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __index_supported__?(type, context, options), do: @__nzdo__index_implementation.__index_supported__?(__MODULE__, type, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __index_record__(type, entity, context, options), do: @__nzdo__index_implementation.__index_record__(__MODULE__, type, entity, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __index_stem__(), do: @index_stem
      def __rt_index__(), do: @rt_index
      def __delta_index__(), do: @delta_index
      def __primary_index__(), do: @primary_index
      def __rt_source__(), do: @rt_source
      def __delta_source__(), do: @delta_source
      def __primary_source__(), do: @primary_source
      def __data_dir__(), do: @data_dir
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __config__(context, options), do: @__nzdo__index_implementation.__config__(__MODULE__, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
      
        has_query_permission?: 4,
      
        __indexing__: 0,
        __indexing__: 1,
      
        __search_clause__: 5,
        __search_max_results__: 4,
        __search_limit__: 4,
        __search_content__: 4,
        __search_order_by__: 5,
        __search_indexes__: 4,
        search_query: 4,
        __build_search_query__: 4,
        search: 4,
      
        fields: 2,
        build: 3,
        update_index: 3,
        delete_index: 3,
        sql_escape_string: 1,
      
        __schema_open__: 0,
        __schema_close__: 0,
        __extract_field__: 4,
        __index_schema_fields__: 2,
        __index_supported__?: 3,
        __index_header__: 3,
        __index_record__: 4,
      
        __index_stem__: 0,
        __rt_index__: 0,
        __delta_index__: 0,
        __primary_index__: 0,
        __rt_source__: 0,
        __delta_source__: 0,
        __primary_source__: 0,
        __data_dir__: 0,
      
        __config__: 2,
      ]
  
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @settings [
        :type,
        :indexing,
        :field_types,
        :schema_open,
        :schema_close,
        :index_stem,
        :rt_index,
        :delta_index,
        :primay_index,
        :rt_source,
        :delta_source,
        :primary_source,
        :data_dir
      ]
    
      def __noizu_info__(), do: __noizu_info__(:all)
      def __noizu_info__(:all), do: Enum.map(@settings, &({&1, __noizu_info__(&1)}))
      def __noizu_info__(:type), do: :index
      def __noizu_info__(:indexing), do: __indexing__()
    
      if @__nzdo__indexing_source == __MODULE__ do
        def __noizu_info__(:field_types), do: {:error, {:nyi, :stand_alone_indexing}}
      else
        def __noizu_info__(:field_types), do: @__nzdo__indexing_source.__noizu_info__(:field_types)
      end
    
      def __noizu_info__(:schema_open), do: __schema_open__()
      def __noizu_info__(:schema_close), do: __schema_close__()
      def __noizu_info__(:index_stem), do: __index_stem__()
      def __noizu_info__(:rt_index), do: __rt_index__()
      def __noizu_info__(:delta_index), do: __delta_index__()
      def __noizu_info__(:primary_index), do: __primary_index__()
      def __noizu_info__(:rt_source), do: __rt_source__()
      def __noizu_info__(:delta_source), do: __delta_source__()
      def __noizu_info__(:primary_source), do: __primary_source__()
      def __noizu_info__(:data_dir), do: __data_dir__()
    
      defoverridable [
        __noizu_info__: 0,
        __noizu_info__: 1,
      ]
    end
  end

  def __after_compile__(_env, _bytecode) do
    # Validate Generated Object
    :ok
  end







end
