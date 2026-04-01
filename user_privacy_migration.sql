ALTER TABLE `user`
  ADD COLUMN IF NOT EXISTS `show_online_status` TINYINT(1) DEFAULT 1 COMMENT 'show online status';

ALTER TABLE `user`
  ADD COLUMN IF NOT EXISTS `show_last_online` TINYINT(1) DEFAULT 1 COMMENT 'show last online';

ALTER TABLE `user`
  ADD COLUMN IF NOT EXISTS `allow_search_by_phone` TINYINT(1) DEFAULT 1 COMMENT 'allow phone search';

ALTER TABLE `user`
  ADD COLUMN IF NOT EXISTS `need_friend_verification` TINYINT(1) DEFAULT 1 COMMENT 'require friend verification';
