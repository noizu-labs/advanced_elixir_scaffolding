#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Test.Fixture.V3.ConCache do
  use Noizu.DomainObject
  @vsn 1.0
  @sref "con-cache"
  @cache {:con_cache, [prime: true, ttl: 123, miss_ttl: 5]}
  @persistence_layer {:redis, cascade?: false}
  defmodule Entity do
    @universal_identifier false
    Noizu.DomainObject.noizu_entity(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
      identifier :atom, constraint: [:foo, :bar, :bop]
      public_field :content
    end
  end

  defmodule Repo do
    Noizu.DomainObject.noizu_repo(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
    end
  end
end
