#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestString do
  use Noizu.DomainObject
  @vsn 1.0
  @sref "tt-string"
  @persistence_layer {NoizuSchema.Database, cascade_block?: true}
  defmodule Entity do
    @universal_identifier true
    Noizu.DomainObject.noizu_entity(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
      identifier :string
      public_field :content
    end
  end

  defmodule Repo do
    Noizu.DomainObject.noizu_repo(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
    end
  end
end
