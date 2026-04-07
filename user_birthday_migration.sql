-- 用户表增加生日字段（与 Flutter /api/user/profile 字段名 birthday 一致，yyyy-MM-dd）
-- 在已有库上执行；新建库可直接使用已更新的 hailiao-im.sql

USE hailiao;

ALTER TABLE `user`
  ADD COLUMN `birthday` VARCHAR(10) DEFAULT NULL COMMENT '生日 yyyy-MM-dd' AFTER `signature`;
