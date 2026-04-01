-- 嗨聊即时通讯系统数据库脚本
-- 数据库: hailiao
-- 编码: utf8mb4
-- 创建日期: 2026-03-10

-- 创建数据库
CREATE DATABASE IF NOT EXISTS hailiao CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hailiao;

-- 1. 用户表
CREATE TABLE IF NOT EXISTS `user` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `user_id` VARCHAR(20) NOT NULL COMMENT '10位随机用户ID',
  `phone` VARCHAR(20) NOT NULL COMMENT '手机号',
  `password` VARCHAR(100) NOT NULL COMMENT '密码(BCrypt加密)',
  `nickname` VARCHAR(50) DEFAULT NULL COMMENT '昵称',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
  `gender` INT(11) DEFAULT 0 COMMENT '性别: 0未知, 1男, 2女',
  `region` VARCHAR(100) DEFAULT NULL COMMENT '地区',
  `signature` VARCHAR(200) DEFAULT NULL COMMENT '个性签名',
  `background` VARCHAR(255) DEFAULT NULL COMMENT '个人主页背景图',
  `online_status` INT(11) DEFAULT 0 COMMENT '在线状态: 0离线, 1在线, 2忙碌, 3隐身',
  `is_vip` TINYINT(1) DEFAULT 0 COMMENT '是否VIP: 0否, 1是',
  `is_pretty_number` TINYINT(1) DEFAULT 0 COMMENT '是否靓号: 0否, 1是',
  `pretty_number` VARCHAR(20) DEFAULT NULL COMMENT '靓号',
  `friend_limit` INT(11) DEFAULT 500 COMMENT '好友上限',
  `group_limit` INT(11) DEFAULT 10 COMMENT '群组上限',
  `group_member_limit` INT(11) DEFAULT 500 COMMENT '群成员上限',
  `device_lock` TINYINT(1) DEFAULT 0 COMMENT '设备锁: 0关闭, 1开启',
  `status` INT(11) DEFAULT 1 COMMENT '状态: 0禁用, 1正常',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `last_login_at` DATETIME DEFAULT NULL COMMENT '最后登录时间',
  `last_login_ip` VARCHAR(50) DEFAULT NULL COMMENT '最后登录IP',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  UNIQUE KEY `uk_phone` (`phone`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 2. 好友表
CREATE TABLE IF NOT EXISTS `friend` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `friend_id` BIGINT(20) NOT NULL COMMENT '好友ID',
  `group_name` VARCHAR(50) DEFAULT '我的好友' COMMENT '分组名称',
  `remark` VARCHAR(50) DEFAULT NULL COMMENT '备注名',
  `status` INT(11) DEFAULT 1 COMMENT '状态: 0删除, 1正常',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_friend_id` (`friend_id`),
  UNIQUE KEY `uk_user_friend` (`user_id`, `friend_id`),
  CONSTRAINT `fk_friend_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_friend_friend` FOREIGN KEY (`friend_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='好友表';

-- 3. 黑名单表
CREATE TABLE IF NOT EXISTS `blacklist` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `blocked_user_id` BIGINT(20) NOT NULL COMMENT '被拉黑用户ID',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_blocked_user_id` (`blocked_user_id`),
  UNIQUE KEY `uk_user_blocked` (`user_id`, `blocked_user_id`),
  CONSTRAINT `fk_blacklist_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_blacklist_blocked` FOREIGN KEY (`blocked_user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='黑名单表';

-- 4. 群组表
CREATE TABLE IF NOT EXISTS `group_chat` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '群组ID',
  `group_id` VARCHAR(20) NOT NULL COMMENT '群组唯一ID',
  `group_name` VARCHAR(100) NOT NULL COMMENT '群组名称',
  `owner_id` BIGINT(20) NOT NULL COMMENT '群主ID',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '群组头像',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '群组描述',
  `notice` VARCHAR(1000) DEFAULT NULL COMMENT '群公告',
  `member_count` INT(11) DEFAULT 1 COMMENT '成员数量',
  `max_member_count` INT(11) DEFAULT 500 COMMENT '最大成员数',
  `is_mute` TINYINT(1) DEFAULT 0 COMMENT '全员禁言: 0否, 1是',
  `join_type` INT(11) DEFAULT 0 COMMENT '加入方式: 0直接加入, 1需要验证, 2禁止加入',
  `status` INT(11) DEFAULT 1 COMMENT '状态: 0解散, 1正常',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_id` (`group_id`),
  KEY `idx_owner_id` (`owner_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_group_owner` FOREIGN KEY (`owner_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群组表';

-- 5. 群成员表
CREATE TABLE IF NOT EXISTS `group_member` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `group_id` BIGINT(20) NOT NULL COMMENT '群组ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `role` INT(11) DEFAULT 0 COMMENT '角色: 0成员, 1管理员, 2群主',
  `group_nickname` VARCHAR(50) DEFAULT NULL COMMENT '群内昵称',
  `is_mute` TINYINT(1) DEFAULT 0 COMMENT '是否禁言: 0否, 1是',
  `join_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  PRIMARY KEY (`id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_user_id` (`user_id`),
  UNIQUE KEY `uk_group_user` (`group_id`, `user_id`),
  CONSTRAINT `fk_member_group` FOREIGN KEY (`group_id`) REFERENCES `group_chat` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_member_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群成员表';

-- 6. 消息表
CREATE TABLE IF NOT EXISTS `message` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `msg_id` VARCHAR(50) NOT NULL COMMENT '消息唯一ID',
  `from_user_id` BIGINT(20) NOT NULL COMMENT '发送者ID',
  `to_user_id` BIGINT(20) DEFAULT NULL COMMENT '接收者ID(单聊)',
  `group_id` BIGINT(20) DEFAULT NULL COMMENT '群组ID(群聊)',
  `content` TEXT COMMENT '消息内容',
  `msg_type` INT(11) DEFAULT 1 COMMENT '消息类型: 1文本, 2图片, 3语音, 4视频, 5文件, 6位置',
  `extra` VARCHAR(1000) DEFAULT NULL COMMENT '额外信息(JSON格式)',
  `status` INT(11) DEFAULT 1 COMMENT '状态: 0失败, 1成功',
  `is_read` TINYINT(1) DEFAULT 0 COMMENT '是否已读: 0否, 1是',
  `is_recall` TINYINT(1) DEFAULT 0 COMMENT '是否撤回: 0否, 1是',
  `recall_time` DATETIME DEFAULT NULL COMMENT '撤回时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_msg_id` (`msg_id`),
  KEY `idx_from_user` (`from_user_id`),
  KEY `idx_to_user` (`to_user_id`),
  KEY `idx_group` (`group_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_msg_from` FOREIGN KEY (`from_user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msg_to` FOREIGN KEY (`to_user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msg_group` FOREIGN KEY (`group_id`) REFERENCES `group_chat` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息表';

-- 7. 会话表
CREATE TABLE IF NOT EXISTS `conversation` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `target_id` BIGINT(20) NOT NULL COMMENT '目标ID(用户ID或群组ID)',
  `type` INT(11) NOT NULL COMMENT '类型: 1单聊, 2群聊',
  `last_msg_id` BIGINT(20) DEFAULT NULL COMMENT '最后消息ID',
  `last_msg_content` VARCHAR(500) DEFAULT NULL COMMENT '最后消息内容预览',
  `unread_count` INT(11) DEFAULT 0 COMMENT '未读消息数',
  `is_top` TINYINT(1) DEFAULT 0 COMMENT '是否置顶: 0否, 1是',
  `is_mute` TINYINT(1) DEFAULT 0 COMMENT '是否免打扰: 0否, 1是',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_target_id` (`target_id`),
  UNIQUE KEY `uk_user_target_type` (`user_id`, `target_id`, `type`),
  CONSTRAINT `fk_conv_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会话表';

-- 8. 管理员表
CREATE TABLE IF NOT EXISTS `admin_user` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '管理员ID',
  `username` VARCHAR(50) NOT NULL COMMENT '用户名',
  `password` VARCHAR(100) NOT NULL COMMENT '密码(BCrypt加密)',
  `name` VARCHAR(50) DEFAULT NULL COMMENT '姓名',
  `role` INT(11) DEFAULT 1 COMMENT '角色: 1超级管理员, 2审核管理员, 3客服管理员, 4财务管理员, 5运营管理员',
  `permissions` VARCHAR(1000) DEFAULT NULL COMMENT '权限(JSON格式)',
  `status` INT(11) DEFAULT 1 COMMENT '状态: 0禁用, 1正常',
  `last_login_at` DATETIME DEFAULT NULL COMMENT '最后登录时间',
  `last_login_ip` VARCHAR(50) DEFAULT NULL COMMENT '最后登录IP',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_role` (`role`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员表';

-- 9. 举报表
CREATE TABLE IF NOT EXISTS `report` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '举报ID',
  `reporter_id` BIGINT(20) NOT NULL COMMENT '举报者ID',
  `target_id` BIGINT(20) NOT NULL COMMENT '被举报对象ID',
  `target_type` INT(11) NOT NULL COMMENT '被举报类型: 1用户, 2消息, 3群组',
  `reason` VARCHAR(500) DEFAULT NULL COMMENT '举报原因',
  `evidence` VARCHAR(1000) DEFAULT NULL COMMENT '证据(图片URL等)',
  `status` INT(11) DEFAULT 0 COMMENT '状态: 0待处理, 1已处理, 2已驳回',
  `handler_id` BIGINT(20) DEFAULT NULL COMMENT '处理人ID',
  `handle_result` VARCHAR(500) DEFAULT NULL COMMENT '处理结果',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `handled_at` DATETIME DEFAULT NULL COMMENT '处理时间',
  PRIMARY KEY (`id`),
  KEY `idx_reporter` (`reporter_id`),
  KEY `idx_target` (`target_id`),
  KEY `idx_status` (`status`),
  KEY `idx_handler` (`handler_id`),
  CONSTRAINT `fk_report_reporter` FOREIGN KEY (`reporter_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_report_handler` FOREIGN KEY (`handler_id`) REFERENCES `admin_user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='举报表';

-- 10. 订单表
CREATE TABLE IF NOT EXISTS `order_info` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `order_no` VARCHAR(50) NOT NULL COMMENT '订单号',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `product_type` INT(11) NOT NULL COMMENT '产品类型: 1VIP会员, 2靓号',
  `product_id` BIGINT(20) DEFAULT NULL COMMENT '产品ID',
  `product_name` VARCHAR(100) DEFAULT NULL COMMENT '产品名称',
  `amount` DECIMAL(10,2) NOT NULL COMMENT '金额',
  `pay_type` INT(11) DEFAULT 0 COMMENT '支付方式: 0未支付, 1支付宝, 2微信, 3余额',
  `pay_status` INT(11) DEFAULT 0 COMMENT '支付状态: 0未支付, 1已支付, 2已退款',
  `pay_time` DATETIME DEFAULT NULL COMMENT '支付时间',
  `pay_no` VARCHAR(100) DEFAULT NULL COMMENT '第三方支付流水号',
  `status` INT(11) DEFAULT 1 COMMENT '订单状态: 0已取消, 1正常',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_pay_status` (`pay_status`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

-- 11. 靓号表
CREATE TABLE IF NOT EXISTS `pretty_number` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `number` VARCHAR(20) NOT NULL COMMENT '靓号',
  `level` INT(11) DEFAULT 1 COMMENT '等级: 1普通, 2高级, 3顶级',
  `price` DECIMAL(10,2) NOT NULL COMMENT '价格',
  `status` INT(11) DEFAULT 0 COMMENT '状态: 0未售出, 1已售出, 2已过期',
  `user_id` BIGINT(20) DEFAULT NULL COMMENT '购买者ID',
  `buy_time` DATETIME DEFAULT NULL COMMENT '购买时间',
  `expire_time` DATETIME DEFAULT NULL COMMENT '过期时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_number` (`number`),
  KEY `idx_status` (`status`),
  KEY `idx_level` (`level`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `fk_pretty_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='靓号表';

-- 12. VIP会员表
CREATE TABLE IF NOT EXISTS `vip_member` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `vip_level` INT(11) DEFAULT 1 COMMENT 'VIP等级: 1普通VIP, 2高级VIP, 3至尊VIP',
  `start_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `expire_time` DATETIME NOT NULL COMMENT '过期时间',
  `status` INT(11) DEFAULT 1 COMMENT '状态: 0已过期, 1有效',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_expire_time` (`expire_time`),
  CONSTRAINT `fk_vip_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='VIP会员表';

-- 13. 系统配置表
CREATE TABLE IF NOT EXISTS `system_config` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `config_key` VARCHAR(100) NOT NULL COMMENT '配置键',
  `config_value` VARCHAR(2000) DEFAULT NULL COMMENT '配置值',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '配置说明',
  `category` VARCHAR(50) DEFAULT NULL COMMENT '配置分类',
  `updated_by` BIGINT(20) DEFAULT NULL COMMENT '更新人ID',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`),
  KEY `idx_category` (`category`),
  CONSTRAINT `fk_config_updater` FOREIGN KEY (`updated_by`) REFERENCES `admin_user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

-- 14. 内容审核表
CREATE TABLE IF NOT EXISTS `content_audit` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `content_type` INT(11) NOT NULL COMMENT '内容类型: 1文本, 2图片, 3语音, 4视频',
  `target_id` BIGINT(20) NOT NULL COMMENT '目标ID(消息ID等)',
  `content` TEXT COMMENT '内容',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `ai_result` INT(11) DEFAULT NULL COMMENT 'AI审核结果: 1通过, 2拒绝, 3待人工审核',
  `ai_score` INT(11) DEFAULT NULL COMMENT 'AI评分(0-100)',
  `manual_result` INT(11) DEFAULT NULL COMMENT '人工审核结果: 1通过, 2拒绝',
  `handler_id` BIGINT(20) DEFAULT NULL COMMENT '处理人ID',
  `handle_note` VARCHAR(500) DEFAULT NULL COMMENT '处理备注',
  `status` INT(11) DEFAULT 0 COMMENT '状态: 0待审核, 1已审核',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `handled_at` DATETIME DEFAULT NULL COMMENT '处理时间',
  PRIMARY KEY (`id`),
  KEY `idx_content_type` (`content_type`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_handler` (`handler_id`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_audit_handler` FOREIGN KEY (`handler_id`) REFERENCES `admin_user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='内容审核表';

-- 15. 操作日志表
CREATE TABLE IF NOT EXISTS `operation_log` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` BIGINT(20) DEFAULT NULL COMMENT '操作用户ID',
  `username` VARCHAR(50) DEFAULT NULL COMMENT '操作用户名',
  `operation_type` VARCHAR(50) DEFAULT NULL COMMENT '操作类型',
  `module` VARCHAR(50) DEFAULT NULL COMMENT '操作模块',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '操作描述',
  `request_method` VARCHAR(10) DEFAULT NULL COMMENT '请求方法',
  `request_url` VARCHAR(500) DEFAULT NULL COMMENT '请求URL',
  `request_params` VARCHAR(2000) DEFAULT NULL COMMENT '请求参数',
  `response_data` VARCHAR(2000) DEFAULT NULL COMMENT '响应数据',
  `ip` VARCHAR(50) DEFAULT NULL COMMENT 'IP地址',
  `status` INT(11) DEFAULT 1 COMMENT '状态: 0失败, 1成功',
  `error_msg` VARCHAR(1000) DEFAULT NULL COMMENT '错误信息',
  `execute_time` BIGINT(20) DEFAULT NULL COMMENT '执行时间(ms)',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_module` (`module`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志表';

-- 初始化数据

-- 插入默认超级管理员
INSERT INTO `admin_user` (`username`, `password`, `name`, `role`, `permissions`, `status`, `created_at`) VALUES
('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EO', '超级管理员', 1, '["*"]', 1, NOW());

-- 插入系统配置
INSERT INTO `system_config` (`config_key`, `config_value`, `description`, `category`) VALUES
('app.name', '嗨聊', '应用名称', 'basic'),
('app.version', '1.0.0', '应用版本', 'basic'),
('user.default_friend_limit', '500', '默认好友上限', 'user'),
('user.default_group_limit', '10', '默认群组上限', 'user'),
('user.default_group_member_limit', '500', '默认群成员上限', 'user'),
('vip.friend_limit', '1000', 'VIP好友上限', 'vip'),
('vip.group_limit', '999', 'VIP群组上限', 'vip'),
('vip.group_member_limit', '5000', 'VIP群成员上限', 'vip'),
('message.recall_time_limit', '120', '消息撤回时间限制(秒)', 'message'),
('message.history_days', '90', '历史消息保存天数', 'message'),
('storage.max_file_size', '104857600', '最大文件大小(字节)', 'storage'),
('storage.max_image_size', '10485760', '最大图片大小(字节)', 'storage');

-- 插入测试靓号
INSERT INTO `pretty_number` (`number`, `level`, `price`, `status`, `created_at`) VALUES
('8888888888', 3, 9999.00, 0, NOW()),
('6666666666', 3, 8888.00, 0, NOW()),
('9999999999', 3, 8888.00, 0, NOW()),
('1234567890', 2, 1999.00, 0, NOW()),
('9876543210', 2, 1999.00, 0, NOW()),
('1111111111', 2, 1666.00, 0, NOW()),
('2222222222', 2, 1666.00, 0, NOW()),
('3333333333', 2, 1666.00, 0, NOW()),
('4444444444', 2, 1666.00, 0, NOW()),
('5555555555', 2, 1666.00, 0, NOW());

-- 16. 视频通话表
CREATE TABLE IF NOT EXISTS `video_call` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '通话ID',
  `caller_id` BIGINT(20) NOT NULL COMMENT '呼叫者ID',
  `callee_id` BIGINT(20) NOT NULL COMMENT '被呼叫者ID',
  `group_id` BIGINT(20) DEFAULT NULL COMMENT '群组ID(群视频)',
  `call_type` INT(11) NOT NULL COMMENT '通话类型: 1音频, 2视频',
  `status` INT(11) NOT NULL DEFAULT 0 COMMENT '状态: 0呼叫中, 1通话中, 2已结束, 3已拒绝, 4已取消, 5无应答',
  `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
  `end_time` DATETIME DEFAULT NULL COMMENT '结束时间',
  `duration` INT(11) DEFAULT 0 COMMENT '通话时长(秒)',
  `end_reason` VARCHAR(200) DEFAULT NULL COMMENT '结束原因',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_caller` (`caller_id`),
  KEY `idx_callee` (`callee_id`),
  KEY `idx_group` (`group_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_call_caller` FOREIGN KEY (`caller_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_call_callee` FOREIGN KEY (`callee_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_call_group` FOREIGN KEY (`group_id`) REFERENCES `group_chat` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='视频通话表';

-- 17. 群机器人表
CREATE TABLE IF NOT EXISTS `group_robot` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '机器人ID',
  `group_id` BIGINT(20) NOT NULL COMMENT '群组ID',
  `name` VARCHAR(50) DEFAULT NULL COMMENT '机器人名称',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '机器人头像',
  `description` VARCHAR(255) DEFAULT NULL COMMENT '机器人描述',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用: 0否, 1是',
  `webhook_url` VARCHAR(255) DEFAULT NULL COMMENT 'Webhook URL',
  `api_key` VARCHAR(100) DEFAULT NULL COMMENT 'API密钥',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_is_enabled` (`is_enabled`),
  CONSTRAINT `fk_robot_group` FOREIGN KEY (`group_id`) REFERENCES `group_chat` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群机器人表';

-- 18. 机器人指令表
CREATE TABLE IF NOT EXISTS `robot_command` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '指令ID',
  `robot_id` BIGINT(20) NOT NULL COMMENT '机器人ID',
  `command` VARCHAR(50) NOT NULL COMMENT '指令名称(触发关键词)',
  `description` VARCHAR(255) DEFAULT NULL COMMENT '指令描述',
  `response_type` INT(11) DEFAULT 1 COMMENT '响应类型: 1文本, 2图片, 3链接, 4API调用',
  `response_content` TEXT DEFAULT NULL COMMENT '响应内容',
  `api_url` VARCHAR(255) DEFAULT NULL COMMENT 'API URL',
  `api_method` VARCHAR(10) DEFAULT 'GET' COMMENT 'API请求方法',
  `api_params` TEXT DEFAULT NULL COMMENT 'API请求参数(JSON)',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用: 0否, 1是',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_robot_id` (`robot_id`),
  KEY `idx_command` (`command`),
  KEY `idx_is_enabled` (`is_enabled`),
  CONSTRAINT `fk_cmd_robot` FOREIGN KEY (`robot_id`) REFERENCES `group_robot` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='机器人指令表';

-- 19. 消息已读状态表
CREATE TABLE IF NOT EXISTS `message_read_status` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `message_id` BIGINT(20) NOT NULL COMMENT '消息ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '已读用户ID',
  `read_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '已读时间',
  PRIMARY KEY (`id`),
  KEY `idx_message_id` (`message_id`),
  KEY `idx_user_id` (`user_id`),
  UNIQUE KEY `uk_msg_user` (`message_id`, `user_id`),
  CONSTRAINT `fk_read_msg` FOREIGN KEY (`message_id`) REFERENCES `message` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_read_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息已读状态表';

-- 新增字段 - 用户表
ALTER TABLE `user` ADD COLUMN `last_online_at` DATETIME DEFAULT NULL COMMENT '最后在线时间' AFTER `online_status`;
ALTER TABLE `user` ADD COLUMN `show_online_status` TINYINT(1) DEFAULT 1 COMMENT '是否显示在线状态' AFTER `last_online_at`;
ALTER TABLE `user` ADD COLUMN `show_last_online` TINYINT(1) DEFAULT 1 COMMENT '是否显示最后在线时间' AFTER `show_online_status`;

-- 新增字段 - 消息表
ALTER TABLE `message` ADD COLUMN `reply_to_msg_id` BIGINT(20) DEFAULT NULL COMMENT '引用回复的消息ID' AFTER `extra`;
ALTER TABLE `message` ADD COLUMN `forward_from_msg_id` BIGINT(20) DEFAULT NULL COMMENT '转发来源消息ID' AFTER `reply_to_msg_id`;
ALTER TABLE `message` ADD COLUMN `forward_from_user_id` BIGINT(20) DEFAULT NULL COMMENT '转发来源用户ID' AFTER `forward_from_msg_id`;
ALTER TABLE `message` ADD COLUMN `forward_from_nickname` VARCHAR(50) DEFAULT NULL COMMENT '转发来源用户昵称' AFTER `forward_from_user_id`;
ALTER TABLE `message` ADD COLUMN `is_edited` TINYINT(1) DEFAULT 0 COMMENT '是否已编辑' AFTER `forward_from_nickname`;
ALTER TABLE `message` ADD COLUMN `edit_time` DATETIME DEFAULT NULL COMMENT '编辑时间' AFTER `is_edited`;
ALTER TABLE `message` ADD COLUMN `is_pinned` TINYINT(1) DEFAULT 0 COMMENT '是否置顶' AFTER `edit_time`;
ALTER TABLE `message` ADD COLUMN `pin_time` DATETIME DEFAULT NULL COMMENT '置顶时间' AFTER `is_pinned`;
ALTER TABLE `message` ADD COLUMN `at_user_ids` VARCHAR(500) DEFAULT NULL COMMENT '@的用户ID列表(JSON)' AFTER `pin_time`;
ALTER TABLE `message` ADD COLUMN `is_at_all` TINYINT(1) DEFAULT 0 COMMENT '是否@所有人' AFTER `at_user_ids`;
ALTER TABLE `message` ADD COLUMN `read_count` INT(11) DEFAULT 0 COMMENT '已读人数(群聊)' AFTER `is_at_all`;

-- 新增字段 - 群组表
ALTER TABLE `group_chat` ADD COLUMN `notice_updated_at` DATETIME DEFAULT NULL COMMENT '公告更新时间' AFTER `notice`;
ALTER TABLE `group_chat` ADD COLUMN `notice_updated_by` BIGINT(20) DEFAULT NULL COMMENT '公告更新人ID' AFTER `notice_updated_at`;
ALTER TABLE `group_chat` ADD COLUMN `mute_all` TINYINT(1) DEFAULT 0 COMMENT '全员禁言' AFTER `is_mute`;
ALTER TABLE `group_chat` ADD COLUMN `allow_member_invite` TINYINT(1) DEFAULT 1 COMMENT '允许成员邀请' AFTER `mute_all`;

-- 新增字段 - 群成员表
ALTER TABLE `group_member` ADD COLUMN `mute_until` DATETIME DEFAULT NULL COMMENT '禁言截止时间' AFTER `is_mute`;
ALTER TABLE `group_member` ADD COLUMN `last_read_msg_id` BIGINT(20) DEFAULT NULL COMMENT '最后已读消息ID' AFTER `join_time`;
ALTER TABLE `group_member` ADD COLUMN `is_top` TINYINT(1) DEFAULT 0 COMMENT '是否置顶' AFTER `last_read_msg_id`;
ALTER TABLE `group_member` ADD COLUMN `is_mute_notification` TINYINT(1) DEFAULT 0 COMMENT '是否消息免打扰' AFTER `is_top`;

-- 创建索引
ALTER TABLE `message` ADD INDEX `idx_reply_to` (`reply_to_msg_id`);
ALTER TABLE `message` ADD INDEX `idx_forward_from` (`forward_from_msg_id`);
ALTER TABLE `message` ADD INDEX `idx_is_pinned` (`is_pinned`);
ALTER TABLE `group_chat` ADD INDEX `idx_mute_all` (`mute_all`);

-- 创建数据库用户并授权(可选)
-- CREATE USER IF NOT EXISTS 'hailiao'@'localhost' IDENTIFIED BY 'hailiao123';
-- GRANT ALL PRIVILEGES ON hailiao.* TO 'hailiao'@'localhost';
-- FLUSH PRIVILEGES;
 
-- 好友申请表补充定义
CREATE TABLE IF NOT EXISTS `friend_request` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `from_user_id` BIGINT(20) NOT NULL COMMENT '申请发起人ID',
  `to_user_id` BIGINT(20) NOT NULL COMMENT '申请接收人ID',
  `remark` VARCHAR(50) DEFAULT NULL COMMENT '好友备注',
  `message` VARCHAR(255) DEFAULT NULL COMMENT '验证消息',
  `status` INT(11) DEFAULT 0 COMMENT '状态: 0待处理, 1已同意, 2已拒绝',
  `handled_at` DATETIME DEFAULT NULL COMMENT '处理时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_from_user_id` (`from_user_id`),
  KEY `idx_to_user_id` (`to_user_id`),
  KEY `idx_friend_request_status` (`status`),
  CONSTRAINT `fk_friend_request_from_user` FOREIGN KEY (`from_user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_friend_request_to_user` FOREIGN KEY (`to_user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='好友申请表';
