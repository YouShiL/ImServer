# Admin API Notes

This file records the current admin API route conventions and compatibility decisions.

Primary route families:
- `/admin/auth`
- `/admin/admin`
- `/admin/operation-log`
- `/admin/user`
- `/admin/group`
- `/admin/order`
- `/admin/report`
- `/admin/content-audit`
- `/admin/system-config`
- `/admin/vip`
- `/admin/pretty-number`
- `/admin/messages`
- `/admin/dashboard`
- `/admin/statistics`

Compatibility route families:
- `/admin/users`

Current recommendation:
- Treat `/admin/user` as the canonical admin user-management route family.
- Treat `/admin/users` as a compatibility layer only.
- Use `/admin/operation-log/list`, `/admin/operation-log/stats`, and `/admin/operation-log/modules` for audit queries.
- `/admin/operation-log/list` now returns labeled log items, including `moduleLabel`, `operationTypeLabel`, and `statusLabel`.
- `/admin/operation-log/list` now also includes a `summary` block for the current filter set, including filtered total, success/failure counts, and per-module counts.
- `/admin/operation-log/export` now exports the filtered operation log list as CSV.
- `/admin/operation-log/stats` now includes `moduleStats` and `dailyTrend` for dashboard-style audit overviews.
- Admin module access is now guarded by [AdminPermissionInterceptor.java](/E:/IM/ImServer/hailiao-admin/src/main/java/com/hailiao/admin/interceptor/AdminPermissionInterceptor.java) using route-to-permission mapping.
- `/admin/group/list` now returns labeled group items and a `summary` block, including mute and join-verification counts.
- `/admin/report/list` now returns labeled report items and a `summary` block, including pending and handled counts.
- `/admin/content-audit/list` now returns labeled audit items and a `summary` block, including pending and handled counts.
- `/admin/user/list` now returns labeled user items and a `summary` block, including banned and VIP counts.
- `/admin/order/list` now returns labeled order items and a `summary` block, including paid and unpaid counts.
- `/admin/vip/list` now returns labeled VIP items and a `summary` block, including active and expired counts.
- `/admin/pretty-number/list` now returns labeled pretty-number items and a `summary` block, including sold and available counts.
- `/admin/user/stats`, `/admin/order/stats`, `/admin/vip/stats`, and `/admin/pretty-number/stats` now return richer summary blocks and label metadata for dashboard cards.
- `/admin/dashboard/stats` and `/admin/dashboard/realtime` now return dashboard-oriented `summary` and `cards`/label metadata.
- `/admin/statistics/system`, `/admin/statistics/messages`, `/admin/statistics/user/{userId}`, and `/admin/statistics/group/{groupId}` now expose richer summary and distribution data from `StatisticsService`.
- `/admin/system-config/list` and `/admin/system-config/category/{category}` now return labeled config items and a `summary` block.
- `/admin/messages` now returns labeled message-monitor items and a `summary` block for the current filter set.
- Use `/admin/admin/permission-options` and `/admin/admin/role-options` to query current permission choices and built-in role templates.
- Built-in role templates now include a `description` field for admin-page guidance.
- Use `/admin/admin/stats` to query total admins, active admins, disabled admins, and per-role counts.
- `/admin/admin/stats` now also includes `riskStats` for administrator permission-risk distribution.
- `/admin/admin/list` now includes a `summary` block for the current filter set, including filtered total, active/disabled counts, per-role counts, and `riskStats`.
- `/admin/admin/list` and `/admin/admin/{adminId}` now also return `statusLabel`, `roleDescription`, `permissionSummary`, `effectivePermissionCount`, `hasWildcardPermission`, `permissionRiskLevel`, and `permissionRiskLabel` for direct UI display.
- `/admin/admin/export` now exports the filtered admin list as CSV.
- Admin CSV export now includes permission summary and effective permission count for permission review and audit work.
- Use `/admin/admin/permission-preview` to preview the final effective permissions before saving a role or custom permission set.
- Use `/admin/admin/{adminId}/permissions` to save role/permission changes and know whether the current login session should refresh its permission context.
- Use `/admin/auth/me` to query the current admin profile and effective permissions after login.
- Use `/admin/auth/context` to refresh the current admin profile, role options, and permission options in one request.
- Use `/admin/auth/profile` to update the current admin's own profile.
- Use `/admin/auth/change-password` to change the current admin's password and trigger a client-side login/token refresh flow.
- Admin list/detail/create/update responses now return a sanitized admin payload and no longer expose password hashes.
- When creating or updating an admin with a role but no explicit custom permissions, the backend now falls back to that role's built-in permission template.
- Admin create/update flows now validate username, password length, role range, status range, nickname length, and normalize custom permissions before saving.
- Admin management now protects critical accounts: a logged-in admin cannot delete or disable themselves, and the system will not allow the last super admin to be deleted, disabled, or downgraded.
- Admin-management write operations now produce clearer operation-log module and action names, especially for create, update, permission change, password reset, and delete flows.
- Admin-management operation logs now include richer target-admin context in descriptions, such as target admin ID, username, role, and permission summary where applicable.

Why:
- `/admin/user` already contains the main list/detail/update/ban/unban/stats flow.
- `/admin/users` was retained to avoid breaking existing callers, but it now delegates to the same service/controller flow where possible.

Suggested future cleanup:
1. Migrate any remaining callers from `/admin/users` to `/admin/user`.
2. Keep `/admin/users` for one compatibility window.
3. Remove `/admin/users` after callers are confirmed migrated.
