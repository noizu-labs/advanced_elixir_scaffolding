#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Implementation.Default do
  @moduledoc """
  Default Implementation.
  """
  require Logger
  alias Giza.SphinxQL

  def __write_index__(domain_object, entity, index, settings, context, options) do
    IO.puts "WRITE INDEX: #{inspect domain_object} . . ."
    cond do
      settings[:options][:type] == :real_time ->
        cond do
          index.__index_supported__?(:real_time, context, options) ->
            # @todo tweak header, return raw fields or only field lists not the replace statement.
            replace = index.__index_header__(:real_time, context, options)
            fields = index.__index_record__(:real_time, entity, context, options) # todo merge options / settings. E.g. for locale randomization etc.
            record = Enum.join(fields, " ,")
            query = replace <> " (" <> record <> ") "
            IO.puts "SPHINX QUERY| #{query}"
            SphinxQL.new() |> SphinxQL.raw(query) |> SphinxQL.send() |> IO.inspect()
          :else ->
            IO.puts ":real_time NOT SUPPORTED"
            :unsupported
        end
      :else ->
        IO.puts "TODO - #{domain_object} - Perform record keeping so entity's can be reindexed/delta-indexed. etc."
        :nyi
    end
  end
  def __update_index__(domain_object, entity, index, settings, context, options) do
    IO.puts "UPDATE INDEX: #{inspect domain_object}"
    cond do
      settings[:options][:type] == :real_time ->
        cond do
          index.__index_supported__?(:real_time, context, options) ->
            replace = index.__index_header__(:real_time, context, options)
            fields = index.__index_record__(:real_time, entity, context, options) # todo merge options / settings. E.g. for locale randomization etc.
            record = Enum.join(fields, " ,")
            query = replace <> " (" <> record <> ") "
            Logger.info "SPHINX QUERY| #{query}"
            SphinxQL.new() |> SphinxQL.raw(query) |> SphinxQL.send()
          :else -> :unsupported
        end
      :else ->
        IO.puts "TODO - Perform record keeping so entity's can be reindexed/delta-indexed. etc."
        :nyi
    end
  end
  def __delete_index__(domain_object, _entity, _index, _settings, _context, _options) do
    # needed
    IO.puts "DELETE INDEX: #{inspect domain_object}"
    IO.puts "TODO - #{domain_object} - iterate over indexes (if any) and call their delete methods."
    :nyi
  end
end

