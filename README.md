# Hailiao IM

This repository contains a multi-module instant messaging system.

Modules:
- [hailiao-common](/E:/IM/ImServer/hailiao-common): shared entities, repositories, services, config, and utilities
- [hailiao-api](/E:/IM/ImServer/hailiao-api): app-facing backend service
- [hailiao-admin](/E:/IM/ImServer/hailiao-admin): admin backend service
- [hailiao_flutter](/E:/IM/ImServer/hailiao_flutter): Flutter client

Backend entry points:
- [HailiaoApiApplication.java](/E:/IM/ImServer/hailiao-api/src/main/java/com/hailiao/api/HailiaoApiApplication.java)
- [HailiaoAdminApplication.java](/E:/IM/ImServer/hailiao-admin/src/main/java/com/hailiao/admin/HailiaoAdminApplication.java)

Quick start:
1. Review environment variables in [.env.example](/E:/IM/ImServer/.env.example).
2. Review backend config notes in [ENVIRONMENT.md](/E:/IM/ImServer/ENVIRONMENT.md).
3. Initialize the database with [database_setup.sql](/E:/IM/ImServer/database_setup.sql).
4. Review setup details in [DATABASE_SETUP.md](/E:/IM/ImServer/DATABASE_SETUP.md) or [DATABASE_SETUP.zh-CN.md](/E:/IM/ImServer/DATABASE_SETUP.zh-CN.md).
5. Start `hailiao-api` and `hailiao-admin`.
6. Review verification guidance in [VERIFICATION.md](/E:/IM/ImServer/VERIFICATION.md).
7. Run [verify-targeted.ps1](/E:/IM/ImServer/scripts/verify-targeted.ps1) when you want one command for the current stable backend regression set.
8. Run [verify-full.ps1](/E:/IM/ImServer/scripts/verify-full.ps1) when you want full module-level backend tests for `common`, `api`, and `admin`.
9. Review [TEST_COVERAGE.md](/E:/IM/ImServer/TEST_COVERAGE.md) for the current automated coverage map and remaining test gaps.
10. Run [verify-flutter-smoke.ps1](/E:/IM/ImServer/scripts/verify-flutter-smoke.ps1) when you want the lightest Flutter smoke flow.
11. Run [verify-flutter.ps1](/E:/IM/ImServer/scripts/verify-flutter.ps1) when you want the broader Flutter check flow for models, providers, and screen smoke tests.
12. Reuse shared Flutter test doubles, detail-screen fake APIs, route placeholders, and screen pump helpers from [hailiao_flutter/test/support](/E:/IM/ImServer/hailiao_flutter/test/support) when adding new provider or screen tests, instead of building `MultiProvider` wrappers, placeholder routes, and local `Fake*Api` classes inside each test file.
13. Review [FLUTTER_TESTING.md](/E:/IM/ImServer/FLUTTER_TESTING.md) for the current Flutter test layering and support helper conventions.

Production hint:
- Use the Spring `prod` profile to get safer defaults from:
  - [application-prod.yml](/E:/IM/ImServer/hailiao-api/src/main/resources/application-prod.yml)
  - [application-prod.yml](/E:/IM/ImServer/hailiao-admin/src/main/resources/application-prod.yml)
- Example:
  - PowerShell: `$env:SPRING_PROFILES_ACTIVE="prod"`

Notes:
- The legacy [hailiao-im.sql](/E:/IM/ImServer/hailiao-im.sql) file has historical encoding corruption and should not be treated as the source of truth.
- The current source of truth is the entity model plus the migration scripts in the repository root.
- Admin route conventions and compatibility notes are documented in [ADMIN_API_NOTES.md](/E:/IM/ImServer/ADMIN_API_NOTES.md).
- Admin operation logging is now wired through [AdminOperationLogInterceptor.java](/E:/IM/ImServer/hailiao-admin/src/main/java/com/hailiao/admin/interceptor/AdminOperationLogInterceptor.java) and exposed by [OperationLogManageController.java](/E:/IM/ImServer/hailiao-admin/src/main/java/com/hailiao/admin/controller/OperationLogManageController.java).
- Admin permission checks are now enforced by [AdminPermissionInterceptor.java](/E:/IM/ImServer/hailiao-admin/src/main/java/com/hailiao/admin/interceptor/AdminPermissionInterceptor.java).