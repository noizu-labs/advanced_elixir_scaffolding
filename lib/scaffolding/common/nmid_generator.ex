#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc.. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.NmidGenerator do
  #@behaviour Noizu.AdvancedScaffolding.NmidBehaviour
  use Amnesia
  use Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table
  @node_key Application.get_env(:noizu_advanced_scaffolding, :node_nmid_index, 0)

  #--------------------
  #
  #--------------------
  def set_incr(seq, v) do
    case :mnesia.dirty_read(Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, seq) do
      [{Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, _, c}] ->
        cond do
          c < v ->
            :mnesia.dirty_write(Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, {Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, seq, v})
            :ok
          :else -> :ok
        end
      _else ->
        # to avoid edge case of out of sync increment from table load inbetween calls.
        :mnesia.dirty_update_counter(Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, seq, v)
    end
  end

  #--------------------
  #
  #--------------------
  def bare(seq), do: :mnesia.dirty_update_counter(Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, seq, 1)
  def bare!(seq), do: bare(seq)

  #--------------------
  #
  #--------------------
  def bare_node(seq) do
    v = :mnesia.dirty_update_counter(Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, seq, 1)
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
        current = :mnesia.dirty_update_counter(Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, seq, 1)
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
    v * 1_00_000 + (rem(node_key, 99) * 1_000) + rem(entity_key, 999)
  end


end
