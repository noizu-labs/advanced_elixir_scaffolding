defmodule Noizu.AdvancedScaffolding.Schema.Metadata.Ecto do
  @moduledoc """
  The Scaffolding library requires Ecto.Repo modules (if used within scaffolding) to include a metadata() method that returns
  this struct.

  @example ```
  defmodule MyAppSchema.MySQL.Repo do

  use Ecto.Repo,
      otp_app: :my_app,
      adapter: Ecto.Adapters.MyXQL

  def metadata(), do: %Noizu.Scaffolding.V3.Schema.EctoMetadata{repo: __MODULE__, database: MyAppSchema.MySQL}

  end
  ```
  """

  @vsn 1.0
  @type t :: %__MODULE__{
               database: atom,
               repo: atom,
               vsn: float
             }

  defstruct [
    database: nil,
    repo: nil,
    vsn: @vsn
  ]
end
