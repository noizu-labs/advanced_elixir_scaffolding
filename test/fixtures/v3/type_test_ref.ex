#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestRef do
  use Noizu.DomainObject
  @vsn 1.0
  @sref "tt-ref"
  @persistence_layer {NoizuSchema.Database, cascade_block?: true}
  defmodule Entity do
    @universal_identifier false
    Noizu.DomainObject.noizu_entity(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
      identifier :ref, constraint: [Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestString.Entity]
      public_field :content
    end
  end

  defmodule Repo do
    Noizu.DomainObject.noizu_repo(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
    end
  end
end
