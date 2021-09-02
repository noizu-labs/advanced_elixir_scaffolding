# Noizu.AdvancedScaffolding

This library provides some general tools to reduce some boiler plate code around working with objects, performing CRUD, auditing changes, performing basic authorization checks, and working with entity references (foreign keys). It includes various concepts previously applied to some of our private projects including blade of eternity, lacrosse alerts, and solace club.

## Additional Documentation
* [Api Documentation](http://noizu-labs.github.io/advanced_elixir_scaffolding)

## Refs
Refs provide a universal way for database records to reference other internal or external entities. They take the form of a tuple as follows: {:ref, Entity.Module, identifier} where
Entity.Module is the type of entity we are referencing and provides a method entity(nmid) that is capable of fetching the entity referenced by the listed identifier.

This makes it straight forward for a table to reference various other entity types in a generic way. Additionally the Noizu.ERP (Entity Reference Protocol) provides a straight forward
mechanism for handling references with out knowing in advance if they have been expanded or their exact type.

The EntityReferenceProtocol (alias Noizu.ERP, as: EntityReferenceProtocol) is defined as follows:

```
  defprotocol Noizu.ERP do
    @doc "Cast to noizu reference object"
    def ref(obj)

    @doc "Cast to noizu string reference object"
    def sref(obj)

    @doc "Convert to persistence object. Options may be passed to coordinate actions like expanding embedded references."
    def record(obj, options)

    @doc "Convert to persistence object Options may be passed to coordinate actions like expanding embedded references. (With transaction wrapper if required)"
    def record!(obj, options)

    @doc "Convert to scaffolding.struct object. Options may be passed to coordinate actions like expanding embedded references."
    def entity(obj, options)

    @doc "Convert to scaffolding.struct object Options may be passed to coordinate actions like expanding embedded references. (With transaction wrapper if required)"
    def entity!(obj, options)
  end # end defprotocol Noizu.ERP
```

Where the methods ref and sref convert any participating objects into {:ref, Module, id} and "ref.module.id" format respectively;  record and record! expand a reference into whatever format is used for db persistence (where options gives us a hook to dynamically adjust how records are converted to, for example, insert linked records if needed); and finally, where entity/2 and entity!/2 will insure our reference is in entity (struct) format.

It is up to the library user to provide the defimpls needed to handle sref format strings "ref.type.identifier", along with defimpls for any structs and database classes used.
Additionally it is up to the library user to ensure that their struct classes implement the Noizu.AdvancedScaffolding.EntityBehaviour and that their structs and persistence records provide defimpls of the EntityReferenceProtocl to allow their conversion into ref, sref, record and entity format.

## AuditEngine

The Noizu.AdvancedScaffolding.RepoBehaviour will automatically make auditing calls as records are accessed and modified. This makes it very straight forward (provided an AuditEngine is defined) to generate robust audits of who has modified what and when.

A possible implementation may look like the following mnesia table and defimpl. Note how the mnesia table is setup to allow us to easily search by
entity, request token, time, or editor.

```elixir
defmodule YourProject.AuditEngine do
  @behaviour Noizu.AdvancedScaffolding.AudingEngineBehaviour

  def audit(event, details, entity, context, note \\ nil) do  
    %MnesiaDb.AuditHistory{
      entity: EntityReferenceProtocol.ref(entity),
      event: event,
      details: details,
      time_stamp: DateTime.utc_now(),
      request_token: context.token,
      editor: EntityReferenceProtocol.ref(context.caller),
      reason: context.reason,
      note: note
    } |> MnesiaDb.AuditHistory.write
    :ok
  end

  def audit!(event, details, entity, context, note \\ nil) do
    Amnesia.Fragment.transaction do
      audit(event, details, entity, context, note)
    end
  end
end


#-----------------------------------------------------------------------------
# @AuditHistory
#-----------------------------------------------------------------------------
deftable AuditHistory,
  [:entity, :event, :details, :time_stamp, :request_token, :editor, :reason, :note],
  type: :bag,
  index: [:request, :time_stamp, :editor],
  fragmentation: [number: 5, copying: %{disk!: 1}] do
  @moduledoc """
  Audit History - Basic structure for an Audit History Table
  """
  @type t :: %AuditHistory{
    entity: Types.entity_reference, # The object being modified.
    event: atom | tuple, # the event being audited, such as create table.
    details: any, # additional details about entry
    time_stamp: DateTime.t, # utc.now() of audit entry.
    request_token: String.t, # unique token that may be used to collate all audit logs related to a specific request.
    editor: Types.entity_reference, # who made the change.
    reason: String.t | nil, # calling.context reason (if any) provided when a call was made via api.
    note: String.t | nil, # internal note about audit entry. Created when entry was created or added by a moderator later on.
  }
end # end deftable
```

## Calling Context

The Noizu.AdvancedScaffolding.CallingContext structure is used to pass information about API or related requests through out the system so that it is possible to confirm that a given caller is authorized to make changes, log who the caller was, apply global options to the request (such as expanding refs where found), and pass along a request token to allow admins to easily
collate requests across systems.

```
@type t :: %CallingContext{
  caller: tuple,
  token: String.t,
  reason: String.t,
  auth: Any,
  options: Map.t,
  vsn: float
}
```

It is left to the user to implement the logic needed to populate a CallingContext with these values. A sample implementation is below.

```
  alias Noizu.AdvancedScaffolding.CallingContext, as: CallingContext
  def default_get_context(conn, params, opts \\ %{})
  def default_get_context(conn, params, _opts) do
    token = params["request-id"] || case (get_resp_header(conn, "x-request-id")) do
      [] -> CallingContext.generate_token()
      [h|_t] -> h
    end
    reason = params["call-reason"] || case (get_req_header(conn, "x-call-reason")) do
      [] -> nil
      [h|_t] -> h
    end

    expand_refs = nil # TODO - support ability for callers to request specific expansions.
    expand_all_refs = if params["expand-all-refs"] == "true" do
      true
    else
      case get_req_header(conn, "x-expand-all-refs") do
        [] -> false
        [h|_t] -> h == "true"
      end
    end

    options = %{
      expand_refs: expand_refs,
      expand_all_refs: expand_all_refs
    }

    case Guardian.Plug.current_resource(conn) do
      auth = %{"identifier" => user_identifier} ->
        %CallingContext{
          caller: {:ref, user_identifier, SolaceBackend.Repos.UserRepo},
          token: token,
          reason: reason,
          auth: auth,
          options: options
        }
      _ ->
      %CallingContext{
        caller: unauthenticated_ref(conn),
        token: token,
        reason: reason,
        auth: nil,
        options: options
      }
    end
  end # end get_context/3

  def get_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [h|_] -> h
      [] -> conn.remote_ip |> Tuple.to_list |> Enum.join(".")
      nil ->  conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    end
  end # end get_ip/1

  def unauthenticated_ref(conn) do
   {:ref, System.UnauthenticatedUser, get_ip(conn)}
  end # end unauthenticated_ref/1  
```

## Noizu Mnesia Identifiers (NMIDs)
AS an alternative to GUID based identifiers this library relies on noizu_mnesia_identifiers.
Each Entity/Table is assigned a unique identifier, as well as each node. 
Relying on these Repos provide a nmid_generator that produces sequential identifiers (per entity/table) with the final digits taken up with the server.node identifier + table/entity identifier. 

```elixir

def generate(seq, _opts \\ nil) do
  case seq.__nmid__(:bare) do
    true -> bare(seq)
    :node -> bare_node(seq)
    _ ->
      current = :mnesia.dirty_update_counter(Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, seq, 1)
      map_id(current, @node_key, seq.__nmid__(:index))
  end
end

def map_id(sequential_identifier, node_key, entity_key) do
  sequential_identifier * 1_00_000 + (rem(node_key, 99) * 1_000) + rem(entity_key, 999)
end
```



New Features 
===========================================
Advanced Scaffolding / Annotation / Indexing / Telemetry / Json Formatting / Security / PII management.

## See
- `Noizu.AdvancedScaffolding.Internal.Core.Entity.Behaviour`
- `Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Behaviour`
- `Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Behaviour`
- `Noizu.AdvancedScaffolding.Internal.Index.Behaviour`
- `Noizu.AdvancedScaffolding.Internal.Json.Entity.Behaviour`


# Json Formatting Annotation
- Support for multiple json formatting view (mobile, admin, etc.)
- 
```elixir
@json_format_group {:user_clients, [:compact]}
@json_provider unquote(json_provider)
defmodule Entity do
  Noizu.DomainObject.noizu_entity do
    @meta {:enum_entity, true}
    identifier :integer
    @json {:*, :expand}
    @json_embed {:user_clients, [{:title, as: :name}]}
    @json_embed {:verbose_mobile, [{:title, as: :name}, {:body, as: :description}, {:editor, sref: true}, :revision]}
    public_field :description, nil, type: Noizu.VersionedString.Type

    @json {:*, format: :iso8601}
    @json_ignore :user_clients
    public_field :created_on, nil, type: Noizu.DateTime.Type

    @json {:*, format: :iso8601}
    @json_ignore [:user_clients]
    public_field :modified_on, nil, type: Noizu.DateTime.Type

    @json {:*, format: :iso8601}
    @json_ignore [:user_clients, :verbose_mobile]
    public_field :deleted_on, nil, type: Noizu.DateTime.Type
  end
end
```

- Support for embedding nested components inside of entity. E.g. pull CMS record details and return inline as port of entity instead of as nested objects.

```elixir
defmodule Entity do
  use Noizu.DomainObject.noizu_entity() do
    @json {:mobile, embed: [{description, as:  :oh_hi}]
    public_field :description
  end
end

a = %Entity{
    description: %VersionedString{identifier: 5, description: "mark", created_on: :tuesday}
}


# Poison.encode!(a, json_format: :mobile)
{identifier: 0, oh_hi: "mark"}

# Poison.encode!(a, json_format: :admin)
{identifier: 0, description: %{identifier: 5, description: "mark", created_on: :tuesday}}
```

# Content Permission Annotation and Fields

- Flag fields that should only be accessible by administrators, owning user, or users owner has shared with with field types and annotation. Flag PII fields automatically suppress in log output by default.
```elixir
defmodule Entity do
    @universal_identifier true
    Noizu.DomainObject.noizu_entity do
    @permissions {[:view, :index], :unrestricted}
    identifier :integer
    
     public_field :owner
    
     @json {:*, :ignore}  # don't include this field by default in json response
     @json {:admin_api, :include} # except for admin_api formatted calls. 
     public_field :last_login
    
      # User (programmer) defined permission check - when attempting to access :bio check UserShare.has_permission? method to see if api caller has permission to view. 
      @permissions :view, {:restricted, {UserShare, :has_permission?}}
      user_field :bio
    
      # Only users with :account_moderator permission (granted by ACL - admin group membership} can edit/set   
      # All callers can view the account_flag field. 
      @permissions {:*, {:has_permission: :account_moderator}}, {:view, :unrestricted}
      @restricted_field :account_flag 
    
      # Only users who are members of the :system_account or :super_admin group may access.
      @permissions {:*,  [{:in_group: :system_account}, {:in_group: :super_admin}]}
      @restricted_field :account_flag 
    
     # Low security (level 3) personally identifiable data. Can be included in most logs and exception messages.
      @pii level_3
      restricted_field :name, nil, Noizu.VersionedName.Type
    
     # High Security (level 0) PII. Only include in the most secure logs, strip from raised exceptions, etc.
      @pii :level_0
      restricted_field :social_security
    end
end

# User (programmer) defined permission check. This example allows caller to view user.bio if the user
# account is public or the caller is a friend with the user who the bio field belongs to.

defmodule UserShare do
    # the caller is a friend of the user, otherwise it restricts access and the bio field will not be returned to the caller.
    def has_permission?(:view, :bio, entity, context) do
      user = Noizu.ERP.entity!(entity.owner)
      cond do
        user.public_account? -> :permission_granted
        user.friend?(context.caller) -> :permission_granted
      :else -> :permission_denied
      end
    end
end
```

# Built in Multiple Datastore(s) + Cache management.

- Scaffolding managing keeping different datastores and cache layers up to date.
```elixir
defmodule RootLevel.NestedLevel.Image do
    use Noizu.DomainObject
    @vsn 1.0
    @sref "image"
    
    # Default Mnesia Database  (RootLevelSchema.Database) and table.  RootLevelSchema.Repo.database() <> "NestedLevel.Image.Table"
    @persistence_layer :mnesia
    
    # Default Ecto Database/Repo (RootLevelSchema.Repo) and table.  RootLevelSchema.Repo.database() <> "NestedLevel.Image.Table"
    @persistence_layer {:ecto, cascade?: true, fallback_load: true}
    
    # Default Ecto Database with specific table, for example to allow lazy migration from a deprecated table
    @persistence_layer {:ecto, cascade?: false, fallback_load: true, table: NoizuSchema.MySQL.PreviousDatabaseTable}
    
    # don't update/delete/create in legacy MSSQL database during crud operations. {cascade?: false}
    # allow load from mssql if entity not found in :mnesia or :ecto (MySQL)
    @persistence_layer {NoizuSchema.MSSQLRepo, cascade?: false, fallback_load: true}
    
    
    # call archive provider on_delete hook when deleted entity, allows archive implementation to save entry to archive storage.
    @persistence_layer {:archive, cascade_delete?: true} # call archive provider on_delete hook when deleted entity, allows archive implementation to save entry to archive storage.
    
    # Cache to redis and precache/update cascade one changes.
    # Don't return from Repo.create/update/delete until redis update complete (cascade_blocking: true),
    # automatic cache delete after 600 seconds. {ttl: 600}
    @persistence_layer {:redis, cascade?: true, cascade_blocking: true, ttl: 600}

    
    defmodule Entity do
      @universal_identifier true
      Noizu.DomainObject.noizu_entity do
        identifier :string
        ecto_identifier :integer
        public_fields [
        :description,
        :blur_hash,
        :hash,
        :base,
        :source,
        :base_dimensions,
        :external,
        :image_type,
        :file_format,
        :locale,
        :localized,
        :interactions]
        public_fields [:created_on, :modified_on, :deleted_on]
      internal_fields [:moderation_status, :content_flag, :sphinx_index]
    end


    def __from_record__(:NoizuSchema.MSSQLRepo, %NoizuSchema.MSSQL.NestedLevel.ImageTable{} = record, context, options) do
      %__MODULE__{custom_table_to_entity_provider: record.field}
    end
    def __from_record__(type, record, context, options) do
      # fallback to default providers. automatically injected by noizu_entity's before_compile method. 
      super(type, record, context, options)
    end
  end
end
```

# Sphinx Indexing Support

- index annotation and definitions automate search index population and formatting

```elixir
# Automatically apply 5.2 km anonymization to location fields, always strip pii level 1 or lower
# Automatically generate Noizu.#{Base}.Indexer module due to inline: :sphinx argument
@index self: :sphinx, type: :realtime, [defaults: [{MyApp.Sphinx.LocationIndex, [anonymize: 5.2]}], pii: :level_2]

# include sensitive user data in index | runtime meta data scanning allows this index :admin_index to cover multiple entity types with out additional user configuration
@index MyApp.Admin.Indexer, pii: :level_0

defmodule Entity do
@universal_identifier true
Noizu.DomainObject.noizu_entity do
@permissions {[:view, :index], :unrestricted}
identifier :integer

      @index true
      restricted_field :name, nil, MyApp.VersionedName.Type

      # Allow custom index controls, such as allowing users with private accounts to exclude their details from search. 
      @index {:user_defined, {MyApp.UserEntity, :index}}
      restricted_field :gender

      @index {MyApp.Admin.Indexer, as: :blob} # Include in multiple entity admin search index, embed field in json blob as admin index will not include entity specific fields like this.  
      @index {:inline, {:user_defined, {MyApp.UserEntity, :index}}}
      restricted_field :orientation

      # use MyAppIndex.Location handler to add  #{field}_longitude, #{field}_latitude, #{field}_zone, and #{field}_radius indexes for this field e.g. geo: %{longitude: 123.3, latitude: 432.0, radius: 5.2} 
      @index MyApp.Admin.Indexer: [with: MyAppIndex.Location]}
      @index inline: [with: {MyAppIndex.Location, anonymize: [radius: 25]}]  # Anonymize location to 25 radius bubble 
      restricted_field :geo

      @index true # Type Specification (MyAppSchema.Geo) will automatically trigger MyAppIndex.Location for unpacking -> :home_town_longitude, :home_town_latitude, :home_town_radius ...
      restricted_field :home_town, nil, MyAppSchema.Geo

# Todo
defmodule Jety.Admin.Indexer do
use Noizu.DomainObject.Sphinx.Indexer
# ...
end
```

# Built in Logging/Telemetry

- Collate-able logs, and telemetrics automatically generated as entities are edited, accessed, cached, etc.

- Unique Numeric Database Identifiers

- Table + Node section of Identifiers allow mapping of universal ids to specific entity (entity encoded in identifiers to mimic the elixir framework's {:ref, _, id} concept.  Greatly simplifies sphinx index id lookup, provides benefits of GUIDs while retaining much faster 64 bit unsigned int matching.Eventually very busy tables will need to break out into UUIDs as we approach the limits of 64 bit universal identifiers.

```elixir
MyApp.User.Repo.generate_identifier!() ->  1234005001 ,  where 1234 is User.Entity current incrementor value for this node, 005 is a unique identifier for a User.Entity/Table, and 001 is a node/server specific identifier.
# Scaffolding automatically injects UniversalIdentifierResolution{1234005001,  ref: {:ref, UserEntity, 1234005001}}} entry
# If User was a univeral_lookup but not universal_identifier entity it's id would be 1234, while the universal identifier would reamain 1234005001 -> UniversalIdentifierResolution{1234005001, ref: {:ref, User.Entity, 1234}}
```

- Built in handling of Atom to Enum mapping when switching between RDMS and elixir.

- Look Up Entities automatically generate Ecto types to avoid the need to manually map back and forth between number enumerators and their associated elixir atoms.Thus we can do something like the following
```elixir
schema "table" do
    field status:  MyApp.Status.EctoEnumType
end

defmodule MyApp.Status.Entity do
    MyApp.ElixirScaffolding.enum_table([online: 0, offline: 1])
end

%MySQL.Table{status: :online} |> Repo.create()
t =Repo.get(MySQL.Table, identifier)
if t.status == :offline, do: stuff()
```

rather than the much more verbose equivalent

```elixir
schema "table" do
    field status: identifier
end


defmodule MyApp.Status.Entity do
    ...
    @enum_to_atom %{
    0 => :online,
    1 => :offline,
    ...
    }
    
    @atom_to_enum %{
    online: 0,
    offline: 1,
    ...
    }
    
    def enum_to_atom(v), do: @enum_to_atom[v]
end

%MySQL.Table{status: MyApp.Status.Entity.atom_to_enum(:status)} |> Repo.create()
t = Repo.get(MySQL.Table, identifier)
if MyApp.Status.Entity.enum_to_atom(t.status) == :offline, do: stuff()
```

- Reduce Lines of Code & Maintenance*

- Scaffolding + Annotation takes care of basic Json/Database Crud

- Aspect-Oriented-Programming via annotation and macros + config options allow fine tuned extensions and customization of objects.

- Straight forward roll out of cluster wide aop behaviors/extensions.

For Example

```elixir
defmodule MyApp.Image.Type do
    @vsn 1.0
    @sref "image-type"
    use MyApp.ElixirScaffolding.EnumEntity,
    values: [none: 0, profile: 1, background: 2, post: 3, user_upload: 4, logo: 5, moment: 6, shout_out: 7]
end
```

- Automatically generates
  - Image.Type.Entity
  - Image.Type.Repo
  - Image.Type.EctoEnumType
  - Image.Type.EctoEnumReference
  - MyApp.EnumEntity.Indexer  # Search all entities or entities of a specific type to bring up matches for api text autocomplete
  - Noizu.ERP.ref handlers for (Image.Type.Entity, Mysql.Image.Type.Table, Mnesia.Image.Type.Table)

- Name/Description Versioning  - (Uses a Noizu.VersionedString that provides simple revision history of changes to fields title/description)

- Runtime Noizu.ERP ref string parser extension to handle "ref.image-type.1234" formatted reference strings.

# Crud

Json formatting (for mobile view collapse to string %MyApp.Image.Type{1, description: %{title: "User"}}) -> "User"

Data setup helpers.

and  this line in  jetzy/lib/jetzy_schema/mysql/enum_tables.ex
```elixir
require MyAppSchema.EnumTableBehaviour
# . . .
MyAppSchema.EnumTableBehaviour.table(:image_type, Elixir.MyApp.Image.Type.Entity)
# . . .
```

generates a MyAppSchema.MySQL.Image.Type.Table currently equivalent to:

```elixir
defmodule MyAppSchema.MySQL.Image.TypeTable do
@primary_key {:identifier, :id, autogenerate: false}
@derive {Phoenix.Param, key: :identifier}
schema "image_type" do
#field :description, MyApp.VersionedString.EctoUniversalReference

          #  Standard Time Stamps
          field :created_on, :utc_datetime_usec
          field :modified_on, :utc_datetime_usec
          field :deleted_on, :utc_datetime_usec
        end

        
      #-------------------------------
      # new
      #-------------------------------
      def new(options \\ %{}) do
        struct(__MODULE__, options)
      end

      #-------------------------------
      # changeset
      #-------------------------------
      def changeset(record, params) do
        fields = Map.keys(record) -- [:__struct__, :__schema__, :__meta__]
        record
        |> cast(params, fields)
        |> validate_required([])
      end


      
      defdelegate __entity__(), to: MyApp.Image.Type.Entity
      defdelegate __repo__(), to: MyApp.Image.Type.Entity
      defdelegate __sref__(), to: MyApp.Image.Type.Entity
      defdelegate __erp__(), to: MyApp.Image.Type.Entity

      defdelegate __persistence__(setting \\ :all), to:  MyApp.Image.Type
      defdelegate __persistence__(selector, setting), to:  MyApp.Image.Type
      defdelegate __nmid__(setting), to: MyApp.Image.Type.Entity

      def __schema_table__(), do: :image_type

      def __noizu_info__(:type), do: :enum_table
      defdelegate __noizu_info__(setting), to:  MyApp.Image.Type
end
```
