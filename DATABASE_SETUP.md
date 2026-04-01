# Database Setup

Use [database_setup.sql](/E:/IM/ImServer/database_setup.sql) for new environments.

Reason:
- [hailiao-im.sql](/E:/IM/ImServer/hailiao-im.sql) contains historical encoding corruption.
- The project already relies on `spring.jpa.hibernate.ddl-auto=update` to create baseline tables.
- Feature-specific migrations in the repo are clean and should be applied after startup.

Recommended order:
1. Create the `hailiao` database with `utf8mb4`.
2. Start `hailiao-api` and `hailiao-admin` once so JPA can create/update baseline tables.
3. Run:
   - [friend_request_migration.sql](/E:/IM/ImServer/friend_request_migration.sql)
   - [group_join_request_migration.sql](/E:/IM/ImServer/group_join_request_migration.sql)
   - [user_privacy_migration.sql](/E:/IM/ImServer/user_privacy_migration.sql)
   - [user_session_migration.sql](/E:/IM/ImServer/user_session_migration.sql)

If you need a fully clean monolithic schema script later, rebuild it from the current entities and migrations instead of editing the corrupted legacy file in place.

Baseline tables currently covered by JPA entities:
- `user`
- `friend`
- `blacklist`
- `group_chat`
- `group_member`
- `message`
- `conversation`
- `admin_user`
- `report`
- `order_info`
- `pretty_number`
- `vip_member`
- `system_config`
- `content_audit`
- `operation_log`
- `video_call`
- `group_robot`
- `robot_command`
- `message_read_status`
- `friend_request`
- `group_join_request`
- `user_session`

Notes:
- `friend_request`, `group_join_request`, `user_privacy`, and `user_session` also have dedicated migration scripts because they were added after the original legacy SQL.
- Prefer the current entity model plus migrations as the source of truth.
