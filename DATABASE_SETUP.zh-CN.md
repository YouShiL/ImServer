# Database Setup (ZH-CN)

Please use [database_setup.sql](/E:/IM/ImServer/database_setup.sql) for new environments.

This Chinese guide was temporarily rewritten in ASCII-safe form because the current repository has a history of encoding corruption in some text files.

Recommended order:
1. Create the `hailiao` database with `utf8mb4`.
2. Start `hailiao-api` and `hailiao-admin` once so JPA can create/update baseline tables.
3. Run:
   - [friend_request_migration.sql](/E:/IM/ImServer/friend_request_migration.sql)
   - [group_join_request_migration.sql](/E:/IM/ImServer/group_join_request_migration.sql)
   - [user_privacy_migration.sql](/E:/IM/ImServer/user_privacy_migration.sql)
   - [user_session_migration.sql](/E:/IM/ImServer/user_session_migration.sql)

Baseline tables covered by current entities:
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

If you need a fully clean Chinese version later, regenerate it after the repository encoding is fully stabilized.
