#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.RepoTest do
  use ExUnit.Case
  use Amnesia
  use NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table
  alias Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Entity
  alias Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Repo
  alias NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table
  alias Noizu.ElixirCore.CallingContext

  Code.ensure_loaded?(Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema)

  setup do
    Table.clear
  end

  @tag :v3
  test "Modules" do
    assert Repo.__entity__() == Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Entity
    assert Repo.__repo__() == Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Repo
    assert Repo.__base__() == Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo
  end

  @tag :v3
  test "Create Entity" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    assert entity.identifier != nil
  end

  @tag :v3
  test "Create, and Update" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    entity = %Entity{entity| content: :goodbye}  |> Repo.update!(context)
    assert entity.content == :goodbye
  end

  @tag :v3
  test "Create, Update, Get" do
    context = CallingContext.system()
    original_entity = %Entity{content: :hello} |> Repo.create!(context)
    updated_entity = %Entity{original_entity| content: :goodbye}  |> Repo.update!(context)
    fetched_entity = Repo.get!(updated_entity.identifier, context)
    assert fetched_entity.content == :goodbye
    assert fetched_entity.identifier == original_entity.identifier
  end

  @tag :v3
  test "Create, Update, Get, Delete, Get" do
    context = CallingContext.system()
    original_entity = %Entity{content: :hello} |> Repo.create!(context)
    updated_entity = %Entity{original_entity| content: :goodbye}  |> Repo.update!(context)
    fetched_entity = Repo.get!(updated_entity.identifier, context)
    Repo.delete!(fetched_entity, context)
    no_entity = Repo.get!(fetched_entity.identifier, context)
    assert no_entity == nil
  end

  @tag :v3
  test "Noizu.ERP.ref(entity)" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    ref = Noizu.ERP.ref(entity)
    assert ref == {:ref, Entity, entity.identifier}
  end

  @tag :v3
  test "Noizu.ERP.ref(record)" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)

    layer = List.first(Entity.__persistence__(:layers))
    record = Entity.__as_record__(layer, entity, context)

    ref = Noizu.ERP.ref(record)
    assert ref == {:ref, Entity, entity.identifier}
  end

  @tag :v3
  test "Entity.ref(sref)" do
    # note we can't test Noizu.ERP.ref(sref) directly as implementor must provide.
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    sref = "ref.foo-v3-test.#{entity.identifier}"
    ref = Entity.ref(sref)
    assert ref == {:ref, Entity, entity.identifier}
  end

  @tag :v3
  test "Noizu.ERP.entity!(ref)" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    IO.inspect NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table.keys!
    ref = Entity.ref(entity.identifier) |> IO.inspect
    unboxed_entity = Noizu.ERP.entity!(ref)
    assert unboxed_entity == entity
  end

  @tag :v3
  test "Noizu.ERP.entity!(record)" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    layer = List.first(Entity.__persistence__(:layers))
    record = Entity.__as_record__(layer, entity, context)
    unboxed_entity = Noizu.ERP.entity!(record)
    assert unboxed_entity == entity
  end

  @tag :v3
  test "Entity.entity!(entity)" do
    # note we can't test Noizu.ERP.ref(sref) directly as implementor must provide.
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    unboxed_entity = Noizu.ERP.entity!(entity)
    assert unboxed_entity == entity
  end

  @tag :v3
  test "Noizu.ERP.sref(ref)" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    ref = Entity.ref(entity.identifier)
    sref = Noizu.ERP.sref(ref)
    expected_sref = "ref.foo-v3-test.#{entity.identifier}"
    assert sref == expected_sref
  end

  @tag :v3
  test "Noizu.ERP.sref(entity)" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    sref = Noizu.ERP.sref(entity)
    expected_sref = "ref.foo-v3-test.#{entity.identifier}"
    assert sref == expected_sref
  end

  @tag :v3
  test "Noizu.ERP.sref(record)" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    layer = List.first(Entity.__persistence__(:layers))
    record = Entity.__as_record__(layer, entity, context)
    sref = Noizu.ERP.sref(record)
    expected_sref = "ref.foo-v3-test.#{entity.identifier}"
    assert sref == expected_sref
  end

  @tag :v3
  test "Noizu.ERP.ref([tuple])" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    entity_two = %Entity{entity| identifier: entity.identifier + 1} |> Repo.create!(context, [override_identifier: true])
    entity_three = %Entity{entity| identifier: entity.identifier + 2} |> Repo.create!(context, [override_identifier: true])

    layer = List.first(Entity.__persistence__(:layers))
    record = Entity.__as_record__(layer, entity_two, context)

    refs = Noizu.ERP.ref([Entity.ref(entity), record, entity_three])
    assert refs == [Entity.ref(entity), Entity.ref(entity_two), Entity.ref(entity_three)]
  end

  @tag :v3
  test "Noizu.ERP.entity([tuple])" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    entity_two = %Entity{entity| identifier: entity.identifier + 1} |> Repo.create!(context, [override_identifier: true])
    entity_three = %Entity{entity| identifier: entity.identifier + 2} |> Repo.create!(context, [override_identifier: true])

    layer = List.first(Entity.__persistence__(:layers))
    record = Entity.__as_record__(layer, entity_two, context)

    refs = Noizu.ERP.ref([Entity.ref(entity), record, entity_three])
    entities = Noizu.ERP.entity!(refs)
    assert entities == [entity, entity_two, entity_three]
  end


  @tag :v3
  test "Repo.list!" do
    context = CallingContext.system()
    entity = %Entity{content: :hello} |> Repo.create!(context)
    _entity_two = %Entity{entity| identifier: entity.identifier + 1} |> Repo.create!(context, [override_identifier: true])
    _entity_three = %Entity{entity| identifier: entity.identifier + 2} |> Repo.create!(context, [override_identifier: true])

    _r = Amnesia.Fragment.transaction do
           Table.where true == true
         end
    # needs to be reimplemented
    #entities = Repo.list!(context) |> Enum.sort(&(&1.identifier <= &2.identifier))
    #assert entities == [entity, entity_two, entity_three]
  end

end
