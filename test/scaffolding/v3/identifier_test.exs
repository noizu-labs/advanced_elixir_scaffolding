#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.IdentifierTypeTest do
  use ExUnit.Case
  use Amnesia
  use NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table
  #alias Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Entity
  #alias Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Repo
  #alias NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table
  #alias Noizu.ElixirCore.CallingContext
  require Logger
  Code.ensure_loaded?(Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema)
  
  setup do
    #Table.clear
    :ok
  end
  
  #----------------------------------
  # atom
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test Atom to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAtom.Entity{identifier: :b}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAtom.Entity.sref(sut)
    assert sref == "ref.tt-atom.b"
    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAtom.Entity.ref(sref)
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAtom.Entity, :b}
    sut = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAtom.Entity.__valid_identifier__(:b)
    assert sut == :ok
  end

  @tag :v3
  @tag :identifier_type
  test "Test Atom to/from sref - not in white list" do
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAtom.Entity.__valid_identifier__(:f)
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAtom.Entity.ref_ok("ref.tt-atom.f")
  end

  #----------------------------------
  # compound
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test compound to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity{identifier: {23, "apple",5}}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity.sref(sut)
    assert sref == "ref.tt-compound.{23,\"apple\",5}"
    {:ok, ref} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity.ref_ok(sref)
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity, {23, "apple",5}}
  end

  @tag :v3
  @tag :identifier_type
  test "Test compound to/from sref - template mismatch" do
    sref = "ref.tt-compound.{23,\"apple\",\"babba\"}"
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity.ref_ok(sref)
  end
  
  #----------------------------------
  # custom
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test custom to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCustom.Entity{identifier: {"a","bb"}}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCustom.Entity.sref(sut)
    assert sref == "ref.tt-custom.a,bb"
    {:ok, ref} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCustom.Entity.ref_ok(sref)
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCustom.Entity, {"a","bb"}}
  end
  
  #----------------------------------
  # float
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test Float to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity{identifier: 2.23}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity.sref(sut)
    assert sref == "ref.tt-float.2.23"
    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity.ref(sref)
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity, 2.23}
    {:ok, ref} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity.ref_ok("ref.tt-float.-1.2")
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity, -1.2}
  end

  @tag :v3
  @tag :identifier_type
  test "Test Float to/from sref - out of range" do
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity.ref_ok("ref.tt-float.555.0")
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity.ref_ok("ref.tt-float.-3.0")
  end

  #----------------------------------
  # hash
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test Hash to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash.Entity{identifier: "MD5HASH"}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash.Entity.sref(sut)
    assert sref == "ref.tt-hash.MD5HASH"
    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash.Entity.ref(sref)
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash.Entity, "MD5HASH"}
  end

  @tag :v3
  @tag :identifier_type
  test "Test Hash to/from sref - invalid" do
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestFloat.Entity.ref_ok("ref.tt-float.ABBA-DABBA")
  end

  #----------------------------------
  # integer
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test Integer to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity{identifier: 2}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.sref(sut)
    assert sref == "ref.tt-integer.2"
    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.ref(sref)
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity, 2}
    {:ok, ref} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.ref_ok("ref.tt-integer.-1")
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity, -1}
  end

  @tag :v3
  @tag :identifier_type
  test "Test Integer to/from sref - out of range" do
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.ref_ok("ref.tt-integer.555")
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.ref_ok("ref.tt-integer.-3")
  end
  
  #----------------------------------
  # list
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test List to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity{identifier: [:foo, :bop]}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity.sref(sut)
    assert sref == "ref.tt-list.[foo,bop]"
    # :nyi
    #{:ok, ref} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity.ref_ok(sref)
    #assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity, [:foo, :bop]}
  end

  
  #----------------------------------
  # ref
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test Ref to/from sref" do
    id = {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity, 2}
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestRef.Entity{identifier: id}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestRef.Entity.sref(sut)
    assert sref == "ref.tt-ref.(ref.tt-integer.2)"
    {:ok, ref} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestRef.Entity.ref_ok(sref)
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestRef.Entity, {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity, 2}}
  end


  #----------------------------------
  # string
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test String to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestString.Entity{identifier: "Anna Boo"}
    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestString.Entity.sref(sut)
    assert sref == "ref.tt-string.\"Anna Boo\""
    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestString.Entity.ref(sref)
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestString.Entity, "Anna Boo"}
  end
  
  #----------------------------------
  # uuid
  #----------------------------------
  @tag :v3
  @tag :identifier_type
  test "Test UUID to/from sref" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestUUID.Entity{identifier: "cd156571-f5db-474c-95e0-4a0581f55214"}
    {:ok, sref} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestUUID.Entity.sref_ok(sut)
    assert sref == "ref.tt-uuid.cd156571-f5db-474c-95e0-4a0581f55214"
    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestUUID.Entity.ref(sref)
    uuid = UUID.string_to_binary!("cd156571-f5db-474c-95e0-4a0581f55214")
    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestUUID.Entity, uuid}
    :ok = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestUUID.Entity.__valid_identifier__("cd156571-f5db-474c-95e0-4a0581f55214")
  end

  @tag :v3
  @tag :identifier_type
  test "Test UUID to/from sref - invalid uuid" do
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestUUID.Entity.__valid_identifier__("ffff-f5db-474c-95e0-4a0581f55214")
    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestUUID.Entity.ref_ok("ref.tt-uuid.ffff-f5db-474c-95e0-4a0581f55214")
  end

  
  
  #
#  @tag :v3
#  @tag :identifier_type
#  test "Test Compound to/from sref" do
#    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity{identifier: {1,"abc"}}
#    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity.sref(sut)
#    assert sref == "ref.tt-compound{1,abc}"
#    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity.ref(sref)
#    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity, {1,"abc"}}
#  end
#
#  @tag :v3
#  @tag :identifier_type
#  test "Test Component to/from sref - not in white list" do
#    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity{identifier: {"abc", 1}}
#    {:error, _} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity.sref_ok(sut)
#    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound.Entity.ref_ok("ref.tt-compound{abc,1}")
#    assert {:error, {:serialized_identifier, {:regex_mismatch, _}, "{abc,1}"}} = ref
#  end
#
#
#  @tag :v3
#  @tag :identifier_type
#  test "Test Custom to/from sref" do
#    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCustom.Entity{identifier: {"cba","abc"}}
#    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCustom.Entity.sref(sut)
#    assert sref == "ref.tt-custom.cba,abc"
#    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCustom.Entity.ref(sref)
#    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCustom.Entity, {"cba","abc"}}
#  end
#
#
#
#  @tag :v3
#  @tag :identifier_type
#  test "Test Hash to/from sref" do
#    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash.Entity{identifier: "BADF00D"}
#    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash.Entity.sref(sut)
#    assert sref == "ref.tt-hash.BADF00D"
#    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash.Entity.ref(sref)
#    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash.Entity, "BADF00D"}
#  end
#
#
#
#
#  @tag :v3
#  @tag :identifier_type
#  test "Test Integer to/from sref" do
#    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity{identifier: 2}
#    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.sref(sut)
#    assert sref == "ref.tt-integer.2"
#    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.ref(sref)
#    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity, 2}
#  end
#
#
#  @tag :v3
#  @tag :identifier_type
#  test "Test Integer to/from sref - not in white list." do
#    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity{identifier: 500}
#    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.sref(sut)
#    assert sref == "ref.tt-integer.500"
#    ref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestInteger.Entity.ref_ok(sref)
#    assert ref == {:error, {:identifier, {:not_in_range, {-2, 4}}, 500}}
#  end
#
#
#
#  @tag :v3
#  @tag :identifier_type
#  test "Test List to/from sref" do
#    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity{identifier: [:bop, :biz, :foo, :bop,:bop]}
#    sref = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity.sref(sut)
#    assert sref == "ref.tt-list[bop,biz,foo,bop,bop]"
#    {:ok, ref} = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity.ref_ok("ref.tt-list[bop,biz,foo,bop,bop]")
#    assert ref == {:ref, Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity, 2}
#  end
#
#
#  @tag :v3
#  @tag :identifier_type
#  test "Test List to/from sref - not in white list." do
#    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity{identifier: [:snoop, :dogg]}
#    {:ok, "ref.tt-list[snoop,dogg]"} =  Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity.sref_ok(sut)
#    {:error, _} = error = Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList.Entity.ref_ok("ref.tt-list[snoop,dogg]")
#    IO.inspect error
#  end



end
