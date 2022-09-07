defmodule NoizuSchema.Redis do
  @pool_size 5
  
  #-------------------------
  # Noizu Scaffolding
  #-------------------------
  def metadata(), do: %Noizu.AdvancedScaffolding.Schema.Metadata.Redis{repo: __MODULE__}
  
  @doc """
  @todo need to tweak scaffolding lib, we want to insure on these calls we have the sref form of the identifier
  If the record has been transformed from the regular entity to a json format.
  """
  def create_handler(record, _context, _options) do
    IO.inspect(record, pretty: true, label: :redix)
    # wip
  end
  
  def create_handler!(_record, _context, _options) do
    # wip
  end
  
  def update_handler(_record, _context, _options) do
    # wip
  end
  
  def update_handler!(_record, _context, _options) do
    # wip
  end
  
  def delete_handler(_record, _context, _options) do
    # wip
  end
  
  def delete_handler!(_record, _context, _options) do
    # wip
  end
  
  #------------------------
  # Pool Supervisor
  #------------------------
  def child_spec(_args) do
    # Specs for the Redix connections.
    children = Enum.map(
      1..@pool_size,
      fn (index) ->
        Supervisor.child_spec({Redix, [[],[name: :"redix_#{index}"]]}, id: {Redix, index})
      end
    )
    rebuild_channels()
    # Spec for the supervisor that will supervise the Redix connections.
    %{
      id: Redix,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end
  
  #------------------------
  # Naive Pool
  #------------------------
  def rebuild_channels() do
    pool = Enum.map(1..@pool_size, &({&1, :"redix_#{&1}"}))
           |> Map.new()
    FastGlobal.put(:redix_cluster, pool)
    pool
  end
  def random_channel() do
    FastGlobal.get(:redix_cluster)[random_index()] || rebuild_channels()[random_index()]
  end
  defp random_index(), do: :rand.uniform(@pool_size)
  
  #------------------------
  # Basic Operations
  #------------------------
  def command(command), do: Redix.command(random_channel(), command)
  def flush(), do: command(["FLUSHALL"])
  
  def get(command), do: command_helper("GET", command)
  def set(command), do: command_helper("SET", command)
  
  def delete(key), do: command_helper("DEL", [key])
  
  def get_json(command) do
    case get(command) do
      {:ok, json} when is_bitstring(json) -> Poison.decode(json, keys: :atoms)
      e -> e
    end
  end
  def set_json([id,object|t] = _command) do
    case Poison.encode(object, [json_format: :redis]) do
      {:ok, json} -> set([id, json|t])
      e -> e
    end
  end
  
  def get_binary(command) do
    case get(command) do
      {:ok, nil} -> {:ok, nil}
      {:ok, binary} ->
        with {:ok, raw} <- Base.decode64(binary) do
          {:ok, :erlang.binary_to_term(raw)}
        end
      e -> e
    end
  end
  def set_binary([id,object|t] = _command) do
    with binary <- :erlang.term_to_binary(object),
         base64 <- binary && Base.encode64(binary) do
      set([id, base64|t])
    else
      e -> e
    end
  end
  
  defp command_helper(action, command) do
    case command do
      v when is_list(v) -> command([action] ++ v)
      v when is_bitstring(v) -> command([action, v])
      _ -> nil
    end
  end
end
