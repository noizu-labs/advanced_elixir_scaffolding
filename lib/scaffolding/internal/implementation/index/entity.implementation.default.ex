defmodule Noizu.AdvancedScaffolding.Internal.Index.Entity.Implementation.Default do
  @moduledoc """
  Default Implementation.
  """
  require Logger
  alias Giza.SphinxQL

  def __write_index__(domain_object, entity, index, settings, context, _options) do
    cond do
      settings[:options][:type] == :real_time ->
        # @todo tweak header, return raw fields or only field lists not the replace statement.
        replace = index.__index_header__(:real_time, context, [])
        fields = index.__index_record__(:real_time, entity, context, []) # todo merge options / settings. E.g. for locale randomization etc.
        record = Enum.join(fields, " ,")
        query = replace <> " (" <> record <> ") "
        Logger.info "SPHINX QUERY| #{query}"
        SphinxQL.new() |> SphinxQL.raw(query) |> SphinxQL.send()
      :else ->
        IO.puts "TODO - #{domain_object} - Perform record keeping so entity's can be reindexed/delta-indexed. etc."
    end
  end
  def __update_index__(_domain_object, entity, index, settings, context, _options) do
    cond do
      settings[:options][:type] == :real_time ->
        replace = index.__index_header__(:real_time, context, [])
        fields = index.__index_record__(:real_time, entity, context, []) # todo merge options / settings. E.g. for locale randomization etc.
        record = Enum.join(fields, " ,")
        query = replace <> " (" <> record <> ") "
        Logger.info "SPHINX QUERY| #{query}"
        SphinxQL.new() |> SphinxQL.raw(query) |> SphinxQL.send()
      :else ->
        IO.puts "TODO - Perform record keeping so entity's can be reindexed/delta-indexed. etc."
    end
  end
  def __delete_index__(domain_object, _entity, _index, _settings, _context, _options) do
    # needed
    IO.puts "TODO - #{domain_object} - iterate over indexes (if any) and call their delete methods."
  end
end

