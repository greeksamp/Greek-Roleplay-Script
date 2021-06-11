CREATE TABLE `accounts` (
  `account_id` int(11) NOT NULL,
  `account_name` varchar(32) NOT NULL,
  `account_password` varchar(256) NOT NULL,
  `account_email` varchar(256) NOT NULL,
  `account_registered` int(11) NOT NULL,
  `account_passwordLastChange` int(11) NOT NULL,
  `account_score` int(11) NOT NULL,
  `account_money` int(11) NOT NULL,
  `account_activeSeconds` int(11) NOT NULL,
  `account_online` int(11) NOT NULL,
  `account_skin` int(11) NOT NULL,
  `account_admin` int(11) NOT NULL,
  `account_faction` int(11) NOT NULL,
  `account_rank` int(11) NOT NULL,
  `account_lastLogin` int(11) NOT NULL,
  `account_jailed` int(11) NOT NULL,
  `account_kills` int(11) NOT NULL,
  `account_deaths` int(11) NOT NULL,
  `account_wanted` int(11) NOT NULL,
  `account_escaped` int(11) NOT NULL,
  `account_succ_escapes` int(11) NOT NULL,
  `account_weekly_seconds` int(11) NOT NULL,
  `account_weekly_score` int(11) NOT NULL,
  `account_quest` int(11) NOT NULL,
  `account_contracts` int(11) NOT NULL,
  `account_contracts_price` int(11) NOT NULL,
  `account_free_vehicle` int(11) NOT NULL,
  `account_spawnInHouse` int(11) NOT NULL,
  `account_robLS_cooldown` int(11) NOT NULL,
  `account_robSF_cooldown` int(11) NOT NULL,
  `account_inviteCooldown` int(11) NOT NULL,
  `account_phoneNumber` int(11) NOT NULL,
  `account_warns` int(11) NOT NULL,
  `account_lastPromotion` int(11) NOT NULL,
  `account_helper` int(11) NOT NULL,
  `account_ban` int(11) NOT NULL,
  `account_ban_by` int(11) NOT NULL,
  `account_ban_reason` varchar(64) NOT NULL,
  `account_ban_date` int(11) NOT NULL,
  `account_helperAnswers` int(11) NOT NULL,
  `account_adminReports` int(11) NOT NULL,
  `account_materials` int(11) NOT NULL,
  `account_skillMaterials` int(11) NOT NULL,
  `account_bank` int(11) NOT NULL,
  `account_clan` int(11) NOT NULL,
  `account_clanRank` int(11) NOT NULL,
  `account_mute` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `activity_reports` (
  `r_id` int(11) NOT NULL,
  `r_player` int(11) NOT NULL,
  `r_faction` int(11) NOT NULL,
  `r_type` varchar(32) NOT NULL,
  `r_serviced_player` int(11) NOT NULL,
  `r_date` int(11) NOT NULL,
  `r_amount` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `banned_ips` (
  `b_id` int(11) NOT NULL,
  `b_ip` varchar(64) NOT NULL,
  `b_date` int(11) NOT NULL,
  `b_variable` int(11) NOT NULL,
  `b_reason` varchar(64) NOT NULL,
  `b_admin` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `business` (
  `biz_id` int(11) NOT NULL,
  `biz_type` int(11) NOT NULL,
  `biz_price` int(11) NOT NULL,
  `biz_entrance` int(11) NOT NULL,
  `biz_owner` int(11) NOT NULL,
  `biz_owner_name` varchar(32) NOT NULL,
  `biz_profit` int(11) NOT NULL,
  `biz_sell` int(11) NOT NULL,
  `biz_x` double NOT NULL,
  `biz_y` double NOT NULL,
  `biz_z` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



CREATE TABLE `clans` (
  `clan_id` int(11) NOT NULL,
  `clan_name` varchar(64) NOT NULL,
  `clan_tag` varchar(32) NOT NULL,
  `clan_slots` int(11) NOT NULL,
  `clan_date` int(11) NOT NULL,
  `clan_until` int(11) NOT NULL,
  `clan_skinL6` int(11) NOT NULL,
  `clan_skin5` int(11) NOT NULL,
  `clan_skin4` int(11) NOT NULL,
  `clan_skin3` int(11) NOT NULL,
  `clan_skin2` int(11) NOT NULL,
  `clan_skin1` int(11) NOT NULL,
  `clan_color` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `components` (
  `component_uid` int(11) NOT NULL,
  `component_car_id` int(11) NOT NULL,
  `component_slot` int(11) NOT NULL,
  `component_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `houses` (
  `house_id` int(11) NOT NULL,
  `house_owner` int(11) NOT NULL,
  `house_interior` int(11) NOT NULL,
  `house_exteriorX` double NOT NULL,
  `house_exteriorY` double NOT NULL,
  `house_exteriorZ` double NOT NULL,
  `house_owner_name` varchar(32) NOT NULL,
  `house_date` int(11) NOT NULL,
  `house_price` int(11) NOT NULL,
  `house_sell` int(11) NOT NULL,
  `house_locked` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `logs` (
  `log_id` int(11) NOT NULL,
  `log_player` int(11) NOT NULL,
  `log_type` varchar(64) NOT NULL,
  `log_info` varchar(256) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `motd` (
  `motd_group` varchar(32) NOT NULL,
  `motd_group_variable` int(11) NOT NULL,
  `motd_by_name` varchar(32) NOT NULL,
  `motd_message` varchar(128) NOT NULL,
  `motd_date` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `promotions` (
  `promotion_id` int(11) NOT NULL,
  `promotion_player` int(11) NOT NULL,
  `promotion_type` varchar(64) NOT NULL,
  `promotion_new_level` int(11) NOT NULL,
  `promotion_by` int(11) NOT NULL,
  `promotion_date` int(11) NOT NULL,
  `promotion_variable` int(11) NOT NULL,
  `promotion_reason` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



CREATE TABLE `sanctions` (
  `sanction_id` int(11) NOT NULL,
  `sanction_player` int(11) NOT NULL,
  `sanction_date` int(11) NOT NULL,
  `sanction_type` varchar(64) NOT NULL,
  `sanction_variable` int(11) NOT NULL,
  `sanction_admin_id` int(11) NOT NULL,
  `sanction_reason` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `shop_transactions` (
  `s_id` int(11) NOT NULL,
  `s_player` int(11) NOT NULL,
  `s_item` varchar(64) NOT NULL,
  `s_date` int(11) NOT NULL,
  `s_cost` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



CREATE TABLE `turfs` (
  `turf_id` int(11) NOT NULL,
  `turf_minx` double NOT NULL,
  `turf_miny` double NOT NULL,
  `turf_maxx` double NOT NULL,
  `turf_maxy` double NOT NULL,
  `turf_owner_clan` int(11) NOT NULL,
  `turf_owner_clanName` varchar(64) NOT NULL,
  `turf_posX` double NOT NULL,
  `turf_posY` double NOT NULL,
  `turf_posZ` double NOT NULL,
  `turf_objectX` double NOT NULL,
  `turf_objectY` double NOT NULL,
  `turf_objectZ` double NOT NULL,
  `turf_objectRX` double NOT NULL,
  `turf_objectRY` double NOT NULL,
  `turf_objectRZ` double NOT NULL,
  `turf_color` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


INSERT INTO `turfs` (`turf_id`, `turf_minx`, `turf_miny`, `turf_maxx`, `turf_maxy`, `turf_owner_clan`, `turf_owner_clanName`, `turf_posX`, `turf_posY`, `turf_posZ`, `turf_objectX`, `turf_objectY`, `turf_objectZ`, `turf_objectRX`, `turf_objectRY`, `turf_objectRZ`, `turf_color`) VALUES
(1, 144.984375, -1328.484375, 837.984375, -953.484375, 0, 'None', 438.6919, -1300.7362, 15.1553, 438.0296, -1300.9158, 14.8747, 0, 0, 33.7, 'blue a'),
(2, 837.984375, -1328.484375, 1530.984375, -953.484375, 0, 'None', 1083.5697, -1194.7473, 18.09, 1082.5961, -1194.2088, 18.374, 0, 0, 0, 'blue a'),
(3, 1530.984375, -1328.484375, 2223.984375, -953.484375, 0, 'None', 1938.4042, -1249.6835, 18.6614, 1937.8081, -1250.4813, 18.5603, 0, 0, 90.2999, 'blue a'),
(4, 2223.984375, -1328.484375, 2916.984375, -953.484375, 0, 'None', 2488.1611, -1312.2734, 34.8582, 2487.9289, -1312.7773, 34.8594, 0, 0, 88.0999, 'blue a'),
(5, 144.984375, -1703.484375, 837.984375, -1328.484375, 0, 'None', 605.6861, -1489.7412, 14.9226, 605.8494, -1488.6597, 14.9244, 0, 0, 90.2999, 'blue a'),
(6, 837.984375, -1703.484375, 1530.984375, -1328.484375, 0, 'None', 1090.6819, -1486.3916, 15.5113, 1090.5717, -1485.356, 15.584, 0, 0, 105.9999, 'blue a'),
(7, 1530.984375, -1703.484375, 2223.984375, -1328.484375, 0, 'None', 1802.1853, -1420.3857, 13.5783, 1802.6801, -1419.1735, 13.5782, 0, 0, 90.0999, 'blue a'),
(8, 2223.984375, -1703.484375, 2916.984375, -1328.484375, 0, 'None', 2432.9878, -1679.7051, 13.7734, 2432.5153, -1681.0341, 12.7742, 0, 0, -89.5998, 'blue a'),
(9, 837.984375, -2078.484375, 1530.984375, -1703.484375, 0, 'None', 1251.3875, -1802.5566, 13.6008, 1250.6143, -1801.539, 13.6008, 0, 0, -53.3999, 'blue a'),
(10, 1530.984375, -2078.484375, 2223.984375, -1703.484375, 0, 'None', 1970.3579, -1916.7559, 13.5469, 1971.7255, -1917.5145, 13.5468, 0, 0, 0, 'blue a'),
(11, 2223.984375, -2078.484375, 2916.984375, -1703.484375, 0, 'None', 2453.1362, -1759.4305, 13.5907, 2453.0839, -1758.2489, 13.5898, 0, 0, 89.4, 'blue a'),
(12, -2472, -311.83349609375, -2123, -106.83349609375, 0, 'None', -2301.9363, -116.8792, 35.3203, -2300.9294, -115.8756, 34.4503, 0, 0, -89.9, 'blue a'),
(13, -2820, -310.83349609375, -2471, -105.83349609375, 0, 'None', -2631.2854, -219.5836, 4.3359, -2632.2453, -220.3972, 3.6335, 0, 0, -89.9999, 'blue a'),
(14, -2123, -310.83349609375, -1774, -105.83349609375, 0, 'None', -2009.949, -232.3288, 35.7109, -2010.6737, -231.1413, 35.0109, 0, 0, 0, 'blue a'),
(15, -2123, -106.83349609375, -1774, 98.16650390625, 0, 'None', -2016.5446, 40.3789, 32.6776, -2017.1771, 41.565, 31.7095, 0, 0, -1.5, 'blue a'),
(16, -2472, -106.83349609375, -2123, 98.16650390625, 0, 'None', -2181.2244, 35.675, 35.3203, -2182.5761, 35.0485, 34.2803, 0, 0, -90.3999, 'blue a'),
(17, -2821, -106.83349609375, -2472, 98.16650390625, 0, 'None', -2647.8818, -23.0412, 6.1328, -2647.0029, -22.0776, 5.7528, 0, 0, -90.0999, 'blue a'),
(18, -2821, 98.16650390625, -2472, 303.16650390625, 0, 'None', -2552.7297, 185.3746, 5.6611, -2551.9157, 184.6951, 5.3096, 0, 0, 0, 'blue a'),
(19, -2472, 97.16650390625, -2123, 302.16650390625, 0, 'None', -2159.8787, 286.3251, 35.3203, -2160.4396, 285.6849, 34.7603, 0, 0, -91.4999, 'blue a'),
(20, -2123, 98.16650390625, -1774, 303.16650390625, 0, 'None', -1993.3265, 237.5657, 29.0391, -1992.9919, 238.4661, 28.832, 0, 0, -90.1999, 'blue a');


CREATE TABLE `vehicles` (
  `vehicle_id` int(11) NOT NULL,
  `vehicle_owner` int(11) NOT NULL,
  `vehicle_model` int(11) NOT NULL,
  `vehicle_parkX` double NOT NULL,
  `vehicle_parkY` double NOT NULL,
  `vehicle_parkZ` double NOT NULL,
  `vehicle_parkA` double NOT NULL,
  `vehicle_plate` varchar(64) NOT NULL,
  `vehicle_date` int(11) NOT NULL,
  `vehicle_color1` int(11) NOT NULL DEFAULT 1,
  `vehicle_color2` int(11) NOT NULL DEFAULT 1,
  `vehicle_fuel` int(11) NOT NULL DEFAULT 100,
  `vehicle_odometer` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


ALTER TABLE `accounts`
  ADD PRIMARY KEY (`account_id`);


ALTER TABLE `banned_ips`
  ADD PRIMARY KEY (`b_id`);


ALTER TABLE `business`
  ADD PRIMARY KEY (`biz_id`);


ALTER TABLE `clans`
  ADD PRIMARY KEY (`clan_id`);


ALTER TABLE `components`
  ADD PRIMARY KEY (`component_uid`);


ALTER TABLE `houses`
  ADD PRIMARY KEY (`house_id`);


ALTER TABLE `logs`
  ADD PRIMARY KEY (`log_id`);


ALTER TABLE `motd`
  ADD PRIMARY KEY (`motd_group`,`motd_group_variable`);


ALTER TABLE `promotions`
  ADD PRIMARY KEY (`promotion_id`);


ALTER TABLE `sanctions`
  ADD PRIMARY KEY (`sanction_id`);


ALTER TABLE `shop_transactions`
  ADD PRIMARY KEY (`s_id`);


ALTER TABLE `turfs`
  ADD PRIMARY KEY (`turf_id`);


ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`vehicle_id`);
