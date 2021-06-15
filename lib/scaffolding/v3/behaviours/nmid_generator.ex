#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc.. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.NmidGenerator do
  @behaviour Noizu.Scaffolding.NmidBehaviour
  use Amnesia
  use Noizu.Scaffolding.V3.Database.NmidV3Generator
  @node_key Application.get_env(:noizu_scaffolding, :node_nmid_index, 0)

  #--------------------
  #
  #--------------------
  def set_incr(seq, v) do
    case :mnesia.dirty_read(Noizu.Scaffolding.V3.Database.NmidV3Generator, seq) do
      [{Noizu.Scaffolding.V3.Database.NmidV3Generator, _, c}] ->
        cond do
          c < v ->
            :mnesia.dirty_write(Noizu.Scaffolding.V3.Database.NmidV3Generator, {Noizu.Scaffolding.V3.Database.NmidV3Generator, seq, v})
            :ok
          :else -> :ok
        end
      _else ->
        # to avoid edge case of out of sync increment from table load inbetween calls.
        :mnesia.dirty_update_counter(Noizu.Scaffolding.V3.Database.NmidV3Generator, seq, v)
    end
  end

  #--------------------
  #
  #--------------------
  def bare(seq), do: :mnesia.dirty_update_counter(Noizu.Scaffolding.V3.Database.NmidV3Generator, seq, 1)
  def bare!(seq), do: bare(seq)

  #--------------------
  #
  #--------------------
  def bare_node(seq) do
    v = :mnesia.dirty_update_counter(Noizu.Scaffolding.V3.Database.NmidV3Generator, seq, 1)
    v * 1000 + @node_key
  end
  def bare_node!(seq), do: bare_node(seq)

  #--------------------
  #
  #--------------------
  def generate(seq, _opts \\ nil) do
    case seq.__nmid__(:bare) do
      true -> bare(seq)
      :node -> bare_node(seq)
      _ ->
        current = :mnesia.dirty_update_counter(Noizu.Scaffolding.V3.Database.NmidV3Generator, seq, 1)
        map_id(current, @node_key, seq.__nmid__(:index))
    end
  end
  def generate!(seq, opts \\ nil) do
    generate(seq, opts)
  end

  #--------------------
  #
  #--------------------
  def map_id(v, node_key, entity_key) do
    v * 1_00_000 + (node_key * 1_000) + entity_key
  end


end
