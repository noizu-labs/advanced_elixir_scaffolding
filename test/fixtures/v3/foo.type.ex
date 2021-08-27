#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 JetzyApp. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Type do
  use Noizu.DomainObject
  @vsn 1.0
  @sref "foo-v3-type"
  @persistence_layer {NoizuSchema.Database, cascade_block?: true}
  defmodule Entity do
    @enum_list [
      {NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table , 0},
    ]
    Noizu.DomainObject.noizu_entity(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
      identifier :integer
      public_field :content
      public_field :second
    end
  end

  defmodule Repo do
    Noizu.DomainObject.noizu_repo(noizu_domain_object_schema: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema) do
    end
  end

end
