#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.Helpers do
  alias Noizu.ElixirCore.CallingContext

  defdelegate banner_text(header, msg, len \\ 120, pad \\ 0), to: Noizu.Scaffolding.Helpers
  defdelegate request_pagination(params, default_page, default_results_per_page), to: Noizu.Scaffolding.Helpers
  defdelegate page(page, query), to: Noizu.Scaffolding.Helpers
  defdelegate expand_concurrency(options), to: Noizu.Scaffolding.Helpers
  defdelegate expand_ref?(options), to: Noizu.Scaffolding.Helpers
  defdelegate expand_ref?(path, depth, options \\ nil), to: Noizu.Scaffolding.Helpers
  defdelegate json_library(), to: Noizu.Scaffolding.Helpers
  defdelegate send_resp(conn, default_status, default_content_type, body), to: Noizu.Scaffolding.Helpers
  defdelegate ensure_resp_content_type(conn, content_type), to: Noizu.Scaffolding.Helpers
  defdelegate format_to_atom(v, default), to: Noizu.Scaffolding.Helpers
  defdelegate default_get_context__json_format(conn, params, get_context_provider, options), to: Noizu.Scaffolding.Helpers
  defdelegate default_get_context__json_formats(conn, params, get_context_provider, options), to: Noizu.Scaffolding.Helpers
  defdelegate default_get_context__expand_all_refs(conn, params, get_context_provider, options), to: Noizu.Scaffolding.Helpers
  defdelegate default_get_context__expand_refs(conn, params, get_context_provider, options), to: Noizu.Scaffolding.Helpers
  defdelegate default_get_context__token_reason_options(conn, params, get_context_provider, opts), to: Noizu.Scaffolding.Helpers
  defdelegate get_ip(conn), to: Noizu.Scaffolding.Helpers
  defdelegate force_put(entity, path, value), to: Noizu.Scaffolding.Helpers

  #-------------------------
  # update_options__json_format
  #-------------------------
  @doc """
    Update Poison Format/Expansion options.
  """
  def update_options__json_format(entity, options) when is_atom(entity) do
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

  #-------------------------
  # update_options
  #-------------------------
  @doc """
    Update Poison Format/Expansion options.
  """
  def update_options(%{__struct__: m} = entity, _context, options) do
    json_format = update_options__json_format(m, options)
    {json_format, update_expand_options(entity, options)}
  end
  def update_options(entity, _context, options) when is_atom(entity) do
    json_format = update_options__json_format(entity, options)
    {json_format, update_expand_options(entity, options)}
  end
  def update_options(entity, _context, options) do
    json_format = update_options__json_format(nil, options)
    {json_format, update_expand_options(entity, options)}
  end

  #-------------------------
  # update_expand_options
  #-------------------------
  @doc """
    Update Entity.expand! option depth and path.
  """
  def update_expand_options(%{__struct__: m} = _entity, options), do: update_expand_options(m, options)
  def update_expand_options(entity, options) when is_atom(entity) do
    sm = cond do
           !function_exported?(entity, :__sref__, 0) -> "[error]"
           v = entity.__sref__() -> v != :undefined && v || "[error]"
           :else -> "[error"
         end
    (options || %{})
    |> update_in([:depth], &((&1 || 1) + 1))
    |> update_in([:path], &(sm <> (&1 && ("." <> &1) || "")))
  end
  def update_expand_options(_entity, options) do
    sm = "[error]"
    (options || %{})
    |> update_in([:depth], &((&1 || 1) + 1))
    |> update_in([:path], &(sm <> (&1 && ("." <> &1) || "")))
  end

  #-------------------------
  # api_response
  #-------------------------
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
                   Noizu.V3.RestrictedProtocol.restricted_view(Noizu.V3.EntityProtocol.expand!(response, context, options), context, options[:restrict_options])
                 options[:expand] ->
                   Noizu.V3.EntityProtocol.expand!(response, context, options)
                 options[:restricted] ->
                   Noizu.V3.RestrictedProtocol.restricted_view(response, context, options[:restrict_options])
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
    |> send_resp(200, "application/json", json_library().encode_to_iodata!(response, options))
  end


  defmodule CustomHelper do
    defmacro __using__(_ \\ nil) do
      quote do
        import Noizu.Scaffolding.V3.Helpers

        defdelegate banner_text(header, msg, len \\ 120, pad \\ 0), to: Noizu.Scaffolding.V3.Helpers
        defdelegate request_pagination(params, default_page, default_results_per_page), to: Noizu.Scaffolding.V3.Helpers
        defdelegate page(page, query), to: Noizu.Scaffolding.V3.Helpers
        defdelegate update_options(entity, options), to: Noizu.Scaffolding.V3.Helpers
        defdelegate update_expand_options(entity, options), to: Noizu.Scaffolding.V3.Helpers
        defdelegate expand_ref?(options), to: Noizu.Scaffolding.V3.Helpers
        defdelegate expand_ref?(path, depth, options \\ nil), to: Noizu.Scaffolding.V3.Helpers
        defdelegate api_response(conn, response, context, options), to: Noizu.Scaffolding.V3.Helpers
        defdelegate json_library(), to: Noizu.Scaffolding.V3.Helpers
        defdelegate send_resp(conn, default_status, default_content_type, body), to: Noizu.Scaffolding.V3.Helpers
        defdelegate ensure_resp_content_type(conn, content_type), to: Noizu.Scaffolding.V3.Helpers
        defdelegate format_to_atom(v, default), to: Noizu.Scaffolding.V3.Helpers
        defdelegate default_get_context__json_format(conn, params, get_context_provider, options), to: Noizu.Scaffolding.V3.Helpers
        defdelegate default_get_context__json_formats(conn, params, get_context_provider, options), to: Noizu.Scaffolding.V3.Helpers
        defdelegate default_get_context__expand_all_refs(conn, params, get_context_provider, options), to: Noizu.Scaffolding.V3.Helpers
        defdelegate default_get_context__expand_refs(conn, params, get_context_provider, options), to: Noizu.Scaffolding.V3.Helpers
        defdelegate default_get_context__token_reason_options(conn, params, get_context_provider, opts), to: Noizu.Scaffolding.V3.Helpers
        defdelegate get_ip(conn), to: Noizu.Scaffolding.V3.Helpers
        defdelegate force_put(entity, path, value), to: Noizu.Scaffolding.V3.Helpers

        defoverridable [
          banner_text: 2,
          banner_text: 3,
          banner_text: 4,
          request_pagination: 3,
          page: 2,
          update_options: 2,
          update_expand_options: 2,
          expand_ref?: 1,
          expand_ref?: 2,
          expand_ref?: 3,
          api_response: 4,
          json_library: 0,
          send_resp: 4,
          ensure_resp_content_type: 2,
          format_to_atom: 2,
          default_get_context__json_format: 4,
          default_get_context__json_formats: 4,
          default_get_context__expand_all_refs: 4,
          default_get_context__expand_refs: 4,
          default_get_context__token_reason_options: 4,
          get_ip: 1,
          force_put: 3,
        ]
      end
    end
  end

end
