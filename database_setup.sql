-- Hailiao clean database bootstrap
-- Recommended date: 2026-03-30
-- Usage:
-- 1. Create the database.
-- 2. Start hailiao-api / hailiao-admin once with spring.jpa.hibernate.ddl-auto=update
--    so JPA creates the baseline tables.
-- 3. Execute the migration scripts below for features added after the original schema.

CREATE DATABASE IF NOT EXISTS hailiao
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hailiao;

-- Feature migrations maintained in this repository:
SOURCE friend_request_migration.sql;
SOURCE group_join_request_migration.sql;
SOURCE user_privacy_migration.sql;
SOURCE user_session_migration.sql;
