# Technical Debt

This file tracks the main remaining risks after the current cleanup pass.

High priority:
- [hailiao-im.sql](/E:/IM/ImServer/hailiao-im.sql) is still a legacy corrupted schema script and should not be used as the source of truth.
- [UserManageController.java](/E:/IM/ImServer/hailiao-admin/src/main/java/com/hailiao/admin/controller/UserManageController.java) is now the main admin user-management route family. [UserManagementController.java](/E:/IM/ImServer/hailiao-admin/src/main/java/com/hailiao/admin/controller/UserManagementController.java) has been reduced to a deprecated compatibility layer and can be retired later.
- `JPA_DDL_AUTO` still defaults to `update` in the base config for convenience. Production should use the `prod` profile or override this explicitly.
- `JPA_SHOW_SQL` and debug log levels still default to development-friendly values in the base config. Production should use the `prod` profile or override them.
- Admin permissions are now enforced by route mapping, but the permission matrix still lives in code defaults instead of a dedicated role/permission management UI.

Medium priority:
- Some ASCII-safe documentation files were used to avoid encoding regression. If full Chinese documentation is needed later, regenerate it after repository encoding is fully stabilized.
- The project still relies on fallback placeholder OSS credentials when environment variables are not provided.
- Maven compile validation in this environment is still blocked by the local repository permission issue on `.m2`.
- Admin operation logs now support list, stats, and module queries, but still only capture request metadata, status, and duration. They do not yet persist request/response bodies.
- Flutter still lacks automated test coverage. See [TEST_COVERAGE.md](/E:/IM/ImServer/TEST_COVERAGE.md) for the current backend-heavy coverage split.

Recommended next cleanup steps:
1. Consolidate the duplicate admin user-management controllers into one API surface and keep the other as a short-lived compatibility layer or remove it.
2. Rebuild a fully clean monolithic SQL schema from entities plus migrations.
3. Decide whether to keep `/admin/users` as a long-lived compatibility route or retire it after callers migrate.
