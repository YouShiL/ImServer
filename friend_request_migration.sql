CREATE TABLE IF NOT EXISTS `friend_request` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `from_user_id` BIGINT(20) NOT NULL COMMENT 'sender user id',
  `to_user_id` BIGINT(20) NOT NULL COMMENT 'receiver user id',
  `remark` VARCHAR(50) DEFAULT NULL COMMENT 'friend remark',
  `message` VARCHAR(255) DEFAULT NULL COMMENT 'verification message',
  `status` INT(11) DEFAULT 0 COMMENT '0 pending, 1 accepted, 2 rejected',
  `handled_at` DATETIME DEFAULT NULL COMMENT 'handled time',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'created time',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'updated time',
  PRIMARY KEY (`id`),
  KEY `idx_from_user_id` (`from_user_id`),
  KEY `idx_to_user_id` (`to_user_id`),
  KEY `idx_friend_request_status` (`status`),
  CONSTRAINT `fk_friend_request_from_user` FOREIGN KEY (`from_user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_friend_request_to_user` FOREIGN KEY (`to_user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='friend request table';
