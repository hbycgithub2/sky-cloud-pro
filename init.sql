-- 创建数据库
CREATE DATABASE IF NOT EXISTS cloud_user DEFAULT CHARACTER SET utf8mb4;
CREATE DATABASE IF NOT EXISTS cloud_order DEFAULT CHARACTER SET utf8mb4;

-- 使用 cloud_user 数据库
USE cloud_user;

-- 创建用户表
CREATE TABLE IF NOT EXISTS `user` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '用户id',
  `username` VARCHAR(100) DEFAULT NULL COMMENT '用户名',
  `address` VARCHAR(200) DEFAULT NULL COMMENT '地址',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 插入测试数据
INSERT INTO `user` (`id`, `username`, `address`) VALUES
(1, '柳岩', '湖南省衡阳市'),
(2, '文二狗', '陕西省西安市'),
(3, '华沙', '湖北省十堰市'),
(4, '张必沉', '天津市'),
(5, '郑爽爽', '辽宁省沈阳市');

-- 使用 cloud_order 数据库
USE cloud_order;

-- 创建订单表
CREATE TABLE IF NOT EXISTS `order` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '订单id',
  `user_id` BIGINT(20) DEFAULT NULL COMMENT '用户id',
  `name` VARCHAR(100) DEFAULT NULL COMMENT '商品名称',
  `price` BIGINT(20) DEFAULT NULL COMMENT '价格',
  `num` INT(11) DEFAULT NULL COMMENT '数量',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

-- 插入测试数据
INSERT INTO `order` (`id`, `user_id`, `name`, `price`, `num`) VALUES
(101, 1, 'Apple 苹果 iPhone 12', 699900, 1),
(102, 2, '雅迪 yadea 新国标电动车', 209900, 1),
(103, 3, '骆驼（CAMEL）休闲运动鞋女', 43900, 1),
(104, 4, '小米10 双模5G 骁龙865', 359900, 1),
(105, 5, 'OPPO Reno3 Pro 双模5G 视频双防抖', 299900, 1);
