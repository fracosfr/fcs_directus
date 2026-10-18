# Graph Report - fcs_directus  (2026-10-18)

## Corpus Check
- 444 files · ~116,073 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: (none) 4, .lock 1, .iml 1)

## Summary
- 2185 nodes · 3463 edges · 104 communities (101 shown, 3 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 98 edges (avg confidence: 0.89)
- Token cost: 811,455 input · 0 output

## Community Hubs (Navigation)
- OpenAPI Panels/Users CRUD Endpoints
- DirectusProperty Typed Accessors
- OpenAPI Comments/Dashboards Endpoints
- DirectusClient Service Hub
- DirectusModel Base & Getters
- WebSocket Realtime Client
- Library Barrel Exports
- Filter Builder
- Directus Functions & Dynamic Vars
- OpenAPI Index & Security
- OpenAPI Permissions/Relations
- CollectionsService
- DirectusUser Model
- OpenAPI Files & Roles
- Asset Transforms
- DirectusField Model
- ItemsService Queries
- ActivityService
- FieldsService
- Flow Model
- AuthService & Tokens
- DirectusPolicy Model
- OpenAPI Utils Endpoints
- OpenAPI Operations Endpoints
- Operation Model
- OpenAPI Files/Folders Bulk
- Preset Model
- Exception Types
- Panel Model
- OpenAPI Notifications Endpoints
- Activity & Revision Models
- HTTP Client (Dio)
- Role Model
- OpenAPI Component Schemas
- Permission Model
- OpenAPI Policies Endpoints
- OpenAPI Current User (Me)
- Notification Model
- OpenAPI Content Versions
- OpenAPI Presets Endpoints
- Deep Queries
- Aggregations
- Relation Model
- AssetsService
- Dashboard Model
- FoldersService
- NotificationsService
- FlowsService
- ItemActiveService
- PresetsService
- UsersService (2FA, Invite)
- VersionsService
- Revision Model
- Property Wrapper Types
- Generated Test Mocks
- FilesService
- OpenAPI Share Info
- Comment Model
- PoliciesService
- RolesService
- SharesService
- TranslationsService
- OpenAPI Schema Migration
- OpenAPI Share Auth
- OpenAPI Server Endpoints
- DirectusConfig
- Unit Tests Core
- CommentsService
- DashboardsService
- OperationsService
- PanelsService
- ItemActiveService Tests
- OpenAPI User Invite/Register
- Folder Model
- Model Subclasses
- OpenAPI Items Endpoints
- OpenAPI Settings & Info
- OpenAPI Shares Bulk
- Package Dependencies
- OpenAPI Extensions
- Exception Hierarchy Docs
- Enum Property Tests
- OpenAPI 2FA Enable
- Custom Models Guide
- Filter Types Hierarchy
- ExtensionsService
- Docs: WebSocket & Files
- Project Scope & Filter Rules
- Changelog & Contributing
- Docs: CRUD & Aggregations
- Response Helper
- OpenAPI User By ID
- Model Test Helpers
- Docs: Authentication
- Docs: Getting Started
- Docs: Users & Permissions
- Nested Filter Tests
- OpenAPI 2FA Disable
- Auto Refresh Tests
- Mock HTTP Client
- ObjectProperty & MapToFilter
- Diff Schema
- Extensions Schema
- Translations Schema

## God Nodes (most connected - your core abstractions)
1. `UnauthorizedError response` - 177 edges
2. `NotFoundError response` - 144 edges
3. `Meta parameter` - 82 edges
4. `Fields parameter` - 74 edges
5. `Sort parameter` - 40 edges
6. `Offset parameter` - 39 edges
7. `x-metadata schema` - 39 edges
8. `Limit parameter` - 39 edges
9. `Filter parameter` - 38 edges
10. `Search parameter` - 38 edges

## Surprising Connections (you probably didn't know these)
- `Session refresh & restore` --semantically_similar_to--> `Automatic token refresh with persistence callbacks`  [INFERRED] [semantically similar]
  docs/02-authentication.md → README.md
- `QueryParameters` --semantically_similar_to--> `OpenAPI query/path parameters (fields, filter, sort, limit, offset, page, search, meta, export, version, backlink)`  [INFERRED] [semantically similar]
  docs/03-crud-operations.md → openapi/components/parameters.yaml
- `fcs_directus package` --semantically_similar_to--> `Directus SDK (@directus/sdk)`  [INFERRED] [semantically similar]
  pubspec.yaml → openapi/paths/shares/createShares.yaml
- `Auth error callback` --semantically_similar_to--> `onAuthError callback (DirectusConfig)`  [INFERRED] [semantically similar]
  docs/02-authentication.md → CHANGELOG.md
- `OpenAPI error responses (NotFoundError, UnauthorizedError)` --semantically_similar_to--> `DirectusNotFoundException`  [INFERRED] [semantically similar]
  openapi/components/responses.yaml → docs/11-error-handling.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Type-safe query building (QueryParameters + Filter + DeepQuery + Aggregate)** — docs_03_crud_operations_queryparameters, docs_05_filters_filter_builder, docs_06_deep_queries_deepquery, docs_07_aggregations_aggregate [INFERRED 0.95]
- **Directus typed exceptions** — docs_11_error_handling_directusexception_hierarchy, docs_11_error_handling_directusauthexception, docs_11_error_handling_directusvalidationexception, docs_11_error_handling_directuspermissionexception, docs_11_error_handling_directusnotfoundexception, docs_11_error_handling_directusratelimitexception, docs_11_error_handling_directusnetworkexception, docs_11_error_handling_directusserverexception [EXTRACTED 1.00]
- **Auth session lifecycle (refresh, restore, error callback)** — readme_auto_refresh, docs_02_authentication_session_restore, changelog_onautherror_callback, docs_02_authentication_auth_error_callback, changelog_fix_404_refresh [INFERRED 0.85]
- **Directus Access Control (users/roles/policies/permissions)** — openapi_components_schemas_users_users, openapi_components_schemas_roles_roles, openapi_components_schemas_policies_policies, openapi_components_schemas_permissions_permissions [EXTRACTED 1.00]
- **Directus Flows Automation** — openapi_components_schemas_flows_flows, openapi_components_schemas_operations_operations, openapi_components_schemas_users_users [EXTRACTED 1.00]
- **Directus Schema Snapshot (collections/fields/relations)** — openapi_components_schemas_schema_schema, openapi_components_schemas_collections_collections, openapi_components_schemas_fields_fields, openapi_components_schemas_relations_relations [EXTRACTED 1.00]
- **Directus token-based auth session lifecycle** — openapi_paths_auth_login_login_login, openapi_paths_auth_refresh_refresh_refresh, openapi_paths_auth_logout_logout_logout, openapi_paths_auth_login_login_auth_mode [INFERRED 0.85]
- **Password reset flow** — openapi_paths_auth_password_request_passwordrequest_passwordrequest, openapi_paths_auth_password_reset_passwordreset_passwordreset, openapi_paths_auth_password_request_passwordrequest_password_reset_url_allow_list [EXTRACTED 1.00]
- **Directus Collections CRUD API** — openapi_paths_collections__id_getcollection_getcollection, openapi_paths_collections__id_updatecollection_updatecollection, openapi_paths_collections_createcollection_createcollection, openapi_paths_collections_getcollections_getcollections [EXTRACTED 1.00]
- **Directus Comments CRUD API** — openapi_paths_comments__id_deletecomment_deletecomment, openapi_paths_comments__id_getcomment_getcomment, openapi_paths_comments__id_updatecomment_updatecomment, openapi_paths_comments_createcomments_createcomments, openapi_paths_comments_deletecomments_deletecomments, openapi_paths_comments_getcomments_getcomments, openapi_paths_comments_singular_createcomment_createcomment, openapi_paths_comments_updatecomments_updatecomments [EXTRACTED 1.00]
- **Directus Dashboards CRUD API** — openapi_paths_dashboards__id_deletedashboard_deletedashboard, openapi_paths_dashboards__id_getdashboard_getdashboard, openapi_paths_dashboards__id_updatedashboard_updatedashboard, openapi_paths_dashboards_createdashboards_createdashboards, openapi_paths_dashboards_deletedashboards_deletedashboards, openapi_paths_dashboards_getdashboards_getdashboards [EXTRACTED 1.00]
- **Extensions API operations** — openapi_paths_extensions__bundle__name_updateextensionbundle_updateextensionbundle, openapi_paths_extensions__name_updateextensions_updateextensions, openapi_paths_extensions_listextensions_listextensions [EXTRACTED 1.00]
- **Fields API operations** — openapi_paths_fields__collection__id_deletefield_deletefield, openapi_paths_fields__collection__id_getcollectionfield_getcollectionfield, openapi_paths_fields__collection__id_updatefield_updatefield, openapi_paths_fields__collection_createfield_createfield, openapi_paths_fields__collection_getcollectionfields_getcollectionfields, openapi_paths_fields_getfields_getfields [EXTRACTED 1.00]
- **Files API operations** — openapi_paths_files__id_deletefile_deletefile, openapi_paths_files__id_getfile_getfile, openapi_paths_files__id_updatefile_updatefile, openapi_paths_files_deletefiles_deletefiles [EXTRACTED 1.00]
- **Directus Flows CRUD + trigger API** — openapi_paths_flows__id_deleteflow_deleteflow, openapi_paths_flows__id_getflow_getflow, openapi_paths_flows__id_updateflow_updateflow, openapi_paths_flows_createflows_createflows, openapi_paths_flows_deleteflows_deleteflows, openapi_paths_flows_getflows_getflows, openapi_paths_flows_singular_createflow_createflow, openapi_paths_flows_trigger__id_triggerflowget_triggerflowget, openapi_paths_flows_trigger__id_triggerflowpost_triggerflowpost, openapi_paths_flows_updateflows_updateflows [EXTRACTED 1.00]
- **Directus Files API** — openapi_paths_files_getfiles_getfiles, openapi_paths_files_import_importfile_importfile, openapi_paths_files_updatefiles_updatefiles, openapi_paths_files_uploadfile_uploadfile, openapi_paths_files_deletefiles_deletefiles [EXTRACTED 1.00]
- **Directus Folder item API** — openapi_paths_folders__id_deletefolder_deletefolder, openapi_paths_folders__id_getfolder_getfolder, openapi_paths_folders__id_updatefolder_updatefolder [EXTRACTED 1.00]
- **Folders CRUD endpoints** — openapi_paths_folders_createfolders_createfolders, openapi_paths_folders_deletefolders_deletefolders, openapi_paths_folders_getfolders_getfolders, openapi_paths_folders_singular_createfolder_createfolder, openapi_paths_folders_updatefolders_updatefolders [EXTRACTED 1.00]
- **Items collection CRUD endpoints** — openapi_paths_items__collection__id_deleteitem_deleteitem, openapi_paths_items__collection__id_getcollectionitem_getcollectionitem, openapi_paths_items__collection__id_updateitem_updateitem, openapi_paths_items__collection_createitems_createitems, openapi_paths_items__collection_deleteitems_deleteitems, openapi_paths_items__collection_getcollectionitems_getcollectionitems, openapi_paths_items__collection_singleton_getsingleton_getsingleton, openapi_paths_items__collection_singleton_updatesingleton_updatesingleton, openapi_paths_items__collection_singular_createitem_createitem, openapi_paths_items__collection_updateitems_updateitems [EXTRACTED 1.00]
- **Notifications CRUD endpoints** — openapi_paths_notifications__id_getnotification_getnotification, openapi_paths_notifications__id_updatenotification_updatenotification, openapi_paths_notifications_createnotifications_createnotifications, openapi_paths_notifications_deletenotifications_deletenotifications, openapi_paths_notifications_getnotifications_getnotifications, openapi_paths_notifications_singular_createnotification_createnotification, openapi_paths_notifications_updatenotifications_updatenotifications [EXTRACTED 1.00]
- **Operations (Flows) CRUD endpoints** — openapi_paths_operations__id_deleteoperation_deleteoperation, openapi_paths_operations__id_getoperation_getoperation, openapi_paths_operations__id_updateoperation_updateoperation, openapi_paths_operations_createoperations_createoperations, openapi_paths_operations_deleteoperations_deleteoperations, openapi_paths_operations_getoperations_getoperations, openapi_paths_operations_singular_createoperation_createoperation, openapi_paths_operations_updateoperations_updateoperations [EXTRACTED 1.00]
- **Panels item endpoints** — openapi_paths_panels__id_deletepanel_deletepanel, openapi_paths_panels__id_getpanel_getpanel, openapi_paths_panels__id_index_index [EXTRACTED 1.00]
- **Directus Panels CRUD endpoints** — openapi_paths_panels__id_updatepanel_updatepanel, openapi_paths_panels_createpanels_createpanels, openapi_paths_panels_deletepanels_deletepanels, openapi_paths_panels_getpanels_getpanels, openapi_paths_panels_singular_createpanel_createpanel, openapi_paths_panels_updatepanels_updatepanels [EXTRACTED 1.00]
- **Directus Permissions CRUD endpoints** — openapi_paths_permissions__id_deletepermission_deletepermission, openapi_paths_permissions__id_getpermission_getpermission, openapi_paths_permissions__id_updatepermission_updatepermission, openapi_paths_permissions_createpermissions_createpermissions, openapi_paths_permissions_deletepermissions_deletepermissions, openapi_paths_permissions_getpermissions_getpermissions, openapi_paths_permissions_me__collection__id_getitempermissions_readitempermissions, openapi_paths_permissions_me_getuserpermissions_getuserpermissions, openapi_paths_permissions_singular_createpermission_createpermission, openapi_paths_permissions_updatepermissions_updatepermissions [EXTRACTED 1.00]
- **Directus Policies CRUD endpoints** — openapi_paths_policies__id_getpolicy_getpolicy, openapi_paths_policies__id_updatepolicy_updatepolicy, openapi_paths_policies_createpolicies_createpolicies, openapi_paths_policies_deletepolicies_deletepolicies, openapi_paths_policies_getpolicies_getpolicies, openapi_paths_policies_singular_createpolicy_createpolicy, openapi_paths_policies_updatepolicies_updatepolicies [EXTRACTED 1.00]
- **Directus Presets CRUD endpoints** — openapi_paths_presets__id_deletepreset_deletepreset, openapi_paths_presets__id_getpreset_getpreset, openapi_paths_presets__id_updatepreset_updatepreset, openapi_paths_presets_createpresets_createpresets, openapi_paths_presets_deletepresets_deletepresets, openapi_paths_presets_getpresets_getpresets, openapi_paths_presets_singular_createpreset_createpreset, openapi_paths_presets_updatepresets_updatepresets [EXTRACTED 1.00]
- **Roles CRUD operations** — openapi_paths_roles_getroles_getroles, openapi_paths_roles_createroles_createroles, openapi_paths_roles_updateroles_updateroles, openapi_paths_roles_deleteroles_deleteroles, openapi_paths_roles__id_getrole_getrole, openapi_paths_roles__id_updaterole_updaterole, openapi_paths_roles__id_deleterole_deleterole, openapi_paths_roles_singular_createrole_createrole [EXTRACTED 1.00]
- **Relations CRUD operations** — openapi_paths_relations_getrelations_getrelations, openapi_paths_relations_createrelation_createrelation, openapi_paths_relations__id_getrelation_getrelation, openapi_paths_relations__id_updaterelation_updaterelation [EXTRACTED 1.00]
- **Schema diff/apply migration flow** — openapi_paths_schema_apply_schemaapply_schemaapply, openapi_paths_schema_diff_schemadiff_schemadiff, openapi_components_schemas_diff [INFERRED 0.85]
- **Shares lifecycle (read/update/delete/public info/authenticate)** — openapi_paths_shares__id_getshare_getshare, openapi_paths_shares__id_updateshare_updateshare, openapi_paths_shares__id_deleteshare_deleteshare, openapi_paths_shares__share_getpublicshareinfo_getpublicshareinfo, openapi_paths_shares_auth_authenticateshare_authenticateshare [INFERRED 0.85]
- **Server introspection endpoints** — openapi_paths_server_health_serverhealth_serverhealth, openapi_paths_server_info_serverinfo_serverinfo, openapi_paths_server_ping_ping_ping, openapi_paths_server_specs_graphql_readgraphqlsdl_readgraphqlsdl, openapi_paths_server_specs_oas_readopenapispec_readopenapispec [INFERRED 0.85]
- **Shares REST API operations** — openapi_paths_shares_getshares_getshares, openapi_paths_shares_createshares_createshares, openapi_paths_shares_updateshares_updatesshares, openapi_paths_shares_deleteshares_deleteshares, openapi_paths_shares_singular_createshare_createshare, openapi_paths_shares_info__id_getshareinfo_getshareinfo, openapi_paths_shares_invite_inviteshare_inviteshare [EXTRACTED 1.00]
- **Translations REST API operations** — openapi_paths_translations_gettranslations_gettranslations, openapi_paths_translations_createtranslations_createtranslations, openapi_paths_translations_updatetranslations_updatetranslations, openapi_paths_translations_deletetranslations_deletetranslations, openapi_paths_translations_singular_createtranslation_createtranslation, openapi_paths_translations__id_gettranslation_gettranslation, openapi_paths_translations__id_updatetranslation_updatetranslation, openapi_paths_translations__id_deletetranslation_deletetranslation [EXTRACTED 1.00]
- **Two-Factor Authentication Flow** — openapi_paths_users_me_tfa_generate_generatetwofactorsecret_generatetwofactorsecret, openapi_paths_users_me_tfa_enable_metfaenable_metfaenable, openapi_paths_users_me_tfa_disable_metfadisable_metfadisable [INFERRED 0.85]
- **User Onboarding (invite/accept/register)** — openapi_paths_users_invite_invite_invite, openapi_paths_users_invite_accept_acceptinvite_acceptinvite, openapi_paths_users_register_registeruser_registeruser [INFERRED 0.75]
- **Users bulk CRUD operations** — openapi_paths_users_getusers_getusers, openapi_paths_users_createusers_createusers, openapi_paths_users_deleteusers_deleteusers, openapi_paths_users__id_updateuser_updateuser [EXTRACTED 1.00]
- **Directus Utilities endpoints** — openapi_paths_utils_cache_clear_clear_cache_clear_cache, openapi_paths_utils_export__collection_export_export, openapi_paths_utils_hash_generate_hash_generate_hash_generate, openapi_paths_utils_hash_verify_hash_verify_hash_verify, openapi_paths_utils_import__collection_import_import, openapi_paths_utils_random_string_random_random, openapi_paths_utils_sort__collection_sort_sort [EXTRACTED 1.00]
- **Content Version operations** — openapi_paths_versions__id_compare_comparecontentversion_comparecontentversion, openapi_paths_versions__id_deletecontentversion_deletecontentversion, openapi_paths_versions__id_getcontentversion_getcontentversion, openapi_paths_versions__id_updatecontentversion_updatecontentversion, openapi_paths_versions__id_promote_promotecontentversion_promotecontentversion [EXTRACTED 1.00]
- **User management operations** — openapi_paths_users_register_verify_email__token_registeruserverify_registeruserverify, openapi_paths_users_singular_createuser_createuser, openapi_paths_users_updateusers_updateusers [INFERRED 0.85]
- **Content Version Lifecycle (create, save, promote)** — openapi_paths_versions_singular_createcontentversion_createcontentversion, openapi_paths_versions__id_save_savecontentversion_savecontentversion, openapi_paths_versions__id_promote_promotecontentversion_promotecontentversion, openapi_paths_versions__id_updatecontentversion_updatecontentversion [INFERRED 0.85]
- **Versions collection bulk CRUD** — openapi_paths_versions_getcontentversions_getcontentversions, openapi_paths_versions_createcontentversions_createcontentversions, openapi_paths_versions_updatecontentversions_updatecontentversions, openapi_paths_versions_deletecontentversions_deletecontentversions, openapi_paths_versions_index_index [EXTRACTED 1.00]

## Communities (104 total, 3 thin omitted)

### Community 0 - "OpenAPI Panels/Users CRUD Endpoints"
Cohesion: 0.04
Nodes (64): GraphQL delete_panels_item, GraphQL delete_users_items, GraphQL panels_by_id, Directus SDK createPanel(), Directus SDK createPresets, Directus SDK deleteUsers, Panels (OpenAPI tag), NotFoundError response (+56 more)

### Community 1 - "DirectusProperty Typed Accessors"
Cohesion: 0.02
Nodes (84): double get, abs, add, addDays, addHours, addMinutes, allValues, append (+76 more)

### Community 2 - "OpenAPI Comments/Dashboards Endpoints"
Cohesion: 0.11
Nodes (56): GraphQL create_users_items, GraphQL users, Directus SDK createUsers, Directus SDK readUsers, SDK updateContentVersions(), Backlink, Fields parameter, Filter parameter (+48 more)

### Community 3 - "DirectusClient Service Hub"
Cohesion: 0.03
Nodes (68): directus_http_client.dart, activity, assets, auth, clearTokens, collections, comments, config (+60 more)

### Community 4 - "DirectusModel Base & Getters"
Cohesion: 0.03
Nodes (61): DateTime? get, directus_property.dart, boolValue, clearFactories, _data, dateCreated, dateTimeValue, dateUpdated (+53 more)

### Community 5 - "WebSocket Realtime Client"
Cohesion: 0.03
Nodes (59): ../core/directus_config.dart, create,

  
  update,, _accessToken, _authenticate, _channel, _config, connect, data (+51 more)

### Community 6 - "Library Barrel Exports"
Cohesion: 0.03
Nodes (59): src/core/directus_client.dart, src/core/directus_config.dart, src/core/directus_http_client.dart, src/exceptions/directus_exception.dart, src/models/asset_transforms.dart, src/models/directus_activity.dart, src/models/directus_aggregate.dart, src/models/directus_comment.dart (+51 more)

### Community 7 - "Filter Builder"
Cohesion: 0.04
Nodes (51): dynamic get, and, between, _buildNestedFilter, contains, containsInsensitive, _data, empty (+43 more)

### Community 8 - "Directus Functions & Dynamic Vars"
Cohesion: 0.04
Nodes (48): add, count, currentPolicies, currentRole, currentTimestamp, currentUser, day, daysAgo (+40 more)

### Community 9 - "OpenAPI Index & Security"
Cohesion: 0.06
Nodes (38): Auth (Authorization header), KeyAuth (access_token query param), MetricsAuth (bearer Metrics token), directus_activity collection, Directus API Reference (OpenAPI 3.0.1, v11.1.0), Activity API tag, Assets API tag, Authentication API tag (+30 more)

### Community 10 - "OpenAPI Permissions/Relations"
Cohesion: 0.07
Nodes (29): Directus SDK deleteRelation, Directus SDK readRelationByCollection, Directus Permissions API, Id parameter, Meta parameter, activity schema, comments schema, relations schema (+21 more)

### Community 11 - "CollectionsService"
Cohesion: 0.05
Nodes (35): ../core/directus_http_client.dart, DirectusHttpClient, CollectionsService, createCollection, deleteCollection, getCollection, getCollections, _httpClient (+27 more)

### Community 12 - "DirectusUser Model"
Cohesion: 0.05
Nodes (40): activate, appearance, authData, avatar, description, email, emailNotifications, externalIdentifier (+32 more)

### Community 13 - "OpenAPI Files & Roles"
Cohesion: 0.08
Nodes (31): UUId, files schema, roles.yaml, versions.yaml schema, deleteFile (Delete a File), getFile (Retrieve a File), files/_id path item, updateFile (PATCH) (+23 more)

### Community 14 - "Asset Transforms"
Cohesion: 0.05
Nodes (37): bool?, AssetFit, AssetFormat, AssetPresets, AssetTransform, avatar, banner, bottom (+29 more)

### Community 15 - "DirectusField Model"
Cohesion: 0.06
Nodes (34): collection, display, displayOptions, factory, field, group, hasDisplay, hasDisplayOptions (+26 more)

### Community 16 - "ItemsService Queries"
Cohesion: 0.06
Nodes (33): aggregate, collection, createMany, createOne, data, deep, deleteMany, deleteOne (+25 more)

### Community 17 - "ActivityService"
Cohesion: 0.07
Nodes (28): item_active_service.dart, items_service.dart, ActivityService, getActivities, getActivitiesByAction, getActivity, getCollectionActivities, getItemActivities (+20 more)

### Community 18 - "FieldsService"
Cohesion: 0.06
Nodes (29): createField, deleteField, fieldExists, FieldsService, getAllFields, getField, getFieldsByInterface, getFieldsInCollection (+21 more)

### Community 19 - "Flow Model"
Cohesion: 0.07
Nodes (29): directus_operation.dart, accountability, activate, color, creator, creatorName, deactivate, description (+21 more)

### Community 20 - "AuthService & Tokens"
Cohesion: 0.07
Nodes (27): json,

  
  cookie,, accessToken, AuthMode, AuthResponse, AuthService, expiresIn, fromJson, getOAuthUrl (+19 more)

### Community 21 - "DirectusPolicy Model"
Cohesion: 0.07
Nodes (27): adminAccess, appAccess, description, disableAdminAccess, disableAppAccess, disableTwoFactor, enableAdminAccess, enableAppAccess (+19 more)

### Community 22 - "OpenAPI Utils Endpoints"
Cohesion: 0.08
Nodes (21): query.yaml schema, Clear the Internal Cache (clear-cache), GraphQL utils_cache_clear, Path /utils/cache/clear, Export Data to a File (export), Path /utils/export/{collection}, GraphQL utils_hash_generate, Generate a Hash (hash-generate) (+13 more)

### Community 23 - "OpenAPI Operations Endpoints"
Cohesion: 0.12
Nodes (21): GraphQL create_operations_items, GraphQL delete_operations_item, GraphQL delete_operations_items, GraphQL operations_by_id, GraphQL update_operations_item, GraphQL update_operations_items, Directus SDK createOperations(), Operations (OpenAPI tag) (+13 more)

### Community 24 - "Operation Model"
Cohesion: 0.07
Nodes (26): creator, creatorName, factory, flow, hasOptions, hasReject, hasResolve, isCondition (+18 more)

### Community 25 - "OpenAPI Files/Folders Bulk"
Cohesion: 0.11
Nodes (25): files schema, flows schema, folders schema, x-metadata schema, deleteFiles (Delete Multiple Files), getFiles (List Files), importFile (Import a File), /files/import path item (+17 more)

### Community 26 - "Preset Model"
Cohesion: 0.08
Nodes (24): directus_role.dart, DirectusRole? get, bookmark, collection, factory, filters, hasFilters, hasLayout (+16 more)

### Community 27 - "Exception Types"
Cohesion: 0.12
Nodes (24): Exception, code, collection, DirectusConfigException, DirectusDatabaseException, DirectusErrorCode, DirectusException, DirectusFileException (+16 more)

### Community 28 - "Panel Model"
Cohesion: 0.08
Nodes (24): area, color, creator, creatorName, dashboard, factory, hasHeader, hasNote (+16 more)

### Community 29 - "OpenAPI Notifications Endpoints"
Cohesion: 0.11
Nodes (18): GraphQL create_notifications_item, GraphQL create_notifications_items, GraphQL delete_notifications_items, GraphQL notifications_by_id, GraphQL update_notifications_item, GraphQL update_notifications_items, Notifications (OpenAPI tag), Notifications Schema (+10 more)

### Community 30 - "Activity & Revision Models"
Cohesion: 0.08
Nodes (23): directus_revision.dart, action, actor, actorEmail, actorName, collection, comment, factory (+15 more)

### Community 31 - "HTTP Client (Dio)"
Cohesion: 0.09
Nodes (22): Dio, directus_config.dart, Future, _accessToken, clearTokens, close, _config, _dio (+14 more)

### Community 32 - "Role Model"
Cohesion: 0.09
Nodes (22): addPolicy, addUser, children, childrenCount, description, factory, hasChildren, hasParent (+14 more)

### Community 33 - "OpenAPI Component Schemas"
Cohesion: 0.13
Nodes (23): OpenAPI schemas index, Activity schema (directus_activity), Collections schema (directus_collections), Comments schema (directus_comments), Dashboards Schema, Fields Schema, Files Schema, Flows Schema (+15 more)

### Community 34 - "Permission Model"
Cohesion: 0.09
Nodes (21): directus_policy.dart, DirectusPolicy? get, action, allowsAllFields, collection, factory, fields, hasFieldRestrictions (+13 more)

### Community 35 - "OpenAPI Policies Endpoints"
Cohesion: 0.13
Nodes (21): Directus SDK createPolicies, Directus SDK createPolicy, Directus SDK deletePolicies, Directus SDK readPolicies, Directus SDK readPolicy, Directus SDK updatePolicies, Directus SDK updatePolicy, Directus Policies API (+13 more)

### Community 36 - "OpenAPI Current User (Me)"
Cohesion: 0.11
Nodes (18): GraphQL update_users_item, GraphQL update_users_me, GraphQL users_me, Directus SDK readMe, Directus SDK updateMe, Directus SDK updateUser, users.yaml schema, Update a User (updateUser) (+10 more)

### Community 37 - "Notification Model"
Cohesion: 0.10
Nodes (19): archive, collection, factory, hasMessage, hasSubject, isArchived, isInInbox, item (+11 more)

### Community 38 - "OpenAPI Content Versions"
Cohesion: 0.11
Nodes (18): Directus SDK (@directus/sdk), SDK createContentVersion(), SDK deleteContentVersions(), SDK promoteContentVersion(), SDK readContentVersions(), SDK saveToContentVersion(), SDK updateContentVersion(), /shares/invite path item (+10 more)

### Community 39 - "OpenAPI Presets Endpoints"
Cohesion: 0.18
Nodes (18): Directus SDK createPreset, Directus SDK deletePreset, Directus SDK readPreset, Directus SDK readPresets, Directus SDK updatePreset, Directus SDK updatePresets, presets schema, deletePreset (Delete a Preset) (+10 more)

### Community 40 - "Deep Queries"
Cohesion: 0.13
Nodes (17): int?, allFields, Deep, DeepFields, DeepMaxDepth, DeepQuery, DeepQueryExtensions, depth (+9 more)

### Community 41 - "Aggregations"
Cohesion: 0.12
Nodes (17): Aggregate, avg, avgDistinct, count, countAll, countDistinct, fields, GroupBy (+9 more)

### Community 42 - "Relation Model"
Cohesion: 0.11
Nodes (17): DirectusRelation, factory, hasAllowedCollections, hasSortField, isManyToMany, isManyToOne, isOneToMany, itemName (+9 more)

### Community 43 - "AssetsService"
Cohesion: 0.12
Nodes (16): dart:convert, AssetsService, getAssetUrl, getAssetWithFocalPoint, getAssetWithMultipleTransforms, getAvatarUrl, getBannerUrl, getCardUrl (+8 more)

### Community 44 - "Dashboard Model"
Cohesion: 0.12
Nodes (16): directus_panel.dart, int get, color, creator, creatorName, factory, getPanelsByType, hasNote (+8 more)

### Community 45 - "FoldersService"
Cohesion: 0.12
Nodes (16): createFolder, createFolderFromData, createFolders, deleteFolder, deleteFolders, FoldersService, getFolder, getFolders (+8 more)

### Community 46 - "NotificationsService"
Cohesion: 0.12
Nodes (16): archiveNotification, archiveNotifications, createNotification, createNotifications, deleteNotification, deleteNotifications, getArchivedNotifications, getInboxNotifications (+8 more)

### Community 47 - "FlowsService"
Cohesion: 0.12
Nodes (15): createFlow, createFlows, deleteFlow, deleteFlows, FlowsService, getActiveFlows, getFlow, getFlows (+7 more)

### Community 48 - "ItemActiveService"
Cohesion: 0.12
Nodes (15): collection, createMany, createOne, deleteMany, deleteManyModels, deleteOne, _httpClient, readMany (+7 more)

### Community 49 - "PresetsService"
Cohesion: 0.12
Nodes (15): createPreset, createPresets, deletePreset, deletePresets, getBookmarks, getGlobalPresets, getPreset, getPresets (+7 more)

### Community 50 - "UsersService (2FA, Invite)"
Cohesion: 0.12
Nodes (15): acceptInvite, disableTwoFactor, enableTwoFactor, fromJson, generateTwoFactorSecret, _httpClient, inviteUsers, otpauthUrl (+7 more)

### Community 51 - "VersionsService"
Cohesion: 0.12
Nodes (15): compareVersions, createVersion, deleteVersion, deleteVersions, getCollectionVersions, getItemVersions, getUserVersions, getVersion (+7 more)

### Community 52 - "Revision Model"
Cohesion: 0.13
Nodes (14): bool get, activity, collection, data, delta, DirectusRevision, factory, hasData (+6 more)

### Community 53 - "Property Wrapper Types"
Cohesion: 0.16
Nodes (15): DateTime?, BoolProperty, DateTimeProperty, DirectusProperty, DoubleProperty, EnumProperty, IntProperty, JsonProperty (+7 more)

### Community 54 - "Generated Test Mocks"
Cohesion: 0.15
Nodes (13): dart:async, DirectusConfig get, _i1.SmartFake, _i2.DirectusConfig, _i3.Response, package:fcs_directus/src/core/directus_config.dart, package:fcs_directus/src/core/directus_http_client.dart, package:mockito/mockito.dart (+5 more)

### Community 55 - "FilesService"
Cohesion: 0.14
Nodes (13): dart:io, deleteFile, FilesService, getFile, getFiles, getFileUrl, getThumbnailUrl, _httpClient (+5 more)

### Community 56 - "OpenAPI Share Info"
Cohesion: 0.15
Nodes (13): Component schemas/shares.yaml, Get Public Share Info (getPublicShareInfo), Path /shares/_share, POST /shares Create Multiple Shares, GraphQL create_shares_items, SDK createShares(), GET /shares/info/{id} Get Share Public Info, SDK readShareInfo() (+5 more)

### Community 57 - "Comment Model"
Cohesion: 0.14
Nodes (13): directus_user.dart, DirectusUser? get, author, authorName, collection, comment, editor, factory (+5 more)

### Community 58 - "PoliciesService"
Cohesion: 0.14
Nodes (13): DirectusPolicy, createPolicies, createPolicy, deletePolicies, deletePolicy, getAdminPolicies, getAppAccessPolicies, getTwoFactorPolicies (+5 more)

### Community 59 - "RolesService"
Cohesion: 0.14
Nodes (13): DirectusRole, createRole, createRoles, deleteRole, deleteRoles, getChildRoles, getParentRole, _httpClient (+5 more)

### Community 60 - "SharesService"
Cohesion: 0.14
Nodes (13): createShare, deleteShare, deleteShares, getActiveShares, getCollectionShares, getItemShares, getShare, getShares (+5 more)

### Community 61 - "TranslationsService"
Cohesion: 0.14
Nodes (13): createTranslation, deleteTranslation, deleteTranslations, getAvailableLanguages, getLanguageTranslations, getMultipleLanguagesTranslations, getTranslation, getTranslationByKey (+5 more)

### Community 62 - "OpenAPI Schema Migration"
Cohesion: 0.23
Nodes (9): Schema snapshot/diff migration (admin only, force bypasses version/vendor checks), Component responses.yaml, diff.yaml, Component schemas/schema.yaml, schemaApply (Apply Schema Difference), Retrieve Schema Difference (schemaDiff), Path /schema/snapshot, Retrieve Schema Snapshot (schemaSnapshot) (+1 more)

### Community 63 - "OpenAPI Share Auth"
Cohesion: 0.19
Nodes (9): Share token authentication (scoped access token, json/cookie/session mode), Component parameters.yaml, Delete a Share (deleteShare), Retrieve a Share (getShare), Path /shares/_id, Update a Share (updateShare), Authenticate a Share (authenticateShare), Path /shares/auth (+1 more)

### Community 64 - "OpenAPI Server Endpoints"
Cohesion: 0.18
Nodes (9): Path /server/health, Server Health (serverHealth), Path /server/ping, Ping (ping), Path /server/specs/graphql, Get GraphQL SDL (readGraphqlSdl), Path /server/specs/oas, Get OpenAPI Specification (readOpenApiSpec) (+1 more)

### Community 65 - "DirectusConfig"
Cohesion: 0.15
Nodes (12): Duration, ../exceptions/directus_exception.dart, baseUrl, copyWith, customUserAgent, DirectusConfig, enableLogging, headers (+4 more)

### Community 66 - "Unit Tests Core"
Cohesion: 0.21
Nodes (8): DynamicModel, package:fcs_directus/fcs_directus.dart, package:test/test.dart, main, main, main, main, main

### Community 67 - "CommentsService"
Cohesion: 0.15
Nodes (12): CommentsService, createComment, createComments, deleteComment, deleteComments, getComment, getComments, getCommentsForItem (+4 more)

### Community 68 - "DashboardsService"
Cohesion: 0.15
Nodes (12): createDashboard, createDashboards, DashboardsService, deleteDashboard, deleteDashboards, getDashboard, getDashboards, getDashboardsByUser (+4 more)

### Community 69 - "OperationsService"
Cohesion: 0.15
Nodes (12): createOperation, deleteOperation, deleteOperations, getFlowOperations, getOperation, getOperations, getOperationsByType, getResolveOperations (+4 more)

### Community 70 - "PanelsService"
Cohesion: 0.15
Nodes (12): createPanel, deletePanel, deletePanels, getDashboardPanels, getFullWidthPanels, getPanel, getPanels, getPanelsByType (+4 more)

### Community 71 - "ItemActiveService Tests"
Cohesion: 0.17
Nodes (11): @GenerateMocks, item_active_service_test.mocks.dart, ItemActiveService, package:mockito/annotations.dart, itemName, main, mockHttpClient, service (+3 more)

### Community 72 - "OpenAPI User Invite/Register"
Cohesion: 0.17
Nodes (12): GraphQL users_invite, GraphQL users_invite_accept, GraphQL users_register, Directus SDK acceptUserInvite, Directus SDK inviteUser, Directus SDK registerUser, Accept User Invite (acceptInvite), Path /users/invite/accept (+4 more)

### Community 73 - "Folder Model"
Cohesion: 0.17
Nodes (11): directus_model.dart, DirectusFolder? get, DirectusFolder, factory, hasParent, isRootFolder, itemName, name (+3 more)

### Community 74 - "Model Subclasses"
Cohesion: 0.17
Nodes (12): DirectusActivity, DirectusComment, DirectusDashboard, DirectusField, DirectusFlow, DirectusModel, DirectusNotification, DirectusOperation (+4 more)

### Community 75 - "OpenAPI Items Endpoints"
Cohesion: 0.30
Nodes (12): Collection, Version, items schema, deleteItem (Delete an item), getCollectionItem (Retrieve an Item), openapi/paths/items/_collection/_id/index.yaml route, updateItem (Update an item), getSingleton (Retrieve a Singleton) (+4 more)

### Community 76 - "OpenAPI Settings & Info"
Cohesion: 0.27
Nodes (7): Component schemas/settings.yaml, Path /server/info, System Info (serverInfo), Retrieve Settings (getSettings), Path /settings, Update Settings (updateSettings), API Tag: Settings

### Community 77 - "OpenAPI Shares Bulk"
Cohesion: 0.20
Nodes (10): DELETE /shares Delete Multiple Shares, GraphQL delete_shares_items, SDK deleteShares(), GET /shares List Shares, GraphQL shares, SDK readShares(), /shares path item, GraphQL update_shares_items (+2 more)

### Community 78 - "Package Dependencies"
Cohesion: 0.22
Nodes (10): build_runner - Code generation (dev), dio - HTTP client, fcs_directus package, json_annotation - JSON serialization, json_serializable - JSON codegen (dev), lints - Linting (dev), logging - Logging, mockito - Mocking (dev) (+2 more)

### Community 79 - "OpenAPI Extensions"
Cohesion: 0.28
Nodes (8): Directus SDK updateExtension(), extensions schema, extensions/_bundle/_name path item, updateExtensionBundle (PATCH), extensions/_name path item, updateExtensions (PATCH), extensions path item, listExtensions (GET)

### Community 80 - "Exception Hierarchy Docs"
Cohesion: 0.22
Nodes (9): DirectusException hierarchy, DirectusNetworkException, DirectusNotFoundException, DirectusPermissionException, DirectusRateLimitException, DirectusServerException, DirectusValidationException, Error Handling guide (+1 more)

### Community 81 - "Enum Property Tests"
Cohesion: 0.22
Nodes (8): itemName, main, Priority, status, TaskModel, TaskStatus, TestModel, TestStatus

### Community 82 - "OpenAPI 2FA Enable"
Cohesion: 0.29
Nodes (8): EnumProperty wrapper, Dirty tracking (toJsonDirty), Model factory registration, Custom Models guide, M2O/O2M/M2M model relations, DeepQuery, Deep Queries guide, Property Wrappers

### Community 83 - "Custom Models Guide"
Cohesion: 0.25
Nodes (8): GraphQL users_me_tfa_enable, GraphQL users_me_tfa_generate, Directus SDK enableTwoFactor, Directus SDK generateTwoFactorSecret, Path /users/me/tfa/enable, Enable 2FA (meTfaEnable), Generate Two-Factor Authentication Secret (generateTwoFactorSecret), Path /users/me/tfa/generate

### Community 84 - "Filter Types Hierarchy"
Cohesion: 0.25
Nodes (8): EmptyFilter, FieldFilter, Filter, LogicalFilter, OperatorFilter, RawFilter, RelationalFilter, RelationFilter

### Community 85 - "ExtensionsService"
Cohesion: 0.25
Nodes (7): ExtensionsService, getExtensions, getExtensionsByType, _httpClient, isExtensionInstalled, updateExtension, updateExtensionInBundle

### Community 86 - "Docs: WebSocket & Files"
Cohesion: 0.29
Nodes (7): Documentation Policy (docs folder, current-state only), DirectusWebSocketClient (subscriptions), WebSocket guide, AssetTransform (image transforms), File upload & folders, Files & Assets guide, Documentation index (docs/README)

### Community 87 - "Project Scope & Filter Rules"
Cohesion: 0.29
Nodes (7): No manual JSON in business classes, fcs_directus Project Scope (Dart lib for Directus), Technical Requirements (async, OOP, tests, dio/json_serializable/web_socket_channel), Fix: dot-notation filters produce nested JSON, Dot-notation relational filters, Filter builder (Filter.field/and/or/some/none), Type-safe Filters guide

### Community 88 - "Changelog & Contributing"
Cohesion: 0.29
Nodes (7): flutter_lints analysis config, Changelog, Fix: 404 on /auth/refresh (custom headers in refresh Dio), Release 0.2.0, lib/src layout (core, exceptions, models, services, utils, websocket), Contribution Guide, Conventional Commits

### Community 89 - "Docs: CRUD & Aggregations"
Cohesion: 0.29
Nodes (7): CRUD Operations guide, items(collection) / itemsOf<T>() service, Pagination (offset/page/meta), QueryParameters, Aggregate (count/sum/avg/min/max, groupBy), Aggregations guide, OpenAPI query/path parameters (fields, filter, sort, limit, offset, page, search, meta, export, version, backlink)

### Community 90 - "Response Helper"
Cohesion: 0.29
Nodes (6): data, extractListData, extractMapData, extractor, hasResponseData, package:dio/dio.dart

### Community 91 - "OpenAPI User By ID"
Cohesion: 0.29
Nodes (7): DELETE /users/{id} Delete a User, GraphQL delete_users_item, SDK deleteUser(), GET /users/{id} Retrieve a User, GraphQL users_by_id, SDK readUser(), Path /users/{id}

### Community 92 - "Model Test Helpers"
Cohesion: 0.33
Nodes (5): ArgumentError, String get, itemName, main, _TestModel

### Community 93 - "Docs: Authentication"
Cohesion: 0.33
Nodes (6): onAuthError callback (DirectusConfig), Auth error callback, Authentication guide, OAuth / SSO login, Session refresh & restore, DirectusAuthException

### Community 94 - "Docs: Getting Started"
Cohesion: 0.47
Nodes (6): DirectusService singleton pattern, Getting Started guide, Automatic token refresh with persistence callbacks, DirectusClient, DirectusConfig, fcs_directus library overview

### Community 95 - "Docs: Users & Permissions"
Cohesion: 0.40
Nodes (5): Two-Factor Authentication (TOTP), DirectusUser model, Users management guide, Roles / Policies / Permissions, DirectusModel (Active Record)

### Community 96 - "Nested Filter Tests"
Cohesion: 0.40
Nodes (4): byRegion, byRegionNom, GeoFilters, main

### Community 97 - "OpenAPI 2FA Disable"
Cohesion: 0.50
Nodes (4): GraphQL users_me_tfa_disable, Directus SDK disableTwoFactor, Path /users/me/tfa/disable, Disable Two-Factor Authentication (meTfaDisable)

### Community 98 - "Auto Refresh Tests"
Cohesion: 0.50
Nodes (3): Function, DirectusAuthException, main

### Community 99 - "Mock HTTP Client"
Cohesion: 0.67
Nodes (3): _i1.Mock, _i4.DirectusHttpClient, MockDirectusHttpClient

### Community 100 - "ObjectProperty & MapToFilter"
Cohesion: 0.67
Nodes (3): MapToFilter, ObjectProperty, Map

## Ambiguous Edges - Review These
- `Dashboards Schema` → `Shares Schema`  [AMBIGUOUS]
  openapi/components/schemas/dashboards.yaml · relation: references
- `Roles Schema` → `Shares Schema`  [AMBIGUOUS]
  openapi/components/schemas/shares.yaml · relation: references
- `createOperations (Create Multiple Operations)` → `createOperation (Create an Operation)`  [AMBIGUOUS]
  openapi/paths/operations/singular/createOperation.yaml · relation: semantically_similar_to
- `Create Multiple Content Versions (createContentVersions)` → `SDK updateContentVersions()`  [AMBIGUOUS]
  openapi/paths/versions/createContentVersions.yaml · relation: references

## Knowledge Gaps
- **1305 isolated node(s):** `DirectusClient`, `config`, `_httpClient`, `_websocket`, `auth` (+1300 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1553 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Dashboards Schema` and `Shares Schema`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `Roles Schema` and `Shares Schema`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `createOperations (Create Multiple Operations)` and `createOperation (Create an Operation)`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `Create Multiple Content Versions (createContentVersions)` and `SDK updateContentVersions()`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `DirectusHttpClient` connect `CollectionsService` to `DirectusClient Service Hub`, `ItemsService Queries`, `ActivityService`, `FieldsService`, `AuthService & Tokens`, `HTTP Client (Dio)`, `AssetsService`, `FoldersService`, `NotificationsService`, `FlowsService`, `ItemActiveService`, `PresetsService`, `UsersService (2FA, Invite)`, `VersionsService`, `FilesService`, `PoliciesService`, `RolesService`, `SharesService`, `TranslationsService`, `CommentsService`, `DashboardsService`, `OperationsService`, `PanelsService`, `ExtensionsService`?**
  _High betweenness centrality (0.090) - this node is a cross-community bridge._
- **Why does `UnauthorizedError response` connect `OpenAPI Panels/Users CRUD Endpoints` to `OpenAPI Comments/Dashboards Endpoints`, `OpenAPI Permissions/Relations`, `OpenAPI Files & Roles`, `OpenAPI Operations Endpoints`, `OpenAPI Files/Folders Bulk`, `OpenAPI Notifications Endpoints`, `OpenAPI Policies Endpoints`, `OpenAPI Current User (Me)`, `OpenAPI Content Versions`, `OpenAPI Presets Endpoints`, `OpenAPI Share Info`, `OpenAPI Schema Migration`, `OpenAPI User Invite/Register`, `OpenAPI Items Endpoints`, `OpenAPI Shares Bulk`, `OpenAPI Extensions`, `Custom Models Guide`, `OpenAPI User By ID`, `OpenAPI 2FA Disable`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **Why does `Users Schema` connect `OpenAPI Component Schemas` to `OpenAPI Notifications Endpoints`, `OpenAPI Operations Endpoints`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._