#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc.. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.NmidGenerator do
  @behaviour Noizu.Scaffolding.NmidBehaviour
  use Amnesia
  use Noizu.Scaffolding.V3.Database.NmidGenerator
  @node_key Application.get_env(:noizu_scaffolding, :node_nmid_index, 0)

  def set_incr(seq, v) do
    case :mnesia.dirty_read(Noizu.Scaffolding.V3.Database.NmidGenerator, seq) do
      [{Noizu.Scaffolding.V3.Database.NmidGenerator, _, c}] ->
        cond do
          c < v ->
            :mnesia.dirty_write(Noizu.Scaffolding.V3.Database.NmidGenerator, {Noizu.Scaffolding.V3.Database.NmidGenerator, seq, v})
            :ok
          :else -> :ok
        end
      _else ->
        # to avoid edge case of out of sync increment from table load inbetween calls.
        :mnesia.dirty_update_counter(Noizu.Scaffolding.V3.Database.NmidGenerator, seq, v)
    end
  end

  def raw(seq) do
    :mnesia.dirty_update_counter(Noizu.Scaffolding.V3.Database.NmidGenerator, seq, 1)
  end

  def generate(seq, _opts \\ nil) do
    current = :mnesia.dirty_update_counter(Noizu.Scaffolding.V3.Database.NmidGenerator, seq, 1)
    map_id(current, @node_key, seq.__noizu_info__(:nmid_index))
  end

  def map_id(v, node_key, entity_key) do
    v * 1_00_000 + (node_key * 1_000) + entity_key
  end

  def generate!(seq, opts \\ nil) do
    generate(seq, opts)
  end
end
