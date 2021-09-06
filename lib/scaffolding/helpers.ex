#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Helpers do
  alias Noizu.ElixirCore.CallingContext


  #-------------------------
  # banner_text
  #-------------------------
  @doc """
  Prepare banner string output.
  """
  def banner_text(header, msg, len \\ 120, pad \\ 0) do
    header_len = String.length(header)
    h_len = div(len, 2)

    sub_len = div(header_len, 2)
    rem = rem(header_len, 2)

    l_len = h_len - sub_len
    r_len = h_len - sub_len - rem

    char = "*"

    lines = String.split(msg, "\n", trim: true)

    pad_str = cond do
                pad == 0 -> ""
                :else -> String.duplicate(" ", pad)
              end

    top = "\n#{pad_str}#{String.duplicate(char, l_len)} #{header} #{String.duplicate(char, r_len)}"
    bottom = pad_str <> String.duplicate(char, len) <> "\n"
    middle = for line <- lines do
               "#{pad_str}#{char} " <> line
             end
    Enum.join([top] ++ middle ++ [bottom], "\n")
  end

  #-------------------------
  # page
  #-------------------------
  @doc """
  Return query page (e.g. run next(query) until reaching desired page.
  """
  def page(page, query) do
    cond do
      page == 0 -> query
      true ->
        Enum.reduce(
          1..page,
          query,
          fn (_, acc) ->
            Amnesia.Selection.next(acc)
          end
        )
    end
    |> Amnesia.Selection.values()
  end


  #-------------------------
  # expand_concurrency
  #-------------------------
  @doc """
    Extract concurrency settings from options
  """
  def expand_concurrency(options) do
    {max_concurrency, next_concurrency} = case options[:max_concurrency] do
                                            [] -> {1, [1]}
                                            [h] -> {h, [max(h - 1, 1)]}
                                            [h | t] -> {h, t}
                                            _ ->
                                              h = System.schedulers_online() * 8
                                              {h, [max(h - 1, 1)]}
                                          end
    {max_concurrency, put_in(options, [:max_concurrency], next_concurrency)}
  end

  #-------------------------
  # expand_ref?
  #-------------------------
  @doc """
    Should entity be expanded for poison/entity expand.
  """
  def expand_ref?(options = %{path: path, depth: depth}) do
    expand_ref?(path, depth, options)
  end
  def expand_ref?(path, depth, options \\ nil) do
    cond do
      options == nil -> false
      options[:expand_all_refs] == :infinity -> true
      is_integer(options[:expand_all_refs]) && options[:expand_all_refs] <= depth -> true
      expand = options[:expand_refs] ->
        Enum.reduce_while(
          expand,
          false,
          fn ({p, d}, acc) ->
            cond do
              is_integer(d) && d > depth -> {:cont, acc}
              Regex.match?(p, path) -> {:halt, true}
              :else -> {:cont, acc}
            end
          end
        )
      :else -> false
    end
  end

  #-------------------------
  # json_library
  #-------------------------
  @doc """
  Return Json Provider.
  """
  def json_library() do
    Application.get_env(:noizu_advanced_scaffolding, :json_library, Application.get_env(:phoenix, :json_library, Poison))
  end

  #-------------------------
  # send_resp
  #-------------------------
  @doc """
  Send API Response.
  """
  def __send_resp__(conn, default_status, default_content_type, body) do
    conn
    |> __ensure_resp_content_type__(default_content_type)
    |> Plug.Conn.send_resp(conn.status || default_status, body)
  end

  #-------------------------
  # ensure_resp_content_type
  #-------------------------
  @doc """
  Set content-type if not set.
  """
  def __ensure_resp_content_type__(%{resp_headers: resp_headers} = conn, content_type) do
    if List.keyfind(resp_headers, "content-type", 0) do
      conn
    else
      content_type = content_type <> "; charset=utf-8"
      %{conn | resp_headers: [{"content-type", content_type} | resp_headers]}
    end
  end


  #-------------------------
  # format_to_atom
  #-------------------------
  @default_json_formats [:standard, :admin, :verbose, :compact, :mobile, :verbose_mobile]
  @json_formats Application.get_env(:noizu_scaffolding, :json_formats, @default_json_formats)
  @formats Map.new(
             @json_formats,
             fn (f) ->
               case f do
                 {k, v} when is_atom(k) and is_bitstring(v) -> {v, k}
                 {k, v} when is_atom(v) and is_bitstring(k) -> {v, v}
                 k when is_atom(k) -> {Atom.to_string(k), k}
               end
             end
           )
  @doc """
  Convert string json format specifier to atom if exists or default.
  """
  def format_to_atom(v, default) do
    @formats[v] || default
  end

  #-------------------------
  # __default_get_context__json_format__
  #-------------------------
  def __default_get_context__json_format__(conn, params, get_context_provider, _options) do
    (params["default-json-format"] || List.first(Plug.Conn.get_resp_header(conn, "x-default-json-format")))
    |> get_context_provider.format_to_atom(:mobile)
  end

  #-------------------------
  # __default_get_context__json_formats__
  #-------------------------
  def __default_get_context__json_formats__(conn, params, get_context_provider, _options) do
    format_overrides = params["json-formats"] || List.first(Plug.Conn.get_resp_header(conn, "x-json-formats"))
    case format_overrides do
      v when is_bitstring(v) ->
        String.split(v, ",")
        |> Enum.map(
             fn (e) ->
               get_context_provider.format_to_tuple(String.split(e, ":"))
             end
           )
        |> Enum.filter(&(&1))
        |> Map.new()
      _ -> %{}
    end
  end

  #-------------------------
  # __default_get_context__expand_all_refs__
  #-------------------------
  def __default_get_context__expand_all_refs__(conn, params, _get_context_provider, _options) do
    case (params["expand-all-refs"] || List.first(Plug.Conn.get_resp_header(conn, "x-expand-all-refs"))) do
      true -> :infinity
      "true" -> :infinity
      false -> false
      "false" -> false
      v when is_bitstring(v) ->
        case Integer.parse(v) do
          {v, ""} -> v
          _ -> false
        end
      v when is_integer(v) -> v
      nil -> false
    end
  end

  #-------------------------
  # __default_get_context__expand_refs__
  #-------------------------
  @doc """
     Prepares a list of paths to expand keyed to a root, plus options depth.
     Example  expand-refs=*.posts.entity-image.image,*.user:5
     Internally paths are converted to regex strings + max depth constraints and compared to input in json methods.
     Regex.match?(~"^image\.entity-image\.user.*$", path)
  """
  def __default_get_context__expand_refs__(conn, params, get_context_provider, _options) do
    case (params["expand-refs"] || List.first(Plug.Conn.get_resp_header(conn, "x-expand-refs"))) do
      v when is_bitstring(v) ->
        Enum.map(
          String.split(v, ","),
          fn (r) ->
            {path, depth} = case String.split(r, ":") do
                              [path, "infinity"] -> {path, :infinity}
                              [path, depth] ->
                                case Integer.parse(depth) do
                                  {v, ""} -> {path, v}
                                  _ -> {nil, nil}
                                end
                              [path] -> {path, :infinity}
                            end
            if path do
              extended = case String.split(path, ".") do
                           [v] ->
                             e = get_context_provider.sref_module(String.trim(v))
                             e && [e, "*"]
                           v when is_list(v) ->
                             Enum.reduce_while(
                               v,
                               [],
                               fn (e, acc) ->
                                 cond do
                                   e == "**" -> {:cont, acc ++ [e]}
                                   e == "*" -> {:cont, acc ++ [e]}
                                   e == "++" -> {:cont, acc ++ [e]}
                                   e == "+" -> {:cont, acc ++ [e]}
                                   Regex.match?(~r/^\{[0-9,]+\}$/, e) -> {:cont, acc ++ [e]}
                                   e = get_context_provider.sref_module(String.trim(e)) -> {:cont, acc ++ [e]}
                                   :else -> {:halt, nil}
                                 end
                               end
                             )
                         end
              if extended do
                [h | t] = extended
                head = cond do
                         is_atom(h) -> "^#{h.sref_module()}"
                         h == "**" -> "^([a-z_\\-0-9\\.])*"
                         h == "++" -> "^([a-z_\\-0-9\\.])+"
                         :else -> "^([a-z_\\-0-9])#{h}"
                       end
                reg = Enum.reduce(
                        t,
                        head,
                        fn (x, acc) ->
                          cond do
                            is_atom(x) -> acc <> "\.#{x.sref_module()}"
                            x == "**" -> acc <> "([a-z_\\-0-9\\.])*"
                            x == "++" -> acc <> "([a-z_\\-0-9\\.])+"
                            Regex.match?(~r/^\{[0-9,]+\}$/, x) -> acc <> "([a-z_\\-0-9]*\.)#{x}"
                            :else -> acc <> "([a-z_\\-0-9])#{x}"
                          end
                        end
                      ) <> "$"
                reg = case Regex.compile(reg) do
                        {:ok, v} -> v
                        _ -> nil
                      end
                reg && {reg, depth}
              end
            end
          end
        )
        |> Enum.filter(&(&1))
      nil -> nil
    end
  end

  #-------------------------
  # default_get_context__token_reason_options
  #-------------------------
  def __default_get_context__token_reason_options__(conn, params, get_context_provider, opts) do
    token = CallingContext.get_token(conn)
    reason = CallingContext.get_reason(conn)
    json_format = __default_get_context__json_format__(conn, params, get_context_provider, opts)
    json_formats = __default_get_context__json_formats__(conn, params, get_context_provider, opts)
    expand_all_refs = __default_get_context__expand_all_refs__(conn, params, get_context_provider, opts)
    expand_refs = __default_get_context__expand_refs__(conn, params, get_context_provider, opts)

    context_options = %{
      expand_refs: expand_refs,
      expand_all_refs: expand_all_refs,
      json_format: json_format,
      json_formats: json_formats,
    }
    {token, reason, context_options}
  end

  #-------------------------
  # get_ip
  #-------------------------
  @doc """
  get caller's IP address.
  """
  def get_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [h | _] ->
        ip_list = case h do
                    v when is_bitstring(v) ->
                      v
                    v when is_tuple(v) ->
                      v
                      |> Tuple.to_list
                      |> Enum.join(".")
                    v when is_list(h) ->
                      v
                      |> to_charlist()
                      |> to_string()
                    v ->
                      "#{v}"
                  end
        [f | _] = String.split(ip_list, ",")
        String.trim(f)
      [] ->
        conn.remote_ip
        |> Tuple.to_list
        |> Enum.join(".")
      nil ->
        conn.remote_ip
        |> Tuple.to_list
        |> Enum.join(".")
    end
  end # end get_ip/1

  #-------------------------
  # force_put/3
  #-------------------------
  @doc """
    injects maps in path if not already populated.
    @example ```
    force_put(%{}, [:a, :b, :c], 1)
    %{a: %{b: %{c: 1}}}
    ```
  """
  def force_put(nil, [h], v), do: %{h => v}
  def force_put(nil, [h | _] = p, v), do: force_put(%{h => %{}}, p, v)
  def force_put(entity, [h], v), do: put_in(entity, [h], v)
  def force_put(entity, path, v) when is_list(path) do
    try do
      put_in(entity, path, v)
    rescue
      _exception ->
        [entity, _] = Enum.slice(path, 0..-2)
                      |> Enum.reduce(
                           [entity, []],
                           fn (x, [e, p]) ->
                             a = p ++ [x]
                             cond do
                               get_in(e, a) -> [e, a]
                               true -> [put_in(e, a, %{}), a]
                             end
                           end
                         )
        put_in(entity, path, v)
    end
  end

  #-------------------------
  # api_response
  #-------------------------
  @doc """
   Prepare and return api response. Expand refs, strip pii, apply specific json formatting etc. to result set before returning,
  """
  def api_response(%Plug.Conn{} = conn, response, %CallingContext{} = context, options \\ []) do
    options = (options || [])
              |> update_in([:pretty], &(&1 == nil && true || &1))
              |> update_in([:expand_refs], &(&1 == nil && context.options[:expand_refs] || &1))
              |> update_in([:expand_all_refs], &(&1 == nil && context.options[:expand_all_refs] || &1))
              |> update_in([:json_format], &(&1 == nil && context.options[:json_format] || &1))
              |> update_in([:json_formats], &(&1 == nil && context.options[:json_formats] || &1))
              |> update_in([:context], &(&1 == nil && context || &1))
              |> update_in([:depth], &(&1 || 1))
              |> Enum.map(&(&1))

    # Preprocess response data.
    response = cond do
                 options[:expand] && options[:restricted] ->
                   Noizu.RestrictedAccess.Protocol.restricted_view(Noizu.Entity.Protocol.expand!(response, context, options), context, options[:restrict_options])
                 options[:expand] ->
                   Noizu.Entity.Protocol.expand!(response, context, options)
                 options[:restricted] ->
                   Noizu.RestrictedAccess.Protocol.restricted_view(response, context, options[:restrict_options])
                 :else ->
                   response
               end

    options = options[:expand] && put_in(options || [], :__nzdo__expanded?, true) || options
    options = options[:restricted] && put_in(options || [], :__nzdo__restricted?, true) || options

    # Injecting Useful content from calling context into headers for api client's consumption.
    case Plug.Conn.get_resp_header(conn, "x-request-id") do
      [request | _] ->
        if request != context.token do
          conn
          |> Plug.Conn.put_resp_header("x-request-id", context.token)
          |> Plug.Conn.put_resp_header("x-orig-request-id", request)
        else
          conn
        end
      [] ->
        conn
        |> Plug.Conn.put_resp_header("x-request-id", context.token)
    end
    |> __send_resp__(200, "application/json", json_library().encode_to_iodata!(response, options))
  end



  #-------------------------
  # __update_options__
  #-------------------------
  @doc """
    Update Poison Format/Expansion options.
  """
  def __update_options__(entity, options) when is_atom(entity) do
    json_format = options[:json_formats][entity] || options[:json_formats][entity.__noizu_info__(:poly)[:base]] || options[:json_format] || :mobile
    {json_format, __update_expand_options__(entity, options)}
  end

  def __update_options__(%{__struct__: m} = entity, options) do
    json_format = options[:json_formats][m] || options[m.__noizu_info__(:poly)[:base]] || options[:json_format] || :mobile
    {json_format, __update_expand_options__(entity, options)}
  end

  def __update_options__(entity, options) do
    json_format = options[:json_format] || :mobile
    {json_format, __update_expand_options__(entity, options)}
  end

  @doc """
    Update Poison Format/Expansion options.
  """
  def __update_options__(%{__struct__: m} = entity, _context, options) do
    json_format = __update_options__json_format__(m, options)
    {json_format, __update_expand_options__(entity, options)}
  end
  def __update_options__(entity, _context, options) when is_atom(entity) do
    json_format = __update_options__json_format__(entity, options)
    {json_format, __update_expand_options__(entity, options)}
  end
  def __update_options__(entity, _context, options) do
    json_format = __update_options__json_format__(nil, options)
    {json_format, __update_expand_options__(entity, options)}
  end


  #-------------------------
  # __update_expand_options__
  #-------------------------
  @doc """
    Update Entity.expand! option depth and path.
  """
  def __update_expand_options__(entity, options) when is_atom(entity) do
    sm = try do
           entity.__kind__()
    rescue _e -> "[error]"
         end
    (options || %{})
    |> update_in([:depth], &((&1 || 1) + 1))
    |> update_in([:path], &(sm <> (&1 && ("." <> &1) || "")))
  end
  def __update_expand_options__(%{__struct__: m} = _entity, options) do
    sm = try do
           m.__kind__()
    rescue _e -> "[error]"
         end
    (options || %{})
    |> update_in([:depth], &((&1 || 1) + 1))
    |> update_in([:path], &(sm <> (&1 && ("." <> &1) || "")))
  end
  def __update_expand_options__(_entity, options) do
    sm = "[error]"
    (options || %{})
    |> update_in([:depth], &((&1 || 1) + 1))
    |> update_in([:path], &(sm <> (&1 && ("." <> &1) || "")))
  end

  #-------------------------
  # __update_options__json_format__
  #-------------------------
  @doc """
    Update Poison Format/Expansion options.
  """
  def __update_options__json_format__(entity, options) when is_atom(entity) do
    if function_exported?(entity, :__noizu_info__, 1) do
      cond do
        entity == nil -> :default
        format = options[:json_formats][entity] -> format
        format = options[:json_formats][entity.__noizu_info__(:poly)][:base] -> format
        format = options[:json_format] -> format
        format = entity.__noizu_info__(:json_format) -> format
        :else -> :default
      end
    else
      cond do
        entity == nil -> :default
        format = options[:json_formats][entity] -> format
        format = options[:json_format] -> format
        :else -> :default
      end
    end
  end


  def request_pagination(params, default_page, default_results_per_page) do
    page = case params["pg"] || default_page do
             v when is_integer(v) -> v
             v when is_bitstring(v) ->
               case Integer.parse(v) do
                 {v, ""} -> v
                 _ -> default_page
               end
             _ -> default_page
           end

    results_per_page = case params["rpp"] || default_results_per_page do
                         v when is_integer(v) -> v
                         v when is_bitstring(v) ->
                           case Integer.parse(v) do
                             {v, ""} -> v
                             _ -> default_results_per_page
                           end
                         _ -> default_results_per_page
                       end

    {page, results_per_page}
  end


  defmodule CustomHelper do
    defmacro __using__(_ \\ nil) do
      quote do
        import Noizu.AdvancedScaffolding.Helpers

        def banner_text(header, msg, len \\ 120, pad \\ 0), do: Noizu.AdvancedScaffolding.Helpers.banner_text(header, msg, len, pad)
        def request_pagination(params, default_page, default_results_per_page), do: Noizu.AdvancedScaffolding.Helpers.request_pagination(params, default_page, default_results_per_page)
        def page(page, query), do: Noizu.AdvancedScaffolding.Helpers.page(page, query)
        def __update_options__(entity, options), do: Noizu.AdvancedScaffolding.Helpers.__update_options__(entity, options)
        def __update_expand_options__(entity, options), do: Noizu.AdvancedScaffolding.Helpers.__update_expand_options__(entity, options)
        def expand_ref?(options), do: Noizu.AdvancedScaffolding.Helpers.expand_ref?(options)
        def expand_ref?(path, depth, options \\ nil), do: Noizu.AdvancedScaffolding.Helpers.expand_ref?(path, depth, options)
        def api_response(conn, response, context, options \\ nil), do: Noizu.AdvancedScaffolding.Helpers.api_response(conn, response, context, options)
        def json_library(), do: Noizu.AdvancedScaffolding.Helpers.json_library()
        def __send_resp__(conn, default_status, default_content_type, body), do: Noizu.AdvancedScaffolding.Helpers.__send_resp__(conn, default_status, default_content_type, body)
        def __ensure_resp_content_type__(conn, content_type), do: Noizu.AdvancedScaffolding.Helpers.__ensure_resp_content_type__(conn, content_type)
        def format_to_atom(v, default), do: Noizu.AdvancedScaffolding.Helpers.format_to_atom(v, default)
        def __default_get_context__json_format__(conn, params, get_context_provider, options), do: Noizu.AdvancedScaffolding.Helpers.__default_get_context__json_format__(conn, params, get_context_provider, options)
        def __default_get_context__json_formats__(conn, params, get_context_provider, options), do: Noizu.AdvancedScaffolding.Helpers.__default_get_context__json_formats__(conn, params, get_context_provider, options)
        def __default_get_context__expand_all_refs__(conn, params, get_context_provider, options), do: Noizu.AdvancedScaffolding.Helpers.__default_get_context__expand_all_refs__(conn, params, get_context_provider, options)
        def __default_get_context__expand_refs__(conn, params, get_context_provider, options), do: Noizu.AdvancedScaffolding.Helpers.__default_get_context__expand_refs__(conn, params, get_context_provider, options)
        def __default_get_context__token_reason_options__(conn, params, get_context_provider, opts), do: Noizu.AdvancedScaffolding.Helpers.__default_get_context__token_reason_options__(conn, params, get_context_provider, opts)
        def get_ip(conn), do: Noizu.AdvancedScaffolding.Helpers.get_ip(conn)
        def force_put(entity, path, value), do: Noizu.AdvancedScaffolding.Helpers.force_put(entity, path, value)

        defoverridable [
          banner_text: 2,
          banner_text: 3,
          banner_text: 4,
          request_pagination: 3,
          page: 2,
          __update_options__: 2,
          __update_expand_options__: 2,
          expand_ref?: 1,
          expand_ref?: 2,
          expand_ref?: 3,
          api_response: 3,
          api_response: 4,
          json_library: 0,
          __send_resp__: 4,
          __ensure_resp_content_type__: 2,
          format_to_atom: 2,
          __default_get_context__json_format__: 4,
          __default_get_context__json_formats__: 4,
          __default_get_context__expand_all_refs__: 4,
          __default_get_context__expand_refs__: 4,
          __default_get_context__token_reason_options__: 4,
          get_ip: 1,
          force_put: 3,
        ]
      end
    end
  end

end
