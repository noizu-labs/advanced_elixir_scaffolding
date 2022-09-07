#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisJsonCache do
  use Noizu.DomainObject
  @vsn 1.0
  @sref "redis-cache"
  @cache {:redis_json, [prime: true, ttl: 123, miss_ttl: 5]}
  @persistence_layer {NoizuSchema.Database, cascade_block?: true}
  @persistence_layer {:redis, cascade?: false}
  defmodule Entity do
    @universal_identifier false
    Noizu.DomainObject.noizu_entity(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
      identifier :atom, constraint: [:foo, :bar, :bop]
      public_field :content
    end

    def __from_cache__!(json, _, _) do
      with true <- json[:json_meta][:kind] == "#{__MODULE__}" || {:cache, {:error, :record_mismatch}},
           true <- json[:vsn] == 1.0 || {:cache, {:error, :vsn_mismatch}},
           {:ok, id} = __string_to_id__(json[:identifier]) do
        %__MODULE__{
          identifier: id,
          content: json[:content],
          meta: json[:meta]
        }
      end
    end
  end

  defmodule Repo do
    Noizu.DomainObject.noizu_repo(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
    end
  end
end
