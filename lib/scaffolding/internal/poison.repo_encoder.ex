#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.Poison.RepoEncoder do
  @moduledoc """
  Custom Poison Encoder Implementation, it handles stripping PII, formatting, etc.
  """

  @doc """
  Convert repo into json string.
  """
  def encode(noizu_repo, options \\ nil) do
    context = options[:context]
    {json_format, options} = Noizu.AdvancedScaffolding.Helpers.__update_options__(noizu_repo, context, options)
    case noizu_repo do
      %{entities: unprocessed_entities} when is_list(unprocessed_entities) ->
        {expanded_entities, options} = cond do
                                         options[:__nzdo__restricted?] && options[:__nzdo__expanded?] ->
                                           {unprocessed_entities, options}
                                         !options[:__nzdo__restricted?] && options[:__nzdo__expanded?] ->
                                           options_b = options
                                                     |> put_in([:__nzdo__restricted?], true)
                                           {Noizu.RestrictedAccess.Protocol.restricted_view(unprocessed_entities, context, options), options_b}
                                         :else ->
                                           options_b = options
                                                       |> put_in([:__nzdo__restricted?], false)
                                                       |> put_in([:__nzdo__expanded?], false)
                                           expanded = Noizu.Entity.Protocol.expand!(unprocessed_entities, context, options_b)
                                           options_c = options_b
                                                       |> put_in([:__nzdo__expanded?], true)
                                           restricted = Noizu.RestrictedAccess.Protocol.restricted_view(expanded, context, options)
                                           options = options_c
                                                     |> put_in([:__nzdo__restricted?], true)
                                           {restricted, options}
                                       end
        # Note currently we don't support expansion/restrict on Repo struct fields.
        %{noizu_repo| entities: expanded_entities}
        |> Map.from_struct()
        |> put_in([:kind], noizu_repo.__struct__.__kind__())
        |> put_in([:json_format], json_format)
        |> Poison.Encoder.encode(options)
      _ ->
        Map.from_struct(noizu_repo)
        |> put_in([:kind], noizu_repo.__struct__.__kind__())
        |> put_in([:json_format], json_format)
        |> Poison.Encoder.encode(options)
    end
  rescue e ->
    IO.warn("[JSON] ", Exception.format(:error, e, __STACKTRACE__))
    Exception.format(:error, e, __STACKTRACE__) |> Poison.Encoder.encode(options)
  end





end
