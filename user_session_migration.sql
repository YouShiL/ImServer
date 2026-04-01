CREATE TABLE IF NOT EXISTS `user_session` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `session_id` VARCHAR(64) NOT NULL,
  `device_id` VARCHAR(100) DEFAULT NULL,
  `device_name` VARCHAR(100) DEFAULT NULL,
  `device_type` VARCHAR(50) DEFAULT NULL,
  `login_ip` VARCHAR(50) DEFAULT NULL,
  `user_agent` VARCHAR(500) DEFAULT NULL,
  `is_active` BIT(1) DEFAULT b'1',
  `created_at` DATETIME DEFAULT NULL,
  `last_active_at` DATETIME DEFAULT NULL,
  `revoked_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_session_session_id` (`session_id`),
  KEY `idx_user_session_user_id` (`user_id`),
  KEY `idx_user_session_user_active` (`user_id`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
