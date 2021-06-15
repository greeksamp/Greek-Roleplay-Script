#include <a_samp>

#undef 		MAX_PLAYERS
#define 	MAX_PLAYERS 		50


#include "import/a_dini2.inc"
#include "import/a_crashdetect.inc"
#include "import/a_mysql.inc"
#include "import/a_easy_dialog.inc"
#include "import/a_sscanf2.inc"
#include "import/a_izcmd.inc"
#include "import/a_timestamp.inc"
#include "import/a_streamer.inc"

#include "import/rpg_anim.inc"
// #include "import/rpg_greek_flag.inc"


#define CONFIG_INI "config.ini"

new bool:ServerInProduction = false;
new MySQL: Database;
new DatabaseConnected = false;

new serverIntervalID;
new serverIntervalTimestamp;

new SCRIPT_VERSION[16];

new serverTimeZoneKey;
new serverTimeZone;

new serverLastPayday = 99; //Hour
new FORCE_PAYDAY = false;
new serverLastSprayingTimeH = 99;

new EVENT_OWNER;
new EVENT_PRIZE;
new EVENT_TITLE[32];

new CARS_FUEL_UPDATE;

new chatIsOff = false;

new colorTagInChat = false;
new modeChat = 0; //0 says, 1 tags

new FORCE_WARTIME = false;

#define IsPlayerAfk(%0) (playerData[%0][playerTick]+1000 < GetTickCount())

#if !defined isnull
    #define isnull(%1) ((!(%1[0])) || (((%1[0]) == '\1') && (!(%1[1]))))
#endif

new passHashSalt[32];
new radioHashSalt[32];

#define COLOR_SERVER    0xe6e6e6FF
#define COLOR_SYNTAX    0x9c9c9cFF
#define COLOR_PUBLIC    0x74ad61FF
#define COLOR_PM	    0xf3fa6bFF
#define COLOR_ADMIN	    0xb3a462FF
#define COLOR_FACTION   0x666fb0FF
#define COLOR_PAINTBALL 0x1adbc1FF
#define COLOR_INFO		0x87a0c9FF
#define COLOR_BADINFO	0xbd7575FF
#define COLOR_PUNISH	0xcf4f2bFF

#define FACTION_CIVIL  0
#define FACTION_TAXILS 1
#define FACTION_LSPD   2
#define FACTION_GROOVE 3
#define FACTION_MEDICS 4
#define FACTION_HITMAN 5

#define INTERIOR_PRISON 	1
#define INTERIOR_BANK_LS	2
#define INTERIOR_BANK_SF	3

#define CARMODTYPE_PAINTJOB 50

#define ROB_PER_CITY_COOL	900

#define WORKING_FARMER		1
#define WORKING_DEALER		2

new ROB_DROP_SF = 0;
new ROB_DROP_LS = 0;

new INFOMESSAGES_INDEX;
new INFOMESSAGES_TIMESTAMP;
new INFOMESSAGES[][] = {
	"{e1ebe9}Info: Find all /biz and /locations.",
	"{e1ebe9}Info: Check the online /admins and send them a /report.",
	"{e1ebe9}Info: Check the online /helpers and ask them if you need any help.",
	"{e1ebe9}Info: Join our discord server:  www.greeksamp.info!",
	"{e1ebe9}Info: All commands for your vehicles are in /carhelp.",
	"{e1ebe9}Info: All commands for your house are in /househelp.",
	"{e1ebe9}Info: Do you want to join a faction? Contact a leader on our discord server.",
	"{e1ebe9}Info: Bored waiting in jail? Use /escape and once you are out go to a clothes shop.",
	"{e1ebe9}Info: Do you want to /sellgun to other players? Collect materials as a dealer. Find it in /locations.",
	"{e1ebe9}Info: Check which clan owns which turf with /turfs.",
	"{e1ebe9}Info: With /sellgun you can sell a gun to your friends anytime, anywhere. Check /materialshelp."

}

new STRM_CAMERA_IP[16];
new STRM_CAMERA_LAST;
new Float:STRM_CAMERA_LOCATIONS[][] = {
	{1211.3134,-1287.5394,19.9516, 1177.4180,-1324.2224,14.0697}, // paramedics
	{1834.0892,-1838.9597,17.1162, 1800.7826,-1865.5585,13.5725}, // main spawn
	{1807.7900,-1939.6539,15.4863, 1754.2646,-1894.3219,13.5570}, // taxi
	{1514.4189,-1697.6023,23.1567, 1553.4355,-1675.1517,16.1953}, // pd
	{1564.2919,-1670.2010,-11.4757, 1552.5116,-1657.2472,-14.3242} // jail
};

new SERVER_SKINS[] = {
	1,2,4,5,6,7,9,10,12,19,26,27,28,
	29,31,32,34,35,36,37,38,39,40,41,
	42,43,44,45,51,52,53,54,55,56,58,
	60,63,64,65,66,67,69,72,73,75,76,
	77,78,79,80,81,82,83,84,85,87,88,
	89,90,91,92,93,94,95,96,97,98,99,
	100,101,129,130,131,132,133,134,135,
	136,137,138,139,140,143,144,145,146,152,155, 	//0  -  87: Civil
	142, 261, 262, 69, 259,							//88 -  92: Taxi
	71, 281, 285, 306, 307, 288,					//93 -  98: LSPD
	274, 275, 276, 308, 290,						//99 -  103: PARAMEDICS
	294, 208, 263, 186								//104 -  107: HITMAN
};

new CLAN_SKINS[] = {0,3,86,102,103,104,105,106,108,109,110,111,112,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,149,173,174,175,185,269,270,271,292,293};

new SPAWN_CIVIL_CARS[17];

new SPAWN_TAXI_CARS[12];

new SPAWN_LSPD_CARS[13];
new PARKING_GATE;
new PARKING_GATE_STATE = 0;

/*new SPAWN_GROOVE_SKINS[] = {105, 106, 107};
new Float:SPAWN_GROOVE[] = {1780.0005,-1882.2371,29.4763,9.1723,  0.0,0.0, 0.0,0.0, 0.0,0.0};*/

new SPAWN_PARAMEDICS_CARS[4];

new SPAWN_HITMAN_CARS[10];

new Float:BUYHOUSE_INTERIORS[][] = {
	{0.0,0.0,0.0,0.0, 0.0},
	{385.803986, 1471.769897, 1080.209961, 15.0, 55000.0},
	{225.756989, 1240.000000, 1082.149902, 2.0, 60000.0},
	{318.565, 1115.210, 1083.58, 5.0, 70000.0},
	{235.508994, 1189.169897, 1080.339966, 3.0, 200000.0},
	{2496.0293,-1692.6401,1014.7422, 3.0, 450000.0},
	{243.8726,304.9992,999.1484, 1.0, 35000.0},
	{266.6557,304.9685,999.1484, 2.0, 39000.0},
	{1261.2664,-785.4082,1091.9063, 5.0, 800000.0},
	{2807.6438,-1174.6353,1025.5703, 8.0, 85000.0},
	{2324.6458,-1149.1840,1050.7101, 12.0, 320000.0}
};

new HEAL_PICKUPS[500];

new BUYCAR_CARS[][] = {
	{510, 450},
	{481, 500},
	{462, 2700},
	{422, 6000},
	{457, 7000},
	{404, 8000},
	{424, 9000},
	{589, 12500},
	{466, 12500},
	{401, 13000},
	{400, 14000},
	{405, 14600},
	{439, 16000},
	{410, 16500},
	{436, 16500},
	{516, 17000},
	{517, 17500},
	{467, 20000},
	{496, 21000},
	{461, 22000},
	{426, 22000},
	{413, 22000},
	{440, 22000},
	{482, 22500},
	{442, 23000},
	{418, 23500},
	{412, 24000},
	{458, 24000},
	{500, 25000},
	{586, 26000},
	{468, 26000},
	{480, 26000},
	{507, 27000},
	{463, 28000},
	{459, 28000},
	{483, 29500},
	{518, 30000},
	{445, 31000},
	{474, 33000},
	{479, 35000},
	{533, 36000},
	{585, 37000},
	{475, 38000},
	{561, 40000},
	{421, 43000},
	{419, 43100},
	{489, 44000},
	{491, 46000},
	{536, 46250},
	{555, 48000},
	{566, 49000},
	{535, 52000},
	{559, 62000},
	{567, 64000},
	{565, 65000},
	{492, 77000},
	{521, 81000},
	{562, 85000},
	{581, 86000},
	{560, 95000},
	{576, 96000},
	{575, 97000},
	{580, 97000},
	{587, 120000},
	{602, 135000},
	{522, 140000},
	{579, 150000},
	{495, 155000},
	{409, 160000},
	{477, 475000},
	{444, 550000},
	{415, 670000},
	{402, 695000},
	{429, 711000},
	{451, 832000},
	{434, 850000},
	{541, 890000},
	{411, 975000},
	{494, 980000},
	{503, 980000}
};

new Float:BUYCAR_LOCATIONS[][] = {
	{-1992.4493,244.6575,34.9170,263.4149},
	{-1992.2484,249.4857,34.8990,261.6099},
	{-1991.5645,254.3693,34.8990,263.0765},
	{-1990.9840,259.4020,34.9064,266.9027},
	{-1990.2792,265.2187,34.9025,266.3352}
};


new FREECAR_PARK_IDX = 0;
new Float:FREECAR_PARK[][] = {
	{1560.3502,-2264.1785,13.3136,91.4463}, // park1
	{1560.1899,-2260.8455,13.3132,90.7046}, // park2
	{1560.1967,-2257.4304,13.3162,91.0132}, // park3
	{1560.4760,-2254.1677,13.3164,91.2391}, // park4
	{1560.2518,-2250.9087,13.3160,90.5245}, // park5
	{1560.3806,-2247.6013,13.3169,90.7653}, // park6
	{1560.4529,-2244.3843,13.3145,90.8483}, // park7
	{1560.3389,-2241.1821,13.3156,90.9164}, // park8
	{1560.4281,-2237.8223,13.3135,92.3286}, // park9
	{1560.1530,-2234.5786,13.3159,90.7779}, // park10
	{1556.1093,-2211.6514,13.3238,180.5528}, // park11
	{1552.7051,-2211.8274,13.3214,180.5748}, // park12
	{1549.4010,-2211.5989,13.3237,178.7121}, // park13
	{1546.2106,-2211.7363,13.3234,179.2895}, // park14
	{1542.8508,-2211.7180,13.3218,180.7363}, // park15
	{1539.5618,-2211.6814,13.3216,180.9946}, // park16
	{1536.3861,-2211.6492,13.3238,180.7113}, // park17
	{1533.0704,-2211.8311,13.3214,180.3780}, // park18
	{1529.7162,-2211.6282,13.3217,180.8610}, // park19
	{1526.5773,-2211.6807,13.3229,180.2854} // park20
};


new FARMER_CARS[4];
new Float:FARMER_POINTS[][] = {
	{-374.8852,-1366.6014,22.3698,351.8254},
	{-360.9429,-1307.5503,24.3806,345.1258},
	{-394.9406,-1276.7181,33.4276,98.2032},
	{-502.4010,-1290.2209,27.3381,91.6468},
	{-575.1254,-1294.0118,22.4917,94.9533},
	{-590.0324,-1382.3140,14.9361,179.8425},
	{-540.4219,-1423.9955,12.0026,239.4561},
	{-458.5714,-1404.2721,19.0148,274.5693},
	{-317.4555,-1317.3914,9.0073,301.7807},
	{-177.8021,-1313.5892,5.7730,272.6902},
	{-193.2562,-1397.5178,4.9386,171.0192},
	{-265.8285,-1420.7914,9.5274,93.6981},
	{-318.9093,-1423.9666,14.3816,93.4132},
	{-347.3196,-1482.6655,20.3185,180.4723},
	{-318.9327,-1556.0699,13.5279,280.6757},
	{-257.4327,-1554.3069,3.4504,270.4528},
	{-215.5530,-1481.6018,7.8314,7.5793},
	{-299.5405,-1476.5468,8.4702,91.2618},
	{-373.1226,-1571.9718,21.4200,104.6233},
	{-428.6546,-1578.8149,18.5825,96.0652},
	{-495.8534,-1584.2231,5.8746,93.0669},
	{-547.9702,-1586.6746,7.4688,92.1492},
	{-617.7452,-1569.6263,17.5012,78.0843},
	{-639.9830,-1498.7676,21.2756,3.4175},
	{-597.3154,-1434.0558,12.9177,282.4485}
};

new Text:PaintballTextdraw0;
new Text:PaintballTextdraw1;
new PaintballStartedOn;
new PAINTBALL_DURATION = 360;
new PAINTBALL_STATE = 0;
new PAINTBALL_CURRENT_SPAWN_POINT = 0;
new Float:PAINTBALL_SPAWNS[][] = {
	{1804.2804,3101.7068,116.1470,326.4544},
	{1812.1704,3160.3755,123.8252,174.7997},
	{1850.5143,3153.4116,116.1470,242.1670},
	{1898.6923,3111.3152,132.2251,18.1669},
	{1895.1511,3171.7854,116.1470,227.1234},
	{1841.7710,3187.6218,116.1470,227.5784},
	{1801.7267,3123.4028,116.1470,275.8071},
	{1836.0277,3121.0764,116.1470,164.2827},
	{1838.7616,3186.7354,116.2294,177.2603},
	{1897.9987,3125.8479,116.1542,6.4150},
	{1898.6920,3108.5835,116.1470,81.2790}
};
new PAINTBALL_CLASS_STRING[] = "Weapons\tMinimum Score\n\
				9mm, Shotgun\t0\n\
				Grenade, Desert Eagle, Combat Shotgun\t5\n\
				Uzi, AK47, Sniper\t15\n\
				Grenade, MP5, M4, Sniper\t30\n\
				Tec9, AK47, Rifle\t40\n\
				Grenade, M4, RPG\t80";


new Float:QUESTPOINTS[][] = {
	{1123.9305,-1200.0776,32.0280, 0.0},
	{1182.1733,-1298.0303,14.2150, 0.0},
	{1552.9904,-1683.6075,13.5496, 0.0},
	{1559.4032,-1661.3328,-13.5063, 0.0},
	{1111.2035,-1805.7091,16.5938, 0.0},
	{491.6211,-1733.3469,11.2804, 0.0},
	{715.4108,-1625.6509,2.4297, 0.0},
	{698.3229,-1363.7803,28.9787, 0.0},
	{1769.0375,-1907.9303,16.6065, 0.0},
	{1797.6497,-2642.4456,13.5469, 0.0},
	{1942.7865,-1014.5077,33.2254, 0.0},
	{1469.4705,-1061.8311,23.8281, 0.0}
};
new questData[MAX_PLAYERS][sizeof(QUESTPOINTS)];

new BUYGUNS[][] = {
	// weapon id	min score	ammo	price
	{1,			25,			1,			560},
	{8,			2,			1,			400},
	{9,			2,			1,			450},
	{22,		5,			150,		200},
	{17,		7,			1,			200},
	{25,		7,			100,		250},
	{24,		8,			150,		350},
	{46,		8,			1,			250},
	{29,		9,			100,		180},
	{27,		10,			50,			300},
	{26,		12,			40,			300},
	{31,		13,			150,		200},
	{30,		15,			150,		200},
	{34,		20,			80,			350},
	{18,		7,			1,			450},
	{16,		25,			1,			550},
	{35,		35,			2,			950}
}

new SAFE_GUNS[MAX_PLAYERS][13];

enum pEnum {
	ORM:ORM_ID,
	logged,
	logged_timeout,
	playerTick,									// AFK
	currentFaction,								// Class Selector
	currentFactionPredef,						// Class Selector
	lastSave,									// ServerInterval
	lastTaxiFare,								// Taxi Fare
	lastHealthDrop,								// Last Health Drop
	lastHealUp,									// Medics Heal Up
	pay_id,										// Pay
	pay_amount,									// Pay
	invite_id,									// Invite
	in_jail,									// In Jail from Spawn
	vehiclesSpawned,							// Avoid first Vehicle Lock Message
	buyhouse_interior,							// Buy new house
	buyhouse_price,								// Buy new house
	buyhouse_confirmed,							// Buy new house
	enteredHouse,								// Enter/Exit
	enteredBiz,									// Enter/Exit
	session_activeSeconds,						// Score
	session_lastReward,							// Score
	paintball_joined,							// Paintball
	paintball_class,							// Paintball
	paintball_kills,							// Paintball
	heal_ups,									// Heal Up
	tarifs,										// Taxi Tarif
	checkpoint,									// Have an active checkpoint
	Text3D:wanted_3D,							// Wanted 3D Text
	wanted_last_3D,								// Last 3D Text for Update
	wanted_seconds,								// Wanted Seconds Current Level
	wanted_last,								// Wanted Last Level
	special_interior,							// Interior IDs for enter/exit
	ip_address[16],								// IP Address,
	spec_player,								// Admin Spec
	spec_mode,									// Admin Spec, on/off
	afk_cooldown,								// SetNameAFK cooldown
	escape_state,								// 0 Nothing, 1 Digging, 2 Checkpoint
	escape_digging,								// Remaining Digging
	escape_dig_cooldown,						// Do not decsrease at each Fire Key
	weekly_seconds_temp,						// Weekly stats
	weekly_score_temp,							// Weekly stats
	PlayerText:td_title,						// TextDraw Legend
	PlayerText:td_version,						// TextDraw Legend
	PlayerText:td_user,							// TextDraw Legend
	td_set,										// TextDraw Legen is Set
	tracking_mode,								// Track player on/off
	tracking_player,							// Track player
	tracking_cooldown,							// Track player
	robbing_state,								// Rob Bank 0. nothing, 1. collecting, 2. driving
	robbing_money,								// Rob Bank, collected money
	robbing_msg_flag,							// Rob Bank, full money
	robbing_inbank,								// Rob Bank, bank from /rob
	robbing_max_money,							// Robb bank, max collected money
	am_stream_camera,							// Stream Camera Mode, 0. nothing, 1. logged, 2. spawned, 3. set up, 4. player, 5. server4
	dont_want_stream,							// Stream Camera, do not spec me
	heal_last_wanted,							// Cooldown for healing wanted players
	skinSelector,								// 0. no, 1. yes
	skinSelector_index,							// Current viewing skin
	PlayerText:skinSelector_civil,				// Skin selector button
	PlayerText:skinSelector_taxi,				// Skin selector button
	PlayerText:skinSelector_lspd,				// Skin selector button
	PlayerText:skinSelector_paramedics,			// Skin selector button
	PlayerText:skinSelector_hitman,				// Skin selector button
	PlayerText:skinSelector_save,				// Skin selector button
	PlayerText:skinSelector_next,				// Skin selector button
	PlayerText:skinSelector_prev,				// Skin selector button
	buycar_state,								// 0. nothing, 1.viewing, 2.testdrive
	buycar_index,								// Buy Car index of viewing car
	buycar_car,									// 0 not set
	buycar_tedtdrive,							// For the duration of testdrive
	PlayerText:buycar_model,					// Buy Car button/info
	PlayerText:buycar_price,					// Buy Car button/info
	PlayerText:buycar_textdrive,				// Buy Car button/info
	PlayerText:buycar_buycar,					// Buy Car button/info
	PlayerText:buycar_prev,						// Buy Car button/info
	PlayerText:buycar_next,						// Buy Car button/info
	enter_cooldown,								// Enter Exit with button
	Float:spec_goback_x,						// Specoff
	Float:spec_goback_y,						// Specoff
	Float:spec_goback_z,						// Specoff
	spec_goback_biz,							// Specoff
	spec_goback_house,							// Specoff
	spec_goback_int,							// Specoff
	spec_goback_flag,							// Specoff
	afk_lastCheck,								// AFK Kick
	afk_flag,									// AFK Kick
	Float:afk_x,								// AFK Kick
	Float:afk_y,								// AFK Kick
	Float:afk_z,								// AFK Kick
	shoot_cars_cooldown,						// Shooting LSPD Vehicles Cooldown
	dm_unwanted_flag,							// Killing unwanted players
	am_working,									// Working Flag
	farmer_index,								// Working Farmer Checkpoint
	sellcar_to,									// Sell car
	sellcar_price,								// Sell car
	sellcar_uid,								// Sell car
	sms_re_info,								// SMS Info for /re
	sms_re,										// SMS player id
	info_car_engine,							// How to start engine.
	buyphone_cooldown,							// Cooldown buyphone
	requested_event,							// /requestevent
	requested_event_prize,						// /requestevent
	requested_event_title[32],					// /requestevent
	withdrawprofit,								// /withdrawprofit
	withdrawprofit_id,							// /withdrawprofit
	current_radio[32],							// Radio
	mod_and_wanted,								// Wanted and in a mod shop
	last_cop_shot,								// Use in vehicle death
	park_cooldown,								// Park cooldown
	have_cigarettes,							// For /smoke
	reported_message[110],						// /report
	PlayerText:active_reportsTXD,				// for /reports
	drive_drunk_cooldown,						// Cooldown drunk and drive
	ip_banned,									// To skip account ban message
	am_in_taxi,									// Taxi Passenger Yes/No
	am_in_taxi_driverid,						// Taxi Passenger, who was the driver
	am_in_taxi_spent,							// Taxi Passenger, amount spent
	drop_house_id,								// /drophouse
	sellgun_weapon,								// /sellgun /acceptgun
	sellgun_price,								// /sellgun /acceptgun
	sellgun_account_id,							// /sellgun /acceptgun
	confiscate_by,								// confiscate dialog
	confiscate_to,								// confiscate for cop
	confiscate_cooldown,						// confiscate for cop
	Float:hp_entered_clothesShop,				// HP before entering clothse shop
	Float:armour_entered_clothesShop,			// HP before entering clothse shop
	shop_upgradeHouseID,						// shop and interior upgrade
	shop_clanSlots,								// shop buying new clan
	shop_clanPrice,								// shop buying new clan
	shop_clanName[64],							// shop buying new clan
	shop_clanTag[32],							// shop buying new clan
	shop_clanColor[32],							// shop buying new clan
	shop_clanSkin_L6,							// shop buying new clan
	shop_clanSkin_5,							// shop buying new clan
	shop_clanSkin_4,							// shop buying new clan
	shop_clanSkin_3,							// shop buying new clan
	shop_clanSkin_2,							// shop buying new clan
	shop_clanSkin_1,							// shop buying new clan
	am_clan_tag,								// 0/1 have clan tag on nickname
	am_spraying,								// /spray
	am_spraying_sprays,							// /spray
	am_spraying_cooldown,						// /spray
	clan_war_kills,								// How many kills during the war
	clan_war_sprays,							// How many completed sprays
	weaponHack_cooldown,						// Anti Weapon Hack
	weaponHack_crash_times,						// Anti Weapon Hack
	am_sleeping,								// /sleep
	commands_cooldown,							// General cmd anti spam
	PlayerText:carIntrumentSpeed,				// Car Instruments
	PlayerText:carIntrumentFuel,				// Car Instruments
	PlayerText:carIntrumentOdometer,			// Car Instruments
	PlayerText:loadScreen_txd,					// Loading Screen TXD
	PlayerText:infoMessage_txd,					// Info Message middle Screen





	account_id,
	account_name[MAX_PLAYER_NAME+1],
	account_password[256],
	account_email[256],
	account_registered,
	account_passwordLastChange,
	account_score,
	account_money,
	account_activeSeconds,
	account_online,
	account_skin,
	account_admin,
	account_faction,
	account_rank,
	account_lastLogin,
	account_jailed,
	account_kills,
	account_deaths,
	account_wanted,
	account_escaped,
	account_succ_escapes,
	account_weekly_score,
	account_weekly_seconds,
	account_quest,
	account_contracts,
	account_contracts_price,
	account_free_vehicle,
	account_spawnInHouse,
	account_robLS_cooldown,
	account_robSF_cooldown,
	account_inviteCooldown,
	account_phoneNumber,
	account_warns,
	account_lastPromotion,
	account_helper,
	account_ban,
	account_ban_by,
	account_ban_reason[64],
	account_ban_date,
	account_helperAnswers,
	account_adminReports,
	account_materials,
	account_skillMaterials,
	account_bank,
	account_clan,
	account_clanRank,
	account_mute
}
new playerData[MAX_PLAYERS + 1][pEnum];
playerData_init(playerid = -1){
	if(playerid == -1){
		new tmp[pEnum];
		playerData[MAX_PLAYERS] = tmp;
	}else{
		playerData[playerid] = playerData[MAX_PLAYERS];
	}
}

#define MAX_VEHICLES_PER_PLAYER 5
//new vehicleData[MAX_PLAYERS][MAX_VEHICLES_PER_PLAYER][2]; // 0: Vehicle ID in DB, 1:  Vehicle ID in GAME
new vehicleRadio[MAX_VEHICLES][32];

new VehicleNames[][] = { "Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus", "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection", "Hunter", "Premier",
"Enforcer", "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral", "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy",
"Solair", "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick",
"News Chopper", "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "Blista Compact", "Police Maverick", "Boxvillde", "Benson", "Mesa", "RC Goblin", "Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster",
"Stunt", "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune", "Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex", "Vincent", "Bullet", "Clover",
"Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite", "Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito", "Freight Flat", "Streak Carriage", "Kart", "Mower", "Dune",
"Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400", "News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club", "Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car", "Police Car", "Police Car", "Police Ranger", "Picador", "S.W.A.T", "Alpha", "Phoenix",
"Glendale", "Sadler", "Luggage", "Luggage", "Stairs", "Boxville", "Tiller", "Utility Trailer" };

new GunNames[][] = {"Fist", "Brass Knucles","Golf Club","Nightstick","Knife","Baseball Bat","Shovel","Pool Cue","Katana",
"Chainsaw","Purple Dildo","Dildo","Vibrator","Silver Vibrator","Flowers","Cane",
"Grenade","Tear Gas","Motolotv Cocktail","","","","9mm","Silenced 9mm","Desert Eagle",
"Shotgun","Sawnoff Shotgun","Combat Shotgun","Uzi","MP5","AK-47","M4","Tec-9","Country Rifle",
"Sniper Rifle","RPG","HS Rocket","Flamethrower","Minigun","Satchel Charge","Detonator",
"Spraycan","Fire Extinguisher","Camera","Night Vision Goggles","Thermal Googles","Parachute"};


enum carEnum {
	playerCar,

	vehicle_owner,
	vehicle_owner_ID, //playerid
	vehicle_id,
	vehicle_fuel,
	vehicle_odometer
}

new carData[MAX_VEHICLES][carEnum];

forward loadPlayerVehicles(playerid, step);
public loadPlayerVehicles(playerid, step)
{
	if (step == 0) {
		new temp[128];
		format(temp, sizeof(temp), "SELECT * FROM `vehicles` WHERE `vehicle_owner`='%d'", playerData[playerid][account_id]);
		mysql_tquery(Database, temp, "loadPlayerVehicles", "ii", playerid, 1);
	} else if (step == 1) {
		new temp_count = 0;
		new temp_uID;
		new temp_model;
		new Float:temp_x, Float:temp_y, Float:temp_z, Float:temp_a;
		new temp_c1, temp_c2;
		new temp_plate[32];
		new temp_fuel;
		new temp_odometer;

		for (new r, j = cache_num_rows(); r != j; r++){

			cache_get_value_name_int(r, "vehicle_id", temp_uID);
			cache_get_value_name_int(r, "vehicle_model", temp_model);
			cache_get_value_name_float(r, "vehicle_parkX", temp_x);
			cache_get_value_name_float(r, "vehicle_parkY", temp_y);
			cache_get_value_name_float(r, "vehicle_parkZ", temp_z);
			cache_get_value_name_float(r, "vehicle_parkA", temp_a);
			cache_get_value_name(r, "vehicle_plate", temp_plate);
			cache_get_value_name_int(r, "vehicle_color1", temp_c1);
			cache_get_value_name_int(r, "vehicle_color2", temp_c2);
			cache_get_value_name_int(r, "vehicle_fuel", temp_fuel);
			cache_get_value_name_int(r, "vehicle_odometer", temp_odometer);


			new temp_carID = CreateVehicle(temp_model, temp_x, temp_y, temp_z, temp_a, temp_c1, temp_c2, -1);

			carData[temp_carID][playerCar] = 1;
			carData[temp_carID][vehicle_owner] = playerData[playerid][account_id];
			carData[temp_carID][vehicle_owner_ID] = playerid;
			carData[temp_carID][vehicle_id] = temp_uID;
			carData[temp_carID][vehicle_fuel] = temp_fuel;
			carData[temp_carID][vehicle_odometer] = temp_odometer;

			SetVehicleNumberPlate(temp_carID, temp_plate);

			SetVehicleToRespawn(temp_carID);

			temp_count++;

		}

		if (temp_count == 0){
			// SendClientMessage(playerid, COLOR_SERVER, "VEHICLES: No personal vehicles were loaded.");
			printf("VEHICLES: Player %s did not load any vehicle.", playerData[playerid][account_name]);
		} else if (temp_count == 1) {
			// SendClientMessage(playerid, COLOR_SERVER, "VEHICLES: Your personal vehicle has been loaded.");
			printf("VEHICLES: Player %s loaded 1 vehicle.", playerData[playerid][account_name]);
		} else if (temp_count > 1) {
			// SendClientMessage(playerid, COLOR_SERVER, "VEHICLES: Your personal vehicles have been loaded.");
			printf("VEHICLES: Player %s loaded %d vehicles.", playerData[playerid][account_name], temp_count);
		}

		playerData[playerid][vehiclesSpawned] = 1;
	}
}

forward unloadPlayerVehicles(playerid);
public unloadPlayerVehicles(playerid)
{
	if (playerData[playerid][logged] == 1) {

		new temp_count = 0;
		for(new i = 1, d = GetVehiclePoolSize(); i <= d; i++) {
			if (carData[i][playerCar] && carData[i][vehicle_owner_ID] == playerid && carData[i][vehicle_owner] == playerData[playerid][account_id]) {
				for (new j = 0, k = GetPlayerPoolSize(); j <= k; j++) {
					if (GetPlayerVehicleID(j) == i) {
						SendClientMessage(j, COLOR_BADINFO, "The owner of this vehicle has unloaded this car.");
						new Float:temp_x, Float:temp_y, Float:temp_z;
						GetPlayerPos(j, temp_x, temp_y, temp_z);
						SetPlayerPos(j, temp_x, temp_y, temp_z+4);
					}
				}

				new temp[512];
				format(temp, sizeof(temp),"UPDATE `vehicles` SET `vehicle_fuel` = '%d', `vehicle_odometer` = '%d' WHERE `vehicle_id` = %d",  carData[i][vehicle_fuel], carData[i][vehicle_odometer], carData[i][vehicle_id]);
				mysql_query(Database, temp, false);

				carData[i][vehicle_owner] = 0;
				carData[i][vehicle_owner_ID] = -1;
				carData[i][playerCar] = false;

				DestroyVehicle(i);
				temp_count++;
			}
		}

		printf("VEHICLES: Player %s has unloaded %d vehicles.", playerData[playerid][account_name], temp_count);
	}
}

forward loadComponents(playerid, vehicleid);
public loadComponents(playerid, vehicleid)
{
	new temp_component, temp_component_slot, temp_count;
	for (new r, j = cache_num_rows(); r != j; r++){
		cache_get_value_name_int(r, "component_id", temp_component);
		cache_get_value_name_int(r, "component_slot", temp_component_slot);

		if (temp_component_slot == CARMODTYPE_PAINTJOB) {
			ChangeVehiclePaintjob(vehicleid, temp_component);
		} else {
			AddVehicleComponent(vehicleid, temp_component);
		}
		temp_count++;
	}
	printf("%d components were loaded to %s's car %d", temp_count, playerData[playerid][account_name], vehicleid);
}

forward loadCarcolor(playerid, vehicleid);
public loadCarcolor(playerid, vehicleid)
{
	new temp_c1, temp_c2;
	cache_get_value_name_int(0, "vehicle_color1", temp_c1);
	cache_get_value_name_int(0, "vehicle_color2", temp_c2);
	ChangeVehicleColor(vehicleid, temp_c1, temp_c2)
}

new Text3D:lockedVehicles3D[MAX_VEHICLES];
forward textLockVehicle(vehicleid);
public textLockVehicle(vehicleid) 
{
	if (!IsValidDynamic3DTextLabel(lockedVehicles3D[vehicleid])) {
		lockedVehicles3D[vehicleid] = CreateDynamic3DTextLabel("locked", 0xdb1a1a00, 0.0, 0.0, 1.0, 40.0, INVALID_PLAYER_ID, vehicleid, 0, 0);
	}
	new engine, lights, alarm, doors, bonnet, boot, objective;
	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
	if (doors == 1) {
		UpdateDynamic3DTextLabelText(lockedVehicles3D[vehicleid], 0xdb1a1aAA, "locked");
	} else {
		UpdateDynamic3DTextLabelText(lockedVehicles3D[vehicleid], 0xdb1a1a00, "unlocked");
	}
}

enum turfEnum {
	turf_id,
	Float:turf_minx,
	Float:turf_miny,
	Float:turf_maxx,
	Float:turf_maxy,
	turf_owner_clan,
	turf_owner_clanName[64],
	Float:turf_posX,
	Float:turf_posY,
	Float:turf_posZ,
	Float:turf_objectX,
	Float:turf_objectY,
	Float:turf_objectZ,
	Float:turf_objectRX,
	Float:turf_objectRY,
	Float:turf_objectRZ,
	turf_color[32],

	turf_object_id,
	turf_gangzone
}

#define MAX_TURFS 20
new turfData[MAX_TURFS][turfEnum];
forward loadTurfs(step);
public loadTurfs(step)
{
	if (step == 0) {
		new temp[128];
		format(temp, sizeof(temp), "SELECT * FROM `turfs` WHERE 1=1");
		mysql_tquery(Database, temp, "loadTurfs", "i", 1);
	} else if (step == 1) {
		new temp_count = 0; 

		for (new r, j = cache_num_rows(); r != j; r++) {

			new temp_turf_owner_clanName[64], temp_turf_color[32];
			cache_get_value_name_int(r, "turf_id", turfData[temp_count][turf_id]);
			cache_get_value_name_float(r, "turf_minx",  turfData[temp_count][turf_minx]);
			cache_get_value_name_float(r, "turf_miny",  turfData[temp_count][turf_miny]);
			cache_get_value_name_float(r, "turf_maxx",  turfData[temp_count][turf_maxx]);
			cache_get_value_name_float(r, "turf_maxy",  turfData[temp_count][turf_maxy]);
			cache_get_value_name_int(r, "turf_owner_clan", turfData[temp_count][turf_owner_clan]);
			cache_get_value_name(r, "turf_owner_clanName", temp_turf_owner_clanName);
			format(turfData[temp_count][turf_owner_clanName], 64, "%s", temp_turf_owner_clanName);
			cache_get_value_name_float(r, "turf_posX",  turfData[temp_count][turf_posX]);
			cache_get_value_name_float(r, "turf_posY",  turfData[temp_count][turf_posY]);
			cache_get_value_name_float(r, "turf_posZ",  turfData[temp_count][turf_posZ]);
			cache_get_value_name_float(r, "turf_objectX",  turfData[temp_count][turf_objectX]);
			cache_get_value_name_float(r, "turf_objectY",  turfData[temp_count][turf_objectY]);
			cache_get_value_name_float(r, "turf_objectZ",  turfData[temp_count][turf_objectZ]);
			cache_get_value_name_float(r, "turf_objectRX",  turfData[temp_count][turf_objectRX]);
			cache_get_value_name_float(r, "turf_objectRY",  turfData[temp_count][turf_objectRY]);
			cache_get_value_name_float(r, "turf_objectRZ",  turfData[temp_count][turf_objectRZ]);
			cache_get_value_name(r, "turf_color", temp_turf_color);
			format(turfData[temp_count][turf_color], 32, "%s", temp_turf_color);

			turfData[temp_count][turf_object_id] = CreateObject(19353, turfData[temp_count][turf_objectX], turfData[temp_count][turf_objectY], turfData[temp_count][turf_objectZ], turfData[temp_count][turf_objectRX], turfData[temp_count][turf_objectRY], turfData[temp_count][turf_objectRZ]);
			
			SetObjectMaterialText(turfData[temp_count][turf_object_id], turfData[temp_count][turf_owner_clanName], 0, OBJECT_MATERIAL_SIZE_512x512, "Arial", 35, 1, 0xFFDC143C, 0x00000000, 0);
			turfData[temp_count][turf_gangzone] = GangZoneCreate(turfData[temp_count][turf_minx], turfData[temp_count][turf_miny], turfData[temp_count][turf_maxx], turfData[temp_count][turf_maxy]);

			new temp[128];
			format(temp, sizeof(temp), "{adadad}Turf #%d\n{A6E9FF}/spray", turfData[temp_count][turf_id]);

			CreateDynamic3DTextLabel(temp, 0xA6E9FFFF, turfData[temp_count][turf_posX], turfData[temp_count][turf_posY], turfData[temp_count][turf_posZ], 5.0);
			CreateDynamicMapIcon(turfData[temp_count][turf_posX], turfData[temp_count][turf_posY], turfData[temp_count][turf_posZ], 19, 0, 0, 0);

			temp_count++;
		}
	}
}

enum clanEnum {
	clan_id,
	clan_name[64],
	clan_tag[32],
	clan_slots,
	clan_date,
	clan_until,
	clan_skinL6,
	clan_skin5,
	clan_skin4,
	clan_skin3,
	clan_skin2,
	clan_skin1,
	clan_color[32]
}

#define NO_CLAN -3
#define EXPIRED_CLAN -2
#define CLAN_NOT_FOUND -1

#define MAX_CLANS 30
new clanData[MAX_CLANS][clanEnum];
forward loadClans(step);
public loadClans(step)
{
	if (step == 0) {
		new temp[128];
		// format(temp, sizeof(temp), "SELECT * FROM `clans` WHERE clan_until > %d", gettime());
		format(temp, sizeof(temp), "SELECT * FROM `clans`");
		mysql_tquery(Database, temp, "loadClans", "i", 1);
	} else if (step == 1) {
		new temp_count = 1; // here it would matter if we start with 0, there is no door enter/exit restriction

		for (new r, j = cache_num_rows(); r != j; r++) {

			new temp_clanName[64];
			new temp_clanTag[32];
			new temp_clanColor[32];
			cache_get_value_name_int(r, "clan_id", clanData[temp_count][clan_id]);
			cache_get_value_name(r, "clan_name", temp_clanName);
			cache_get_value_name(r, "clan_tag", temp_clanTag);
			cache_get_value_name_int(r, "clan_slots", clanData[temp_count][clan_slots]);
			cache_get_value_name_int(r, "clan_date", clanData[temp_count][clan_date]);
			cache_get_value_name_int(r, "clan_until", clanData[temp_count][clan_until]);
			cache_get_value_name_int(r, "clan_skinL6", clanData[temp_count][clan_skinL6]);
			cache_get_value_name_int(r, "clan_skin5", clanData[temp_count][clan_skin5]);
			cache_get_value_name_int(r, "clan_skin4", clanData[temp_count][clan_skin4]);
			cache_get_value_name_int(r, "clan_skin3", clanData[temp_count][clan_skin3]);
			cache_get_value_name_int(r, "clan_skin2", clanData[temp_count][clan_skin2]);
			cache_get_value_name_int(r, "clan_skin1", clanData[temp_count][clan_skin1]);
			cache_get_value_name(r, "clan_color", temp_clanColor);

			format(clanData[temp_count][clan_name], 64, "%s", temp_clanName);
			format(clanData[temp_count][clan_tag], 32, "%s", temp_clanTag);
			format(clanData[temp_count][clan_color], 32, "%s", temp_clanColor);

			temp_count++;
		}

		printf("CLAN: Server loaded %d clans.", temp_count - 1);
	} else if (step == 2) {
		new temp_count;
		for(new i=0; i < MAX_CLANS; i++) {
			clanData[temp_count][clan_id] = 0;
		}
	}
}

#define BIZ_TYPE_GUNSHOP1 		1
#define BIZ_TYPE_FASTFOOD1 		2	// Burger shot
#define BIZ_TYPE_247_1	 		3
#define BIZ_TYPE_BANKLS			4
#define BIZ_TYPE_BANKSF			5
#define BIZ_TYPE_CLOTHES		6
#define BIZ_TYPE_PAINTBALL		7
#define BIZ_TYPE_CLUB			8
#define BIZ_TYPE_GASSTATION		9

enum biEnum {
	Float:bi_x,
	Float:bi_y,
	Float:bi_z,
	Float:bi_a,
	bi_interior,
	bi_name[32]
}
new Float:BIZ_INTERIORS[10][biEnum];


new UPDATE_BIZ_COOLDOWN;
new UPDATE_BIZ_STATE;		// 0, 1

#define MAX_BIZ 500
enum bEnum {
	Text3D:biz_3D,
	biz_map_icon,
	biz_id,
	biz_type,
	biz_price,
	biz_entrance,
	biz_owner,
	biz_owner_name[32],
	biz_profit,
	biz_sell,
	Float:biz_x,
	Float:biz_y,
	Float:biz_z,
}
new bizData[MAX_BIZ][bEnum];
forward loadBiz(step);
public loadBiz(step)
{
	if (step == 0) {
		new temp[128];
		format(temp, sizeof(temp), "SELECT * FROM `business` WHERE 1=1");
		mysql_tquery(Database, temp, "loadBiz", "i", 1);
	} else if (step == 1) {
		new temp_count = 1;

		for (new r, j = cache_num_rows(); r != j; r++) {

			new temp_owner_name[32];
			cache_get_value_name_int(r, "biz_id", bizData[temp_count][biz_id]);
			cache_get_value_name_int(r, "biz_type", bizData[temp_count][biz_type]);
			cache_get_value_name_int(r, "biz_price", bizData[temp_count][biz_price]);
			cache_get_value_name_int(r, "biz_entrance", bizData[temp_count][biz_entrance]);
			cache_get_value_name_int(r, "biz_owner", bizData[temp_count][biz_owner]);
			cache_get_value_name_int(r, "biz_profit", bizData[temp_count][biz_profit]);
			cache_get_value_name_int(r, "biz_sell", bizData[temp_count][biz_sell]);
			cache_get_value_name(r, "biz_owner_name", temp_owner_name);
			cache_get_value_name_float(r, "biz_x",  bizData[temp_count][biz_x]);
			cache_get_value_name_float(r, "biz_y",  bizData[temp_count][biz_y]);
			cache_get_value_name_float(r, "biz_z",  bizData[temp_count][biz_z]);

			format(bizData[temp_count][biz_owner_name], 32, "%s", temp_owner_name);

			new temp[256];
			format(temp, sizeof(temp), "{1d69db}%s\n{FFFFFF}Biz %d\nOwner: %s\nEntrance: $%s", BIZ_INTERIORS[bizData[temp_count][biz_type]][bi_name], bizData[temp_count][biz_id], bizData[temp_count][biz_owner_name], formatMoney(bizData[temp_count][biz_entrance]));

			if (bizData[temp_count][biz_sell] > 0) {
				format(temp, sizeof(temp), "%s\n{32a852}Biz Price: $%s (/buybiz)", temp, formatMoney(bizData[temp_count][biz_sell]));
			}

			if (bizData[temp_count][biz_type] == BIZ_TYPE_GUNSHOP1) {
				bizData[temp_count][biz_map_icon] = CreateDynamicMapIcon(bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 6, 0, 0, 0);
			}
			if (bizData[temp_count][biz_type] == BIZ_TYPE_FASTFOOD1) {
				bizData[temp_count][biz_map_icon] = CreateDynamicMapIcon(bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 10, 0, 0, 0);
			}
			if (bizData[temp_count][biz_type] == BIZ_TYPE_BANKLS || bizData[temp_count][biz_type] == BIZ_TYPE_BANKSF) {
				bizData[temp_count][biz_map_icon] = CreateDynamicMapIcon(bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 52, 0, 0, 0);
			}
			if (bizData[temp_count][biz_type] == BIZ_TYPE_247_1) {
				bizData[temp_count][biz_map_icon] = CreateDynamicMapIcon(bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 17, 0, 0, 0);
			}
			if (bizData[temp_count][biz_type] == BIZ_TYPE_CLOTHES) {
				bizData[temp_count][biz_map_icon] = CreateDynamicMapIcon(bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 45, 0, 0, 0);
			}
			if (bizData[temp_count][biz_type] == BIZ_TYPE_PAINTBALL) {
				bizData[temp_count][biz_map_icon] = CreateDynamicMapIcon(bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 18, 0, 0, 0);
			}
			if (bizData[temp_count][biz_type] == BIZ_TYPE_CLUB) {
				bizData[temp_count][biz_map_icon] = CreateDynamicMapIcon(bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 48, 0, 0, 0);
			}
			if (bizData[temp_count][biz_type] == BIZ_TYPE_GASSTATION) {
				bizData[temp_count][biz_map_icon] = CreateDynamicMapIcon(bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 27, 0, 0, 0);

				format(temp, sizeof(temp), "{1d69db}%s\n{FFFFFF}Biz %d\nOwner: %s\nPrice: $%s/1%", BIZ_INTERIORS[bizData[temp_count][biz_type]][bi_name], bizData[temp_count][biz_id], bizData[temp_count][biz_owner_name], formatMoney(bizData[temp_count][biz_entrance]));

				if (bizData[temp_count][biz_sell] > 0) {
					format(temp, sizeof(temp), "%s\n{32a852}Biz Price: $%s (/buybiz)", temp, formatMoney(bizData[temp_count][biz_sell]));
				}

				format(temp, sizeof(temp), "%s\n{bac70c}Use /fill", temp);
			}

			bizData[temp_count][biz_3D] = Create3DTextLabel(temp, 0xFFFFFFFF, bizData[temp_count][biz_x], bizData[temp_count][biz_y], bizData[temp_count][biz_z], 30.0, 0, 0);

			temp_count++;
		}

		printf("BIZ: Server loaded %d businesses.", temp_count - 1);
	} else if (step == 2) {
		new temp_count;
		for(new i=0; i < MAX_BIZ; i++){
			if (bizData[i][biz_id] == 0) {
				continue;
			}

			if (IsValidDynamicMapIcon(bizData[i][biz_map_icon])) {
				DestroyDynamicMapIcon(bizData[i][biz_map_icon]);
			}
			Delete3DTextLabel(bizData[i][biz_3D]);
			bizData[i][biz_id] = 0;
			temp_count++;
		}
		printf("BIZ: Server unloaded all %d businesses.", temp_count);
	}

	return 1;
}

#define MAX_HOUSES 500
enum hEnum {
	Text3D:house_3D,
	house_id,
	house_interior,
	house_owner_id,
	house_owner_name[32],
	Float:house_x,
	Float:house_y,
	Float:house_z,
	house_price,
	house_sell,
	house_locked,
	map_icon_id
}
new houseData[MAX_HOUSES][hEnum];
new houseTogUpdate = 1;

forward loadHouses(step);
public loadHouses(step)
{
	if (step == 0) {
		new temp[128];
		format(temp, sizeof(temp), "SELECT * FROM `houses` WHERE 1=1");
		mysql_tquery(Database, temp, "loadHouses", "i", 1);
	} else if (step == 1) {
		new temp_count = 1;

		for (new r, j = cache_num_rows(); r != j; r++) {

			new temp_owner_name[32];
			cache_get_value_name_int(r, "house_id", houseData[temp_count][house_id]);
			cache_get_value_name_int(r, "house_interior", houseData[temp_count][house_interior]);
			cache_get_value_name_int(r, "house_owner", houseData[temp_count][house_owner_id]);
			cache_get_value_name_int(r, "house_price", houseData[temp_count][house_price]);
			cache_get_value_name_int(r, "house_sell", houseData[temp_count][house_sell]);
			cache_get_value_name_int(r, "house_locked", houseData[temp_count][house_locked]);
			cache_get_value_name(r, "house_owner_name", temp_owner_name);
			cache_get_value_name_float(r, "house_exteriorX",  houseData[temp_count][house_x]);
			cache_get_value_name_float(r, "house_exteriorY",  houseData[temp_count][house_y]);
			cache_get_value_name_float(r, "house_exteriorZ",  houseData[temp_count][house_z]);

			format(houseData[temp_count][house_owner_name], 32, "%s", temp_owner_name);

			new temp[256];
			if (houseData[temp_count][house_sell] == 0) {
				format(temp, sizeof(temp), "{1DDB33}House %d\n{FFFFFF}Owner: %s\nInterior: %d", houseData[temp_count][house_id], houseData[temp_count][house_owner_name], houseData[temp_count][house_interior]);
			} else {
				format(temp, sizeof(temp), "{1DDB33}House %d\n{FFFFFF}Owner: %s\nInterior: %d\n{32a852}House Price: $%s (/buyhouse)", houseData[temp_count][house_id], houseData[temp_count][house_owner_name], houseData[temp_count][house_interior], formatMoney(houseData[temp_count][house_sell]));
			}
			houseData[temp_count][house_3D] = Create3DTextLabel(temp, 0xFFFFFFFF, houseData[temp_count][house_x], houseData[temp_count][house_y], houseData[temp_count][house_z], 30.0, 0, 0);
			houseData[temp_count][map_icon_id] = CreateDynamicMapIcon(houseData[temp_count][house_x], houseData[temp_count][house_y], houseData[temp_count][house_z], 31, 0, 0, 0);

			temp_count++;
		}

		houseTogUpdate = 0;

		printf("HOUSES: Server loaded %d houses.", temp_count);
	} else if (step == 2) {
		new temp_count;
		for(new i=0; i < MAX_HOUSES; i++){
			if (houseData[i][house_id] == 0) {
				continue;
			}

			if (IsValidDynamicMapIcon(houseData[i][map_icon_id])) {
				DestroyDynamicMapIcon(houseData[i][map_icon_id]);
			}
			Delete3DTextLabel(houseData[i][house_3D]);
			houseData[i][house_id] = 0;
			temp_count++;
		}
		printf("HOUSES: Server unloaded all %d houses.", temp_count - 1);
	}
}

forward DelayedKick(playerid);
public DelayedKick(playerid)
{
    Kick(playerid);
    return 1;
}


forward DelayedBan(playerid);
public DelayedBan(playerid)
{
    Ban(playerid);
    return 1;
}

forward setNameAFK(playerid, yesno);
public setNameAFK(playerid, yesno)
{
	new temp[32];
	if (yesno == 1) {
		format(temp, sizeof(temp), "AFK_%s", playerData[playerid][account_name]);
	} else {
		format(temp, sizeof(temp), "%s", playerData[playerid][account_name]);
	}
	SetPlayerName(playerid, temp);
}

forward assignORM(playerid);
public assignORM(playerid)
{
	new ORM:ormid = playerData[playerid][ORM_ID];

	orm_addvar_int(ormid, playerData[playerid][account_id], "account_id");
	orm_addvar_string(ormid, playerData[playerid][account_name], MAX_PLAYER_NAME+1, "account_name");
	orm_addvar_string(ormid, playerData[playerid][account_password], 256, "account_password");
	orm_addvar_string(ormid, playerData[playerid][account_email], 256, "account_email");
	orm_addvar_int(ormid, playerData[playerid][account_registered], "account_registered");
	orm_addvar_int(ormid, playerData[playerid][account_passwordLastChange], "account_passwordLastChange");
	orm_addvar_int(ormid, playerData[playerid][account_score], "account_score");
	orm_addvar_int(ormid, playerData[playerid][account_money], "account_money");
	orm_addvar_int(ormid, playerData[playerid][account_activeSeconds], "account_activeSeconds");
	orm_addvar_int(ormid, playerData[playerid][account_online], "account_online");
	orm_addvar_int(ormid, playerData[playerid][account_skin], "account_skin");
	orm_addvar_int(ormid, playerData[playerid][account_admin], "account_admin");
	orm_addvar_int(ormid, playerData[playerid][account_faction], "account_faction");
	orm_addvar_int(ormid, playerData[playerid][account_rank], "account_rank");
	orm_addvar_int(ormid, playerData[playerid][account_lastLogin], "account_lastLogin");
	orm_addvar_int(ormid, playerData[playerid][account_jailed], "account_jailed");
	orm_addvar_int(ormid, playerData[playerid][account_kills], "account_kills");
	orm_addvar_int(ormid, playerData[playerid][account_deaths], "account_deaths");
	orm_addvar_int(ormid, playerData[playerid][account_wanted], "account_wanted");
	orm_addvar_int(ormid, playerData[playerid][account_escaped], "account_escaped");
	orm_addvar_int(ormid, playerData[playerid][account_succ_escapes], "account_succ_escapes");
	orm_addvar_int(ormid, playerData[playerid][account_weekly_score], "account_weekly_score");
	orm_addvar_int(ormid, playerData[playerid][account_weekly_seconds], "account_weekly_seconds");
	orm_addvar_int(ormid, playerData[playerid][account_quest], "account_quest");
	orm_addvar_int(ormid, playerData[playerid][account_contracts], "account_contracts");
	orm_addvar_int(ormid, playerData[playerid][account_contracts_price], "account_contracts_price");
	orm_addvar_int(ormid, playerData[playerid][account_free_vehicle], "account_free_vehicle");
	orm_addvar_int(ormid, playerData[playerid][account_spawnInHouse], "account_spawnInHouse");
	orm_addvar_int(ormid, playerData[playerid][account_robSF_cooldown], "account_robSF_cooldown");
	orm_addvar_int(ormid, playerData[playerid][account_robLS_cooldown], "account_robLS_cooldown");
	orm_addvar_int(ormid, playerData[playerid][account_inviteCooldown], "account_inviteCooldown");
	orm_addvar_int(ormid, playerData[playerid][account_phoneNumber], "account_phoneNumber");
	orm_addvar_int(ormid, playerData[playerid][account_warns], "account_warns");
	orm_addvar_int(ormid, playerData[playerid][account_lastPromotion], "account_lastPromotion");
	orm_addvar_int(ormid, playerData[playerid][account_helper], "account_helper");
	orm_addvar_int(ormid, playerData[playerid][account_ban], "account_ban");
	orm_addvar_int(ormid, playerData[playerid][account_ban_by], "account_ban_by");
	orm_addvar_string(ormid, playerData[playerid][account_ban_reason], 256, "account_ban_reason");
	orm_addvar_int(ormid, playerData[playerid][account_ban_date], "account_ban_date");
	orm_addvar_int(ormid, playerData[playerid][account_helperAnswers], "account_helperAnswers");
	orm_addvar_int(ormid, playerData[playerid][account_adminReports], "account_adminReports");
	orm_addvar_int(ormid, playerData[playerid][account_materials], "account_materials");
	orm_addvar_int(ormid, playerData[playerid][account_skillMaterials], "account_skillMaterials");
	orm_addvar_int(ormid, playerData[playerid][account_bank], "account_bank");
	orm_addvar_int(ormid, playerData[playerid][account_clan], "account_clan");
	orm_addvar_int(ormid, playerData[playerid][account_clanRank], "account_clanRank");
	orm_addvar_int(ormid, playerData[playerid][account_mute], "account_mute");

}

forward savePlayerData(playerid);
public savePlayerData(playerid){
	if(playerData[playerid][logged] == 1) {
		orm_update(playerData[playerid][ORM_ID]);
	}
}

forward checkIPBan(playerid);
public checkIPBan(playerid)
{
	if (cache_num_rows() >= 1) {
		playerData[playerid][ip_banned] = 1;
		new temp[256];
		new temp_name[64];
		new temp_reason[64];
		new temp_variable;
		new temp_date;
		cache_get_value_name(0, "account_name", temp_name);
		cache_get_value_name(0, "b_reason", temp_reason);
		cache_get_value_int(0, "b_variable", temp_variable);
		cache_get_value_int(0, "b_date", temp_date);



		if (temp_variable == 99) {
			format(temp, sizeof(temp), "This IP has been permanently banned with an account by %s. Reason: %s", temp_name, temp_reason);
		} else {
			new tempY, tempM, tempD, tempH, tempI, tempS;
			TimestampToDate(temp_date + (temp_variable  * 86400), tempY, tempM, tempD, tempH, tempI, tempS, serverTimeZone);
			format(temp, sizeof(temp), "This IP has been temporarly banned until %02d/%02d/%02d %02d:%02d:%02d with an account by %s. Reason: %s",  tempD, tempM, tempY, tempH, tempI, tempS, temp_name, temp_reason);
		}

		SendClientMessage(playerid, COLOR_BADINFO, temp);
		printf("%s: %s", playerData[playerid][account_name], temp);
		
		SendClientMessage(playerid, COLOR_INFO, "If you think that this is a mistake, make an unban request on our discord server.");

		SetTimerEx("DelayedKick", 300, 0, "i", playerid);
	} else {
		printf("No IP ban on %s", playerData[playerid][account_name]);
	}
	return 1;
}

forward printBanInfo(playerid);
public printBanInfo(playerid)
{
	if (playerData[playerid][ip_banned] == 0) {
		new temp[128];
		new temp_name[64];
		cache_get_value_name(0, "account_name", temp_name);
		if (playerData[playerid][account_ban] == 99) {
			format(temp, sizeof(temp), "Your account has been permanently banned by admin %s. Reason: %s", temp_name, playerData[playerid][account_ban_reason]);
			SendClientMessage(playerid, COLOR_BADINFO, temp);
			printf("%s: %s", playerData[playerid][account_name], temp);
		} else {
			new temp_ban_expires = playerData[playerid][account_ban_date] + playerData[playerid][account_ban] * 86400;
			new tempY, tempM, tempD, tempH, tempI, tempS;
			TimestampToDate(temp_ban_expires, tempY, tempM, tempD, tempH, tempI, tempS, serverTimeZone);
			format(temp, sizeof(temp), "Your account has been banned until %02d/%02d/%02d %02d:%02d:%02d by admin %s. Reason: %s", tempD, tempM, tempY, tempH, tempI, tempS, temp_name, playerData[playerid][account_ban_reason]);
			SendClientMessage(playerid, COLOR_BADINFO, temp);
			printf("%s: %s", playerData[playerid][account_name], temp);
		}

		SendClientMessage(playerid, COLOR_INFO, "If you think that this is a mistake, make an unban request on our discord server.");

		SetTimerEx("DelayedKick", 1000, 0, "i", playerid);
	}
	return 1;	
}

forward connectPlayer(playerid);
public connectPlayer(playerid)
{
	switch(orm_errno(playerData[playerid][ORM_ID]))
	{
		case ERROR_OK: {
			printf("Login: Player %s is registered.", playerData[playerid][account_name]);
			if (playerData[playerid][account_ban] == 99 || gettime() < playerData[playerid][account_ban_date] + playerData[playerid][account_ban] * 86400) {
				new temp[128];
				format(temp, sizeof(temp), "SELECT account_name FROM `accounts` WHERE account_id='%d'", playerData[playerid][account_ban_by]);
				mysql_tquery(Database, temp, "printBanInfo", "i", playerid);
			} else {
				new temp[256];
				if (playerData[playerid][account_lastLogin] != 0) {
					new tempY, tempM, tempD, tempH, tempI, tempS;
					TimestampToDate(playerData[playerid][account_lastLogin], tempY, tempM, tempD, tempH, tempI, tempS, serverTimeZone);
					format(temp, sizeof(temp), "\n{9dbfbe}Welcome back {5eaba9}%s{9dbfbe}!\nLast Login: {5eaba9}%02d/%02d/%02d %02d:%02d:%02d\n\n{9dbfbe}Log in with your password.\n\n", playerData[playerid][account_name], tempD, tempM, tempY, tempH, tempI, tempS);
				} else {
					format(temp, sizeof(temp), "\n{9dbfbe}Welcome back {5eaba9}%s{9dbfbe}!\n\n{9dbfbe}Log in with your password.\n\n", playerData[playerid][account_name]);
				}
				Dialog_Show(playerid, DLG_LOGIN_PASSWORD, DIALOG_STYLE_PASSWORD, "Login", temp, "Play", "Quit");
			}
		}
		case ERROR_NO_DATA: {
			printf("Register: Player %s is new.", playerData[playerid][account_name]);
			new temp[256];
			format(temp, sizeof(temp), "\nWelcome %s.\n\nRegister your name with us. Set a strong password to protect your new account.\n", playerData[playerid][account_name]);
			Dialog_Show(playerid, DLG_REGISTER_PASSWORD, DIALOG_STYLE_PASSWORD, "Register: New password", temp, "Next", "Quit");
		}
	}
	return 1;
}

Dialog:DLG_LOGIN_PASSWORD(playerid, response, listitem, inputtext[])
{
    if (response) {

		new temp[364];
		SHA256_PassHash(inputtext, passHashSalt, temp, sizeof(temp));
		if((!isnull(inputtext) && strcmp(playerData[playerid][account_password], temp, true) == 0) || !ServerInProduction) {
			playerData[playerid][logged] = 1;
			playerData[playerid][account_online] = 1;
			playerData[playerid][account_lastLogin] = gettime();
			PlayerPlaySound(playerid, 0, 0.0,0.0,0.0);
			orm_update(playerData[playerid][ORM_ID]);
			format(temp, sizeof(temp),"INSERT INTO `logs` (`log_player`, `log_type`, `log_info`) VALUES ('%d', 'login', '{\"login\":%d, \"ip\":\"%s\"}')", playerData[playerid][account_id], gettime(), playerData[playerid][ip_address]);
			mysql_query(Database, temp, false);
			printf("Login: Player %s (%s) got logged in.\n", playerData[playerid][account_name], playerData[playerid][account_email]);


			SetTimerEx("setNameAFK", 200, 0, "ii", playerid, 0);

			format(temp, sizeof(temp), "%s (%d) is now online.", playerData[playerid][account_name], playerid);
			SendClientMessageToAll(COLOR_PUBLIC, temp);

			format(temp, sizeof(temp), "STATS: Hours: [%d], Money: [$%s], Bank: [$%s], Faction: [%s]", floatround(playerData[playerid][account_activeSeconds]/3600.0, floatround_floor), formatMoney(playerData[playerid][account_money]), formatMoney(playerData[playerid][account_bank]), getFactionNameWithColor(playerData[playerid][account_faction], COLOR_SERVER));
			if (playerData[playerid][account_rank] == 7) {
				format(temp, sizeof(temp), "%s, Leader: [Yes]", temp);
			}
			if (playerData[playerid][account_admin] > 0) {
				format(temp, sizeof(temp), "%s, Admin: [%d]", temp, playerData[playerid][account_admin]);
			}
			if (playerData[playerid][account_helper] > 0) {
				format(temp, sizeof(temp), "%s, Helper: [%d]", temp, playerData[playerid][account_helper]);
			}
			SendClientMessage(playerid, COLOR_SERVER, temp);

			if (playerData[playerid][account_free_vehicle] <= 0) {
				FREECAR_PARK_IDX ++;
				if (FREECAR_PARK_IDX >= sizeof(FREECAR_PARK)) {
					FREECAR_PARK_IDX = 0;
				}
				new temp_veh[1024];

				new temp_model;

				if (playerData[playerid][account_free_vehicle] == 0) {
					temp_model = 436; // previon
				} else if (playerData[playerid][account_free_vehicle] == -1) {
					temp_model = 439; // stallion
				}

				format(temp_veh, sizeof(temp_veh),"INSERT INTO `vehicles` (`vehicle_owner`, `vehicle_model`, `vehicle_parkX`, `vehicle_parkY`, `vehicle_parkZ`, `vehicle_parkA`, `vehicle_plate`, `vehicle_date`, `vehicle_color1`, `vehicle_color2`, `vehicle_fuel`, `vehicle_odometer`) VALUES ('%d', '%d', '%f', '%f', '%f', '%f', '%s', '%d', '1', '1', '100', '0')",
				playerData[playerid][account_id], temp_model, FREECAR_PARK[FREECAR_PARK_IDX][0], FREECAR_PARK[FREECAR_PARK_IDX][1], FREECAR_PARK[FREECAR_PARK_IDX][2], FREECAR_PARK[FREECAR_PARK_IDX][3], playerData[playerid][account_name], gettime());
				mysql_query(Database, temp_veh, false);
				SendClientMessage(playerid, COLOR_INFO, "Server has given to you a free car. Locate it with /locations and lock it /lock.");
				playerData[playerid][account_free_vehicle] = 1;
				printf("%s received the free car.", playerData[playerid][account_name]);
			}

			loadPlayerVehicles(playerid, 0);

			if (playerData[playerid][account_wanted] > 0) {
				format(temp, sizeof(temp), "The wanted player %s (%d) is now back to the server. Current Wanted Level: %d", playerData[playerid][account_name], playerid, playerData[playerid][account_wanted]);
			}

			SetTimerEx("DelayedSpawn", 500, false, "i", playerid);

			playerData[playerid][weekly_seconds_temp] = playerData[playerid][account_activeSeconds];
			playerData[playerid][weekly_score_temp] = playerData[playerid][account_score];


			printFactionMOTD(playerid, 0);
			printClanMOTD(playerid, 0);


			if (isWarTime()) {
				SendClientMessage(playerid, 0x00C3FFFF, "Spraying Time for clans has begun!");
			}

			
		} else {
			format(temp, sizeof(temp), "{ab5e5e}\nWe are sorry %s, but this is the wrong password.\n\nLogin with your password:\n", playerData[playerid][account_name]);
			Dialog_Show(playerid, DLG_LOGIN_PASSWORD, DIALOG_STYLE_PASSWORD, "Login", temp, "Play", "Quit");
		}

    } else {
		SendClientMessage(playerid, COLOR_SERVER, "Ok, bye!");
		SetTimerEx("DelayedKick", 1000, 0, "i", playerid);
		printf("Kick: Player %d closed the login dialog.", playerid);
	}
    return 1;
}

Dialog:DLG_REGISTER_PASSWORD(playerid, response, listitem, inputtext[])
{
    if (response) {
		if (!isnull(inputtext)) {
			new temp[256];
			SHA256_PassHash(inputtext, passHashSalt, temp, sizeof(temp));
			format(playerData[playerid][account_password], 256, "%s", temp);

			format(temp, sizeof(temp), "\nPlease provide us an email address that you have access to, in case your account gets locked or banned.\n");
			Dialog_Show(playerid, DLG_REGISTER_EMAIL, DIALOG_STYLE_INPUT, "Register: New email", temp, "Save", "Quit");
		} else {
			new temp[256];
			format(temp, sizeof(temp), "\nWelcome %s.\n\nRegister your name with us. Set a strong password to protect your new account.\n", playerData[playerid][account_name]);
			Dialog_Show(playerid, DLG_REGISTER_PASSWORD, DIALOG_STYLE_PASSWORD, "Register: New password", temp, "Next", "Quit");
		}
    } else {
		SendClientMessage(playerid, COLOR_SERVER, "Ok, bye!");
		SetTimerEx("DelayedKick", 1000, 0, "i", playerid);
		printf("Kick: Player %d closed the registration dialog (new password).", playerid);
	}
    return 1;
}

Dialog:DLG_REGISTER_EMAIL(playerid, response, listitem, inputtext[])
{
    if (response) {
		if (!isValidEmail(inputtext)) {
			new temp[256];
			format(temp, sizeof(temp), "\nIt is really important that you save a valid email address for your account.\n");
			Dialog_Show(playerid, DLG_REGISTER_EMAIL, DIALOG_STYLE_INPUT, "Register: New email", temp, "Save", "Quit");
		} else {
			format(playerData[playerid][account_email], 256, "%s", inputtext);
			Dialog_Show(playerid, DLG_REGISTER_COMPLETE, DIALOG_STYLE_MSGBOX, "Register: Completed", "\nWelcome officially to our Greek Server!\n\nPlease visit our website if you need any help: www.greeksamp.info\n\nSelect skin and good luck!\n", "Thanks!","");

			orm_destroy(playerData[playerid][ORM_ID]);
			playerData[playerid][ORM_ID] = orm_create("accounts");
			
			playerData[playerid][logged] = 1;

			playerData[playerid][account_money] = 350;
			playerData[playerid][account_skin] = -1;
			playerData[playerid][account_registered] = gettime();
			playerData[playerid][account_passwordLastChange] = gettime();
			playerData[playerid][account_lastLogin] = gettime();

			playerData[playerid][account_online] = 1;
			
			assignORM(playerid);
			
			orm_setkey(playerData[playerid][ORM_ID], "account_id");
			orm_insert(playerData[playerid][ORM_ID], "registerComplete", "d", playerid);

			PlayerPlaySound(playerid, 0, 0.0,0.0,0.0);
		}
    } else {
		SendClientMessage(playerid, COLOR_SERVER, "Ok, bye!");
		SetTimerEx("DelayedKick", 1000, 0, "i", playerid);
		printf("Kick: Player %d closed the registration dialog (new email).", playerid);

		
	}
    return 1;
}

forward registerComplete(playerid);
public registerComplete(playerid)
{
	new temp[364];
	format(temp, sizeof(temp),"INSERT INTO `logs` (`log_player`, `log_type`, `log_info`) VALUES ('%d', 'register', '{\"register\":%d,\"ip\":\"%s\"}')", playerData[playerid][account_id], gettime(), playerData[playerid][ip_address]);
	mysql_query(Database, temp, false);
	printf("Register: Player %s (%s) got registered and saved in logs.\n", playerData[playerid][account_name], playerData[playerid][account_email]);

	SetTimerEx("setNameAFK", 200, 0, "ii", playerid, 0);

	format(temp, sizeof(temp), "%s (%d) is now online.", playerData[playerid][account_name], playerid);
	SendClientMessageToAll(COLOR_PUBLIC, temp);

	format(temp, sizeof(temp), "STATS: Score: [%d], Money: [$%s], Faction: [%s]", playerData[playerid][account_score], formatMoney(playerData[playerid][account_money]), getFactionNameWithColor(playerData[playerid][account_faction], COLOR_SERVER));
	SendClientMessage(playerid, COLOR_SERVER, temp);

	FREECAR_PARK_IDX ++;
	if (FREECAR_PARK_IDX >= sizeof(FREECAR_PARK)) {
		FREECAR_PARK_IDX = 0;
	}
	new temp_veh[512];
	format(temp_veh, sizeof(temp_veh),"INSERT INTO `vehicles` (`vehicle_owner`, `vehicle_model`, `vehicle_parkX`, `vehicle_parkY`, `vehicle_parkZ`, `vehicle_parkA`, `vehicle_plate`, `vehicle_date`, `vehicle_color1`, `vehicle_color2`) VALUES ('%d', '%d', '%f', '%f', '%f', '%f', '%s', '%d', '1', '1')", playerData[playerid][account_id], 436,
	FREECAR_PARK[FREECAR_PARK_IDX][0], FREECAR_PARK[FREECAR_PARK_IDX][1], FREECAR_PARK[FREECAR_PARK_IDX][2], FREECAR_PARK[FREECAR_PARK_IDX][3], playerData[playerid][account_name], gettime());
	mysql_query(Database, temp_veh, false);
	SendClientMessage(playerid, COLOR_INFO, "Server has given to you a free car. Locate it with /locations and lock it /lock.");
	playerData[playerid][account_free_vehicle] = 1;
	printf("%s received the free car.", playerData[playerid][account_name]);

	loadPlayerVehicles(playerid, 0);

	SetTimerEx("DelayedSpawn", 500, false, "i", playerid);
}

forward giveMoney(playerid, amount);
public giveMoney(playerid, amount)
{
	if(playerData[playerid][account_money] + amount < 0){
		return false;
	}

	new text[32];

	if(amount == 0) return true;

	if(amount > 0) format(text, sizeof(text), "~g~+%s$", formatMoney(amount));
	else format(text, sizeof(text), "~r~-%s$", formatMoney(floatround(floatabs(amount * 1.0))));

	GameTextForPlayer(playerid, text, 2000, 3);

	playerData[playerid][account_money] += amount;

	
	if (amount >= 0) {
		printf("Money: Player %s amount +$%s: %s$", playerData[playerid][account_name], formatMoney(amount), formatMoney(playerData[playerid][account_money]));
	} else {
		printf("Money: Player %s amount -$%s: %s$", playerData[playerid][account_name], formatMoney(-amount), formatMoney(playerData[playerid][account_money]));
	}

	return true;
}

forward stopPlayerSound(playerid);
public stopPlayerSound(playerid)
{
	PlayerPlaySound(playerid, 0, 0.0,0.0,0.0);
}

forward initRac();
public initRac()
{
	for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
		if (GetVehicleDriverID(i) == -1) {
			SetVehicleToRespawn(i);
		}
	}

	print("Init RAC. Fuel for Server cars has been filled.");
}


forward serverInterval();
public serverInterval()
{
	new timestamp = gettime();

	if (timestamp-serverIntervalTimestamp < 1) {
		return 1;
	}

	serverIntervalTimestamp = timestamp;

	serverTime(2);

	new H,m,s;
	new PAYDAY = false;
	gettime(H, m, s);

	if ((m == 00 && serverLastPayday != H) || FORCE_PAYDAY) {
		serverLastPayday = H;

		SetWorldTime(H);

		new temp_p[256];
		format(temp_p, sizeof(temp_p),"The time is now %s.", getTimeString(2));
		SendClientMessageToAll(-1, temp_p);

		PAYDAY = true;
		FORCE_PAYDAY = false;
	}

	if (timestamp - UPDATE_BIZ_COOLDOWN > 4 && UPDATE_BIZ_STATE == 1 || timestamp - UPDATE_BIZ_COOLDOWN > 60 * 30) {
		UPDATE_BIZ_STATE = 0;
		UPDATE_BIZ_COOLDOWN = timestamp;

		loadBiz(2);
		SetTimerEx("loadBiz", 600, 0, "i", 0);
	}

	if (timestamp - INFOMESSAGES_TIMESTAMP > 60 * 5) {
		INFOMESSAGES_TIMESTAMP = timestamp;

		if (INFOMESSAGES_INDEX >= sizeof(INFOMESSAGES)) {
			INFOMESSAGES_INDEX = 0;
		}

		SendClientMessageToAll(-1, INFOMESSAGES[INFOMESSAGES_INDEX]);

		INFOMESSAGES_INDEX++;
	}

	new temp_maxKills, temp_maxKills_player;

	new temp_active_reports;

	new pd_near_gate;

	////////////////
	// MAIN INTERVAL
	////////////////

	for(new playerid = 0, j = GetPlayerPoolSize(); playerid <= j; playerid++) {

		if (strlen(playerData[playerid][reported_message]) > 0) {
			temp_active_reports++;
		}

		if (playerData[playerid][logged] && playerData[playerid][paintball_kills] > temp_maxKills) {
			temp_maxKills = playerData[playerid][paintball_kills];
			temp_maxKills_player = playerid;
		}

		if (playerData[playerid][buycar_state] == 2) {
			if (timestamp - playerData[playerid][buycar_tedtdrive] > 60) {
				playerData[playerid][buycar_state] = 1;
				buyCar_show(playerid);
			}
		}

		if (playerData[playerid][am_stream_camera] > 0) {
			if (playerData[playerid][am_stream_camera] == 2) {
				playerData[playerid][am_stream_camera] = 3;
				SetPlayerPos(playerid, 9999,9999,0);
				TogglePlayerSpectating(playerid, 1);
			} else if (playerData[playerid][am_stream_camera] == 3) {
				if (timestamp - STRM_CAMERA_LAST > 10) {

					STRM_CAMERA_LAST = timestamp;

					GameTextForPlayer(playerid, " ", 2000, 3);

					new temp_count;
					for(new x = 0, f = GetPlayerPoolSize(); x <= f; x++) {
						if (playerData[x][logged] == 1 && playerData[x][dont_want_stream] == 0 && !IsPlayerAfk(x)) {
							temp_count++;
						}
					}

					if (temp_count > 0) {
						new temp_random_player = 1 + random(temp_count);
						temp_count = 0;

						for(new x = 0, f = GetPlayerPoolSize(); x <= f; x++) {
							if (playerData[x][logged] == 1 && playerData[x][dont_want_stream] == 0 && !IsPlayerAfk(x)) {
								temp_count++;
								if (temp_count == temp_random_player) {
									
									SetPlayerInterior(playerid, GetPlayerInterior(x));
									SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(x));

									if (GetPlayerVehicleID(x) != 0) {
										TogglePlayerSpectating(playerid, 1);
										PlayerSpectateVehicle(playerid, GetPlayerVehicleID(x));
									} else {
										TogglePlayerSpectating(playerid, 1);
										PlayerSpectatePlayer(playerid, x);
									}
									break;
								}
							}
						}


					} else {

						SetPlayerInterior(playerid, 0);
						SetPlayerVirtualWorld(playerid, 0);

						new temp_rnd_index = random(sizeof(STRM_CAMERA_LOCATIONS));

						SetPlayerCameraPos(playerid, STRM_CAMERA_LOCATIONS[temp_rnd_index][0], STRM_CAMERA_LOCATIONS[temp_rnd_index][1], STRM_CAMERA_LOCATIONS[temp_rnd_index][2]);
						SetPlayerCameraLookAt(playerid, STRM_CAMERA_LOCATIONS[temp_rnd_index][3], STRM_CAMERA_LOCATIONS[temp_rnd_index][4], STRM_CAMERA_LOCATIONS[temp_rnd_index][5]);

					}
				}

				new temp[128];
				format(temp, sizeof(temp), "~n~~n~~n~~g~Next camera in %d...",(STRM_CAMERA_LAST+10)-timestamp);
				GameTextForPlayer(playerid, temp, 2000, 3);
			}
		}

		if (playerData[playerid][logged] == 1) {

			if (PAYDAY) {
				if (playerData[playerid][session_activeSeconds] <  60 * 20) {
					SendClientMessage(playerid, -1, "You have not played 20 minutes. You can not get a paycheck.");
				} else {
					SendClientMessage(playerid, -1, "|________________ PAYDAY ________________|");
					new temp[128];
					new s_reward = playerData[playerid][session_activeSeconds] * 20 / 100;
					format(temp, sizeof(temp), "Server: +$%s", formatMoney(s_reward));
					SendClientMessage(playerid, 0xb5b5b5FF, temp);
					giveMoney(playerid, s_reward);
					new b_reward = playerData[playerid][account_bank] * 2 / 100;
					format(temp, sizeof(temp), "Bank Interest: +$%s", formatMoney(b_reward));
					SendClientMessage(playerid, 0xb5b5b5FF, temp);
					playerData[playerid][account_bank] += b_reward;
					SendClientMessage(playerid, 0xb5b5b5FF, "");
					format(temp, sizeof(temp), "New Balance: $%s", formatMoney(playerData[playerid][account_bank]));
					SendClientMessage(playerid, 0xb5b5b5FF, temp);

					playerData[playerid][account_score] += 1;
					SendClientMessage(playerid, 0x00C3FFFF, "You have received 1 Score Point.");

					GameTextForPlayer(playerid, "~y~Payday~n~~w~Time to get Paid", 3000, 1);
				}
			}


			if (!IsPlayerAfk(playerid)) {

				if (playerData[playerid][am_sleeping] == 0) {
					playerData[playerid][account_activeSeconds] += 1; // overall

					playerData[playerid][session_activeSeconds] += 1; // session
				}

				/*if (playerData[playerid][session_activeSeconds] >= 3600 && playerData[playerid][session_lastReward] < 3600) {
					playerData[playerid][session_lastReward] = 3600;
					playerData[playerid][account_score] += 1;
					SendClientMessage(playerid, COLOR_INFO, "You received 1 Score point for playing 1 hour.");
					printf("SCORE: Player %s received 1 Score point for playing 1 hour.", playerData[playerid][account_name]);
				}

				if (playerData[playerid][session_activeSeconds] >= 7200 && playerData[playerid][session_lastReward] < 7200) {
					playerData[playerid][session_lastReward] = 7200;
					playerData[playerid][account_score] += 2;
					SendClientMessage(playerid, COLOR_INFO, "You received 2 Score points for playing 2 Hours.");
					printf("SCORE: Player %s received 2 Score points for playing 2 hours.", playerData[playerid][account_name]);
				}

				if (playerData[playerid][session_activeSeconds] >= 10800 && playerData[playerid][session_lastReward] < 10800) {
					playerData[playerid][session_lastReward] = 10800;
					playerData[playerid][account_score] += 5;
					SendClientMessage(playerid, COLOR_INFO, "You received 5 Score points for playing 3 Hours.");
					printf("SCORE: Player %s received 5 Score points for playing 3 hours.", playerData[playerid][account_name]);
				}

				if (playerData[playerid][session_activeSeconds] >= 18000 && playerData[playerid][session_lastReward] < 18000) {
					playerData[playerid][session_lastReward] = 18000;
					playerData[playerid][account_score] += 10;
					SendClientMessage(playerid, COLOR_INFO, "You received 10 Score points for playing 5 Hours.");
					printf("SCORE: Player %s received 10 Score points for playing 5 hours.", playerData[playerid][account_name]);
				}

				if (playerData[playerid][session_activeSeconds] >= 36000 && playerData[playerid][session_lastReward] < 36000) {
					playerData[playerid][session_lastReward] = 36000;
					playerData[playerid][account_score] += 60;
					SendClientMessage(playerid, COLOR_INFO, "You received 60 Score points for playing 10 Hours.");
					printf("SCORE: Player %s received 60 Score points for playing 10 hours.", playerData[playerid][account_name]);
				}*/


				if(playerData[playerid][account_money] != GetPlayerMoney(playerid)) {
					ResetPlayerMoney(playerid);
					GivePlayerMoney(playerid, playerData[playerid][account_money]);
				}
				SetPlayerScore(playerid, playerData[playerid][account_score]);

				new temp_clanIndex = getClanIndex(playerid);
				if (playerData[playerid][am_clan_tag] == 0) {
					if (temp_clanIndex != NO_CLAN && temp_clanIndex != CLAN_NOT_FOUND) {
						new temp_tag[32];
						format(temp_tag, sizeof(temp_tag), "[%s]%s", clanData[temp_clanIndex][clan_tag], playerData[playerid][account_name]);
						SetPlayerName(playerid, temp_tag);
						playerData[playerid][am_clan_tag] = 1;
					}
				} else {
					if (temp_clanIndex == NO_CLAN && temp_clanIndex != CLAN_NOT_FOUND) {
						new temp_tag[32];
						format(temp_tag, sizeof(temp_tag), "%s", playerData[playerid][account_name]);
						SetPlayerName(playerid, temp_tag);
						playerData[playerid][am_clan_tag] = 0;
					}
				}

				if (playerData[playerid][am_spraying] != 0) {

					if (playerData[playerid][am_spraying_sprays] > 0) {
						new temp_turf_id;
						for (new tt = 0; tt < MAX_TURFS; tt++) {
							if (turfData[tt][turf_id] == playerData[playerid][am_spraying]) {
								temp_turf_id = tt;
							}
						}
						if (turfData[temp_turf_id][turf_owner_clan] != playerData[playerid][account_clan]) {
							new temp[128];
							format(temp, 128, "~y~~h~Spraying: ~r~~h~~h~%d", playerData[playerid][am_spraying_sprays]);
							TXDInfoMessage_update(playerid, temp);
						} else {
							playerData[playerid][am_spraying] = 0;
							ClearAnimations(playerid);
							TXDInfoMessage_update(playerid, "");
						}
					} else {
						playerData[playerid][am_spraying] = 0;
						ClearAnimations(playerid);
						TXDInfoMessage_update(playerid, "");
					}
				}


				if (playerData[playerid][in_jail] == 1) {

					if (playerData[playerid][escape_state] != 0) {
						if (playerData[playerid][escape_state] == 1) {
							new temp[128];
							format(temp, 128, "~y~~h~Digging: ~r~~h~%d", playerData[playerid][escape_digging]);
							TXDInfoMessage_update(playerid, temp);

							for(new g = 0, h = GetPlayerPoolSize(); g <= h; g++) {
								if (playerData[g][account_faction] == FACTION_LSPD && playerData[g][special_interior] == INTERIOR_PRISON) {
									format(temp, sizeof(temp), "Escape attempt has been aborted. LSPD Member %s is now in the prison.", playerData[g][account_name]);
									SendClientMessage(playerid, COLOR_BADINFO, temp);
									ResetPlayerWeapons(playerid);
									DisablePlayerCheckpoint(playerid);
									playerData[playerid][escape_state] = 0;
									playerData[playerid][account_escaped] = 0;
								}
							}
						}
					} else {
						if (playerData[playerid][account_jailed] > 0) {
							if (GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) {
								new temp[128];
								format(temp, 128, "~r~JAILED %d SECS", playerData[playerid][account_jailed]);
								GameTextForPlayer(playerid, temp, 4000, 4);
								playerData[playerid][account_jailed] -= 1;

								if (!IsPlayerInRangeOfPoint(playerid, 50.0, 1556.9856,-1657.3517,-14.3242)) {
									SetPlayerPos(playerid, 1556.9856,-1657.3517,-14.3242);
									SetPlayerInterior(playerid, 0);
									printf("Warning: %s was jaied but far away from the jail. Got sent back to jail.", playerData[playerid][account_name]);
								}
							}
						} else {
							playerData[playerid][in_jail] = 0;
							playerData[playerid][account_jailed] = 0;
							playerData[playerid][account_escaped] = 0;
							playerData[playerid][escape_state] = 0;
							SetPlayerSkin(playerid, playerData[playerid][account_skin]);
							SpawnPlayer(playerid);
							GameTextForPlayer(playerid, "~g~FREE!", 2000, 4);
							SendClientMessage(playerid, COLOR_INFO, "You are now free to go. See you soon!");
							printf("%s is now free from jail.", playerData[playerid][account_name]);
						}
					}
				}

				carInstrumentsUpdate(playerid);

				if (playerData[playerid][robbing_state] > 0) {
					if (playerData[playerid][robbing_state] == 1) {
						if (playerData[playerid][special_interior] == INTERIOR_BANK_LS || playerData[playerid][special_interior] == INTERIOR_BANK_SF) {
							if (playerData[playerid][robbing_money] < playerData[playerid][robbing_max_money]) {
								playerData[playerid][robbing_money] += 10 + random(15);
								new temp[64];
								format(temp, sizeof(temp), "~g~COLLECTING... $%s", formatMoney(playerData[playerid][robbing_money]));
								TXDInfoMessage_update(playerid, temp);
							} else {
								if (playerData[playerid][robbing_msg_flag] == 0) {
									SendClientMessage(playerid, COLOR_BADINFO, "You cannot collect more money. You need to get out!");
									playerData[playerid][robbing_msg_flag] = 1;

									new temp[64];
									format(temp, sizeof(temp), "~g~COLLECTED $%s, LEAVE!", formatMoney(playerData[playerid][robbing_money]));
									TXDInfoMessage_update(playerid, temp);
								}
							}
						} else {
							playerData[playerid][robbing_state] = 2;
							new temp[128];
							format(temp, sizeof(temp), "You have collected $%s. Deliver the money at the safe checkpoint.", formatMoney(playerData[playerid][robbing_money]));
							SendClientMessage(playerid, COLOR_INFO, temp);
							printf("ROB: %s collected during the rob $%s. He will go to the checkpoint.", playerData[playerid][account_name], formatMoney(playerData[playerid][robbing_money]));

							playerData[playerid][tracking_mode] = 0;
							playerData[playerid][checkpoint] = 0;
							DisablePlayerCheckpoint(playerid);

							TXDInfoMessage_update(playerid, "");

							if (playerData[playerid][robbing_inbank] == INTERIOR_BANK_LS) {
								// BANK LS, DROP IN SF

								if (ROB_DROP_SF > 4) {
									ROB_DROP_SF = 0;
								}

								switch(ROB_DROP_SF) {
									case 0: setCheckpoint(playerid, -1817.9363,1314.5695,7.1875, 3.0);
									case 1: setCheckpoint(playerid, -2994.5305,485.3201,4.9141, 3.0);
									case 2: setCheckpoint(playerid, -2377.3396,-579.7125,132.1172, 3.0);
									case 3: setCheckpoint(playerid, -1968.8573,-976.9600,32.2266, 3.0);
									case 4: setCheckpoint(playerid, -1523.6281,-559.9769,14.1440, 3.0);

								}
								ROB_DROP_SF++;

							} else 	if (playerData[playerid][robbing_inbank] == INTERIOR_BANK_SF) {
								// BANK SF, DROP IN LS

								if (ROB_DROP_LS > 3) {
									ROB_DROP_LS = 0;
								}
								
								switch(ROB_DROP_LS) {
									case 0: setCheckpoint(playerid, 1852.2762,-2333.7764,13.5469, 3.0);
									case 1: setCheckpoint(playerid, 1247.5916,-2055.2761,59.7758, 3.0);
									case 2: setCheckpoint(playerid, 2338.4768,-1328.9816,24.3081, 3.0);
									case 3: setCheckpoint(playerid, 384.7445,-2087.2080,7.8359, 3.0);

								}
								ROB_DROP_LS++;

							}
						}
					}
				}

				for (new i = 0 ; i < MAX_TURFS ; i++) {
					if (turfData[i][turf_id] == 0) continue;
					GangZoneShowForPlayer(playerid, turfData[i][turf_gangzone], clanColors(turfData[i][turf_color]));
				}

				// No more active, since clan Tags
				// setNameAFK(playerid, 0);
				// playerData[playerid][afk_cooldown] = timestamp;
			} else {
				// No more active, since clan Tags
				/*if (timestamp-playerData[playerid][afk_cooldown] > 10) {
					setNameAFK(playerid, 1);
				}*/
			}

			if (playerData[playerid][am_sleeping] == 0 && timestamp-playerData[playerid][afk_lastCheck] >= 5 * 60) {
				playerData[playerid][afk_lastCheck] = timestamp;
				if (IsPlayerInRangeOfPoint(playerid, 5.0, playerData[playerid][afk_x], playerData[playerid][afk_y], playerData[playerid][afk_z])) {
					playerData[playerid][afk_flag] ++;

					if (playerData[playerid][afk_flag] == 3) {
						SendClientMessage(playerid, COLOR_BADINFO, "You need to move your player, otherwise you will be kicked in a few minutes for being AFK.");
					} else if (playerData[playerid][afk_flag] == 4) {
						kickAdmBot(playerid, "AFK without /sleep");
					}

				} else {
			
					GetPlayerPos(playerid, playerData[playerid][afk_x], playerData[playerid][afk_y], playerData[playerid][afk_z]);

					playerData[playerid][afk_flag] = 0;

				}
			}


			new vehicleid = GetPlayerVehicleID(playerid);

			if (vehicleid >= SPAWN_LSPD_CARS[0] && vehicleid <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1] && playerData[playerid][account_faction] == FACTION_LSPD) {
				if(IsPlayerInRangeOfPoint(playerid, 18.0, 1544.70, -1630.10, 13.29)) {
					pd_near_gate = 1;
				}
			}

			if (vehicleid != 0) {
				if ((isnull(playerData[playerid][current_radio]) && !isnull(vehicleRadio[vehicleid])) || strcmp(playerData[playerid][current_radio], vehicleRadio[vehicleid]) != 0) {
					if (strlen(vehicleRadio[vehicleid]) == 0 || isnull(vehicleRadio[vehicleid])) {
						format(playerData[playerid][current_radio], 32, "");
						StopAudioStreamForPlayer(playerid);
					} else {
						carRadio(playerid, vehicleRadio[vehicleid]);
					}
				}

				if (isnull(vehicleRadio[vehicleid]) && !isnull(playerData[playerid][current_radio])) {
					format(playerData[playerid][current_radio], 32, "");
					StopAudioStreamForPlayer(playerid);
				}
			} else {
				if (strlen(playerData[playerid][current_radio]) != 0) {
					format(playerData[playerid][current_radio], 32, "");
					StopAudioStreamForPlayer(playerid)
				}
			}

			if (vehicleid != 0) {
				if (GetPlayerDrunkLevel(playerid) > 0) {
					if (timestamp-playerData[playerid][drive_drunk_cooldown] > 60 * 10) {
						playerData[playerid][drive_drunk_cooldown] = timestamp;
						if (playerData[playerid][account_faction] == FACTION_LSPD) {
							new temp_notify[128];
							format(temp_notify, sizeof(temp_notify), "Warning! LSPD Member %s (%d) is drunk and driving a car.", playerData[playerid][account_name], playerid);
							SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp_notify);
						} else {
							reportCrime(playerid, 3, "Drunk Driving");
						}
					}
				}
			}

			if (timestamp-playerData[playerid][lastSave] > 180) {
				savePlayerData(playerid);
				playerData[playerid][lastSave] = timestamp;
			}

			if (playerData[playerid][am_sleeping] == 0 && (playerData[playerid][account_jailed] == 0 || playerData[playerid][escape_state] == 2)) {
				if (playerData[playerid][lastHealthDrop] == 0) {
					SetPlayerHealth(playerid, 100);
					playerData[playerid][lastHealthDrop] = timestamp;	
				} else if (timestamp-playerData[playerid][lastHealthDrop] > 120) {
					new Float: tempH;
					GetPlayerHealth(playerid, tempH);
					if (playerData[playerid][account_wanted] > 0) {
						SetPlayerHealth(playerid, tempH - 8);
					} else {
						SetPlayerHealth(playerid, tempH - 4);
					}
					playerData[playerid][lastHealthDrop] = timestamp;
				}
			}

			if (playerData[playerid][am_working] == 0) {
				if (vehicleid >= FARMER_CARS[0] && vehicleid <= FARMER_CARS[sizeof(FARMER_CARS) - 1]) {
					if (playerData[playerid][account_wanted] > 0) {
						RemovePlayerFromVehicle(playerid);
						SendClientMessage(playerid, COLOR_BADINFO, "Wanted players cannot work here.");
					} else {
						playerData[playerid][tracking_mode] = 0;
						playerData[playerid][checkpoint] = 0;
						DisablePlayerCheckpoint(playerid);

						playerData[playerid][am_working] = WORKING_FARMER;
						SendClientMessage(playerid, COLOR_INFO, "You have started working as a farmer. Follow the checkpoints.");
						printf("%s started working as a farmer.", playerData[playerid][account_name]);
						playerData[playerid][farmer_index] = 0;
						setCheckpoint(playerid, FARMER_POINTS[0][0],FARMER_POINTS[0][1],FARMER_POINTS[0][1], 8.0);
					}
				}
			} else {
				if (playerData[playerid][am_working] == WORKING_FARMER) {
					if (!(vehicleid >= FARMER_CARS[0] && vehicleid <= FARMER_CARS[sizeof(FARMER_CARS) - 1])) {
						playerData[playerid][am_working] = 0;
						SendClientMessage(playerid, COLOR_INFO, "You have stopped working as a farmer.");
						printf("%s stopped working as a farmer.", playerData[playerid][account_name]);
						DisablePlayerCheckpoint(playerid);
						playerData[playerid][checkpoint] = 0;
					} else {
						new temp_i = playerData[playerid][farmer_index];
						if (IsPlayerInRangeOfPoint(playerid, 12.0, FARMER_POINTS[temp_i][0], FARMER_POINTS[temp_i][1], FARMER_POINTS[temp_i][2])) {

							playerData[playerid][farmer_index]++;
							if (playerData[playerid][farmer_index] >= sizeof(FARMER_POINTS)) {
								playerData[playerid][farmer_index] = 0;
							}
							temp_i = playerData[playerid][farmer_index];

							giveMoney(playerid, 5 + random(5));
							printf("%s reached a farmer checkpoint.", playerData[playerid][account_name]);

							setCheckpoint(playerid, FARMER_POINTS[temp_i][0], FARMER_POINTS[temp_i][1], FARMER_POINTS[temp_i][2], 8.0);
						}
					}
				}
			}

			if (playerData[playerid][am_in_taxi] == 1 && timestamp-playerData[playerid][lastTaxiFare] >= 6) {
				if (vehicleid >= SPAWN_TAXI_CARS[0] && vehicleid <= SPAWN_TAXI_CARS[sizeof(SPAWN_TAXI_CARS)-1]) {
					if (playerData[playerid][account_faction] != FACTION_TAXILS) {
						new driverid = GetVehicleDriverID(vehicleid); 
						if (driverid != -1) {
							if (playerData[playerid][account_money] < 10) {
								RemovePlayerFromVehicle(playerid);
								new temp[128];
								format(temp, 128, "%s does not have enough money and got removed from the taxi.", playerData[playerid][account_name]);
								SendClientMessage(driverid, COLOR_BADINFO, temp);
								SendClientMessage(playerid, COLOR_BADINFO, "You do not have enough money. You got removed from the taxi.");
							}

							playerData[driverid][tarifs] += 1;
							if (playerData[driverid][tarifs] == 50) {
								SendClientMessage(driverid, COLOR_INFO, "You have received 1 Score point for earning taxi money 50 times in a row.");
								playerData[driverid][account_score] += 1;
								printf("SCORE: Player %s received 1 Score point in taxi for earning 50 times in a row.", playerData[driverid][account_name]);
								playerData[driverid][tarifs] = 0;
							}
							giveMoney(playerid, -5);
							giveMoney(driverid, 5);
							playerData[playerid][lastTaxiFare] = timestamp;
							playerData[playerid][am_in_taxi_spent] += 5;
						}
					}
				}
			}

			if (timestamp-playerData[playerid][lastHealUp] >= 6) {
				if (GetVehicleModel(vehicleid) == 416 || GetVehicleModel(vehicleid) == 417) {
					if (playerData[playerid][account_faction] != FACTION_MEDICS) {
						new driverid = GetVehicleDriverID(vehicleid);
						if (driverid != -1) {
							if (playerData[playerid][account_money] <= 35) {
								RemovePlayerFromVehicle(playerid);
								new temp[128];
								format(temp, 128, "%s does not have enough money and got removed from the vehicle.", playerData[playerid][account_name]);
								SendClientMessage(driverid, COLOR_BADINFO, temp);
								SendClientMessage(playerid, COLOR_BADINFO, "You do not have enough money. You got removed from the vehicle.");
							} else {
								new temp[512];
								new Float: tempH;
								GetPlayerHealth(playerid, tempH);
								if (tempH <= 85.0) {
									SetPlayerHealth(playerid, tempH + 30);
									SetPlayerHealth(driverid, tempH + 30);
									giveMoney(playerid, -75);
									giveMoney(driverid, 75);
									playerData[playerid][lastHealUp] = timestamp;
									playerData[driverid][heal_ups] += 1;

									if (playerData[driverid][heal_ups] == 15) {
										SendClientMessage(driverid, COLOR_INFO, "You have received 1 Score point for healing 15 players.");
										playerData[driverid][account_score] += 1;
										printf("SCORE: Player %s received 1 Score point for healing 15 players in a row.", playerData[driverid][account_name]);
										playerData[driverid][heal_ups] = 0;
									}

									format(temp, 128, "* %s has healed you +30HP for $75.", playerData[driverid][account_name]);
									SendClientMessage(playerid, COLOR_INFO, temp);
									format(temp, 128, "* You have healed +30HP %s for $75.", playerData[playerid][account_name]);
									SendClientMessage(driverid, COLOR_INFO, temp);

									format(temp, sizeof(temp),"INSERT INTO `activity_reports` (`r_player`, `r_faction`, `r_type`, `r_serviced_player`, `r_date`, `r_amount`) VALUES ('%d', '%d', 'heal 30HP', '%d', '%d', '%d')", playerData[driverid][account_id], FACTION_MEDICS, playerData[playerid][account_id], gettime(), 75);
									mysql_query(Database, temp, false);
								}

								if (playerData[playerid][account_wanted] > 0) {
									if (timestamp - playerData[driverid][heal_last_wanted] > 60 && playerData[driverid][account_wanted] == 0) {
										playerData[driverid][heal_last_wanted] = timestamp;

										if (playerData[driverid][account_wanted] < 6) {
											playerData[driverid][account_wanted]+= 1;
											if (playerData[driverid][account_wanted] >= 6) {
												playerData[driverid][account_wanted] = 6;
											}
										}

										format(temp, sizeof(temp), "Player %s (%d) got reported for helping the wanted player %s. Current Wanted Level: %d", playerData[driverid][account_name], driverid, playerData[playerid][account_name], playerData[driverid][account_wanted]);
										SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp);

										format(temp, sizeof(temp), "You have helped the wanted player %s. You have now wanted level: %d.", playerData[playerid][account_name], playerData[driverid][account_wanted]);
										SendClientMessage(driverid, COLOR_BADINFO, temp);
									}

								}
							}
						}
					}
				}
			}

			if (playerData[playerid][account_wanted] != playerData[playerid][wanted_last_3D]) {
				if (playerData[playerid][account_wanted] == 0) {
					Update3DTextLabelText(playerData[playerid][wanted_3D], 0xFFFFFF00, " ");
				} else if (playerData[playerid][account_wanted] == 1) {
					Update3DTextLabelText(playerData[playerid][wanted_3D], 0xebba34FF, "Wanted 1");
				} else if (playerData[playerid][account_wanted] == 2) {
					Update3DTextLabelText(playerData[playerid][wanted_3D], 0xebba34FF, "Wanted 2");
				} else if (playerData[playerid][account_wanted] == 3) {
					Update3DTextLabelText(playerData[playerid][wanted_3D], 0xebba34FF, "Wanted 3");
				} else if (playerData[playerid][account_wanted] == 4) {
					Update3DTextLabelText(playerData[playerid][wanted_3D], 0xebba34FF, "Wanted 4");
				} else if (playerData[playerid][account_wanted] == 5) {
					Update3DTextLabelText(playerData[playerid][wanted_3D], 0xebba34FF, "Wanted 5");
				} else if (playerData[playerid][account_wanted] == 6) {
					Update3DTextLabelText(playerData[playerid][wanted_3D], 0xebba34FF, "Wanted 6");
				}
				playerData[playerid][wanted_last_3D] = playerData[playerid][account_wanted];
			}

			if (playerData[playerid][account_wanted] > 0 && IsPlayerAttachedObjectSlotUsed(playerid, 2) == 0) {
				if (playerData[playerid][wanted_last] != playerData[playerid][account_wanted]) {
					playerData[playerid][wanted_last] = playerData[playerid][account_wanted];
					playerData[playerid][wanted_seconds] = 100;
					SetPlayerWantedLevel(playerid, playerData[playerid][account_wanted]);
				} else {
					playerData[playerid][wanted_seconds]--;
					if (playerData[playerid][wanted_seconds] <= 0) {
						playerData[playerid][account_wanted]--;
						playerData[playerid][wanted_last] = 0;
						new temp[128];
						if (playerData[playerid][account_wanted] == 0) {
							format(temp, sizeof(temp), "Player %s is no wanted anymore.", playerData[playerid][account_name]);
						} else {
							format(temp, sizeof(temp), "Player %s is less wanted now. Current Wanted Level: %d", playerData[playerid][account_name], playerData[playerid][account_wanted]);
						}
						SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp);
					}
				}
			}
			SetPlayerWantedLevel(playerid, playerData[playerid][account_wanted]);

			if (playerData[playerid][tracking_mode] == 1) {
				if (timestamp-playerData[playerid][tracking_cooldown] > 2) {
					playerData[playerid][tracking_cooldown] = timestamp;

					new temp_tracked_player = playerData[playerid][tracking_player];

					if (!IsPlayerConnected(temp_tracked_player) || playerData[temp_tracked_player][logged] == 0) {
						SendClientMessage(playerid, COLOR_BADINFO, "The player that you were tracking has left the server.");
						playerData[playerid][tracking_mode] = 0;
						playerData[playerid][checkpoint] = 0;
						DisablePlayerCheckpoint(playerid);
					} else if (IsPlayerInRangeOfPoint(temp_tracked_player, 70.0, 1412.639892,-1.787510,1000.924377) || playerData[temp_tracked_player][spec_mode] == 1) {
						SendClientMessage(playerid, COLOR_BADINFO, "You can not track that player right now.");
						playerData[playerid][tracking_mode] = 0;
						playerData[playerid][checkpoint] = 0;
						DisablePlayerCheckpoint(playerid);
					} else {
						if (playerData[temp_tracked_player][enteredBiz] != 0) {

							new temp_biz_id = playerData[temp_tracked_player][enteredBiz];
							setCheckpoint(playerid, bizData[temp_biz_id][biz_x], bizData[temp_biz_id][biz_y], bizData[temp_biz_id][biz_z], 3.0);

						} else if (playerData[temp_tracked_player][enteredHouse] != 0) {

							new temp_house_id = playerData[temp_tracked_player][enteredHouse];
							setCheckpoint(playerid,  houseData[temp_house_id][house_x], houseData[temp_house_id][house_y], houseData[temp_house_id][house_z], 3.0);

						} else {
							new Float:temp_x, Float:temp_y, Float:temp_z;
							GetPlayerPos(temp_tracked_player, temp_x, temp_y, temp_z);
							setCheckpoint(playerid, temp_x, temp_y, temp_z, 3.0);
						}
					}
				}
			}

			if (carData[vehicleid][vehicle_fuel] <= 0 && !isBike(vehicleid)) {
				new engine, lights, alarm, doors, bonnet, boot, objective;
				GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
				if (engine == 1) {
					SendClientMessage(playerid, COLOR_BADINFO, "Engine cannot hold. Fuel is empty. Call a taxi driver or buy from /shop.");
					SetVehicleParamsEx(vehicleid, 0, 0, alarm, doors, bonnet, boot, objective);
				}
			}


			
			// Anti Weapon Hack
			/*for (new i = 0; i <= 12; i++) {
				new weaponid, weaponammo;
				GetPlayerWeaponData(playerid, i, weaponid, weaponammo);

				if (weaponid != 0 && SAFE_GUNS[playerid][i] != weaponid && weaponid != WEAPON_PARACHUTE) {
					if (timestamp - playerData[playerid][weaponHack_cooldown] >  20) {
						playerData[playerid][weaponHack_cooldown] = timestamp;
						new temp[128];
						format(temp, sizeof(temp), "Warning: %s (%d) might be using weapon hack (%s). Verify.", playerData[playerid][account_name], playerid, GunNames[weaponid]);
						SendClientMessageToAdmins(1, 0xed2828FF, temp);

						playerData[playerid][weaponHack_crash_times]++;

						printf("WARNING: %s might be using weapon hack (%s) (%d).", playerData[playerid][account_name],GunNames[weaponid], playerData[playerid][weaponHack_crash_times]);

						if (playerData[playerid][weaponHack_crash_times] == 20) {
								GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 1000, 0);
								GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 2000, 1);
								GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 3000, 2);
								GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 4000, 3);
								GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 5000, 4);
								GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 6000, 5);
								GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 7000, 6);
								GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 12000, 6);

								printf("WARNING: %s might be using weapon hack (We crashed his game).", playerData[playerid][account_name]);
						}
					}
				}

			}*/

			if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK) {
				GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 1000, 0);
				GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 2000, 1);
				GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 3000, 2);
				GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 4000, 3);
				GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 5000, 4);
				GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 6000, 5);
				GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 7000, 6);
				GameTextForPlayer(playerid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 12000, 6);
				printf("Warning; %s had Jetpack. Got crashed.", playerData[playerid][account_name]);
			}

		}
	}


	new temp_active_reports_str[32];
	format(temp_active_reports_str, sizeof(temp_active_reports_str), "ACTIVE REPORTS: %d", temp_active_reports);

	for(new playerid = 0, j = GetPlayerPoolSize(); playerid <= j; playerid++) {
		if (temp_active_reports > 0 && playerData[playerid][logged] == 1 && (playerData[playerid][account_admin] > 0 || IsPlayerAdmin(playerid))) {
			PlayerTextDrawSetString(playerid, playerData[playerid][active_reportsTXD], temp_active_reports_str);
			PlayerTextDrawShow(playerid, playerData[playerid][active_reportsTXD]);
		} else {
			PlayerTextDrawHide(playerid, playerData[playerid][active_reportsTXD]);
		}

	}


	if (timestamp-CARS_FUEL_UPDATE > 30) {
		CARS_FUEL_UPDATE = timestamp;

		for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(i, engine, lights, alarm, doors, bonnet, boot, objective);
			if (engine == 1) {
				new Float:x,Float:y,Float:z;
				GetVehicleVelocity(i,x,y,z);
				new Float:km = floatsqroot(((x*x)+(y*y))+(z*z))*181.5;
				if (carData[i][playerCar] == 1) {
					carData[i][vehicle_odometer] += floatround(km / 1000 * 15);
				}
				if (km > 100) {
					carData[i][vehicle_fuel] -= 2;
				} else {
					carData[i][vehicle_fuel] -= 1;
				}
				if (carData[i][vehicle_fuel] <= 0) {
					carData[i][vehicle_fuel] = 0;
				} 
			}
		}
		
	}


	if (pd_near_gate == 1 && PARKING_GATE_STATE == 0) {
		PARKING_GATE_STATE = 1;
		MoveObject(PARKING_GATE, 1544.71631, -1630.81335, 12.99840, 0.5,  -0.18000, -1.74000, -89.70010);
		
	} else if (pd_near_gate == 0 && PARKING_GATE_STATE == 1) {
		PARKING_GATE_STATE = 0;
		MoveObject(PARKING_GATE, 1544.71936, -1630.93188, 13.07240, 0.5,  0.00000, -90.00000, -89.70010);
	}


	if (PAINTBALL_STATE > 0) {
		if (PAINTBALL_STATE == 1) {
			// setup from :paintball
			if (timestamp-PaintballStartedOn >= 20) {
				PAINTBALL_STATE = 2;
				PaintballStartedOn = timestamp;

				SendClientMessageToPaintballers(COLOR_PAINTBALL, "Please select your weapon class. Match begins in 10 seconds.");
				for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
					if (playerData[i][logged] && playerData[i][paintball_joined] == 1) {
						Dialog_Show(i, DLG_PAINTBALL_CLASS, DIALOG_STYLE_TABLIST_HEADERS, "Paintball: Weapon Class", PAINTBALL_CLASS_STRING, "Confirm", "");
					}
				}
			}
		} else if (PAINTBALL_STATE == 2) {
			if (timestamp-PaintballStartedOn >= 10) {
				PAINTBALL_STATE = 3;
				PaintballStartedOn = timestamp;
				SendClientMessageToPaintballers(COLOR_PAINTBALL, "Free for all. Good luck!");

				for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
					if (playerData[i][logged] && playerData[i][paintball_joined] == 1) {
						SpawnPlayer(i);
					}
					playerData[i][paintball_kills] = 0;
				}
			}
		} else if (PAINTBALL_STATE == 3) {
			new temp_paint[32];
			format(temp_paint, sizeof(temp_paint), "REMAINING TIME: %d sec", PAINTBALL_DURATION-(timestamp-PaintballStartedOn));
			TextDrawSetString(PaintballTextdraw0, temp_paint);
			
			format(temp_paint, sizeof(temp_paint), "WINNER: %s (%d KILLS)", playerData[temp_maxKills_player][account_name], temp_maxKills);
			TextDrawSetString(PaintballTextdraw1, temp_paint);

			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged] && playerData[i][paintball_joined] == 1) {
					TextDrawShowForPlayer(i, PaintballTextdraw0);
					TextDrawShowForPlayer(i, PaintballTextdraw1);
				}
			}

			if (timestamp - PaintballStartedOn >= PAINTBALL_DURATION) {
				PAINTBALL_STATE = 4;
				PaintballStartedOn = timestamp;

				SendClientMessageToPaintballers(COLOR_PAINTBALL, "Match is over!");

				temp_maxKills = temp_maxKills_player = 0;

				new temp_count_players = 0;

				for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {

					if (playerData[i][logged] && playerData[i][paintball_kills] > temp_maxKills) {
						temp_maxKills = playerData[i][paintball_kills];
						temp_maxKills_player = i;
					}

					if (playerData[i][logged] && playerData[i][paintball_joined] == 1) {
						SetPlayerVirtualWorld(i, 0);
						SetPlayerHealth(i, 0);

						temp_count_players ++;
					}
				}

				if (temp_maxKills != 0) {
					new temp[128], temp_winnings = 300 * temp_count_players;
					format(temp, 128, "Paintball winner is %s (%d). Winnings: $%s. Congratulations!", playerData[temp_maxKills_player][account_name], temp_maxKills_player, formatMoney(temp_winnings));
					printf("%s", temp);
					giveMoney(temp_maxKills_player, temp_winnings);
					SendClientMessageToAll(COLOR_PUBLIC, temp);
				} else {
					printf("Paintball match is over. No kills were counted, no message was sent.");
				}

			}
		} else if (PAINTBALL_STATE == 4) {
			if (timestamp-PaintballStartedOn >= 10) {
				for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
					if (playerData[i][logged] && playerData[i][paintball_joined] == 1) {
						playerData[i][paintball_joined] = 0;
						TextDrawHideForPlayer(i, PaintballTextdraw0);
						TextDrawHideForPlayer(i, PaintballTextdraw1);
					}
				}
				PAINTBALL_STATE = 0;
			}
		}

	}

	if (isWarTime() && serverLastSprayingTimeH != H) {
		serverLastSprayingTimeH = H;

		SendClientMessageToAll(0x00C3FFFF,"Spraying Time for clans has begun! Use /turfs to see the main Spraying Points.");


		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			playerData[i][clan_war_kills] = 0;

			playerData[i][clan_war_sprays] = 0;
		}


		new query_temp[256];
		mysql_format(Database, query_temp, sizeof(query_temp),"INSERT INTO `discord_message` (`message_content`, `webhook_name`, `added_on`) VALUES ( 'Spraying Time for clans has begun!', 'welcome', '%d')", gettime());
		mysql_query(Database, query_temp, false);

	} else if (!isWarTime() && serverLastSprayingTimeH == H) {
		serverLastSprayingTimeH = 99;

		SendClientMessageToAll(0x00C3FFFF,"Spraying Time for clans is now over!");

		new query_temp[256];
		mysql_format(Database, query_temp, sizeof(query_temp),"INSERT INTO `discord_message` (`message_content`, `webhook_name`, `added_on`) VALUES ( 'Spraying Time for clans is now over! Turfs: https://www.greeksamp.info/rpg/clans.php', 'welcome', '%d')", gettime());
		mysql_query(Database, query_temp, false);


		new best_player = -1;
		new best_player_kills = 0;
		
		new best_sprayer = -1;
		new best_sprayer_sprays = 0;

		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][clan_war_kills] > best_player_kills) {
				best_player = i;
				best_player_kills = playerData[i][clan_war_kills];
			}

			if (playerData[i][clan_war_sprays] > best_sprayer_sprays) {
				best_sprayer = i;
				best_sprayer_sprays = playerData[i][clan_war_sprays];
			}

			playerData[i][clan_war_kills] = 0;
			playerData[i][clan_war_sprays] = 0;

			if (playerData[i][am_spraying] == 1) {
				TXDInfoMessage_update(i, "");
			}

			playerData[i][am_spraying] = 0;
			playerData[i][am_spraying_sprays] = 0;
		}

		if (best_player != -1) {

			new temp_clanIndex = getClanIndex(best_player);
			if (temp_clanIndex != NO_CLAN && temp_clanIndex != CLAN_NOT_FOUND) {

				format(query_temp, sizeof(query_temp), "* %s from %s was the clan member with the most kills (%d) during the game.", playerData[best_player][account_name], clanData[temp_clanIndex][clan_name], best_player_kills);

				SendClientMessageToAll(0x00C3FFFF, query_temp);

				format(query_temp, sizeof(query_temp), "**%s** from %s was the clan member with the most kills (%d) during the game.", playerData[best_player][account_name], clanData[temp_clanIndex][clan_name], best_player_kills);

				giveMoney(best_player, 2500);

				mysql_format(Database, query_temp, sizeof(query_temp),"INSERT INTO `discord_message` (`message_content`, `webhook_name`, `added_on`) VALUES ( '%e', 'welcome', '%d')", query_temp, gettime());
				mysql_query(Database, query_temp, false);

			}

		}

		if (best_sprayer != -1) {

			new temp_clanIndex = getClanIndex(best_sprayer);
			if (temp_clanIndex != NO_CLAN && temp_clanIndex != CLAN_NOT_FOUND) {

				format(query_temp, sizeof(query_temp), "* %s from %s was the clan member with the most successful sprays (%d).", playerData[best_sprayer][account_name], clanData[temp_clanIndex][clan_name], best_sprayer_sprays);

				SendClientMessageToAll(0x00C3FFFF, query_temp);

				format(query_temp, sizeof(query_temp), "**%s** from %s was the clan member with the most successful sprays (%d).", playerData[best_sprayer][account_name], clanData[temp_clanIndex][clan_name], best_sprayer_sprays);

				giveMoney(best_sprayer, 3500);

				mysql_format(Database, query_temp, sizeof(query_temp),"INSERT INTO `discord_message` (`message_content`, `webhook_name`, `added_on`) VALUES ( '%e', 'welcome', '%d')", query_temp, gettime());
				mysql_query(Database, query_temp, false);

			}

		}

	}


	return 1;
}

new Text:Clock1;
new Text:Clock2;
forward serverTime(step);
public serverTime(step)
{
	if (step == 1) {
		Clock1 = TextDrawCreate(545.000000, 10.000000, "19/05/2018");
		TextDrawBackgroundColor(Clock1, 255);
		TextDrawFont(Clock1, 3);
		TextDrawLetterSize(Clock1, 0.340000, 1.500000);
		TextDrawColor(Clock1, -1);
		TextDrawSetOutline(Clock1, 0);
		TextDrawSetProportional(Clock1, 1);
		TextDrawSetShadow(Clock1, 1);
		TextDrawSetSelectable(Clock1, 0);

		Clock2 = TextDrawCreate(576.000000, 23.000000, "11:00");
		TextDrawAlignment(Clock2, 2);
		TextDrawBackgroundColor(Clock2, 255);
		TextDrawFont(Clock2, 3);
		TextDrawLetterSize(Clock2, 0.360000, 1.800000);
		TextDrawColor(Clock2, -1);
		TextDrawSetOutline(Clock2, 0);
		TextDrawSetProportional(Clock2, 1);
		TextDrawSetShadow(Clock2, 1);
		TextDrawSetSelectable(Clock2, 0);
	} else if (step == 2) {
		TextDrawSetString(Clock1, getTimeString(1));
		TextDrawSetString(Clock2,  getTimeString(2));

		TextDrawShowForAll(Clock1);
		TextDrawShowForAll(Clock2);
	} else if (step == 3) {
		TextDrawDestroy(Clock1);
		TextDrawDestroy(Clock2);
	}

}



main()
{


}

public OnGameModeInit()
{
	print("\n\n\n\n\n\n\nLoading Greek Roleplay\n");


	if (dini_Exists(CONFIG_INI)) {
		new temp[64];
		format(temp, sizeof(temp), "%s", dini_Get(CONFIG_INI, "ServerInProduction"));
		if (strcmp(temp, "True") == 0) {
			ServerInProduction = true;
			print("Server has been set in production.\n");
		} else {
			print("Server is in beta mode!\n");
		}

		format(SCRIPT_VERSION, sizeof(SCRIPT_VERSION), "%s", dini_Get(CONFIG_INI, "Version"));

        format(temp, sizeof(temp), "%s", dini_Get(CONFIG_INI, "GameModeText"));
        printf("Setting GameModeText from %s to %s", CONFIG_INI, temp);
        SetGameModeText(temp);

        format(temp, sizeof(temp), "%s", dini_Get(CONFIG_INI, "HostName"));
        format(temp, sizeof(temp), "hostname %s", temp);
        printf("Setting HostName from %s to %s", CONFIG_INI, temp);
        SendRconCommand(temp);
        
        format(temp, sizeof(temp), "%s", dini_Get(CONFIG_INI, "MapName"));
        format(temp, sizeof(temp), "mapname %s", temp);
        printf("Setting MapName from %s to %s", CONFIG_INI, temp);
        SendRconCommand(temp);

        format(temp, sizeof(temp), "%s", dini_Get(CONFIG_INI, "WebUrl"));
        format(temp, sizeof(temp), "weburl %s", temp);
        printf("Setting WebUrl from %s to %s", CONFIG_INI, temp);
        SendRconCommand(temp);

        format(temp, sizeof(temp), "%s", dini_Get(CONFIG_INI, "Language"));
        format(temp, sizeof(temp), "language %s", temp);
        printf("Setting Language from %s to %s", CONFIG_INI, temp);
        SendRconCommand(temp);

		format(passHashSalt, sizeof(passHashSalt), "%s", dini_Get(CONFIG_INI, "passHashSalt"));

		format(radioHashSalt, sizeof(radioHashSalt), "%s", dini_Get(CONFIG_INI, "radioHashSalt"));

        print("\n");

        ShowNameTags(1);

        ShowPlayerMarkers(PLAYER_MARKERS_MODE_STREAMED);

        EnableStuntBonusForAll(0);

        UsePlayerPedAnims();

        DisableInteriorEnterExits();

        ManualVehicleEngineAndLights();
	}

	serverTimeZoneKey = dini_Int(CONFIG_INI, "serverTimeZoneKey");
	serverTimeZone = dini_Int(CONFIG_INI, "serverTimeZone");

	AddPlayerClass(0, 0, 0, 5, 269.15, 0, 0, 0, 0, 0, 0);


	new host[32], user[32], pass[32], db[32];
	if (ServerInProduction) {
		format(host, sizeof(host), "%s", dini_Get(CONFIG_INI, "host_prod"));
		format(user, sizeof(user), "%s", dini_Get(CONFIG_INI, "user_prod"));
		format(pass, sizeof(pass), "%s", dini_Get(CONFIG_INI, "pass_prod"));
		format(db, sizeof(db), "%s", dini_Get(CONFIG_INI, "db_prod"));
	} else {
		format(host, sizeof(host), "%s", dini_Get(CONFIG_INI, "host"));
		format(user, sizeof(user), "%s", dini_Get(CONFIG_INI, "user"));
		format(pass, sizeof(pass), "%s", dini_Get(CONFIG_INI, "pass"));
		format(db, sizeof(db), "%s", dini_Get(CONFIG_INI, "db"));
	}
	Database = mysql_connect(host, user, pass, db);
	if (mysql_errno(Database) != 0) {
		printf("Error: Could not connect with the database (`%s`, `%s`, `%s`, `%s`).\n", host, user, pass, db);
	} else {
		printf("Successfully connected with the database (`%s`, `%s`, `%s`, `%s`).\n", host, user, pass, db);
		DatabaseConnected = true;
	}

	if (!ServerInProduction) {
		mysql_log(DEBUG);
	}

	new temp[128];
    format(temp, sizeof(temp),"UPDATE `accounts` SET `account_online` = '0' WHERE 1=1");
	mysql_query(Database, temp, false);
	print("All Accounts have been set offline in the database.\n");

	loadHouses(0);

	loadClans(0);

	loadTurfs(0);

	UPDATE_BIZ_COOLDOWN = gettime();
	loadBiz(0);

	playerData_init(-1);
	print("Initialized a clear player data.\n");

	serverTime(1);
	
	serverIntervalID = SetTimer("serverInterval", 50, true);

	SetTimer("initRac", 1000 * 10, false); // For Server Car's Fuel

	if (GetPlayerPoolSize() == 0 && !IsPlayerConnected(0))
	{
		print("No players found online.\n");
	} else {
		printf("There are players online. Highest ID: %d\n", GetPlayerPoolSize());

		for(new playerid = 0, j = GetPlayerPoolSize(); playerid <= j; playerid++) {
			SetPlayerHealth(playerid, 0);

			playerData_init(playerid);

			GetPlayerName(playerid, playerData[playerid][account_name], MAX_PLAYER_NAME);
			
			// No more active, since clan tags
			// SetTimerEx("setNameAFK", 1000, 0, "ii", playerid, 1);

			SendClientMessage(playerid, COLOR_SERVER, "Welcome to Greek Roleplay Server.");

			new ORM:ormid = playerData[playerid][ORM_ID] = orm_create("accounts");

			assignORM(playerid);

			orm_setkey(ormid, "account_name");
			orm_select(ormid, "connectPlayer", "d", playerid);

			SetPlayerColor(playerid, 0xFFFFFFFF);

			SetPlayerHealth(playerid, 999999);

			PlayerPlaySound(playerid, 1, 0.0,0.0,0.0); // Stops the wind
			PlayerPlaySound(playerid, 176, 0.0,0.0,0.0); // SA Intro
		}

	}

	PaintballTextdraw0 = TextDrawCreate(311.000000, 380.000000, "Remaining Time: 600 sec");
	TextDrawAlignment(PaintballTextdraw0, 2);
	TextDrawBackgroundColor(PaintballTextdraw0, 255);
	TextDrawFont(PaintballTextdraw0, 2);
	TextDrawLetterSize(PaintballTextdraw0, 0.240000, 1.500000);
	TextDrawColor(PaintballTextdraw0, -1);
	TextDrawSetOutline(PaintballTextdraw0, 1);
	TextDrawSetProportional(PaintballTextdraw0, 1);
	TextDrawSetSelectable(PaintballTextdraw0, 0);

	PaintballTextdraw1 = TextDrawCreate(312.000000, 394.000000, "WINNER: SOUVLAKI (4 Kills)");
	TextDrawAlignment(PaintballTextdraw1, 2);
	TextDrawBackgroundColor(PaintballTextdraw1, 255);
	TextDrawFont(PaintballTextdraw1, 2);
	TextDrawLetterSize(PaintballTextdraw1, 0.280000, 1.600000);
	TextDrawColor(PaintballTextdraw1, -1);
	TextDrawSetOutline(PaintballTextdraw1, 1);
	TextDrawSetProportional(PaintballTextdraw1, 1);
	TextDrawSetSelectable(PaintballTextdraw1, 0);



	BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_x] = 315.4268;
	BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_y] = -142.1427;
	BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_z] = 999.6016;
	BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_a] = 0.9421;
	BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_interior] = 7;
	format(BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_name], 32, "Gun Shop");

	BIZ_INTERIORS[BIZ_TYPE_BANKLS][bi_x] = 2315.952880;
	BIZ_INTERIORS[BIZ_TYPE_BANKLS][bi_y] = -1.618174;
	BIZ_INTERIORS[BIZ_TYPE_BANKLS][bi_z] = 26.742187;
	BIZ_INTERIORS[BIZ_TYPE_BANKLS][bi_a] = 0.9421;
	BIZ_INTERIORS[BIZ_TYPE_BANKLS][bi_interior] = 0;
	format(BIZ_INTERIORS[BIZ_TYPE_BANKLS][bi_name], 32, "Bank Los Santos");

	BIZ_INTERIORS[BIZ_TYPE_BANKSF][bi_x] = 2315.952880;
	BIZ_INTERIORS[BIZ_TYPE_BANKSF][bi_y] = -1.618174;
	BIZ_INTERIORS[BIZ_TYPE_BANKSF][bi_z] = 26.742187;
	BIZ_INTERIORS[BIZ_TYPE_BANKSF][bi_a] = 0.9421;
	BIZ_INTERIORS[BIZ_TYPE_BANKSF][bi_interior] = 0;
	format(BIZ_INTERIORS[BIZ_TYPE_BANKSF][bi_name], 32, "Bank San Fierro");

	BIZ_INTERIORS[BIZ_TYPE_FASTFOOD1][bi_x] = 364.3727;
	BIZ_INTERIORS[BIZ_TYPE_FASTFOOD1][bi_y] = -74.0874;
	BIZ_INTERIORS[BIZ_TYPE_FASTFOOD1][bi_z] = 1001.5078;
	BIZ_INTERIORS[BIZ_TYPE_FASTFOOD1][bi_a] = 299.6965;
	BIZ_INTERIORS[BIZ_TYPE_FASTFOOD1][bi_interior] = 10;
	format(BIZ_INTERIORS[BIZ_TYPE_FASTFOOD1][bi_name], 32, "Burger Shot");
	
	BIZ_INTERIORS[BIZ_TYPE_247_1][bi_x] = -25.884498;
	BIZ_INTERIORS[BIZ_TYPE_247_1][bi_y] = -185.868988;
	BIZ_INTERIORS[BIZ_TYPE_247_1][bi_z] = 1003.546875;
	BIZ_INTERIORS[BIZ_TYPE_247_1][bi_a] = 299.6965;
	BIZ_INTERIORS[BIZ_TYPE_247_1][bi_interior] = 17;
	format(BIZ_INTERIORS[BIZ_TYPE_247_1][bi_name], 32, "24/7");

	BIZ_INTERIORS[BIZ_TYPE_CLUB][bi_x] = 493.390991;
	BIZ_INTERIORS[BIZ_TYPE_CLUB][bi_y] = -22.722799;
	BIZ_INTERIORS[BIZ_TYPE_CLUB][bi_z] = 1000.679687;
	BIZ_INTERIORS[BIZ_TYPE_CLUB][bi_a] = 299.6965;
	BIZ_INTERIORS[BIZ_TYPE_CLUB][bi_interior] = 17;
	format(BIZ_INTERIORS[BIZ_TYPE_CLUB][bi_name], 32, "Alhambra Club");

	format(BIZ_INTERIORS[BIZ_TYPE_CLOTHES][bi_name], 32, "Clothes Shop");

	format(BIZ_INTERIORS[BIZ_TYPE_PAINTBALL][bi_name], 32, "Paintball");

	format(BIZ_INTERIORS[BIZ_TYPE_GASSTATION][bi_name], 32, "Gas Station");

	
	CreateDynamic3DTextLabel("/exit", 0xA6E9FFFF, 315.4268,-142.1427,999.6016, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);
	CreateDynamic3DTextLabel("/enter", 0xA6E9FFFF, 305.7246,-141.9838,1004.0547, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);
	CreateDynamic3DTextLabel("/exit", 0xA6E9FFFF, 303.5598,-141.6759,1004.0625, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);
	CreateDynamic3DTextLabel("/enter", 0xA6E9FFFF, 300.0557,-141.8702,1004.0625, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);
	CreateDynamic3DTextLabel("/exit", 0xA6E9FFFF, 298.9916,-141.8995,1004.0547, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);


	CreateDynamic3DTextLabel("/getmaterials", 0xA6E9FFFF, 2770.7419,-1628.3348,12.1775, 10.0);
	CreatePickup(1239, 1, 2770.7419,-1628.3348,12.1775, 0);
	CreateDynamic3DTextLabel("/delivermaterials", 0xA6E9FFFF, 1712.9161,913.1354,10.8203, 10.0);
	CreatePickup(1239, 1, 1712.9161,913.1354,10.8203, 0);


	SPAWN_CIVIL_CARS[0] = CreateVehicle(510,1809.2808,-1867.0035,13.1810,357.8989,46,46, 300); // bike start
	SPAWN_CIVIL_CARS[1] = CreateVehicle(509,1807.1936,-1866.9532,13.0836,1.0040,61,1, 300); // bike start
	SPAWN_CIVIL_CARS[2] = CreateVehicle(481,1793.1426,-1866.9518,13.0862,358.7024,3,3, 300); // bike start
	SPAWN_CIVIL_CARS[3] = CreateVehicle(481,1791.7391,-1867.0018,13.0839,2.8081,6,6, 300); // bike start
	SPAWN_CIVIL_CARS[4] = CreateVehicle(509,1790.4320,-1866.9374,13.0832,357.0405,74,1, 300); // bike start
	SPAWN_CIVIL_CARS[5] = CreateVehicle(462,1798.6040,-1846.7732,13.1742,319.7916,14,14, 300); // faggio start
	SPAWN_CIVIL_CARS[6] = CreateVehicle(462,1796.3966,-1846.4872,13.1757,312.9067,13,13, 300); // faggio start
	SPAWN_CIVIL_CARS[7] = CreateVehicle(516,1758.7454,-1860.4858,13.3260,271.8540,119,1, 300); // car start
	SPAWN_CIVIL_CARS[8] = CreateVehicle(527,1785.1792,-1824.3978,13.1876,71.7477,53,1, 300); // car start
	SPAWN_CIVIL_CARS[9] = CreateVehicle(512,1788.9985,-2647.7087,13.8294,10.5334,15,123, 300); // 512 plane
	SPAWN_CIVIL_CARS[10] = CreateVehicle(519,2026.3856,-2494.0479,14.4610,90.4303,1,1, 300); // shamal plane
	SPAWN_CIVIL_CARS[11] = CreateVehicle(558,1523.8905,-1629.7168,13.0917,180.7377,-1,-1, 300); // car uranus pd
	SPAWN_CIVIL_CARS[12] = CreateVehicle(585,1523.7211,-1681.2428,13.0507,180.9176,-1,-1, 300); // car another pd
	SPAWN_CIVIL_CARS[13] = CreateVehicle(549,1077.8789,-1772.5380,13.0484,89.5675,-1,-1, 300); // tampa paintball
	SPAWN_CIVIL_CARS[14] = CreateVehicle(551,1084.1866,-1760.7977,13.1751,269.6954,-1,-1, 300); // car paintball
	SPAWN_CIVIL_CARS[15] = CreateVehicle(511,-1630.1243,-137.0746,15.5177,315.7511,-1,-1, 300); // plain sf
	SPAWN_CIVIL_CARS[16] = CreateVehicle(513,-1370.6370,68.4547,15.0889,21.8104,-1,-1, 300); // plain sf

	SPAWN_TAXI_CARS[0] = CreateVehicle(420,1799.5483,-1932.3701,13.1657,359.9643,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[1] = CreateVehicle(420,1792.4320,-1932.3826,13.1671,0.2926,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[2] = CreateVehicle(420,1785.2406,-1932.1494,13.1676,0.0172,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[3] = CreateVehicle(420,1778.0653,-1932.2455,13.1670,0.0615,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[4] = CreateVehicle(420,1777.5765,-1919.2874,13.1663,270.1472,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[5] = CreateVehicle(420,1777.7185,-1909.8383,13.1670,270.4143,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[6] = CreateVehicle(438,1777.2858,-1901.4611,13.3900,270.9780,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[7] = CreateVehicle(438,1803.5602,-1919.4237,13.3876,90.4931,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[8] = CreateVehicle(438,1803.6678,-1909.4045,13.4024,90.6074,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[9] = CreateVehicle(438,1803.6718,-1901.0190,13.4059,90.9325,6,1, 300); // taxi starts
	SPAWN_TAXI_CARS[10] = CreateVehicle(560,1792.9136,-1884.9640,13.1862,269.4929,1,0, 300); // taxi sultan
	SPAWN_TAXI_CARS[11] = CreateVehicle(560,1802.8011,-1885.1006,13.1934,269.5790,1,0, 300); // taxi sultan


	new taxiTag1 = CreateObject(19308, 0, 0, 0, 0.0000, 0.0000, 359.4038); //taxi tag over
	new taxiTag2 = CreateObject(19308, 0, 0, 0, 0.0000, 0.0000, 359.4038); //taxi tag over

	AttachObjectToVehicle(taxiTag1, SPAWN_TAXI_CARS[10], 0.0199, -0.1599, 0.9399, 0.0000, 0.0000, 267.0100);
	AttachObjectToVehicle(taxiTag2, SPAWN_TAXI_CARS[11], 0.0199, -0.1599, 0.9399, 0.0000, 0.0000, 267.0100);


	SPAWN_PARAMEDICS_CARS[0] = CreateVehicle(416,1190.2482,-1359.8915,13.6145,179.0802,1,3, 300); // paramedics cars start
	SPAWN_PARAMEDICS_CARS[1] = CreateVehicle(416,1181.4156,-1339.0280,13.8783,270.6177,1,3, 300); // paramedics cars start
	SPAWN_PARAMEDICS_CARS[2] = CreateVehicle(416,1180.7607,-1308.3082,13.8487,269.5818,1,3, 300); // paramedics cars start
	SPAWN_PARAMEDICS_CARS[3] = CreateVehicle(417,1179.5963,-1376.2332,24.1216,178.9038,0,0, 300); // paramedics cars start heli

	SPAWN_LSPD_CARS[0] = CreateVehicle(599,1558.8359,-1710.3641,6.0806,356.7947,0,1, 300); // pd
	SPAWN_LSPD_CARS[1] = CreateVehicle(599,1595.5363,-1710.4030,6.0791,359.1125,0,1, 300); // pd
	SPAWN_LSPD_CARS[2] = CreateVehicle(599,1529.3362,-1687.9736,6.0782,269.0895,0,1, 300); // pd
	SPAWN_LSPD_CARS[3] = CreateVehicle(596,1587.3986,-1709.9915,5.6117,358.6431,0,1, 300); // pd
	SPAWN_LSPD_CARS[4] = CreateVehicle(596,1583.3983,-1710.1194,5.6123,0.1490,0,1, 300); // pd
	SPAWN_LSPD_CARS[5] = CreateVehicle(596,1578.5043,-1710.3064,5.6121,0.1151,0,1, 300); // pd
	SPAWN_LSPD_CARS[6] = CreateVehicle(523,1566.9943,-1712.0258,5.4605,358.6877,0,0, 300); // pd
	SPAWN_LSPD_CARS[7] = CreateVehicle(523,1565.3962,-1711.9709,5.4595,359.8462,0,0, 300); // pd
	SPAWN_LSPD_CARS[8] = CreateVehicle(523,1563.1996,-1712.1223,5.4622,0.9577,0,0, 300); // pd
	SPAWN_LSPD_CARS[9] = CreateVehicle(411,1535.6647,-1677.3761,13.1099,0.7192,1,1, 300, 1); // pd
	SPAWN_LSPD_CARS[10] = CreateVehicle(411,1535.8024,-1668.7988,13.1099,359.2820,1,1, 300, 1); // pd
	SPAWN_LSPD_CARS[11] = CreateVehicle(497,1550.1667,-1643.7217,28.5790,92.8140,-1,-1, 300); // heli
	SPAWN_LSPD_CARS[12] = CreateVehicle(520,1566.0411,-1649.2850,29.1270,0.8537,-1,-1, 300); // hydra

	new sirena1 = CreateObject(19419, 0, 0, 0, 0, 0, 0, 0);
	new sirena2 = CreateObject(19419, 0, 0, 0, 0, 0, 0, 0);
	new policecar1 = CreateObject(19327, 0, 0, 0, 0, 0, 0);
	new policecar2 = CreateObject(19327, 0, 0, 0, 0, 0, 0);

	SetObjectMaterialText(policecar1, "POLICE", 0, 50, "Arial", 25, 1, -16777216, 0, 1);
	SetObjectMaterialText(policecar2, "POLICE", 0, 50, "Arial", 25, 1, -16777216, 0, 1);

	AttachObjectToVehicle(sirena1, SPAWN_LSPD_CARS[9], 0.0, 0.0, 0.7, 0.0, 0.0, 0.0);
	AttachObjectToVehicle(policecar1, SPAWN_LSPD_CARS[9], 0.0, -1.9, 0.3, 270.0, 0.0, 0.0);
	AttachObjectToVehicle(sirena2, SPAWN_LSPD_CARS[10], 0.0, 0.0, 0.7, 0.0, 0.0, 0.0);
	AttachObjectToVehicle(policecar2, SPAWN_LSPD_CARS[10], 0.0, -1.9, 0.3, 270.0, 0.0, 0.0);


	SPAWN_HITMAN_CARS[0] = CreateVehicle(489,783.5194,-1337.3409,13.6829,90.5267,0,0, 300); // hitman cars, rancher
	SPAWN_HITMAN_CARS[1] = CreateVehicle(489,783.5165,-1343.0583,13.6834,90.1046,0,0, 300); // hitman cars, rancher
	SPAWN_HITMAN_CARS[2] = CreateVehicle(489,783.7252,-1348.4479,13.6843,90.7987,0,0, 300); // hitman cars, rancher
	SPAWN_HITMAN_CARS[3] = CreateVehicle(468,757.2678,-1367.9520,13.1846,273.0517,0,0, 300); // hitman cars, sanchez
	SPAWN_HITMAN_CARS[4] = CreateVehicle(468,756.9948,-1364.8799,13.1834,270.8706,0,0, 300); // hitman cars, sanchez
	SPAWN_HITMAN_CARS[5] = CreateVehicle(468,756.8773,-1362.0018,13.1838,274.8133,0,0, 300); // hitman cars, sanchez
	SPAWN_HITMAN_CARS[6] = CreateVehicle(459,750.6031,-1355.1437,13.5506,359.0629,0,0, 300); // hitman cars, van
	SPAWN_HITMAN_CARS[7] = CreateVehicle(459,743.4319,-1355.0560,13.5580,0.5305,0,0, 300); // hitman cars, van
	SPAWN_HITMAN_CARS[8] = CreateVehicle(459,736.6736,-1336.6360,13.5872,269.2946,0,0, 300); // hitman cars, van
	SPAWN_HITMAN_CARS[9] = CreateVehicle(487,740.9434,-1366.5110,25.8691,269.3624,0,1, 300); // hitman cars, heli

	FARMER_CARS[0] = CreateVehicle(532,-382.5790,-1476.6251,26.7027,278.9648,0,0, 5); // farmer car
	FARMER_CARS[1] = CreateVehicle(532,-401.4457,-1460.7012,26.7026,264.3109,0,0, 5); // farmer car
	FARMER_CARS[2] = CreateVehicle(532,-408.8918,-1473.9177,26.6328,102.4780,0,0, 5); // farmer car
	FARMER_CARS[3] = CreateVehicle(532,-409.1371,-1437.3821,26.6435,104.4660,0,0, 5); // farmer car


	//PARAMEDICS STAIRS FOR HELI
	CreateObject(8613, 1178.14233, -1363.44214, 17.48772,   0.00000, 0.00000, 179.64017);


	//LSPD HELICOPTER OBJECTS
	CreateObject(3934, 1548.36584, -1643.75793, 27.43287,   0.00000, 0.00000, -0.12000);
	CreateObject(1237, 1544.77380, -1622.27820, 12.40683,   0.00000, 0.00000, 0.00000);
	CreateObject(1237, 1544.85339, -1620.38794, 12.40683,   0.00000, 0.00000, 0.00000);
	CreateObject(1237, 1544.79382, -1618.48572, 12.40683,   0.00000, 0.00000, 0.00000);
	CreateObject(1237, 1544.33740, -1634.51575, 12.40683,   0.00000, 0.00000, 0.00000);
	CreateObject(3399, 1570.46924, -1636.12134, 25.14556,   0.00000, 0.00000, 0.90001);
	CreateObject(3399, 1558.74524, -1636.26477, 20.51881,   0.00000, 0.00000, 0.90001);
	CreateObject(3399, 1547.21484, -1636.44678, 15.57663,   -0.12000, -3.12000, 0.90001);
	PARKING_GATE = CreateObject(968, 1544.71936, -1630.93188, 13.07240,   0.00000, -90.00000, -89.70010);



	//PRISON LS
	CreateObject(8399, 1556.08142, -1664.09326, -20.06862,   0.00000, 0.00000, 0.00000);
	CreateObject(19911, 1547.80237, -1650.13281, -12.24236,   0.00000, 0.00000, 0.00000);
	CreateObject(19911, 1547.78442, -1659.56775, -12.24236,   0.00000, 0.00000, 0.00000);
	CreateObject(19911, 1547.76355, -1668.92468, -12.24236,   0.00000, 0.00000, 0.00000);
	CreateObject(19911, 1551.74963, -1671.40857, -12.24236,   0.00000, 0.00000, 89.76001);
	CreateObject(19911, 1561.31750, -1671.44189, -12.24236,   0.00000, 0.00000, 89.76001);
	CreateObject(19911, 1565.19031, -1666.62769, -12.24236,   0.00000, 0.00000, 180.18007);
	CreateObject(19911, 1565.13391, -1657.09888, -12.24236,   0.00000, 0.00000, 180.18007);
	CreateObject(19911, 1565.07544, -1647.51270, -12.24236,   0.00000, 0.00000, 180.18007);
	CreateObject(19911, 1560.41577, -1645.27551, -12.24236,   0.00000, 0.00000, 270.60016);
	CreateObject(19911, 1551.09424, -1645.35864, -12.24236,   0.00000, 0.00000, 270.60016);
	CreateObject(19825, 1555.60938, -1645.43591, -10.24646,   0.00000, 0.00000, 0.00000);
	CreateObject(2921, 1564.77771, -1645.19202, -10.76671,   0.00000, 0.00000, 78.89995);
	CreateObject(2921, 1565.25671, -1670.91345, -10.29015,   0.00000, 0.00000, -19.26006);
	CreateObject(19447, 1549.03650, -1651.50378, -13.78957,   0.00000, 0.00000, 90.60003);
	CreateObject(19447, 1548.90442, -1657.75500, -13.78957,   0.00000, 0.00000, 90.60003);
	CreateObject(19447, 1548.89844, -1664.29187, -13.78957,   0.00000, 0.00000, 90.60003);
	CreateObject(19447, 1548.89844, -1664.29187, -10.32989,   0.00000, 0.00000, 90.60003);
	CreateObject(19447, 1548.90442, -1657.75500, -10.34036,   0.00000, 0.00000, 90.60003);
	CreateObject(19447, 1549.03650, -1651.50378, -10.34122,   0.00000, 0.00000, 90.60003);
	CreateObject(1771, 1549.18481, -1650.60474, -14.79313,   0.00000, 0.00000, -89.21998);
	CreateObject(1771, 1549.25952, -1656.93494, -14.79313,   0.00000, 0.00000, -89.21998);
	CreateObject(1771, 1549.31653, -1663.45801, -14.79313,   0.00000, 0.00000, -89.21998);
	CreateObject(1771, 1549.28955, -1670.55823, -14.79313,   0.00000, 0.00000, -89.21998);
	CreateObject(2602, 1548.21619, -1645.99817, -14.47568,   0.00000, 0.00000, 89.10005);
	CreateObject(2602, 1548.21033, -1652.64478, -14.47568,   0.00000, 0.00000, 89.10005);
	CreateObject(2602, 1548.20361, -1658.77393, -14.47568,   0.00000, 0.00000, 89.10005);
	CreateObject(2602, 1548.14270, -1665.37366, -14.47568,   0.00000, 0.00000, 89.10005);
	CreateObject(19836, 1550.77039, -1665.90686, -15.31673,   0.00000, 0.00000, 0.00000);
	CreateObject(19836, 1551.34058, -1666.11328, -15.31673,   0.00000, 0.00000, 0.00000);
	CreateObject(19836, 1551.05042, -1659.40515, -15.31673,   0.00000, 0.00000, 0.00000);
	CreateObject(19836, 1551.52271, -1660.07654, -15.31673,   0.00000, 0.00000, 0.00000);
	CreateObject(19836, 1551.06274, -1653.19543, -15.31673,   0.00000, 0.00000, 0.00000);
	CreateObject(19836, 1551.89160, -1653.92090, -15.31673,   0.00000, 0.00000, 0.00000);
	CreateObject(19836, 1550.81677, -1647.16736, -15.31673,   0.00000, 0.00000, 0.00000);
	CreateObject(19836, 1551.65063, -1647.83765, -15.31673,   0.00000, 0.00000, 0.00000);
	CreateObject(11710, 1564.96350, -1647.77795, -12.47387,   0.00000, 0.00000, -89.52000);
	CreateObject(366, 1564.69250, -1645.38635, -14.75218,   1.32000, 39.42002, 0.00000);
	CreateObject(366, 1564.46460, -1645.38904, -14.75218,   1.32000, 39.42002, 0.00000);
	CreateObject(2690, 1564.84021, -1645.72351, -15.06298,   0.00000, 0.00000, 0.00000);
	CreateObject(2961, 1564.61560, -1645.31970, -13.28260,   0.00000, 0.00000, 0.00000);
	CreateObject(11714, 1565.00232, -1647.73010, -14.11808,   0.00000, 0.00000, 0.00000);
	CreateObject(3034, 1565.02393, -1652.56128, -13.42655,   0.00000, 0.00000, -89.64003);
	CreateObject(3034, 1565.07263, -1657.05859, -13.42655,   0.00000, 0.00000, -89.64003);
	CreateObject(3034, 1565.07678, -1661.45386, -13.42655,   0.00000, 0.00000, -89.64003);
	CreateObject(3034, 1565.07654, -1665.93958, -13.42655,   0.00000, 0.00000, -89.64003);
	CreateObject(8399, 1556.03906, -1652.70337, -4.90671,   -180.96008, -0.84001, -0.06000);
	CreateObject(2357, 1559.62195, -1665.29614, -14.91658,   0.00000, 0.00000, 0.00000);
	CreateObject(2357, 1559.59045, -1661.24768, -14.91658,   0.00000, 0.00000, 0.00000);
	CreateObject(2357, 1559.57178, -1656.21265, -14.91658,   0.00000, 0.00000, 0.00000);
	CreateObject(946, 1559.42993, -1646.11755, -14.16315,   0.00000, 0.00000, 183.30008);
	CreateObject(1946, 1559.04639, -1645.65649, -15.21438,   0.00000, 0.00000, 0.00000);
	CreateObject(19303, 1553.71875, -1665.18042, -14.05545,   0.00000, 0.00000, 92.21999);
	CreateObject(19303, 1553.79114, -1666.85974, -14.05545,   0.00000, 0.00000, 92.21999);
	CreateObject(19303, 1553.94458, -1670.51855, -14.05545,   0.00000, 0.00000, 272.04022);
	CreateObject(19303, 1553.68079, -1663.28394, -14.05545,   0.00000, 0.00000, 269.88031);
	CreateObject(19303, 1553.62415, -1658.63977, -14.05545,   0.00000, 0.00000, 451.56018);
	CreateObject(19303, 1553.69055, -1661.58313, -14.05545,   0.00000, 0.00000, 269.88031);
	CreateObject(19303, 1553.63660, -1656.77893, -14.05545,   0.00000, 0.00000, 630.17993);
	CreateObject(19303, 1553.72668, -1652.42029, -14.05545,   0.00000, 0.00000, 809.81934);
	CreateObject(19303, 1553.71265, -1654.12146, -14.05545,   0.00000, 0.00000, 809.81934);
	CreateObject(19303, 1553.75708, -1650.54016, -14.05545,   0.00000, 0.00000, 989.39783);
	CreateObject(19303, 1553.78223, -1648.86035, -14.05545,   0.00000, 0.00000, 989.39783);
	CreateObject(19303, 1553.79309, -1646.20142, -14.05545,   0.00000, 0.00000, 1170.17981);


	//Door to Prison
	CreateObject(11714, 1564.94092, -1667.29614, 28.60782,   0.00000, 0.00000, 90.06001);



	/*CreatePickup(1239, 1, 1109.8433,-1796.7095,16.5938, 0);
	Create3DTextLabel("{FFFFFF}Paintball - Free for all\nUse {A6E9FF}/paintball {FFFFFF}to join.", 0xFFFFFFFF, 1109.8433,-1796.7095,16.5938, 20.0, 0, 1);*/

	CreatePickup(1239, 1, 1564.9336,-1666.5422,28.3956, 0);
	Create3DTextLabel("{FFFFFF}Prison\nUse {A6E9FF}/enter {FFFFFF}to get in.", 0xFFFFFFFF, 1564.9336,-1666.5422,28.3956, 40.0, 0, 1);

	CreatePickup(1239, 1, 1563.7126,-1647.6243,-14.3242, 0);
	Create3DTextLabel("{FFFFFF}LSPD Roof\nUse {A6E9FF}/exit {FFFFFF}to get out.", 0xFFFFFFFF, 1563.7126,-1647.6243,-14.3242, 40.0, 0, 1);
	
	/*CreatePickup(1239, 1, 1465.1649,-1051.1298,24.0156, 0);
	Create3DTextLabel("{FFFFFF}Bank LS\nUse {A6E9FF}/enter {FFFFFF}to get in.", 0xFFFFFFFF, 1465.1649,-1051.1298,24.0156, 40.0, 0, 1);
	
	CreatePickup(1239, 1, -2170.5684, 252.0390, 35.3347, 0);
	Create3DTextLabel("{FFFFFF}Bank SF\nUse {A6E9FF}/enter {FFFFFF}to get in.", 0xFFFFFFFF, -2170.5684, 252.0390, 35.3347, 40.0, 0, 1);*/

	CreatePickup(1239, 1, -1966.5516,293.9211,35.4688, 0);
	Create3DTextLabel("{FFFFFF}Car Shop\nUse {A6E9FF}/buycar {FFFFFF}to buy a car.", 0xFFFFFFFF, -1966.5516,293.9211,35.4688, 40.0, 0, 1);


	// LSPD
	CreateDynamicMapIcon(1553.4355,-1675.1517,16.1953, 30, 0, 0, 0);

	// Hitman
	CreateDynamicMapIcon(734.2955,-1355.4347,15.1563, 23, 0, 0, 0);

	// Taxi
	CreateDynamicMapIcon(1754.2646,-1894.3219,13.5570, 56, 0, 0, 0);

	// Paramedics
	CreateDynamicMapIcon(1177.4180,-1324.2224,14.0697, 22, 0, 0, 0);

	// Paintball
	// CreateDynamicMapIcon(1109.8433,-1796.7095,16.5938, 6, 0, 0, 0);
	
	// Bank LS
	// CreateDynamicMapIcon(1465.1649,-1051.1298,24.0156, 52, 0, 0, 0);

	// Bank SF
	// CreateDynamicMapIcon(-2170.5684, 252.0390, 35.3347, 52, 0, 0, 0);

	// PayNSpray, Transfender in LS
	CreateDynamicMapIcon(487.6313,-1736.9135,11.1244, 63, 0, 0, 0);
	CreateDynamicMapIcon(1024.9147,-1027.2291,32.1016, 63, 0, 0, 0);
	CreateDynamicMapIcon(1041.4126,-1026.4100,32.1016, 63, 0, 0, 0); // transfender
	CreateDynamicMapIcon(2067.5195,-1831.4760,13.5469, 63, 0, 0, 0); // transfender
	CreateDynamicMapIcon(2644.6111,-2038.8057,13.5500, 63, 0, 0, 0); // transfender
	CreateDynamicMapIcon(720.4619,-459.1967,15.9449, 63, 0, 0, 0); // transfender
	CreateDynamicMapIcon(-1903.2355,282.1736,40.8002, 63, 0, 0, 0); // respray icon
	CreateDynamicMapIcon(-1935.9620,238.9442,34.1395, 63, 0, 0, 0); // transfender icon
	CreateDynamicMapIcon(-2713.2739,217.7508,4.0148, 63, 0, 0, 0); // arch icon

	// Buycar SF
	CreateDynamicMapIcon(-1966.5516,293.9211,35.4688, 55, 0, 0, 0);

	// Quest Init
	for (new i = 0; i < sizeof(QUESTPOINTS); i++) {
		//QUESTPOINTS[i][3] = float(CreateDynamicPickup(1247, 1, QUESTPOINTS[i][0], QUESTPOINTS[i][1], QUESTPOINTS[i][2]));
	}

	#if defined create_greek_flag
		create_greek_flag();
	#endif


	new DM_Forest_Objs;
    DM_Forest_Objs = CreateDynamicObject(18753,1857.966,3151.175,111.647,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    SetDynamicObjectMaterial(DM_Forest_Objs, 0, 10101, "2notherbuildsfe", "Bow_church_grass_alt", 0x00000000);
    DM_Forest_Objs = CreateDynamicObject(16118,1815.499,3092.869,110.227,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1893.557,3092.869,110.227,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1854.029,3092.869,110.227,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1915.923,3114.800,110.227,0.000,0.000,180.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1915.923,3153.941,110.227,0.000,0.000,180.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1916.383,3198.160,110.227,0.000,0.000,180.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1888.893,3198.160,110.227,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1850.025,3198.160,110.227,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1811.065,3198.160,110.227,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1791.296,3171.652,110.227,0.000,0.000,360.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1791.296,3132.901,110.227,0.000,0.000,360.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16118,1791.296,3094.131,110.227,0.000,0.000,360.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19909,1809.662,3123.444,112.127,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19909,1898.848,3154.929,112.127,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19909,1899.269,3169.323,112.127,0.000,0.000,180.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(3414,1897.490,3124.854,114.287,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19843,1891.563,3119.516,113.907,90.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19843,1891.563,3120.517,113.907,90.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19843,1891.563,3121.518,113.907,90.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19843,1891.573,3121.518,114.807,90.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19843,1891.573,3120.517,114.807,90.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19843,1891.573,3119.516,114.807,90.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(19909,1810.083,3137.832,112.127,0.000,0.000,180.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(3279,1812.102,3159.954,112.147,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(3279,1897.688,3111.813,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(1501,1856.225,3128.866,112.757,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(655,1846.249,3145.295,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(655,1870.759,3164.505,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(655,1828.319,3171.834,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(655,1821.899,3111.342,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(655,1886.219,3180.368,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1888.923,3131.463,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1876.914,3148.615,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1859.473,3180.316,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1864.814,3139.664,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1837.143,3135.465,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1863.193,3153.655,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1816.683,3176.747,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1831.021,3114.926,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1863.342,3106.808,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1870.344,3178.217,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1854.793,3163.472,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1853.896,3141.983,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3138.070,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3137.030,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3135.950,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3136.400,112.357,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3137.441,112.357,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3138.302,112.377,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3137.951,112.587,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3136.830,112.587,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3138.151,112.787,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3137.060,112.787,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1864.882,3137.561,112.957,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3136.320,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3137.301,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3138.341,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3139.382,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3138.942,112.327,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3137.891,112.327,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3136.861,112.327,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3135.719,112.327,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.610,3136.350,112.497,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.630,3137.401,112.497,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.630,3138.472,112.497,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.630,3138.021,112.647,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.630,3136.941,112.647,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.630,3135.920,112.647,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.630,3136.460,112.827,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2060,1837.630,3137.572,112.827,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(2669,1838.510,3187.089,113.447,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(17005,1851.106,3121.150,119.877,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(656,1829.104,3160.028,112.147,0.000,0.000,0.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1839.876,3172.964,112.147,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1839.876,3174.265,112.147,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1839.876,3174.265,113.067,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1839.876,3172.964,113.067,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1839.886,3175.587,112.147,0.000,0.000,270.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1888.162,3143.422,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1888.162,3144.723,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1888.162,3146.054,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1886.861,3146.054,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1886.861,3144.733,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1886.861,3143.422,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1886.861,3143.422,113.067,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1886.861,3144.733,113.067,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1886.861,3146.054,113.067,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1888.172,3146.054,113.067,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(964,1886.861,3142.091,112.147,0.000,0.000,90.000,5,-1,-1,500.000,500.000);
    DM_Forest_Objs = CreateDynamicObject(16280,1850.700,3174.022,115.947,0.000,0.000,0.000,5,-1,-1,500.000,500.000);

	fillUpAllCars();

	print("Gamemode Greek Roleplay has been loaded.\n\n");

	return 1;
}

public OnGameModeExit()
{
	for(new playerid = 0, j = GetPlayerPoolSize(); playerid <= j; playerid++) {
		// No more active since clan tags.
		// setNameAFK(playerid, 0);
		savePlayerData(playerid);
		unloadPlayerVehicles(playerid)
	}

	new temp[128];
    format(temp, sizeof(temp),"UPDATE `accounts` SET `account_online` = '0' WHERE 1=1");
	mysql_query(Database, temp, false);
	print("All Accounts have been set offline in the database.\n");

	mysql_close(Database);
	print("Disconnected from the database.\n");

	KillTimer(serverIntervalID);
	serverTime(3);

	print("Gamemode Greek Roleplay has been unloaded.\n\n");
	return 1;
}

forward DelayedSpawn(playerid);
public DelayedSpawn(playerid)
{
	SpawnPlayer(playerid);
}

public OnPlayerRequestClass(playerid, classid)
{
	// SetTimerEx("SpawnPlayer", 1000, false, "i", playerid);
	// The dialog will spawn the player
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if (playerData[playerid][am_stream_camera] == 1) {
		return 1;
	}
	// Do not spawn, we have a timer.
	return 0;
}



public OnPlayerConnect(playerid)
{
	new temp[512];
	GetPlayerVersion(playerid, temp, sizeof(temp));
	if (strcmp("0.3.7-R4", temp, false) != 0 && false){
		SendClientMessage(playerid, COLOR_SERVER, "You are using an outdated version of SA:MP. Please install the latest version from our website.");
		SetTimerEx("DelayedKick", 1000, 0, "i", playerid);
		printf("Kick: Player %d had an outdated version %s.", playerid, temp);
	} else {

		playerData_init(playerid);

		GetPlayerName(playerid, playerData[playerid][account_name], MAX_PLAYER_NAME);

		if (!DatabaseConnected) {
			SendClientMessage(playerid, 0x7bafdcFF, "Please reconnect and try again later.");
			SetTimerEx("DelayedKick", 1000, 0, "i", playerid);
			printf("Kick: Player %s - Server is not ready yet.", playerData[playerid][account_name]);

			return 1;
		}

		GetPlayerIp(playerid, playerData[playerid][ip_address], 16);

		playerData[playerid][logged_timeout] = SetTimerEx("logged_timeout_callback", 30000, false, "i", playerid);


		anim_preload_anims(playerid);


		new timestamp = gettime();
		format(temp, sizeof(temp), "SELECT accounts.account_name, banned_ips.b_date, banned_ips.b_variable, banned_ips.b_reason FROM accounts, banned_ips WHERE accounts.account_id = banned_ips.b_admin AND banned_ips.b_ip='%s' AND (banned_ips.b_variable = 99 OR banned_ips.b_date >= %d - (banned_ips.b_variable * 8400))", playerData[playerid][ip_address], timestamp);
		mysql_tquery(Database, temp, "checkIPBan", "i", playerid);


		if (strcmp("stream_camera", playerData[playerid][account_name], false) == 0){
			if ((!isnull(STRM_CAMERA_IP) && !isnull(playerData[playerid][ip_address]) && strcmp(STRM_CAMERA_IP, playerData[playerid][ip_address], false) == 0) || !ServerInProduction){
				playerData[playerid][am_stream_camera] = 1;
				printf("Connected as Streaming Camera ip: %s. Excepted: %s", playerData[playerid][ip_address], STRM_CAMERA_IP);
				return 1;
			} else {
				printf("A player attempted to login as stream_camera but with wrong ip: %s. Excepted: %s", playerData[playerid][ip_address], STRM_CAMERA_IP);
				Kick(playerid);
			}
		}
		
		// No more active, since clan Tags.
		// SetTimerEx("setNameAFK", 1000, 0, "ii", playerid, 1);

		SendClientMessage(playerid, COLOR_SERVER, "Welcome to Greek Roleplay Server.");

		new ORM:ormid = playerData[playerid][ORM_ID] = orm_create("accounts");

		assignORM(playerid);

		orm_setkey(ormid, "account_name");
		orm_select(ormid, "connectPlayer", "d", playerid);

		SetPlayerColor(playerid, 0xFFFFFFFF);

		SetPlayerHealth(playerid, 999999);

		PlayerPlaySound(playerid, 1, 0.0,0.0,0.0); // Stops the wind
		PlayerPlaySound(playerid, 176, 0.0,0.0,0.0); // SA Intro

		playerData[playerid][wanted_3D] = Create3DTextLabel(" ", 0x00808000, 0.0, 0.0, 0.0, 40.0, 0, 1);
		Attach3DTextLabelToPlayer(playerData[playerid][wanted_3D], playerid, 0.0, 0.0, 0.7);

		// Quest Clear
		for (new i=0; i < sizeof(QUESTPOINTS); i++) {
			questData[playerid][i] = 0;
		}

		// Vending Machines
		//Los Santos and Countryside
    	RemoveBuildingForPlayer(playerid, 956, 1634.1487,-2238.2810,13.5077, 20.0); //Snack vender @ LS Airport
        RemoveBuildingForPlayer(playerid, 956, 2480.9885,-1958.5117,13.5831, 20.0); //Snack vender @ Sushi Shop in Willowfield
        RemoveBuildingForPlayer(playerid, 955, 1729.7935,-1944.0087,13.5682, 20.0); //Sprunk machine @ Unity Station
        RemoveBuildingForPlayer(playerid, 955, 2060.1099,-1898.4543,13.5538, 20.0); //Sprunk machine opposite Tony's Liqour in Willowfield
        RemoveBuildingForPlayer(playerid, 955, 2325.8708,-1645.9584,14.8270, 20.0); //Sprunk machine @ Ten Green Bottles
        RemoveBuildingForPlayer(playerid, 955, 1153.9130,-1460.8893,15.7969, 20.0); //Sprunk machine @ Market
        RemoveBuildingForPlayer(playerid, 955,1788.3965,-1369.2336,15.7578, 20.0); //Sprunk machine in Downtown Los Santos
        RemoveBuildingForPlayer(playerid, 955, 2352.9939,-1357.1105,24.3984, 20.0); //Sprunk machine @ Liquour shop in East Los Santos
        RemoveBuildingForPlayer(playerid, 1775, 2224.3235,-1153.0692,1025.7969, 20.0); //Sprunk machine @ Jefferson Motel
        RemoveBuildingForPlayer(playerid, 956, 2140.2566,-1161.7568,23.9922, 20.0); //Snack machine @ pick'n'go market in Jefferson
        RemoveBuildingForPlayer(playerid, 956, 2154.1199,-1015.7635,62.8840, 20.0); //Snach machine @ Carniceria El Pueblo in Las Colinas
        RemoveBuildingForPlayer(playerid, 956, 662.5665,-551.4142,16.3359, 20.0); //Snack vender at Dillimore Gas Station
        RemoveBuildingForPlayer(playerid, 955, 200.2010,-107.6401,1.5513, 20.0); //Sprunk machine @ Blueberry Safe House
        RemoveBuildingForPlayer(playerid, 956, 2271.4666,-77.2104,26.5824, 20.0); //Snack machine @ Palomino Creek Library
        RemoveBuildingForPlayer(playerid, 955, 1278.5421,372.1057,19.5547, 20.0); //Sprunk machine @ Papercuts in Montgomery
        RemoveBuildingForPlayer(playerid, 955, 1929.5527,-1772.3136,13.5469, 20.0); //Sprunk machine @ Idlewood Gas Station
       
        //San Fierro
        RemoveBuildingForPlayer(playerid, 1302, -2419.5835,984.4185,45.2969, 20.0); //Soda machine 1 @ Juniper Hollow Gas Station
        RemoveBuildingForPlayer(playerid, 1209, -2419.5835,984.4185,45.2969, 20.0); //Soda machine 2 @ Juniper Hollow Gas Station
        RemoveBuildingForPlayer(playerid, 956, -2229.2075,287.2937,35.3203, 20.0); //Snack vender @ King's Car Park
        RemoveBuildingForPlayer(playerid, 955, -1349.3947,493.1277,11.1953, 20.0); //Sprunk machine @ SF Aircraft Carrier
        RemoveBuildingForPlayer(playerid, 956, -1349.3947,493.1277,11.1953, 20.0); //Snack vender @ SF Aircraft Carrier
        RemoveBuildingForPlayer(playerid, 955, -1981.6029,142.7232,27.6875, 20.0); //Sprunk machine @ Cranberry Station
        RemoveBuildingForPlayer(playerid, 955, -2119.6245,-422.9411,35.5313, 20.0); //Sprunk machine 1/2 @ SF Stadium
        RemoveBuildingForPlayer(playerid, 955, -2097.3696,-397.5220,35.5313, 20.0); //Sprunk machine 3 @ SF Stadium
        RemoveBuildingForPlayer(playerid, 955, -2068.5593,-397.5223,35.5313, 20.0); //Sprunk machine 3 @ SF Stadium
        RemoveBuildingForPlayer(playerid, 955, -2039.8802,-397.5214,35.5313, 20.0); //Sprunk machine 3 @ SF Stadium
        RemoveBuildingForPlayer(playerid, 955, -2011.1403,-397.5225,35.5313, 20.0); //Sprunk machine 3 @ SF Stadium
        RemoveBuildingForPlayer(playerid, 955, -2005.7861,-490.8688,35.5313, 20.0); //Sprunk machine 3 @ SF Stadium
        RemoveBuildingForPlayer(playerid, 955, -2034.5267,-490.8681,35.5313, 20.0); //Sprunk machine 3 @ SF Stadium
        RemoveBuildingForPlayer(playerid, 955, -2063.1875,-490.8687,35.5313, 20.0); //Sprunk machine 3 @ SF Stadium
        RemoveBuildingForPlayer(playerid, 955, -2091.9780,-490.8684,35.5313, 20.0); //Sprunk machine 3 @ SF Stadium
       
        //Las Venturas
        RemoveBuildingForPlayer(playerid, 956, -1455.1298,2592.4138,55.8359, 20.0); //Snack vender @ El Quebrados GONE
        RemoveBuildingForPlayer(playerid, 955, -252.9574,2598.9048,62.8582, 20.0); //Sprunk machine @ Las Payasadas GONE
        RemoveBuildingForPlayer(playerid, 956, -252.9574,2598.9048,62.8582, 20.0); //Snack vender @ Las Payasadas GONE
        RemoveBuildingForPlayer(playerid, 956, 1398.7617,2223.3606,11.0234, 20.0); //Snack vender @ Redsands West GONE
        RemoveBuildingForPlayer(playerid, 955, -862.9229,1537.4246,22.5870, 20.0); //Sprunk machine @ The Smokin' Beef Grill in Las Barrancas GONE
        RemoveBuildingForPlayer(playerid, 955, -14.6146,1176.1738,19.5634, 20.0); //Sprunk machine @ Fort Carson GONE
        RemoveBuildingForPlayer(playerid, 956, -75.2839,1227.5978,19.7360, 20.0); //Snack vender @ Fort Carson GONE
        RemoveBuildingForPlayer(playerid, 955, 1519.3328,1055.2075,10.8203, 20.0); //Sprunk machine @ LVA Freight Department GONE
        RemoveBuildingForPlayer(playerid, 956, 1659.5096,1722.1096,10.8281, 20.0); //Snack vender near Binco @ LV Airport GONE
        RemoveBuildingForPlayer(playerid, 955, 2086.5872,2071.4958,11.0579, 20.0); //Sprunk machine @ Sex Shop on The Strip
        RemoveBuildingForPlayer(playerid, 955, 2319.9001,2532.0376,10.8203, 20.0); //Sprunk machine @ Pizza co by Julius Thruway (North)
        RemoveBuildingForPlayer(playerid, 955, 2503.2061,1244.5095,10.8203, 20.0); //Sprunk machine @ Club in the Camels Toe
        RemoveBuildingForPlayer(playerid, 956, 2845.9919,1294.2975,11.3906, 20.0); //Snack vender @ Linden Station
       
        //Interiors: 24/7 and Clubs
        RemoveBuildingForPlayer(playerid, 1775, 496.0843,-23.5310,1000.6797, 20.0); //Sprunk machine 1 @ Club in Camels Toe
        RemoveBuildingForPlayer(playerid, 1775, 501.1219,-2.1968,1000.6797, 20.0); //Sprunk machine 2 @ Club in Camels Toe
        RemoveBuildingForPlayer(playerid, 1776, 501.1219,-2.1968,1000.6797, 20.0); //Snack vender @ Club in Camels Toe
        RemoveBuildingForPlayer(playerid, 1775, -19.2299,-57.0460,1003.5469, 20.0); //Sprunk machine @ Roboi's type 24/7 stores
        RemoveBuildingForPlayer(playerid, 1776, -35.9012,-57.1345,1003.5469, 20.0); //Snack vender @ Roboi's type 24/7 stores
        RemoveBuildingForPlayer(playerid, 1775, -17.0036,-90.9709,1003.5469, 20.0); //Sprunk machine @ Other 24/7 stores
        RemoveBuildingForPlayer(playerid, 1776, -17.0036,-90.9709,1003.5469, 20.0); //Snach vender @ Others 24/7 stores


		skinSelector_init(playerid);

		buyCar_init(playerid);

		createTXDActiveReports(playerid);

		carInstrumentsCreate(playerid);

		// TXDLoadScreen_init(playerid);
		// PlayerTextDrawShow(playerid, playerData[playerid][loadScreen_txd]);


		TXDInfoMessage_init(playerid);


		playerData[playerid][sms_re] = -1;
		playerData[playerid][confiscate_by] = -1;
	}
	return 1;
}

forward logged_timeout_callback(playerid);
public logged_timeout_callback(playerid) {

	if (playerData[playerid][logged] == 0) {

		SendClientMessage(playerid, 0x7bafdcFF, "Please reconnect and try again later.");

		printf("Login Kick %s - Login timout.", playerData[playerid][account_name]);
		
		SetTimerEx("DelayedKick", 1000, 0, "i", playerid);

		playerData[playerid][logged_timeout] = 0;

	}

}

public OnPlayerDisconnect(playerid, reason)
{
	if (playerData[playerid][logged] == 1) {
		new temp[256];
		new temp2[3][] = {"Timeout/Crash", "Quit", "Kick/Ban"};
	
		format(temp, sizeof(temp), "%s (%d) is now offline (%s).", playerData[playerid][account_name], playerid, temp2[reason]);
		SendClientMessageToAll(COLOR_PUBLIC, temp);

		playerData[playerid][account_weekly_seconds] += playerData[playerid][account_activeSeconds] - playerData[playerid][weekly_seconds_temp];
		playerData[playerid][account_weekly_score] += playerData[playerid][account_score] - playerData[playerid][weekly_score_temp];

		playerData[playerid][account_online] = 0;

		format(playerData[playerid][reported_message], 105, "");

		savePlayerData(playerid);

		unloadPlayerVehicles(playerid);

		KillTimer(playerData[playerid][logged_timeout]);

		playerData[playerid][logged] = 0;

		Delete3DTextLabel(playerData[playerid][wanted_3D]);


		updateSpectators(playerid);
		


		// Skin selector
		skinSelector_destroy(playerid);

		//
		buyCar_destroy(playerid);

		//
		PlayerTextDrawDestroy(playerid, playerData[playerid][td_title]);
		PlayerTextDrawDestroy(playerid, playerData[playerid][td_version]);
		PlayerTextDrawDestroy(playerid, playerData[playerid][td_user]);

		//
		destroyTXDActiveReports(playerid);

		//
		carInstrumentsRemove(playerid)

		//
		// TXDLoadScreen_destroy(playerid);

		//
		TXDInfoMessage_destroy(playerid);

		playerData_init(playerid);
		

	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	ClearPlayerWeaponSafe(playerid);

	if (playerData[playerid][spec_mode] == 1) return 1;

	new temp_clanIndex = getClanIndex(playerid);

	if (playerData[playerid][account_skin] == -1) {

		SetPlayerInterior(playerid,11);
		SetPlayerPos(playerid,508.7362,-87.4335,998.9609);
		SetPlayerFacingAngle(playerid,0.0);
    	SetPlayerCameraPos(playerid,508.7362,-83.4335,998.9609);
		SetPlayerCameraLookAt(playerid,508.7362,-87.4335,998.9609);

		SetPlayerVirtualWorld(playerid, 1 + playerid);

		skinSelector_show(playerid);

	} else {

		if (playerData[playerid][am_stream_camera] == 1) {
			playerData[playerid][am_stream_camera] = 2;
		}

		playerData[playerid][special_interior] = 0;

		if (playerData[playerid][paintball_joined] == 1) {

			SetPlayerSkin(playerid, playerData[playerid][account_skin]);

			if (PAINTBALL_STATE == 3) {
				if (PAINTBALL_CURRENT_SPAWN_POINT >= sizeof(PAINTBALL_SPAWNS)) {
					PAINTBALL_CURRENT_SPAWN_POINT = 0;
				}
				SetPlayerPos(playerid, PAINTBALL_SPAWNS[PAINTBALL_CURRENT_SPAWN_POINT][0], PAINTBALL_SPAWNS[PAINTBALL_CURRENT_SPAWN_POINT][1], PAINTBALL_SPAWNS[PAINTBALL_CURRENT_SPAWN_POINT][2]);
				SetPlayerFacingAngle(playerid, PAINTBALL_SPAWNS[PAINTBALL_CURRENT_SPAWN_POINT][3]);
				PAINTBALL_CURRENT_SPAWN_POINT ++;
				SetPlayerInterior(playerid, 0);
				SetPlayerVirtualWorld(playerid, 5);

				SetPlayerHealth(playerid, 100);
				SetPlayerArmour(playerid, 0);
				ResetPlayerWeapons(playerid);

				if (playerData[playerid][paintball_class] == 0) {
					GivePlayerWeaponSafe(playerid, 22, 350);
					GivePlayerWeaponSafe(playerid, 25, 350);
				} else if (playerData[playerid][paintball_class] == 1) {
					GivePlayerWeaponSafe(playerid, 16, 2);
					GivePlayerWeaponSafe(playerid, 24, 350);
					GivePlayerWeaponSafe(playerid, 27, 350);
				} else if (playerData[playerid][paintball_class] == 2) {
					GivePlayerWeaponSafe(playerid, 28, 350);
					GivePlayerWeaponSafe(playerid, 30, 350);
					GivePlayerWeaponSafe(playerid, 34, 25);
				} else if (playerData[playerid][paintball_class] == 3) {
					GivePlayerWeaponSafe(playerid, 16, 3);
					GivePlayerWeaponSafe(playerid, 29, 350);
					GivePlayerWeaponSafe(playerid, 31, 350);
					GivePlayerWeaponSafe(playerid, 34, 350);
				} else if (playerData[playerid][paintball_class] == 4) {
					GivePlayerWeaponSafe(playerid, 32, 350);
					GivePlayerWeaponSafe(playerid, 30, 350);
					GivePlayerWeaponSafe(playerid, 34, 350);
				} else if (playerData[playerid][paintball_class] == 5) {
					GivePlayerWeaponSafe(playerid, 16, 3);
					GivePlayerWeaponSafe(playerid, 31, 500);
					GivePlayerWeaponSafe(playerid, 35, 1);
				}

			} else if (PAINTBALL_STATE == 4) {
				SetPlayerHealth(playerid, 100);
				SetPlayerPos(playerid, 1109.8433,-1796.7095,16.5938);
				playerData[playerid][paintball_joined] = 0;
				TextDrawHideForPlayer(playerid, PaintballTextdraw0);
				TextDrawHideForPlayer(playerid, PaintballTextdraw1);

			}
		} else {
			if (playerData[playerid][account_jailed] > 0) {
				
				playerData[playerid][account_wanted] = 0; // In case he was escaping and did /q

				SetPlayerSkin(playerid, 62);
				SetPlayerHealth(playerid, 9999999);
				ResetPlayerWeapons(playerid);

				SetPlayerInterior(playerid, 0);

				SetPlayerVirtualWorld(playerid, 0);

				switch(random(4)) {
					case 0: { SetPlayerPos(playerid, 1551.2333,-1648.4364,-14.3242); SetPlayerFacingAngle(playerid, 268.3279);}
					case 1: { SetPlayerPos(playerid,1550.9054,-1654.9496,-14.3242); SetPlayerFacingAngle(playerid, 271.1479);}
					case 2: { SetPlayerPos(playerid, 1551.1182,-1661.1329,-14.3242); SetPlayerFacingAngle(playerid, 268.3279);}
					case 3: { SetPlayerPos(playerid, 1550.9534,-1667.1189,-14.3242); SetPlayerFacingAngle(playerid, 269.2679);}
				}

				GivePlayerWeaponSafe(playerid, 10, 1);

				SetCameraBehindPlayer(playerid);

				playerData[playerid][in_jail] = 1;
			} else {

				SetPlayerSkin(playerid, playerData[playerid][account_skin]);

				if (isWarTime() && playerData[playerid][account_clan] != 0) {
					SetPlayerHealth(playerid, 100);
					SetPlayerArmour(playerid, 100);

					// Guns during the war time
					GivePlayerWeaponSafe(playerid, WEAPON_DEAGLE, 50);
					GivePlayerWeaponSafe(playerid, WEAPON_AK47, 90);
					GivePlayerWeaponSafe(playerid, WEAPON_UZI, 120);

				} else {
					SetPlayerHealth(playerid, 100);
					SetPlayerArmour(playerid, 0);
				}

				SetPlayerVirtualWorld(playerid, 0);
				SetPlayerInterior(playerid, 0);

				if (playerData[playerid][account_spawnInHouse] == 0) {

					if (playerData[playerid][account_faction] == FACTION_CIVIL) {
						SetPlayerPos(playerid, 1800.7826 + random(3),-1865.5585 + random(3), 13.5725);
						SetPlayerFacingAngle(playerid, 356.3357);

						GivePlayerWeaponSafe(playerid, 1, 1);
						GivePlayerWeaponSafe(playerid, 14, 1);

					} else if (playerData[playerid][account_faction] == FACTION_TAXILS) {
						SetPlayerPos(playerid, 1754.2646 + random(3),-1894.3219 + random(3),13.5570);
						SetPlayerFacingAngle(playerid, 271.1082);

						if (playerData[playerid][account_rank] == 1) {
							GivePlayerWeaponSafe(playerid, WEAPON_BAT, 1);
						} else if (playerData[playerid][account_rank] == 2) {
							GivePlayerWeaponSafe(playerid, WEAPON_BAT, 1);
						} else if (playerData[playerid][account_rank] == 3) {
							GivePlayerWeaponSafe(playerid, WEAPON_BAT, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_COLT45, 250);
						} else if (playerData[playerid][account_rank] == 4) {
							GivePlayerWeaponSafe(playerid, WEAPON_BAT, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_COLT45, 250);
						} else if (playerData[playerid][account_rank] == 5) {
							GivePlayerWeaponSafe(playerid, WEAPON_BAT, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGUN, 250);
						} else if (playerData[playerid][account_rank] >= 6) {
							GivePlayerWeaponSafe(playerid, WEAPON_BAT, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGUN, 250);
						}
					} else if (playerData[playerid][account_faction] == FACTION_LSPD) {
						SetPlayerPos(playerid, 1568.4164 + random(3),-1691.9011 + random(3),5.8906);
						SetPlayerFacingAngle(playerid, 179.0574);

						if (playerData[playerid][account_rank] == 1) {
							GivePlayerWeaponSafe(playerid, WEAPON_NITESTICK, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_COLT45, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_AK47, 250);
						} else if (playerData[playerid][account_rank] == 2) {
							GivePlayerWeaponSafe(playerid, WEAPON_NITESTICK, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_DEAGLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_AK47, 250);
						} else if (playerData[playerid][account_rank] == 3) {
							GivePlayerWeaponSafe(playerid, WEAPON_NITESTICK, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_DEAGLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGSPA, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_AK47, 250);
						} else if (playerData[playerid][account_rank] == 4) {
							GivePlayerWeaponSafe(playerid, WEAPON_NITESTICK, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_DEAGLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGSPA, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_MP5, 250);
						} else if (playerData[playerid][account_rank] == 5) {
							GivePlayerWeaponSafe(playerid, WEAPON_NITESTICK, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_DEAGLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGSPA, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_M4, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SNIPER, 250);
						} else if (playerData[playerid][account_rank] >= 6) {
							GivePlayerWeaponSafe(playerid, WEAPON_NITESTICK, 1);
							GivePlayerWeaponSafe(playerid, WEAPON_DEAGLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGSPA, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_M4, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SNIPER, 250);
						}
					} else if (playerData[playerid][account_faction] == FACTION_MEDICS) {
						SetPlayerPos(playerid, 1177.4180 + random(3),-1324.2224 + random(3),14.0697);
						SetPlayerFacingAngle(playerid, 268.5545);

						if (playerData[playerid][account_rank] == 1) {
							GivePlayerWeaponSafe(playerid, WEAPON_FIREEXTINGUISHER, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_COLT45, 250);
						} else if (playerData[playerid][account_rank] == 2) {
							GivePlayerWeaponSafe(playerid, WEAPON_FIREEXTINGUISHER, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_COLT45, 250);
						} else if (playerData[playerid][account_rank] == 3) {
							GivePlayerWeaponSafe(playerid, WEAPON_FIREEXTINGUISHER, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGUN, 250);
						} else if (playerData[playerid][account_rank] == 4) {
							GivePlayerWeaponSafe(playerid, WEAPON_FIREEXTINGUISHER, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_RIFLE, 250);
						} else if (playerData[playerid][account_rank] == 5) {
							GivePlayerWeaponSafe(playerid, WEAPON_FIREEXTINGUISHER, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_RIFLE, 250);
						} else if (playerData[playerid][account_rank] >= 6) {
							GivePlayerWeaponSafe(playerid, WEAPON_FIREEXTINGUISHER, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_DEAGLE, 250);
						}
					} else if (playerData[playerid][account_faction] == FACTION_HITMAN) {
						SetPlayerPos(playerid, 734.2955 + random(3),-1355.4347 + random(3),15.1563);
						SetPlayerFacingAngle(playerid, 268.9346);

						if (playerData[playerid][account_rank] == 1) {
							GivePlayerWeaponSafe(playerid, WEAPON_SILENCED, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_RIFLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_KNIFE, 250);
						} else if (playerData[playerid][account_rank] == 2) {
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGUN, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_RIFLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_KNIFE, 250);
						} else if (playerData[playerid][account_rank] == 3) {
							GivePlayerWeaponSafe(playerid, WEAPON_SHOTGSPA, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_RIFLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_KNIFE, 250);
						} else if (playerData[playerid][account_rank] == 4) {
							GivePlayerWeaponSafe(playerid, WEAPON_MP5, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_RIFLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_KNIFE, 250);
						} else if (playerData[playerid][account_rank] == 5) {
							GivePlayerWeaponSafe(playerid, WEAPON_MP5, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SNIPER, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_KNIFE, 250);
						} else if (playerData[playerid][account_rank] >= 6) {
							GivePlayerWeaponSafe(playerid, WEAPON_MP5, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_DEAGLE, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_SNIPER, 250);
							GivePlayerWeaponSafe(playerid, WEAPON_KNIFE, 250);
						}
					}
				
				} else {
					new temp_spawnHouse = playerData[playerid][account_spawnInHouse];
					new temp_houses = 1, temp_spawned = 0;
					for (new i = 0; i < sizeof(houseData); i++) {
						if (houseData[i][house_owner_id] == playerData[playerid][account_id] && houseData[i][house_owner_id] != 0) {
							if (temp_houses == temp_spawnHouse) {
								SetPlayerPos(playerid, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z]);
								temp_spawned = 1;
							}
							temp_houses += 1;
						}
					}

					if (temp_spawned == 0) {
						SendClientMessage(playerid, COLOR_INFO, "You have lost your house, you will not get spawned there.");
						SetPlayerPos(playerid, 1800.7826 + random(3),-1865.5585 + random(3), 13.5725); // Civil Spawn
						SetPlayerFacingAngle(playerid, 356.3357);
						playerData[playerid][account_spawnInHouse] = 0;
					}
				}

				SetCameraBehindPlayer(playerid);
				
				if (playerData[playerid][account_faction] == FACTION_LSPD) {
					SetPlayerArmour(playerid, 100);
				} else if (playerData[playerid][account_faction] == FACTION_HITMAN) {
					SetPlayerArmour(playerid, 50);
				}
			}

			
		}

		if (playerData[playerid][account_faction] == FACTION_CIVIL) {
			SetPlayerColor(playerid, 0xFFFFFFFF);
		} else if (playerData[playerid][account_faction] == FACTION_GROOVE) {
			SetPlayerColor(playerid, 0x189e1aFF);
		} else if (playerData[playerid][account_faction] == FACTION_HITMAN) {
			SetPlayerColor(playerid, 0x5c4646FF);
		} else if (playerData[playerid][account_faction] == FACTION_MEDICS) {
			SetPlayerColor(playerid, 0xe34949FF);
		} else if (playerData[playerid][account_faction] == FACTION_TAXILS) {
			SetPlayerColor(playerid, 0xced459FF);
		} else if (playerData[playerid][account_faction] == FACTION_LSPD) {
			SetPlayerColor(playerid, 0x2429b5FF);
		}


		SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 500);


		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][spec_mode] == 1 && playerData[i][spec_player] == playerid) {
				PlayerSpectatePlayer(i, playerid);
			}
		}

		if (playerData[playerid][td_set] == 0 && playerData[playerid][am_stream_camera] == 0) {
			playerData[playerid][td_set] = 1;

			new temp[64];

			new PlayerText:temp_td_title = CreatePlayerTextDraw(playerid,633.000000, 413.000000, "Greek Roleplay Server - www.greeksamp.info");
			PlayerTextDrawAlignment(playerid,temp_td_title, 3);
			PlayerTextDrawBackgroundColor(playerid,temp_td_title, 255);
			PlayerTextDrawFont(playerid,temp_td_title, 1);
			PlayerTextDrawLetterSize(playerid,temp_td_title, 0.220000, 1.200000);
			PlayerTextDrawColor(playerid,temp_td_title, -1);
			PlayerTextDrawSetOutline(playerid,temp_td_title, 0);
			PlayerTextDrawSetProportional(playerid,temp_td_title, 1);
			PlayerTextDrawSetShadow(playerid,temp_td_title, 0);
			PlayerTextDrawSetSelectable(playerid,temp_td_title, 0);

			format(temp, sizeof(temp), "Version %s", SCRIPT_VERSION);
			new PlayerText:temp_td_version = CreatePlayerTextDraw(playerid,632.000000, 429.000000, temp);
			PlayerTextDrawAlignment(playerid,temp_td_version, 3);
			PlayerTextDrawBackgroundColor(playerid,temp_td_version, 255);
			PlayerTextDrawFont(playerid,temp_td_version, 1);
			PlayerTextDrawLetterSize(playerid,temp_td_version, 0.150000, 0.899999);
			PlayerTextDrawColor(playerid,temp_td_version, -1);
			PlayerTextDrawSetOutline(playerid,temp_td_version, 0);
			PlayerTextDrawSetProportional(playerid,temp_td_version, 1);
			PlayerTextDrawSetShadow(playerid,temp_td_version, 0);
			PlayerTextDrawSetSelectable(playerid,temp_td_version, 0);

			format(temp, sizeof(temp), "Player: %s #%d", playerData[playerid][account_name], playerData[playerid][account_id]);
			new PlayerText:temp_td_user = CreatePlayerTextDraw(playerid,6.000000, 432.000000, temp);
			PlayerTextDrawBackgroundColor(playerid,temp_td_user, 255);
			PlayerTextDrawFont(playerid,temp_td_user, 1);
			PlayerTextDrawLetterSize(playerid,temp_td_user, 0.140000, 0.699999);
			PlayerTextDrawColor(playerid,temp_td_user, -1);
			PlayerTextDrawSetOutline(playerid,temp_td_user, 0);
			PlayerTextDrawSetProportional(playerid,temp_td_user, 1);
			PlayerTextDrawSetShadow(playerid,temp_td_user, 0);
			PlayerTextDrawSetSelectable(playerid,temp_td_user, 0);

			playerData[playerid][td_title] = temp_td_title;
			playerData[playerid][td_version] = temp_td_version;
			playerData[playerid][td_user] = temp_td_user;

			PlayerTextDrawShow(playerid, temp_td_title);
			PlayerTextDrawShow(playerid, temp_td_version);
			PlayerTextDrawShow(playerid, temp_td_user);
		}

		if (playerData[playerid][robbing_state] > 0) {
			new temp[128];
			format(temp, sizeof(temp), "Your robbery attempt failed. You had collected $%s.", formatMoney(playerData[playerid][robbing_money]));
			SendClientMessage(playerid, COLOR_BADINFO, temp);
			playerData[playerid][robbing_state] = 0;
			playerData[playerid][robbing_money] = 0;
			RemovePlayerAttachedObject(playerid, 1);
			DisablePlayerCheckpoint(playerid);

			TXDInfoMessage_update(playerid, "");
		}

		playerData[playerid][tracking_mode] = 0;
		playerData[playerid][checkpoint] = 0;
		DisablePlayerCheckpoint(playerid);

		// Bug: Some players get stucked at spawn.
		TogglePlayerControllable(playerid, 1);
		ClearAnimations(playerid);

	}

	if (playerData[playerid][enteredBiz] != 0 && bizData[playerData[playerid][enteredBiz]][biz_type] == BIZ_TYPE_CLOTHES) {
		new temp_biz = playerData[playerid][enteredBiz];
		SetPlayerInterior(playerid, 0);
		SetPlayerPos(playerid, bizData[temp_biz][biz_x], bizData[temp_biz][biz_y], bizData[temp_biz][biz_z]);
		SetPlayerVirtualWorld(playerid, 0);

		SetPlayerHealth(playerid, playerData[playerid][hp_entered_clothesShop]);
		SetPlayerArmour(playerid, playerData[playerid][armour_entered_clothesShop]);
	}

	playerData[playerid][enteredBiz] = 0;
	playerData[playerid][enteredHouse] = 0;

	playerData[playerid][last_cop_shot] = -1;

	if (playerData[playerid][spec_goback_flag] == 1) {
		playerData[playerid][spec_goback_flag] = 0;
		SetPlayerPos(playerid, playerData[playerid][spec_goback_x], playerData[playerid][spec_goback_y], playerData[playerid][spec_goback_z]);
		SetPlayerInterior(playerid, playerData[playerid][spec_goback_int]);
		playerData[playerid][enteredBiz] = playerData[playerid][spec_goback_biz];
		playerData[playerid][enteredHouse] = playerData[playerid][spec_goback_house];
	}

	if (temp_clanIndex == EXPIRED_CLAN) {
		SendClientMessage(playerid, COLOR_BADINFO, "Your clan has been expired. You are no longer member of this clan.");

		new temp_clan = playerData[playerid][account_clan];
		playerData[playerid][account_clanRank] = 0;
		playerData[playerid][account_clan] = 0;

		if (playerData[playerid][account_faction] == FACTION_CIVIL) {
			playerData[playerid][account_skin] = -1;
		}

		new temp[546];

		mysql_format(Database, temp, sizeof(temp),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'clan_rank', '%d', '%d', '%d', 'expired clan', '%d')", playerData[playerid][account_id], 0, playerData[playerid][account_id], gettime(), temp_clan);
		mysql_query(Database, temp, false);

		savePlayerData(playerid);
	}

	playerData[playerid][am_spraying] = 0;
	playerData[playerid][am_spraying_sprays] = 0;

	// PlayerTextDrawHide(playerid, playerData[playerid][loadScreen_txd]);
	return 1;
}


public OnPlayerDeath(playerid, killerid, reason)
{

	printf("playerid:%d killerid:%d reason:%d",playerid, killerid, reason);

	
	if (playerData[playerid][account_escaped] == 1) {
		printf("%s died during the Escape. Escape State is now 0.", playerData[playerid][account_name]);
		SendClientMessage(playerid, COLOR_BADINFO, "You cannot attempt to escape again. You need to wait your full jail time now.")
		playerData[playerid][escape_state] = 0;
	}
	
		
	if(killerid == INVALID_PLAYER_ID) return 1;


	if (playerData[playerid][logged] == 0 || playerData[killerid][logged] == 0) return 1;

	if (playerData[playerid][paintball_joined] == 1 && playerData[playerid][paintball_joined] == 1) {
		playerData[killerid][paintball_kills] ++;

		SendDeathMessage(killerid, playerid, reason);
	} else {
		playerData[playerid][account_deaths] ++;
		playerData[killerid][account_kills] ++;

		new temp[512];

		if (playerData[killerid][account_faction] == FACTION_LSPD) {
			if (playerData[playerid][account_wanted] > 0) {

				GameTextForPlayer(playerid, "Wasted", 3000, 2);

				killWanted(playerid, killerid);

			} else {
				if (playerData[playerid][account_faction] == FACTION_LSPD) {
					format(temp, sizeof(temp), "Player %s (%d) killed the colleague %s (%d) of our faction.", playerData[killerid][account_name], killerid, playerData[playerid][account_name], playerid);
					SendClientMessageToFaction(playerData[killerid][account_faction], COLOR_FACTION, temp);
					printf("DEATH: %s", temp);
				} else {
					format(temp, sizeof(temp), "LSPD Member %s (%d) killed the unwanted player %s (%d).", playerData[killerid][account_name], killerid, playerData[playerid][account_name], playerid);
					SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp);
					format(temp, sizeof(temp), "LSPD Member %s (%d) killed the unwanted player %s (%d). Make sure he is not doing DM.", playerData[killerid][account_name], killerid, playerData[playerid][account_name], playerid);
					SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
					printf("DEATH: %s", temp);

					playerData[killerid][dm_unwanted_flag]++;
					if (playerData[killerid][dm_unwanted_flag] == 2) {
						kickAdmBot(killerid, "Killed unwanted players as PD");
					}
				}
			}

			SendDeathMessage(killerid, playerid, reason);

		} else if (playerData[killerid][account_faction] == FACTION_HITMAN) {

			if (playerData[playerid][account_contracts] > 0) {

				if (isWarTime() && playerData[killerid][account_clan] != 0 && playerData[playerid][account_clan] != 0) {

				} else {
				
					format(temp, sizeof(temp), "Hitman %s fulfilled the %d contract(s) on %s and collected $%s.", playerData[killerid][account_name], playerData[playerid][account_contracts], playerData[playerid][account_name], formatMoney(playerData[playerid][account_contracts_price]));

					printf("%s", temp);

					SendClientMessageToFaction(FACTION_HITMAN, COLOR_FACTION, temp);
					
					giveMoney(killerid, playerData[playerid][account_contracts_price]);

					format(temp, sizeof(temp),"INSERT INTO `activity_reports` (`r_player`, `r_faction`, `r_type`, `r_serviced_player`, `r_date`, `r_amount`) VALUES ('%d', '%d', 'contract', '%d', '%d', '%d')", playerData[killerid][account_id], FACTION_HITMAN, playerData[playerid][account_id], gettime(), playerData[playerid][account_contracts_price]);
					mysql_query(Database, temp, false);

					playerData[playerid][account_contracts] = 0;
					playerData[playerid][account_contracts_price] = 0;


					reportCrime(killerid, 3, "Murdering a player");
				}
	

			} else {

				if (isWarTime() && playerData[killerid][account_clan] != 0 && playerData[playerid][account_clan] != 0) {

					// Kill during War (for hitmen)
					new temp_free_index = -1;
					for(new i; i<sizeof(HEAL_PICKUPS); i++) {
						if (HEAL_PICKUPS[i] == 0) {
							temp_free_index = i;
						}
					}

					if (temp_free_index != -1) {

						new Float:temp_px, Float:temp_py, Float:temp_pz;
						GetPlayerPos(playerid, temp_px, temp_py, temp_pz);

						HEAL_PICKUPS[temp_free_index] = CreateDynamicPickup(1240, 8, temp_px, temp_py, temp_pz);
					}

					playerData[killerid][clan_war_kills]++;

					
				} else {
					reportCrime(killerid, 1, "Murdering a player");

					format(temp, sizeof(temp), "You killed the player %s (%d) with no contract.", playerData[playerid][account_name], playerid);
					SendClientMessage(killerid, COLOR_BADINFO, temp);
				}
			}

		} else {

			if (playerData[playerid][account_faction] == FACTION_LSPD) {

				reportCrime(killerid, 5, "Killing a cop");

			} else {
				if (isWarTime() && playerData[killerid][account_clan] != 0 && playerData[playerid][account_clan] != 0) {

					// Kill during War
					new temp_free_index = -1;
					for(new i; i<sizeof(HEAL_PICKUPS); i++) {
						if (HEAL_PICKUPS[i] == 0) {
							temp_free_index = i;
						}
					}

					if (temp_free_index != -1) {
						
						new Float:temp_px, Float:temp_py, Float:temp_pz;
						GetPlayerPos(playerid, temp_px, temp_py, temp_pz);

						HEAL_PICKUPS[temp_free_index] = CreateDynamicPickup(1240, 8, temp_px, temp_py, temp_pz);
					}

					playerData[killerid][clan_war_kills]++;

				} else {

					format(temp, sizeof(temp), "Player %s (%d) killed you. He has been reported to Police Department.", playerData[killerid][account_name], killerid);
					SendClientMessage(playerid, COLOR_BADINFO, temp);

					reportCrime(killerid, 3, "Murdering a player");

				}
			}


			if (playerData[killerid][account_faction] != FACTION_CIVIL && playerData[killerid][account_faction] == playerData[playerid][account_faction]) {
				format(temp, sizeof(temp), "Player %s (%d) killed the colleague %s (%d) of our faction.", playerData[killerid][account_name], killerid, playerData[playerid][account_name], playerid);
				SendClientMessageToFaction(playerData[killerid][account_faction], COLOR_FACTION, temp);
			}

			SendDeathMessage(killerid, playerid, reason);

		}

		if (playerData[killerid][robbing_state] > 0 || playerData[killerid][account_escaped] > 0) {
			if (playerData[playerid][account_faction] == FACTION_LSPD) {
				new Float:temp_px, Float:temp_py, Float:temp_pz;
				GetPlayerPos(playerid, temp_px, temp_py, temp_pz);

				new temp_free_index = -1;
				for(new i; i<sizeof(HEAL_PICKUPS); i++) {
					if (HEAL_PICKUPS[i] == 0) {
						temp_free_index = i;
					}
				}

				if (temp_free_index != -1) {
					HEAL_PICKUPS[temp_free_index] = CreateDynamicPickup(1240, 8, temp_px, temp_py, temp_pz);
				}
			}
		}

		
	}

	return 1;
}

public OnVehicleSpawn(vehicleid)
{

	if (carData[vehicleid][playerCar]) {
		if (carData[vehicleid][vehicle_owner] != 0) {
			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
			SetVehicleParamsEx(vehicleid, engine, lights, alarm, 1, bonnet, boot, objective);

			textLockVehicle(vehicleid);

			new temp[256];

			new playerid = carData[vehicleid][vehicle_owner_ID];

			if (playerData[playerid][vehiclesSpawned] == 1) {
				format(temp, sizeof(temp), "Your %s has been respawned and locked.", VehicleNames[GetVehicleModel(vehicleid) - 400]);
				SendClientMessage(playerid, COLOR_SERVER, temp);
			}

			format(temp, sizeof(temp), "SELECT * FROM `components` WHERE `component_car_id`='%d'", carData[vehicleid][vehicle_id]);
			mysql_tquery(Database, temp, "loadComponents", "ii", playerid, vehicleid);

			format(temp, sizeof(temp), "SELECT `vehicle_color1`, `vehicle_color2` FROM `vehicles` WHERE `vehicle_id`='%d' AND `vehicle_owner`='%d'", carData[vehicleid][vehicle_id], playerData[playerid][account_id]);
			mysql_tquery(Database, temp, "loadCarcolor", "ii", playerid, vehicleid);
		}
	} else {
		carData[vehicleid][vehicle_fuel] = 100;
	}
		
	format(vehicleRadio[vehicleid], 32, "");

	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	if (playerData[killerid][account_faction] == FACTION_LSPD) {

	} else {
		if (playerData[killerid][account_wanted] > 0) {
			if (playerData[killerid][last_cop_shot] == -1 || playerData[playerData[killerid][last_cop_shot]][account_faction] != FACTION_LSPD) {

			} else {
				killWanted(killerid, playerData[killerid][last_cop_shot]);
			}
		}
	}
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if (GetPlayerVirtualWorld(playerid) == 0) {
		if (playerData[playerid][account_faction] != FACTION_LSPD) {
			if (hittype == BULLET_HIT_TYPE_VEHICLE) {
				if (hitid >= SPAWN_LSPD_CARS[0] && hitid <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1]) {

					if (gettime() - playerData[playerid][shoot_cars_cooldown] > 30) {
						playerData[playerid][shoot_cars_cooldown] = gettime();

						reportCrime(playerid, 3, "Shooting PD vehicles");

					}
				}
			}
		}

		if (hittype == BULLET_HIT_TYPE_PLAYER) {

			if (playerData[playerid][account_faction] == FACTION_LSPD) {
				playerData[hitid][last_cop_shot] = playerid;
			}

			if (playerData[playerid][account_faction] == FACTION_LSPD && playerData[hitid][account_faction] != FACTION_LSPD) {
				if (playerData[hitid][account_wanted] <= 0 && GetPlayerState(hitid) != PLAYER_STATE_WASTED) {
					SetPlayerArmedWeapon(playerid, WEAPON_NITESTICK);
					SendClientMessage(playerid, COLOR_BADINFO, "That player is not wanted!");
				}
			}

			if (playerData[playerid][account_faction] != FACTION_LSPD && playerData[hitid][account_faction] == FACTION_LSPD) {
				if (playerData[playerid][account_wanted] == 0) {
					reportCrime(playerid, 3, "Shooting a police officer");
				}
			}
		}
	}
    return 1;
}

public OnPlayerText(playerid, text[])
{
	if (playerData[playerid][logged] == 0) {
		printf("Ban: Player %s spoke on the chat while not being logged in.", playerData[playerid][account_name]);
		return 0;
	} else if (playerData[playerid][am_sleeping] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You can not talk while you are sleeping.");
	} else if (chatIsOff && playerData[playerid][account_admin] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: The Public Chat has been temporarily disabled by an administrator.")
	} else if (!isnull(text)) {
		if (IsPlayerInRangeOfPoint(playerid, 70.0, 1412.639892,-1.787510,1000.924377)) {
			new temp[256];
			format(temp, sizeof(temp), "(( GOTOIN CHAT %s: %s ))", playerData[playerid][account_name], text);
			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged] == 1 && IsPlayerInRangeOfPoint(i, 50.0, 1412.639892,-1.787510,1000.924377)) {
					SendClientMessage(i,0xc2c2c2FF, temp);
				}
			}
		} else {
			if (isGreeklish(text) && !isnull(text)) {
				SetPlayerChatBubble(playerid, text, 0xF2F2F2FF, 40.0, 10000);
				new temp[256];
				if (modeChat == 1) {
					new temp_name[32];
					GetPlayerName(playerid, temp_name, sizeof(temp_name));
					format(temp, sizeof(temp), "%s says: %s",temp_name, text);
					SendClientMessageToAll(-1, temp);
				} else {
					new temp_name[32];
					GetPlayerName(playerid, temp_name, sizeof(temp_name));
					if (colorTagInChat) {
						format(temp, 256, "{%s}|{74ad61} %s (%d): {FFFFFF}%s", getFactionColor(playerData[playerid][account_faction]), temp_name, playerid, text);
					} else {
						format(temp, 256, "%s (%d): {FFFFFF}%s", temp_name, playerid, text);
					}
					SendClientMessageToAll(COLOR_PUBLIC, temp);
				}
			} else {
				SendClientMessage(playerid, COLOR_BADINFO, "Error: You can only use latin characters.");
			}
		}
	}
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if (ispassenger == 0) {

		// Civil Cars
		if (vehicleid >= SPAWN_CIVIL_CARS[0] && vehicleid <= SPAWN_CIVIL_CARS[sizeof(SPAWN_CIVIL_CARS)-1]) {
			if (isPlane(vehicleid) && playerData[playerid][account_score] < 20) {
				new temp[128];
				format(temp, sizeof(temp), "Error: You need at least Score 20 to drive this %s.", VehicleNames[GetVehicleModel(vehicleid) - 400]);
				SendClientMessage(playerid, COLOR_SERVER, temp);
				ClearAnimations(playerid);
			} else if (playerData[playerid][account_score] < 2 && !isBike(vehicleid)) {
				new temp[128];
				format(temp, sizeof(temp), "Error: You need at least Score 2 to drive this %s.", VehicleNames[GetVehicleModel(vehicleid) - 400]);
				SendClientMessage(playerid, COLOR_SERVER, temp);
				ClearAnimations(playerid);
			}
		}

		if (vehicleid >= SPAWN_TAXI_CARS[0] && vehicleid <= SPAWN_TAXI_CARS[sizeof(SPAWN_TAXI_CARS)-1]){
			if (playerData[playerid][account_faction] != FACTION_TAXILS) {
				// Taxi LS
				SendClientMessage(playerid, COLOR_SERVER, "Error: Only members of Taxi LS have the keys for this vehicle. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			} else if (playerData[playerid][account_rank] < 3 && GetVehicleModel(vehicleid) == 560) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Rank 3 to drive this Sultan. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			}
		}

		if (vehicleid >= SPAWN_PARAMEDICS_CARS[0] && vehicleid <= SPAWN_PARAMEDICS_CARS[sizeof(SPAWN_PARAMEDICS_CARS)-1]) {
			// Paramedics
			if (playerData[playerid][account_faction] != FACTION_MEDICS) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: Only members of Paramedics have the keys for this vehicle. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			} else if (GetVehicleModel(vehicleid) == 417 && playerData[playerid][account_rank] < 3) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Rank 3 to drive this Leviathan. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			}
		}

		if (vehicleid >= SPAWN_LSPD_CARS[0] && vehicleid <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1]) {
			if (playerData[playerid][account_faction] != FACTION_LSPD) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: Only members of Police Department have the keys for this vehicle. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			} else if (GetVehicleModel(vehicleid) == 599 && playerData[playerid][account_rank] < 2) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Rank 2 to drive this Ranger. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			} else if (GetVehicleModel(vehicleid) == 497 && playerData[playerid][account_rank] < 3) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Rank 3 to drive this Maverick. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			} else if (GetVehicleModel(vehicleid) == 520 && playerData[playerid][account_rank] < 4) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Rank 4 to drive this Hydra. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			} else if (GetVehicleModel(vehicleid) == 411 && playerData[playerid][account_rank] < 4) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Rank 4 to drive this Hydra. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			}
		}

		if (vehicleid >= SPAWN_HITMAN_CARS[0] && vehicleid <= SPAWN_HITMAN_CARS[sizeof(SPAWN_HITMAN_CARS)-1]) {
			if (playerData[playerid][account_faction] != FACTION_HITMAN) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: Only a Hitman has the keys for this vehicle. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			} else if (GetVehicleModel(vehicleid) == 487 && playerData[playerid][account_rank] < 4) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Rank 4 to drive this Maverick. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			} else if (GetVehicleModel(vehicleid) == 489 && playerData[playerid][account_score] < 3) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Rank 3 to drive this Rancher. Press G to enter as a passenger.");
				ClearAnimations(playerid);
			}
		}

	}

	// Notify that it is locked, if personal vehicle
	if (carData[vehicleid][vehicle_owner_ID] == playerid && carData[vehicleid][vehicle_owner] == playerData[playerid][account_id]) {
		new engine, lights, alarm, doors, bonnet, boot, objective;
		GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
		if (doors == 1) {
			new temp[128];
			format(temp, 128, "Your %s is locked. Use /lock to unlock it.", VehicleNames[GetVehicleModel(vehicleid) - 400]);
			SendClientMessage(playerid, COLOR_SERVER, temp);
		}
	}

	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (newstate == PLAYER_STATE_DRIVER && vehicleid != 0) {

		if (playerData[playerid][info_car_engine] == 0 && !isBike(vehicleid) && !isPlane(vehicleid)) {
			playerData[playerid][info_car_engine] = 1;
			SendClientMessage(playerid, COLOR_INFO, "You can start the engine by pressing the `2` button. More help on /carhelp");
		}

		if (isBike(vehicleid)) {
			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
			SetVehicleParamsEx(vehicleid, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective);
		}

		if (isPlane(vehicleid)) {
			SendClientMessage(playerid, COLOR_INFO, "You can start the engine with /engine.");
		}
		
		if (carData[vehicleid][playerCar] == 1) {
			new j = carData[vehicleid][vehicle_owner_ID];
			if (carData[vehicleid][vehicle_owner] == playerData[playerid][account_id] && carData[vehicleid][vehicle_owner_ID] == playerid) {
				new temp[128];
				format(temp, sizeof(temp), "You are driving your own %s.", VehicleNames[GetVehicleModel(vehicleid) - 400])
				SendClientMessage(playerid, COLOR_INFO, temp);
			} else {
				new temp[128];
				format(temp, sizeof(temp), "You are driving %s's %s.", playerData[j][account_name], VehicleNames[GetVehicleModel(vehicleid) - 400]);
				SendClientMessage(playerid, COLOR_BADINFO, temp);
				format(temp, sizeof(temp), "%s is now driving your %s.", playerData[playerid][account_name], VehicleNames[GetVehicleModel(vehicleid) - 400]);
				SendClientMessage(j, COLOR_BADINFO, temp);
			}
			printf("%s(%d) is now driving %s's %s.", playerData[playerid][account_name], playerid, playerData[j][account_name], VehicleNames[GetVehicleModel(vehicleid) - 400])
		}

	}

	if (newstate == PLAYER_STATE_PASSENGER && playerData[playerid][account_faction] != FACTION_TAXILS) {
		
		if (vehicleid >= SPAWN_TAXI_CARS[0] && vehicleid <= SPAWN_TAXI_CARS[sizeof(SPAWN_TAXI_CARS)-1]) {
			new driverid = GetVehicleDriverID(vehicleid);
			if (driverid == -1) {
				SendClientMessage(playerid, COLOR_SERVER, "You need to wait a taxi driver to enter first.");
				RemovePlayerFromVehicle(playerid);
			} else {
				new temp[128];
				format(temp, sizeof(temp), "* %s has entered your taxi.", playerData[playerid][account_name]);
				SendClientMessage(driverid, COLOR_INFO, temp);
				SendClientMessage(playerid, COLOR_INFO, "You have entered this Taxi as a passenger. Current Price: 2$ per 6 seconds.");
				playerData[playerid][am_in_taxi] = 1;
				playerData[playerid][am_in_taxi_driverid] = driverid;
				playerData[playerid][am_in_taxi_spent] = 0;
			}
		}
	} else if (oldstate == PLAYER_STATE_PASSENGER && playerData[playerid][am_in_taxi] == 1) {
		if (playerData[playerData[playerid][am_in_taxi_driverid]][logged] == 1) {
			playerData[playerid][am_in_taxi] = 0;
			new temp[512];

			format(temp, sizeof(temp),"INSERT INTO `activity_reports` (`r_player`, `r_faction`, `r_type`, `r_serviced_player`, `r_date`, `r_amount`) VALUES ('%d', '%d', 'fare', '%d', '%d', '%d')", playerData[playerData[playerid][am_in_taxi_driverid]][account_id], FACTION_TAXILS, playerData[playerid][account_id], gettime(), playerData[playerid][am_in_taxi_spent]);
			mysql_query(Database, temp, false);

			format(temp, sizeof(temp), "* %s has exited your taxi. Total fare: $%s", playerData[playerid][account_name], formatMoney(playerData[playerid][am_in_taxi_spent]));
			SendClientMessage(playerData[playerid][am_in_taxi_driverid], COLOR_INFO, temp);
			format(temp, sizeof(temp), "* You have exited %s's taxi. Total fare: $%s", playerData[playerData[playerid][am_in_taxi_driverid]][account_name], formatMoney(playerData[playerid][am_in_taxi_spent]));
			SendClientMessage(playerid, COLOR_INFO, temp);
			playerData[playerid][am_in_taxi_spent] = 0;
		}
	}

	if (newstate == PLAYER_STATE_PASSENGER && playerData[playerid][account_faction] != FACTION_MEDICS) {

		if (vehicleid >= SPAWN_PARAMEDICS_CARS[0] && vehicleid <= SPAWN_PARAMEDICS_CARS[sizeof(SPAWN_PARAMEDICS_CARS)-1]) {
			if (GetVehicleModel(vehicleid) == 416) {
				SendClientMessage(playerid, COLOR_INFO, "You have entered this Ambulance as a patient. Heal Up Price: 10$ per 6 seconds (+ 30HP).");
			} else if (GetVehicleModel(vehicleid) == 417) {
				SendClientMessage(playerid, COLOR_INFO, "You have entered this Leviathan as a patient. Heal Up Price: 10$ per 6 seconds (+ 30HP).");
			}
		}
	}

	if (newstate == PLAYER_STATE_DRIVER && GetVehicleModel(vehicleid) == 420 && playerData[playerid][account_faction] == FACTION_TAXILS) {
		new temp[128];
		format(temp, 128, "Taxi driver %s (%d) is now available. Contact him if you need a reliable transportation.", playerData[playerid][account_name], playerid);
		SendClientMessageToAll(COLOR_PUBLIC, temp);
	}

	if (newstate == PLAYER_STATE_DRIVER && (GetVehicleModel(vehicleid) == 416 || GetVehicleModel(vehicleid) == 417) && playerData[playerid][account_faction] == FACTION_MEDICS) {
		new temp[128];
		format(temp, 128, "Paramedic %s (%d) is now available. Contact him if you need to heal up.", playerData[playerid][account_name], playerid);
		SendClientMessageToAll(COLOR_PUBLIC, temp);
	}

	updateSpectators(playerid);

	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{

	if (playerData[playerid][robbing_state] == 2) {
		new temp[128];
		SendClientMessage(playerid, COLOR_INFO, "You have delivered your money. Robbery is now completed.");
		format(temp, sizeof(temp), "Collected Money: $%s.", formatMoney(playerData[playerid][robbing_money]));
		SendClientMessage(playerid, COLOR_INFO, temp);
		giveMoney(playerid, playerData[playerid][robbing_money]);

		new query_temp[256];
		format(query_temp, sizeof(query_temp), "**%s** completed the Robbery and earned $%s!", playerData[playerid][account_name], formatMoney(playerData[playerid][robbing_money]));
		mysql_format(Database, query_temp, sizeof(query_temp),"INSERT INTO `discord_message` (`message_content`, `webhook_name`, `added_on`) VALUES ( '%s', 'welcome', '%d')", query_temp, gettime());
		mysql_query(Database, query_temp, false);

		playerData[playerid][robbing_state] = 0;
		playerData[playerid][robbing_money] = 0;
		RemovePlayerAttachedObject(playerid, 1);
		DisablePlayerCheckpoint(playerid);
		playerData[playerid][checkpoint] = 0;
	} else if (playerData[playerid][am_working] == WORKING_FARMER) {
		// Controll in serverInterval.
	} else {
		DisablePlayerCheckpoint(playerid);
		playerData[playerid][checkpoint] = 0;
	}
	return 1;
}

stock setCheckpoint(playerid, Float: x, Float: y, Float: z, Float: r)
{
	if (playerData[playerid][checkpoint] == 1) {
		DisablePlayerCheckpoint(playerid);
	}
	SetPlayerCheckpoint(playerid, x, y, z, r);
	playerData[playerid][checkpoint] = 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	if (IsPlayerAdmin(playerid)) {
		SetPlayerPos(playerid, fX, fY, fZ);
    	SetTimerEx("DelayedSetPlayerPosFindZ", 1000, 0, "ifff", playerid, fX, fY, fZ);
	}
    return 1;
}

forward DelayedSetPlayerPosFindZ(playerid, Float:fX, Float:fY, Float:fZ);
public DelayedSetPlayerPosFindZ(playerid, Float:fX, Float:fY, Float:fZ)
{
	SetPlayerPosFindZ(playerid, fX, fY, fZ);
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{

	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	new componentType = GetVehicleComponentType(componentid);

	if (carData[vehicleid][vehicle_owner_ID] == playerid && carData[vehicleid][vehicle_owner] == playerData[playerid][account_id]) {
		new temp[256];
		format(temp, sizeof(temp), "DELETE FROM `components` WHERE `component_car_id` = %d AND `component_slot` = %d", carData[vehicleid][vehicle_id], componentType);
		mysql_query(Database, temp, false);

		format(temp, sizeof(temp), "INSERT INTO `components` (`component_car_id`, `component_slot`, `component_id`) VALUES ('%d', '%d', '%d')", carData[vehicleid][vehicle_id], componentType, componentid);
		mysql_query(Database, temp, false);
	}
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	if (carData[vehicleid][vehicle_owner_ID] == playerid && carData[vehicleid][vehicle_owner] == playerData[playerid][account_id]) {
		new temp[256];
		format(temp, sizeof(temp), "DELETE FROM `components` WHERE `component_car_id` = %d AND `component_slot` = %d", carData[vehicleid][vehicle_id], CARMODTYPE_PAINTJOB);
		mysql_query(Database, temp, false);

		format(temp, sizeof(temp), "INSERT INTO `components` (`component_car_id`, `component_slot`, `component_id`) VALUES ('%d', '%d', '%d')", carData[vehicleid][vehicle_id], CARMODTYPE_PAINTJOB, paintjobid);
		mysql_query(Database, temp, false);
	}
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	if (carData[vehicleid][vehicle_owner_ID] == playerid && carData[vehicleid][vehicle_owner] == playerData[playerid][account_id]) {

		new temp[256];

		printf("CARCOLOR: %s changed his %s's colors to %d,%d in mod shop", playerData[playerid][account_name], VehicleNames[GetVehicleModel(vehicleid) - 400],  color1, color2)

		format(temp, sizeof(temp),"UPDATE `vehicles` SET `vehicle_color1` = '%d', `vehicle_color2` = '%d' WHERE `vehicle_id` = %d",  color1, color2, carData[vehicleid][vehicle_id]);
		mysql_query(Database, temp, false);

		ChangeVehicleColor(vehicleid, color1, color2);
	}
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(_:clickedid == INVALID_TEXT_DRAW)
    {
		if (playerData[playerid][skinSelector] == 1) {
			SelectTextDraw(playerid, 0xab5e5eFF);
			return 1;
		} else if (playerData[playerid][buycar_state] == 1) {
			buyCar_hide(playerid);
			SetPlayerPos(playerid, -1966.5516,293.9211,35.4688);
		}
    }
    return 0;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	if (playerData[playerid][skinSelector] == 1) {
		if (playertextid == playerData[playerid][skinSelector_save]) {

			new temp_index = playerData[playerid][skinSelector_index];
			new temp_faction = playerData[playerid][account_faction];
			new temp[128];
			if (temp_index >= 0 && temp_index <= 87 && temp_faction != FACTION_CIVIL) {
				format(temp, sizeof(temp), "Error: You are not a civilian. You are a member of %s.", getFactionName(temp_faction));
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (temp_index >= 88 && temp_index <= 92 && temp_faction != FACTION_TAXILS) {
				format(temp, sizeof(temp), "Error: You are not a member of Taxi LS. You are a member of %s.", getFactionName(temp_faction));
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (temp_index >= 93 && temp_index <= 98 && temp_faction != FACTION_LSPD) {
				format(temp, sizeof(temp), "Error: You are not a member of LSPD. You are a member of %s.", getFactionName(temp_faction));
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (temp_index >= 99 && temp_index <= 103 && temp_faction != FACTION_MEDICS) {
				format(temp, sizeof(temp), "Error: You are not a member of Paramedics. You are a member of %s.", getFactionName(temp_faction));
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (temp_index >= 104 && temp_index <= 107 && temp_faction != FACTION_HITMAN) {
				format(temp, sizeof(temp), "Error: You are not a member of the Hitman Faction. You are a member of %s.", getFactionName(temp_faction));
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (temp_index == 92 && playerData[playerid][account_rank] < 7) {
				format(temp, sizeof(temp), "Error: You are not a leader.");
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (temp_index == 98 && playerData[playerid][account_rank] < 7) {
				format(temp, sizeof(temp), "Error: You are not a leader.");
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (temp_index == 103 && playerData[playerid][account_rank] < 7) {
				format(temp, sizeof(temp), "Error: You are not a leader.");
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (temp_index == 107 && playerData[playerid][account_rank] < 7) {
				format(temp, sizeof(temp), "Error: You are not a leader.");
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else {
				playerData[playerid][account_skin] = GetPlayerSkin(playerid);
				SpawnPlayer(playerid);
				skinSelector_hide(playerid);
			}
		} else { 
			if (playertextid == playerData[playerid][skinSelector_civil]) {
				playerData[playerid][skinSelector_index] = 0;
			} else if (playertextid == playerData[playerid][skinSelector_taxi]) {
				playerData[playerid][skinSelector_index] = 88;
			} else if (playertextid == playerData[playerid][skinSelector_lspd]) {
				playerData[playerid][skinSelector_index] = 93;
			} else if (playertextid == playerData[playerid][skinSelector_paramedics]) {
				playerData[playerid][skinSelector_index] = 99;
			} else if (playertextid == playerData[playerid][skinSelector_hitman]) {
				playerData[playerid][skinSelector_index] = 104;
			} else if (playertextid == playerData[playerid][skinSelector_next]) {
				playerData[playerid][skinSelector_index] ++;
				if (playerData[playerid][skinSelector_index] >= sizeof(SERVER_SKINS)) {
					playerData[playerid][skinSelector_index] = 0;
				}
			} else if (playertextid == playerData[playerid][skinSelector_prev]) {
				playerData[playerid][skinSelector_index] --;
				if (playerData[playerid][skinSelector_index] < 0) {
					playerData[playerid][skinSelector_index] = sizeof(SERVER_SKINS) - 1;
				}
			}
			SetPlayerSkin(playerid, SERVER_SKINS[playerData[playerid][skinSelector_index]]);
		}
	} else if (playerData[playerid][buycar_state] == 1) {
		if (playertextid == playerData[playerid][buycar_prev]) {
			playerData[playerid][buycar_index]--;
			if (playerData[playerid][buycar_index] < 0) {
				playerData[playerid][buycar_index] = sizeof(BUYCAR_CARS) - 1;
			}

			buyCar_show(playerid);
		} else if (playertextid == playerData[playerid][buycar_next]) {
			playerData[playerid][buycar_index]++;
			if (playerData[playerid][buycar_index] >= sizeof(BUYCAR_CARS)) {
				playerData[playerid][buycar_index] = 0;
			}

			buyCar_show(playerid);
		} else if (playertextid == playerData[playerid][buycar_textdrive]) {

			playerData[playerid][buycar_tedtdrive] = gettime();
			playerData[playerid][buycar_state] = 2;

			SetCameraBehindPlayer(playerid);
			SetVehiclePos(playerData[playerid][buycar_car], 994.0883, -1785.7783, 13.8625);
			SetVehicleZAngle(playerData[playerid][buycar_car], 77.1264);

			SetVehicleHealth(playerData[playerid][buycar_car], 9999999);

			carData[playerData[playerid][buycar_car]][vehicle_fuel] = 100;

			SendClientMessage(playerid, COLOR_INFO, "*You have 1 minute to test drive.");

			buyCar_hide(playerid);
		} else if (playertextid == playerData[playerid][buycar_buycar]) {

			new temp_model = BUYCAR_CARS[playerData[playerid][buycar_index]][0];

			new temp_found2, temp_count;
			for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
				if (carData[i][vehicle_owner_ID] == playerid && carData[i][vehicle_owner] == playerData[playerid][account_id]) {
					temp_count++;
					if (GetVehicleModel(i) == temp_model) {
						temp_found2 = 1;
					}
				}
			}

			if (temp_count >= MAX_VEHICLES_PER_PLAYER) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot buy more personal vehicles.");
			} else if (temp_found2 == 1) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You already own a vehicle of that model id.");
			} else {

				new temp[512];
				new temp_price = BUYCAR_CARS[playerData[playerid][buycar_index]][1];
				if (playerData[playerid][account_money] < temp_price) {
					format(temp, sizeof(temp), "Error: You do not have enough money to buy this model ($%s).", formatMoney(temp_price));
					SendClientMessage(playerid, COLOR_SERVER, temp);
				} else {

					buyCar_hide(playerid);


					giveMoney(playerid, -temp_price);
					PlayerPlaySound(playerid, 182, 0.0,0.0,0.0);
					SetTimerEx("stopPlayerSound", 7400, 0, "i", playerid);

					new Float:temp_x, Float:temp_y, Float:temp_z, Float:temp_a;

					new temp_random = random(sizeof(BUYCAR_LOCATIONS));

					temp_x = BUYCAR_LOCATIONS[temp_random][0];
					temp_y = BUYCAR_LOCATIONS[temp_random][1];
					temp_z = BUYCAR_LOCATIONS[temp_random][2];
					temp_a = BUYCAR_LOCATIONS[temp_random][3];

					playerData[playerid][vehiclesSpawned] = 0;

					format(temp, sizeof(temp),"INSERT INTO `vehicles` (`vehicle_owner`, `vehicle_model`, `vehicle_parkX`, `vehicle_parkY`, `vehicle_parkZ`, `vehicle_parkA`, `vehicle_plate`, `vehicle_date`, `vehicle_color1`, `vehicle_color2`,`vehicle_fuel`, `vehicle_odometer`) VALUES ('%d', '%d', '%f', '%f', '%f', '%f', '%s', '%d', '1', '1', '100', '0')", playerData[playerid][account_id], temp_model, temp_x, temp_y, temp_z, temp_a, playerData[playerid][account_name], gettime());
					mysql_query(Database, temp, false);

					unloadPlayerVehicles(playerid);
					loadPlayerVehicles(playerid, 0);

					printf("BUYCAR: Player %s bought a new %s for $%s.", playerData[playerid][account_name], VehicleNames[temp_model - 400], formatMoney(temp_price));

					SetTimerEx("putPlayerInNewCar", 1000, 0, "ii", playerid, temp_model);
				}
			}
		}
	}
    return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{

	new vehicleid = GetPlayerVehicleID(playerid);


	if (playerData[playerid][account_jailed] > 0 && playerData[playerid][escape_state] == 1) {
		if (IsPlayerInRangeOfPoint(playerid, 3.0, 1548.4712,-1665.2664,-14.3242)) {
			if ((newkeys & KEY_FIRE) && !(oldkeys & KEY_FIRE)) {
				if (gettime()-playerData[playerid][escape_dig_cooldown] > 1) {
					playerData[playerid][escape_digging]--;
					playerData[playerid][escape_dig_cooldown] = gettime();
				}
			}
			if (playerData[playerid][escape_digging] <= 0) {
				playerData[playerid][escape_digging] = 0;
				playerData[playerid][escape_state] = 2;
				SetPlayerPos(playerid, 1567.8713,-1685.0571,28.3956);
				SendClientMessage(playerid, COLOR_INFO, "You have escaped! Go to a clothes shop and change clothes (/biz).");
				SetPlayerHealth(playerid, 100);

				GameTextForPlayer(playerid, "~r~GO TO A CLOTHES SHOP!", 3000, 4);

				playerData[playerid][account_wanted] = 6;

				GameTextForPlayer(playerid, " ", 100, 4);

				new temp[128];
				format(temp, sizeof(temp), "Prisoner %s (%d) has escaped. Current Wanted Level: 6", playerData[playerid][account_name], playerid);
				SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp);

				TXDInfoMessage_update(playerid, "");
			}
		}
	}

	if (playerData[playerid][am_spraying] != 0) {
		if (gettime() - playerData[playerid][am_spraying_cooldown] > 1) {
			playerData[playerid][am_spraying_cooldown] = gettime();
			new temp_turf_id;
			for (new i = 0; i < MAX_TURFS; i++) {
				if (turfData[i][turf_id] == playerData[playerid][am_spraying]) {
					temp_turf_id = i;
				}
			}

			if (IsPlayerInRangeOfPoint(playerid, 4.0, turfData[temp_turf_id][turf_posX], turfData[temp_turf_id][turf_posY], turfData[temp_turf_id][turf_posZ] )) {
				playerData[playerid][am_spraying_sprays] --;
				if (playerData[playerid][am_spraying_sprays] <= 0) {
					new temp[546];
					playerData[playerid][am_spraying] = 0;
					format(temp, sizeof(temp), "* %s has sprayed the turf (%d).", playerData[playerid][account_name], turfData[temp_turf_id][turf_id]);
					for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
						if (playerData[i][logged] == 1 && playerData[i][account_clan] == playerData[playerid][account_clan]) {
							SendClientMessage(i, 0xd8c2a9FF, temp);
							giveMoney(i, 250);
						}
					}
					format(temp, sizeof(temp), "* We have lost turf (%d) by %s.", turfData[temp_turf_id][turf_id], playerData[playerid][account_name]);
					for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
						if (playerData[i][logged] == 1 && playerData[i][account_clan] == turfData[temp_turf_id][turf_owner_clan]) {
							SendClientMessage(i, 0xc29159FF, temp);
						}
					}

					turfData[temp_turf_id][turf_owner_clan] = playerData[playerid][account_clan];
					new temp_clan_id;
					for (new i = 0; i < MAX_CLANS ; i++) {
						if (clanData[i][clan_id] == playerData[playerid][account_clan]) {
							temp_clan_id = i;
						}
					}
					format(turfData[temp_turf_id][turf_owner_clanName], 64, clanData[temp_clan_id][clan_name]);
					format(turfData[temp_turf_id][turf_color], 32, "%s", clanData[temp_clan_id][clan_color])

					format(temp, sizeof(temp),"UPDATE `turfs` SET `turf_owner_clanName` = '%s', `turf_owner_clan` = %d, `turf_color` = '%s' WHERE `turf_id` = %d;", clanData[temp_clan_id][clan_name], clanData[temp_clan_id][clan_id], clanData[temp_clan_id][clan_color], turfData[temp_turf_id][turf_id]);
					mysql_query(Database, temp, false);

					SetObjectMaterialText(turfData[temp_turf_id][turf_object_id], turfData[temp_turf_id][turf_owner_clanName], 0, OBJECT_MATERIAL_SIZE_512x512, "Arial", 35, 1, 0xFFFF0000, 0x00000000, 0);

					TXDInfoMessage_update(playerid, "");

					playerData[playerid][clan_war_sprays]++;

					reportCrime(playerid, 1, "Spraying Public Wall");

				}
			}
		}
	}

	if ((newkeys & KEY_SECONDARY_ATTACK) && vehicleid == 0) {
		new timestamp = gettime();
		if (timestamp - playerData[playerid][enter_cooldown] > 1) {
			playerData[playerid][enter_cooldown] = timestamp;
			if (!door_enter(playerid)) {
				door_exit(playerid);
			}
		}
	}

	if ((newkeys & KEY_NO)) {
		new timestamp = gettime();
		if (timestamp - playerData[playerid][enter_cooldown] > 1) {

			playerData[playerid][enter_cooldown] = timestamp;

			for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {

				new Float:temp_x, Float:temp_y, Float:temp_z;
				GetVehiclePos(i, temp_x, temp_y, temp_z);
				if (IsPlayerInRangeOfPoint(playerid, 5.0, temp_x, temp_y, temp_z)) {

					if (carData[i][vehicle_owner_ID] == playerid && carData[i][vehicle_owner] == playerData[playerid][account_id]) {
						new engine, lights, alarm, doors, bonnet, boot, objective;
						GetVehicleParamsEx(i, engine, lights, alarm, doors, bonnet, boot, objective);

						doors = !doors;
						SetVehicleParamsEx(i, engine, lights, alarm, doors, bonnet, boot, objective);

						new temp[128];
						if (doors == 1) {
							format(temp, sizeof(temp), "Your %s is now locked.", VehicleNames[GetVehicleModel(i) - 400]);
						} else {
							format(temp, sizeof(temp), "Your %s is now unlocked.", VehicleNames[GetVehicleModel(i) - 400]);
						}
						SendClientMessage(playerid, COLOR_INFO, temp);
						textLockVehicle(i);
					
					}
				}
			}

		}
	}

	if ((newkeys & KEY_ANALOG_UP) && vehicleid != 0) {
		new engine, lights, alarm, doors, bonnet, boot, objective;
		GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
		SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, !bonnet, boot, objective);
	}

	if ((newkeys & KEY_ANALOG_DOWN) && vehicleid != 0) {
		new engine, lights, alarm, doors, bonnet, boot, objective;
		GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
		SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, !boot, objective);
	}


	if ((newkeys & KEY_LOOK_BEHIND) && vehicleid != 0 && !isBike(vehicleid) && !isPlane(vehicleid)) {
		new engine, lights, alarm, doors, bonnet, boot, objective;
		GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);

		if (carData[vehicleid][vehicle_fuel] <= 0 && !isBike(vehicleid)) {
			SendClientMessage(playerid, COLOR_BADINFO, "Engine cannot hold. Fuel is empty. Call a taxi driver or buy from /shop.");
			SetVehicleParamsEx(vehicleid, 0, 0, alarm, doors, bonnet, boot, objective);
		} else {
			if (engine == -1) {
				engine = VEHICLE_PARAMS_OFF;
			}
			if (engine == VEHICLE_PARAMS_ON) {
				lights = VEHICLE_PARAMS_OFF;
			} else {
				lights = VEHICLE_PARAMS_ON;
			}
			SetVehicleParamsEx(vehicleid, !engine, lights, alarm, doors, bonnet, boot, objective);
		}
	}

	if ((newkeys & KEY_ACTION) && vehicleid != 0 && !isBike(vehicleid) && !isPlane(vehicleid)) {
		new engine, lights, alarm, doors, bonnet, boot, objective;
		GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
		SetVehicleParamsEx(vehicleid, engine, !lights, alarm, doors, bonnet, boot, objective);
	}

	if (playerData[playerid][spec_mode] == 1 && (newkeys & KEY_FIRE) ) {

		SetPlayerInterior(playerid, GetPlayerInterior(playerData[playerid][spec_player]));
		SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(playerData[playerid][spec_player]));

		if (GetPlayerVehicleID(playerData[playerid][spec_player]) != 0) {
			TogglePlayerSpectating(playerid, 1);
			PlayerSpectateVehicle(playerid, GetPlayerVehicleID(playerData[playerid][spec_player]));
		} else {
			TogglePlayerSpectating(playerid, 1);
			PlayerSpectatePlayer(playerid, playerData[playerid][spec_player]);
		}

	}
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	for (new i; i < sizeof(HEAL_PICKUPS); i++) {
		if (HEAL_PICKUPS[i] == pickupid) {
			DestroyDynamicPickup(pickupid);

			new Float: tempH;
			GetPlayerHealth(playerid, tempH);

			if (tempH < 80) {
				SetPlayerHealth(playerid, tempH + 25);
			}

			HEAL_PICKUPS[i] = 0;
		}
	}

	for (new i=0; i < sizeof(QUESTPOINTS); i++) {
		if (floatround(QUESTPOINTS[i][3]) == pickupid) {
			if (playerData[playerid][account_quest] == 1) {
				SendClientMessage(playerid, COLOR_BADINFO, "Error: You cannot collect more stars. You have already completed the Quest.");
			} else {
				if (questData[playerid][i] == 0) {
					questData[playerid][i] = 1;
					new temp_count = 0;
					for (new j=0; j < sizeof(QUESTPOINTS); j++) {
						if (questData[playerid][j] == 1) {
							temp_count ++;
						}
					}
					new temp[128];
					if (temp_count == sizeof(QUESTPOINTS)) {
						format(temp, sizeof(temp), "Player %s has completed the Quest and got $15.000 and 7 Score Points.", playerData[playerid][account_name]);
						SendClientMessageToAll(COLOR_PUBLIC, temp);
						printf("%s", temp);
						giveMoney(playerid, 15000);
						playerData[playerid][account_score] += 7;
						printf("SCORE: Player %s received 7 Score point for completing the quest.", playerData[playerid][account_name]);
						playerData[playerid][account_quest] = 1;
					} else {
						format(temp, sizeof(temp), "You found a Quest Star! You have %d/%d more to find and get the special reward!", sizeof(QUESTPOINTS) - temp_count, sizeof(QUESTPOINTS));
						SendClientMessage(playerid, COLOR_INFO, temp);
					}
				} else {
					SendClientMessage(playerid, COLOR_SERVER, "Error: You have already collected this star.");
				}
			}
		}
	}
}

public OnPlayerCommandReceived(playerid,cmdtext[])
{
	if (gettime()-playerData[playerid][commands_cooldown] < 1) {
		SendClientMessage(playerid, COLOR_BADINFO, "Do not spam the commands.");
		playerData[playerid][commands_cooldown] = gettime();
		return 0;
	}
	playerData[playerid][commands_cooldown] = gettime();

	if (playerData[playerid][am_sleeping] == 1 && strcmp(cmdtext, "/sleep") != 0) {
		SendClientMessage(playerid, COLOR_BADINFO, "Error: You can not use this command while your are sleeping.");
		return 0;
	}
	return 1;
}

public OnPlayerCommandPerformed(playerid,cmdtext[], success)
{
	printf("%s: %s", playerData[playerid][account_name], cmdtext);
	return success;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	playerData[playerid][playerTick] = GetTickCount();

	gunGolder(playerid);
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}


CMD:findnumber(playerid, params[])
{
	new temp_id;
	if(sscanf(params, "u", temp_id)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /findnumber <player>");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else {
		if (playerData[temp_id][account_phoneNumber] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "That player does not have any phone number.");
		} else {
			new temp[128];
			format(temp, 128, "%s's phone number is: %d-%d", playerData[temp_id][account_name], playerData[temp_id][account_phoneNumber], playerData[temp_id][account_id]);
			SendClientMessage(playerid, COLOR_INFO, temp);
		}
	}
	return 1;
}

CMD:sms(playerid, params[])
{
	if (playerData[playerid][account_phoneNumber] == 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have a phone number. Buy one in a 24/7 Shop (/biz).");
	new temp_snumber, temp[128];
	if(sscanf(params, "is[128]", temp_snumber, temp)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /sms <player number (xxxxxxx, without - symbol)> <message>");
	} else if (strlen(temp) > 80) {
		SendClientMessage(playerid, COLOR_BADINFO, "Your message was to big. We could not send it.");
	} else {
		
		new temp_number[32], temp_found = -1;
		new temp_snumber_text[32];
		format(temp_snumber_text, sizeof(temp_snumber_text), "%d", temp_snumber);

		for (new j = 0, k = GetPlayerPoolSize(); j <= k; j++) {
			if (playerData[j][logged] == 1) {
				format(temp_number, sizeof(temp_number), "%d%d", playerData[j][account_phoneNumber], playerData[j][account_id]);
				if (strcmp(temp_number, temp_snumber_text, true) == 0) {
					temp_found = j;
					break;
				}
			}
		}

		new temp_sms[128];
		if (temp_found == -1) {
			SendClientMessage(playerid, COLOR_BADINFO, "We could not reach that phone number.");
		} else if (temp_found == playerid) {
			SendClientMessage(playerid, COLOR_BADINFO, "You can not send a message to your own phone number.");
		} else {
			format(temp_sms, sizeof(temp_sms), "SMS: %s, Sender: %s ({FFFFFF}%d-%d{fbfc9a})", temp, playerData[playerid][account_name], playerData[playerid][account_phoneNumber], playerData[playerid][account_id]);
			SendClientMessage(temp_found, 0xfbfc9aFF, temp_sms);

			format(temp_sms, sizeof(temp_sms), "SMS: %s, Receiver: %s ({FFFFFF}%d-%d{d4d654})", temp, playerData[temp_found][account_name], playerData[temp_found][account_phoneNumber], playerData[temp_found][account_id]);
			SendClientMessage(playerid, 0xd4d654FF, temp_sms);

			if (playerData[temp_found][sms_re_info] == 0) {
				playerData[temp_found][sms_re_info] = 1;
				SendClientMessage(temp_found, COLOR_INFO, "You can responde to your last incoming message with /re.");
			}
			playerData[temp_found][sms_re] = playerid;

			giveMoney(playerid, -1);
		}
	}
	return 1;
}


CMD:re(playerid, params[])
{
	if (playerData[playerid][account_phoneNumber] == 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have a phone number. Buy one in a 24/7 Shop (/biz).");
	if (playerData[playerid][sms_re] == -1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You have not received any message yet.");
	} else if (!IsPlayerConnected(playerData[playerid][sms_re]) || playerData[playerData[playerid][sms_re]][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else {
		new temp[128];
		if(sscanf(params, "s[128]", temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /re <message>");
		} else if (strlen(temp) > 80) {
			SendClientMessage(playerid, COLOR_BADINFO, "Your message was to big. We could not send it.");
		} else {
			new temp_sms[128];
			new temp_receiver = playerData[playerid][sms_re];

			format(temp_sms, sizeof(temp_sms), "SMS: %s, Sender: %s ({FFFFFF}%d-%d{fbfc9a})", temp, playerData[playerid][account_name], playerData[playerid][account_phoneNumber], playerData[playerid][account_id]);
			SendClientMessage(temp_receiver, 0xfbfc9aFF, temp_sms);

			format(temp_sms, sizeof(temp_sms), "SMS: %s, Receiver: %s ({FFFFFF}%d-%d{d4d654})", temp, playerData[temp_receiver][account_name], playerData[temp_receiver][account_phoneNumber], playerData[temp_receiver][account_id]);
			SendClientMessage(playerid, 0xd4d654FF, temp_sms);

			if (playerData[temp_receiver][sms_re_info] == 0) {
				playerData[temp_receiver][sms_re_info] = 1;
				SendClientMessage(temp_receiver, COLOR_INFO, "You can responde to your last incoming message with /re.");
			}
			playerData[temp_receiver][sms_re] = playerid;

			giveMoney(playerid, -1);
		}
	}
	return 1;
}

CMD:cw(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (vehicleid == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a vehicle.");
	} else {
		new temp[146];
		if(sscanf(params, "s[100]", temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /cw <message>");
		} else if (strlen(temp) > 95) {
			SendClientMessage(playerid, COLOR_SERVER, "Message text too big. Max Characters: 95.")
		} else {
			format(temp, sizeof(temp), "* %s whispers in car: %s", playerData[playerid][account_name], temp);

			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged] == 1 && GetPlayerVehicleID(i) == vehicleid) {
					SendClientMessage(i, 0xd6d6d6FF, temp);
				}
			}
		}

	}
	return 1;
}


CMD:pm(playerid, params[])
{
	if (playerData[playerid][account_helper] == 0 && playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp[128];
		if(sscanf(params, "us[128]", temp_id, temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /pm <player> <message>");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot send a PM to yourself.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp2[128];
			format(temp2, 128, "PM from %s (%d): %s", playerData[playerid][account_name], playerid, temp);
			SendClientMessage(temp_id, COLOR_PM, temp2);
			format(temp2, 128, "PM to %s (%d): %s", playerData[temp_id][account_name], temp_id, temp);
			SendClientMessage(playerid, COLOR_PM, temp2);
			printf("PM: %s -> %s: %s", playerData[playerid][account_name], playerData[temp_id][account_name], temp);
		}
	}
	return 1;
}

CMD:report(playerid, params[])
{
	if (strlen(playerData[playerid][reported_message]) != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You have an active report. You need to wait an administrator to close it.");
	} else {
		new temp[128];
		if(sscanf(params, "s[146]",  temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /report <message>");
		} else if (strlen(temp) > 105) {
			SendClientMessage(playerid, COLOR_SERVER, "Report message to big. Max characters: 105");
		} else {
			format(playerData[playerid][reported_message], 105, "%s", temp);
			format(temp, sizeof(temp), "%s (%d) reports: %s", playerData[playerid][account_name], playerid, temp);
			SendClientMessageToAdmins(1, 0xf0072eFF, temp);
			SendClientMessage(playerid, 0x0a610dFF, "Your report has been sent to online administrators.");
			print(temp);
		}
	}
	return 1;
}


CMD:reports(playerid, params[])
{
	if (playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_count;
		new temp_reports[546];
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][logged] == 1 && strlen(playerData[i][reported_message]) > 0) {
				if (temp_count == 0) {
					format(temp_reports, sizeof(temp_reports), "%s(%d)\t%s", playerData[i][account_name], i, playerData[i][reported_message]);
				} else {
					format(temp_reports, sizeof(temp_reports), "%s\n%s(%d)\t%s", temp_reports, playerData[i][account_name], i, playerData[i][reported_message]);
				}
				temp_count++;
			}
		}

		if (temp_count == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "There is no active report.");
		} else {
			Dialog_Show(playerid, DLG_REPORTS, DIALOG_STYLE_TABLIST, "Active Reports", temp_reports, "OK", "");
		}

	}

	return 1;
}


CMD:cr(playerid, params[])
{
	if (playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp[128];
		if(sscanf(params, "us[128]", temp_id, temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /cr <player> <answer message>");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot close your own reports.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (strlen(playerData[temp_id][reported_message]) == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player has not reported anything.");
		} else {
			new temp2[146];
			format(temp2, sizeof(temp2), "%s closed %s's report (%s).", playerData[playerid][account_name], playerData[temp_id][account_name], temp);
			SendClientMessageToAdmins(1, 0xFF4545FF, temp2);

			format(temp2, sizeof(temp2), "Admin %s closed your report (%s).", playerData[playerid][account_name], temp);
			SendClientMessage(temp_id, 0x960909FF, temp2);

			format(playerData[temp_id][reported_message], 105, "");

			playerData[playerid][account_adminReports] ++;
			format(temp2, sizeof(temp2), "* You have answered %d reports so far.", playerData[playerid][account_adminReports]);
			SendClientMessage(playerid, COLOR_INFO, temp2);
		}
	}
	return 1;
}


CMD:hanswer(playerid, params[])
{
	if (playerData[playerid][account_helper] == 0 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp[128];
		if(sscanf(params, "us[128]", temp_id, temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /hanswer <player> <message>");
		} else if (strlen(temp) > 105) {
			SendClientMessage(playerid, COLOR_SERVER, "Answer too big. Max 105 characters.");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot answer to yourself.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp2[144];
			format(temp2, sizeof(temp2), "Helper %s answers to %s: %s", playerData[playerid][account_name], playerData[temp_id][account_name], temp);
			SendClientMessageToAll(0x4eadc7FF, temp2);

			print(temp2);

			playerData[playerid][account_helperAnswers]++;
		}
	}
	return 1;
}

CMD:disablecheckpoint(playerid, params[])
{
	if (playerData[playerid][account_jailed] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail.")
	} else if (playerData[playerid][account_escaped] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are escaping.");
	} else if (playerData[playerid][robbing_state] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");
	} else {
		if (playerData[playerid][checkpoint] == 1) {
			playerData[playerid][checkpoint] = 0;
			DisablePlayerCheckpoint(playerid);
			SendClientMessage(playerid, COLOR_SERVER, "Checkpoint has been removed.");
		} else {
			SendClientMessage(playerid, COLOR_SERVER, "Error: No checkpoint is been set.");
		}
	}
	return 1;
}

CMD:cancelcheckpoint(playerid, params[])
{
	return cmd_disablecheckpoint(playerid, params);
}

CMD:removecheckpoint(playerid, params[])
{
	return cmd_disablecheckpoint(playerid, params);
}


CMD:admins(playerid,params[])
{
	new temp[128], count = 0;

	SendClientMessage(playerid, -1, "{ADFF5C}|__________Admins:__________|");

	for(new admlevel = 1; admlevel <= 6; admlevel++){
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++){
			
			if(playerData[i][logged] == 1 && playerData[i][account_admin] == admlevel){
				format(temp, sizeof(temp),"{FF6347}%s {FFFFFF}(%d) - Level %d",playerData[i][account_name],i,admlevel);
				SendClientMessage(playerid, -1, temp);
				count++;
			}
			
		}
	}
		
	if(count == 0){
		SendClientMessage(playerid, 0xF2F2F2FF, "{ADFF5C}* There is no admin online right now.");
	}else if(count == 1){
		SendClientMessage(playerid, 0xF2F2F2FF, "{ADFF5C}* There is 1 admin online right now.");
	}else{
		format(temp, sizeof(temp),"{ADFF5C}* There are %d admins online right now.",count);
		SendClientMessage(playerid, 0xF2F2F2FF, temp);
	}

	return CMD_SUCCESS;
}

CMD:helpers(playerid,params[])
{
	new temp[128], count = 0;

	SendClientMessage(playerid, -1, "{ADFF5C}|__________Helpers:__________|");

	for(new admlevel = 1; admlevel <= 2; admlevel++){
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++){
			
			if(playerData[i][logged] == 1 && playerData[i][account_helper] == admlevel){
				format(temp, sizeof(temp),"{FF6347}%s {FFFFFF}(%d) - Level %d",playerData[i][account_name],i,admlevel);
				SendClientMessage(playerid, -1, temp);
				count++;
			}
			
		}
	}
		
	if(count == 0){
		SendClientMessage(playerid, 0xF2F2F2FF, "{ADFF5C}* There is no helper online right now.");
	}else if(count == 1){
		SendClientMessage(playerid, 0xF2F2F2FF, "{ADFF5C}* There is 1 helper online right now.");
	}else{
		format(temp, sizeof(temp),"{ADFF5C}* There are %d helper online right now.",count);
		SendClientMessage(playerid, 0xF2F2F2FF, temp);
	}

	return CMD_SUCCESS;
}



CMD:shop(playerid, params[])
{
	if (playerData[playerid][account_jailed] > 0) {
		return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail.")
	} else if (playerData[playerid][account_escaped] == 1) {
		return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are escaping.");
	} else if (playerData[playerid][robbing_state] > 0) {
		return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");
	}
	
	new temp[546];

	strcat(temp, "Item\tCost\n");

	if (playerData[playerid][account_score] >= 25) {
		strcat(temp, "{FFFFFF}Cash $35.000\t{1dd14a}25 Score Points\n");
	} else {
		strcat(temp, "{FFFFFF}Cash $35.000\t{d93030}25 Score Points\n");
	}

	if (playerData[playerid][account_score] >= 100) {
		strcat(temp, "{FFFFFF}Cash $400.000\t{1dd14a}100 Score Points\n");
	} else {
		strcat(temp, "{FFFFFF}Cash $400.000\t{d93030}100 Score Points\n");
	}

	if (playerData[playerid][account_score] >= 0) {
		strcat(temp, "{FFFFFF}House Interior Upgrade\tdepends on interior\n");
	}

	if (playerData[playerid][account_money] >= 18000) {
		strcat(temp, "{FFFFFF}Clan (3 Members, 30 Days)\t{1dd14a}$18.000\n");
	} else {
		strcat(temp, "{FFFFFF}Clan (3 Members, 30 Days)\t{d93030}$18.000\n");
	}

	if (playerData[playerid][account_money] >= 30000) {
		strcat(temp, "{FFFFFF}Clan (5 Members, 30 Days)\t{1dd14a}$30.000\n");
	} else {
		strcat(temp, "{FFFFFF}Clan (5 Members, 30 Days)\t{d93030}$30.000\n");
	}

	if (playerData[playerid][account_money] >= 75000) {
		strcat(temp, "{FFFFFF}Clan (20 Members, 30 Days)\t{1dd14a}$75.000\n");
	} else {
		strcat(temp, "{FFFFFF}Clan (20 Members, 30 Days)\t{d93030}$75.000\n");
	}

	if (playerData[playerid][account_money] >= 2500) {
		strcat(temp, "{FFFFFF}Fuel (+30)\t{1dd14a}$2.500\n");
	} else {
		strcat(temp, "{FFFFFF}Fuel (+30)\t{d93030}$2.500\n");
	}

	Dialog_Show(playerid, DLG_SHOP, DIALOG_STYLE_TABLIST_HEADERS, "Shop", temp, "Buy", "Cancel");
	return 1;
}


Dialog:DLG_SHOP(playerid, response, listitem, inputtext[])
{

	if (response) {
		new temp[546];

		if (strcmp(inputtext, "Cash $35.000") == 0) {
			if (playerData[playerid][account_score] < 25) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough Score Points for this item.");
			giveMoney(playerid, 35000);
			playerData[playerid][account_score] -= 25;

			SendClientMessage(playerid, 0xFFC266FF, "Congratulations! You have received $35.000 for 25 Score Points.");

			format(temp, sizeof(temp),"INSERT INTO `shop_transactions` (`s_player`, `s_item`, `s_date`, `s_cost`) VALUES ('%d', 'Cash $35.000', '%d', '25 Score')", playerData[playerid][account_id], gettime());
			mysql_query(Database, temp, false);
		}

		if (strcmp(inputtext, "Cash $400.000") == 0) {
			if (playerData[playerid][account_score] < 100) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough Score Points for this item.");
			giveMoney(playerid, 400000);
			playerData[playerid][account_score] -= 100;

			SendClientMessage(playerid, 0xFFC266FF, "Congratulations! You have received $400.000 for 100 Score Points.");

			format(temp, sizeof(temp),"INSERT INTO `shop_transactions` (`s_player`, `s_item`, `s_date`, `s_cost`) VALUES ('%d', 'Cash $400.000', '%d', '100 Score')", playerData[playerid][account_id], gettime());
			mysql_query(Database, temp, false);
		}

		if (strcmp(inputtext, "House Interior Upgrade") == 0) {
			if (houseTogUpdate == 1) return SendClientMessage(playerid, COLOR_SERVER, "Please wait a few seconds and try again.");
	
			new temp_found = 0;
			for (new i=0; i < MAX_HOUSES; i++){
				if(IsPlayerInRangeOfPoint(playerid, 3.0, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z])){
					if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {
						temp_found = 1;
						format(temp, sizeof(temp), "ID\tHouse Interior\tUpgrade Price");
						for (new ii = 1; ii < sizeof(BUYHOUSE_INTERIORS); ii++) {

							if (ii == houseData[i][house_interior]) continue;

							new temp_p = floatround(BUYHOUSE_INTERIORS[ii][4]);
							if (playerData[playerid][account_money] < temp_p) {
								format(temp, sizeof(temp), "%s\n{FFFFFF}%d\tHouse Interior %d\t{d93030}$%s", temp, ii, ii, formatMoney(temp_p));
							} else {
								format(temp, sizeof(temp), "%s\n{FFFFFF}%d\tHouse Interior %d\t{1dd14a}$%s", temp, ii, ii, formatMoney(temp_p));
							}
						}
						Dialog_Show(playerid, DLG_UPGRADE_HOUSE, DIALOG_STYLE_TABLIST_HEADERS, "Shop > Upgrade House Interior", temp, "Buy", "Cancel");

						playerData[playerid][shop_upgradeHouseID] = houseData[i][house_id];
						break;
					}
				}
			}
			if (temp_found == 0) SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be at the entrance of a house that you own.");
		}

		if (strcmp(inputtext, "Clan (3 Members, 30 Days)") == 0 || strcmp(inputtext, "Clan (5 Members, 30 Days)") == 0 || strcmp(inputtext, "Clan (20 Members, 30 Days)") == 0) {
			if (playerData[playerid][account_clan] != 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You need to leave your clan in order to buy a new one.");

			if (strcmp(inputtext, "Clan (3 Members, 30 Days)") == 0 && playerData[playerid][account_money] < 18000) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for this item.");
			if (strcmp(inputtext, "Clan (5 Members, 30 Days)") == 0 && playerData[playerid][account_money] < 30000) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for this item.");
			if (strcmp(inputtext, "Clan (20 Members, 30 Days)") == 0 && playerData[playerid][account_money] < 75000) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for this item.");

			if (strcmp(inputtext, "Clan (3 Members, 30 Days)") == 0) { playerData[playerid][shop_clanSlots] = 3; playerData[playerid][shop_clanPrice] = 18000; }
			if (strcmp(inputtext, "Clan (5 Members, 30 Days)") == 0) { playerData[playerid][shop_clanSlots] = 5; playerData[playerid][shop_clanPrice] = 30000; }
			if (strcmp(inputtext, "Clan (20 Members, 30 Days)") == 0) { playerData[playerid][shop_clanSlots] = 20; playerData[playerid][shop_clanPrice] = 75000; }

			if (playerData[playerid][account_faction] == FACTION_LSPD) return SendClientMessage(playerid, COLOR_SERVER, "Error: You can not buy a clan as a cop.");

			format(temp, sizeof(temp), "You are about to create a new Clan with %d members.\nDo you agree with the Clan Rules? You can read them here: greeksamp.info", playerData[playerid][shop_clanSlots]);
			
			Dialog_Show(playerid, DLG_SHOP_CLAN_RULES, DIALOG_STYLE_MSGBOX, "Shop > Clan > Rules", temp, "I Agree", "Cancel");
		}

		if (strcmp(inputtext, "Fuel (+30)") == 0) {
			if (playerData[playerid][account_money] < 2500) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for this item.");

			new vehicleid = GetPlayerVehicleID(playerid);
			
			if (vehicleid == 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be inside a vehicle.");

			carData[vehicleid][vehicle_fuel] += 30;
			if (carData[vehicleid][vehicle_fuel] > 100) {
				carData[vehicleid][vehicle_fuel] = 100;
			}

			giveMoney(playerid, -2500);

			SendClientMessage(playerid, 0xFFC266FF, "Congratulations! You have filled your car for $2.500.");

			format(temp, sizeof(temp),"INSERT INTO `shop_transactions` (`s_player`, `s_item`, `s_date`, `s_cost`) VALUES ('%d', 'Fuel (+30)', '%d', '$2.500')", playerData[playerid][account_id], gettime());
			mysql_query(Database, temp, false);
		}
	}
	return 1;
}


Dialog:DLG_SHOP_CLAN_RULES(playerid, response, listitem, inputtext[])
{
	if (response) {
		Dialog_Show(playerid, DLG_SHOP_CLAN_NAME, DIALOG_STYLE_INPUT, "Shop > Clan > Name", "Select a name for your new clan.", "Ok", "Cancel");
	}
	return 1;
}

Dialog:DLG_SHOP_CLAN_NAME(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (strlen(inputtext) == 0 || isnull(inputtext) || strlen(inputtext) > 40 || !isOnlyLetter(inputtext)) {
			SendClientMessage(playerid, COLOR_BADINFO, "Error: Invalid Clan Name. Only Letters. Max characters: 40.");
			Dialog_Show(playerid, DLG_SHOP_CLAN_NAME, DIALOG_STYLE_INPUT, "Shop > Clan > Name", "Select a name for your new clan.", "Ok", "Cancel");
		} else {
			format(playerData[playerid][shop_clanName], 64, "%s", inputtext);
			Dialog_Show(playerid, DLG_SHOP_CLAN_TAG, DIALOG_STYLE_INPUT, "Shop > Clan > Tag", "Select a tag for your clan.\nMaximum Characters: 4\nExamples: grTm, VIP, BEST", "Ok", "Cancel");
		}
	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_TAG(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (strlen(inputtext) == 0 || isnull(inputtext) || strlen(inputtext) > 4 || !isOnlyLetter(inputtext)) {
			SendClientMessage(playerid, COLOR_BADINFO, "Error: Invalid Tag Name. Only Letters. Max characters: 4.");
			Dialog_Show(playerid, DLG_SHOP_CLAN_TAG, DIALOG_STYLE_INPUT, "Shop > Clan > Tag", "Select a tag for your clan.\nMaximum Characters: 4\nExamples: grTm, VIP, BEST", "Ok", "Cancel");
		} else {
			format(playerData[playerid][shop_clanTag], 32, "%s", inputtext);
			Dialog_Show(playerid, DLG_SHOP_CLAN_COLOR, DIALOG_STYLE_LIST, "Clan Color", "{bf3d3d}red a\n{cc1616}red b\n{ff0000}red c\n{ff9500}orange a\n{d99a41}orange b\n{b8700b}orange c\n{ded71d}yellow a\n\
			{d9d44e}yellow b\n{ede97e}yellow c\n{76e80c}green a\n{58a312}green b\n{8ed44c}green c\n{0ac986}blue a\n{048d91}blue b\n{56d8db}blue c\n{5680db}blue d\n{2531d9}blue e\n{9425d9}purple a\n{ff05f7}pink a" , "Ok", "Cancel");
		}
	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_COLOR(playerid, response, listitem, inputtext[])
{
	if (response) {
		
		format(playerData[playerid][shop_clanColor], 32, "%s", inputtext);

		new temp[546];
		format(temp, sizeof(temp), "None (Normal from Clothes Shop)");
		for(new i=0; i<sizeof(CLAN_SKINS);i++) {
			format(temp, sizeof(temp), "%s\n%d", temp, CLAN_SKINS[i]);
		}

		Dialog_Show(playerid, DLG_SHOP_CLAN_SKIN_L6, DIALOG_STYLE_LIST, "Skin for Owner & Rank 6", temp , "Ok", "Cancel");

	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_SKIN_L6(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (listitem == 0) {
			playerData[playerid][shop_clanSkin_L6] = -1;
		} else {
			playerData[playerid][shop_clanSkin_L6] = strval(inputtext);
		}
		new temp[546];
		format(temp, sizeof(temp), "None (Normal from Clothes Shop)");
		for(new i=0; i<sizeof(CLAN_SKINS);i++) {
			format(temp, sizeof(temp), "%s\n%d", temp, CLAN_SKINS[i]);
		}
		Dialog_Show(playerid, DLG_SHOP_CLAN_SKIN_5, DIALOG_STYLE_LIST, "Skin for Rank 5", temp , "Ok", "Cancel");
	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_SKIN_5(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (listitem == 0) {
			playerData[playerid][shop_clanSkin_5] = -1;
		} else {
			playerData[playerid][shop_clanSkin_5] = strval(inputtext);
		}
		new temp[546];
		format(temp, sizeof(temp), "None (Normal from Clothes Shop)");
		for(new i=0; i<sizeof(CLAN_SKINS);i++) {
			format(temp, sizeof(temp), "%s\n%d", temp, CLAN_SKINS[i]);
		}
		Dialog_Show(playerid, DLG_SHOP_CLAN_SKIN_4, DIALOG_STYLE_LIST, "Skin for Rank 4", temp , "Ok", "Cancel");
		
	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_SKIN_4(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (listitem == 0) {
			playerData[playerid][shop_clanSkin_4] = -1;
		} else {
			playerData[playerid][shop_clanSkin_4] = strval(inputtext);
		}
		new temp[546];
		format(temp, sizeof(temp), "None (Normal from Clothes Shop)");
		for(new i=0; i<sizeof(CLAN_SKINS);i++) {
			format(temp, sizeof(temp), "%s\n%d", temp, CLAN_SKINS[i]);
		}
		Dialog_Show(playerid, DLG_SHOP_CLAN_SKIN_3, DIALOG_STYLE_LIST, "Skin for Rank 3", temp , "Ok", "Cancel");
		
	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_SKIN_3(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (listitem == 0) {
			playerData[playerid][shop_clanSkin_3] = -1;
		} else {
			playerData[playerid][shop_clanSkin_3] = strval(inputtext);
		}
		new temp[546];
		format(temp, sizeof(temp), "None (Normal from Clothes Shop)");
		for(new i=0; i<sizeof(CLAN_SKINS);i++) {
			format(temp, sizeof(temp), "%s\n%d", temp, CLAN_SKINS[i]);
		}
		Dialog_Show(playerid, DLG_SHOP_CLAN_SKIN_2, DIALOG_STYLE_LIST, "Skin for Rank 2", temp , "Ok", "Cancel");
		
	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_SKIN_2(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (listitem == 0) {
			playerData[playerid][shop_clanSkin_2] = -1;
		} else {
			playerData[playerid][shop_clanSkin_2] = strval(inputtext);
		}
		new temp[546];
		format(temp, sizeof(temp), "None (Normal from Clothes Shop)");
		for(new i=0; i<sizeof(CLAN_SKINS);i++) {
			format(temp, sizeof(temp), "%s\n%d", temp, CLAN_SKINS[i]);
		}
		Dialog_Show(playerid, DLG_SHOP_CLAN_SKIN_1, DIALOG_STYLE_LIST, "Skin for Rank 1", temp , "Ok", "Cancel");
		
	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_SKIN_1(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (listitem == 0) {
			playerData[playerid][shop_clanSkin_1] = -1;
		} else {
			playerData[playerid][shop_clanSkin_1] = strval(inputtext);
		}
		new temp[546];
		format(temp, sizeof(temp), "Clan Name: %s\nClan Tag: [%s]\nClan Slots: %d\nClan Color: %s\n\nSkins Rank (1-6): %d, %d, %d, %d, %d, %d\n*-1 means that no skin was set.\n\nAre you ready for your new clan?", 
		playerData[playerid][shop_clanName], playerData[playerid][shop_clanTag], playerData[playerid][shop_clanSlots], playerData[playerid][shop_clanColor], playerData[playerid][shop_clanSkin_1], playerData[playerid][shop_clanSkin_2], playerData[playerid][shop_clanSkin_3], playerData[playerid][shop_clanSkin_4], playerData[playerid][shop_clanSkin_5], playerData[playerid][shop_clanSkin_L6]);
		Dialog_Show(playerid, DLG_SHOP_CLAN_SUMMARY, DIALOG_STYLE_MSGBOX, "Summary", temp , "Yes", "Cancel");

		
	}
	return 1;
}
Dialog:DLG_SHOP_CLAN_SUMMARY(playerid, response, listitem, inputtext[])
{
	if (response) {
		new temp[864];
		format(temp, sizeof(temp),"INSERT INTO `clans` (`clan_name`, `clan_tag`, `clan_slots`, `clan_date`, `clan_until`, `clan_skinL6`, `clan_skin5`, `clan_skin4`, `clan_skin3`, `clan_skin2`, `clan_skin1`, `clan_color`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%s');",
		playerData[playerid][shop_clanName], playerData[playerid][shop_clanTag], playerData[playerid][shop_clanSlots], gettime(), gettime() + 2592000, playerData[playerid][shop_clanSkin_L6],
		 playerData[playerid][shop_clanSkin_5], playerData[playerid][shop_clanSkin_4], playerData[playerid][shop_clanSkin_3], playerData[playerid][shop_clanSkin_2], playerData[playerid][shop_clanSkin_1], playerData[playerid][shop_clanColor]);
		mysql_tquery(Database, temp, "clanCreation", "i", playerid);

		format(temp, sizeof(temp),"INSERT INTO `shop_transactions` (`s_player`, `s_item`, `s_date`, `s_cost`) VALUES ('%d', 'Clan (%d Slots)', '%d', '$%s')", playerData[playerid][account_id], playerData[playerid][shop_clanSlots], gettime(), formatMoney(playerData[playerid][shop_clanPrice]));
		mysql_query(Database, temp, false);

		giveMoney(playerid, -playerData[playerid][shop_clanPrice]);
	}
	return 1;
}

forward clanCreation(playerid);
public clanCreation(playerid)
{
	new temp_clanID = cache_insert_id();

	new temp[546];
	format(temp, sizeof(temp),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'clan_rank', '%d', '%d', '%d', '', '%d')", playerData[playerid][account_id], 7, playerData[playerid][account_id], gettime(), temp_clanID);
	mysql_query(Database, temp, false);

	new tempD, tempM, tempY, tempH, tempI, tempS;
	TimestampToDate(gettime() + 2592000, tempY, tempM, tempD, tempH, tempI, tempS, serverTimeZoneKey);

	playerData[playerid][account_clan] = temp_clanID;
	playerData[playerid][account_clanRank] = 7;

	format(temp, sizeof(temp), "Congratulations! Your new clan has been created. Expiration Date: %02d/%02d/%02d %02d:%02d:%02d",tempD, tempM, tempY, tempH, tempI, tempS);
	SendClientMessage(playerid, 0x00C3FFFF, temp);
	SendClientMessage(playerid, COLOR_INFO, "* Use /clanhelp to find all important commands for your new clan.");

	if (playerData[playerid][account_faction] != FACTION_CIVIL) {
		SendClientMessage(playerid, COLOR_SERVER, "You can not get the clan's skin because you are a member of a faction.");
	} else {
		if (playerData[playerid][shop_clanSkin_L6] != -1) {
			playerData[playerid][account_skin] = playerData[playerid][shop_clanSkin_L6];
		}
	}

	loadClans(2);
	SetTimerEx("loadClans", 600, 0, "i", 0);

	SetPlayerHealth(playerid, 0);

	savePlayerData(playerid);
}

Dialog:DLG_UPGRADE_HOUSE(playerid, response, listitem, inputtext[])
{

	if (response) {
		new temp_ii = strval(inputtext);
		new temp_p = floatround(BUYHOUSE_INTERIORS[temp_ii][4]);
		if (playerData[playerid][account_money] < temp_p) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for this house interior.");
		} else {
			new temp[546];

			SendClientMessage(playerid, COLOR_INFO, "Congratulations! You just bought a new house interior.");

			format(temp, sizeof(temp), "UPDATE `houses` SET `house_interior` = '%d' WHERE `house_id` = %d;", temp_ii, playerData[playerid][shop_upgradeHouseID]);
			mysql_query(Database, temp, false);
			houseTogUpdate = 1;
			loadHouses(2);
			SetTimerEx("loadHouses", 600, 0, "i", 0);

			giveMoney(playerid, -temp_p);

			PlayerPlaySound(playerid, 182, 0.0,0.0,0.0);
			SetTimerEx("stopPlayerSound", 7400, 0, "i", playerid);

			format(temp, sizeof(temp),"INSERT INTO `shop_transactions` (`s_player`, `s_item`, `s_date`, `s_cost`) VALUES ('%d', 'House Upgrade (House %d, Interior %d)', '%d', '$%s')", playerData[playerid][account_id], playerData[playerid][shop_upgradeHouseID], temp_ii, gettime(), formatMoney(temp_p));
			mysql_query(Database, temp, false);
		}
	}

	return 1;

}


CMD:factions(playerid, params[])
{
	new temp_count_civil, temp_count_groove, temp_count_hitman, temp_count_medics, temp_count_lspd, temp_count_taxi;
	new temp[256];

	for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
		if (playerData[i][account_faction] == FACTION_CIVIL) {
			temp_count_civil++;
		} else if (playerData[i][account_faction] == FACTION_GROOVE) {
			temp_count_groove++;
		} else if (playerData[i][account_faction] == FACTION_HITMAN) {
			temp_count_hitman++;
		} else if (playerData[i][account_faction] == FACTION_MEDICS) {
			temp_count_medics++;
		} else if (playerData[i][account_faction] == FACTION_LSPD) {
			temp_count_lspd++;
		} else if (playerData[i][account_faction] == FACTION_TAXILS) {
			temp_count_taxi++;
		}
	}

	format(temp, sizeof(temp), "Faction\tOnline Members\nCivil\t%d\nGrove Street\t%d\nHitman\t%d\nParamedics\t%d\nPolice Department\t%d\nTaxi\t%d", temp_count_civil, temp_count_groove, temp_count_hitman, temp_count_medics, temp_count_lspd, temp_count_taxi);

	Dialog_Show(playerid, DLG_FACTIONS, DIALOG_STYLE_TABLIST_HEADERS, "Factions", temp, "OK", "");

	return 1;
}


CMD:shout(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (playerData[playerid][account_faction] != FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of Police Department.");
	} else if ( !(vehicleid >= SPAWN_LSPD_CARS[0] && vehicleid <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1]) ) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a LSPD vehicle in order to use this command.");
	} else {
		new temp[546];
		new temp_count = 0;
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][account_wanted] > 0 && playerData[i][logged] == 1) {
				new Float: temp_distance = GetDistanceBetweenPlayers(playerid, i);
				if (temp_distance < 60) {
					format(temp, sizeof(temp), "(( Cop {2416f0}%s {FFFFFF}shouts: {dbd407}%s{FFFFFF} you are wanted! {dbd407}Do you surrender{FFFFFF}? ))", playerData[playerid][account_name], playerData[i][account_name]);
					SendClientMessageToAll(-1, temp);
					temp_count++;
					break;
				}
			}
		}

		if (temp_count ==0 ) {
			SendClientMessage(playerid, COLOR_SERVER, "There is no wanted player near.");
		}
	}

	return 1;
}


CMD:wanted(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (playerData[playerid][account_faction] != FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of Police Department.");
	} else if ( !(vehicleid >= SPAWN_LSPD_CARS[0] && vehicleid <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1]) ) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a LSPD vehicle in order to use this command.");
	} else {
		new temp[546];
		new temp_count = 0;
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][account_wanted] > 0 && playerData[i][logged] == 1) {
				new Float: temp_distance = GetDistanceBetweenPlayers(playerid, i);
				if (temp_count == 0) {
					format(temp, sizeof(temp), "%d\t%s\tWanted %d\t%0.2fm", i, playerData[i][account_name], playerData[i][account_wanted], temp_distance);
				} else {
					format(temp, sizeof(temp), "%s\n%d\t%s\tWanted %d\t%0.2fm", temp, i, playerData[i][account_name], playerData[i][account_wanted], temp_distance);
				}
				temp_count++;
			}
		}
		if (temp_count > 0) {
			format(temp, sizeof(temp), "ID\tPlayer\tWanted Level\tDistance\n%s", temp);
			Dialog_Show(playerid, DLG_WANTRD, DIALOG_STYLE_TABLIST_HEADERS, "Wanted Players", temp, "OK", "");
		} else {
			Dialog_Show(playerid, DLG_INFO, DIALOG_STYLE_MSGBOX, "Wanted Players", "There is no wanted player.", "OK", "");
		}
	}

	return 1;
}


Dialog:DLG_WANTRD(playerid, response, listitem, inputtext[])
{
	new temp_count = 0;
	for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
		if (playerData[i][account_wanted] > 0 && playerData[i][logged] == 1) {
			temp_count++;
		}
	}

	if (response && temp_count >0) {
		if (playerData[strval(inputtext)][logged] == 1 && playerData[strval(inputtext)][account_wanted] > 0) {
			
			cmd_track(playerid, inputtext);

		} else {
			SendClientMessage(playerid, COLOR_BADINFO, "That player is not wanted any more.");
		}
	}
	return 1;
}

CMD:frisk(playerid, params[])
{
	if (playerData[playerid][account_faction] != FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of Police Department.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /track <player>");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot frisk yourself.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[temp_id][account_faction] == FACTION_LSPD) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot frisk a Cop.");
		} else {

			if (gettime()-playerData[playerid][confiscate_cooldown] < 10) return SendClientMessage(playerid, COLOR_SERVER, "You need to wait 10 seconds since your last frisk.");
			playerData[playerid][confiscate_cooldown] = gettime();

			new Float: tempx, Float: tempy, Float: tempz;
			GetPlayerPos(playerid, tempx, tempy, tempz);
			if (!IsPlayerInRangeOfPoint(temp_id, 10.0, tempx, tempy, tempz)) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not near you.");

			new temp[128];

			if (playerData[temp_id][account_materials] == 0) {
				SendClientMessage(playerid, COLOR_INFO, "That player has no illegal materials on him.");
			} else {
				format(temp, sizeof(temp), "* %s has %d materials on him. You can use /confiscate %d", playerData[temp_id][account_name], playerData[temp_id][account_materials], temp_id);
				SendClientMessage(playerid, COLOR_INFO, temp);
			}

			format(temp, sizeof(temp), "Cop %s frisked %s for illegal materials.", playerData[playerid][account_name], playerData[temp_id][account_name]);
			SendClientMessageToAll(COLOR_PUBLIC, temp);

			playerData[playerid][confiscate_to] = temp_id;

		}
	}

	return 1;
}


CMD:confiscate(playerid, params[])
{
	if (playerData[playerid][account_faction] != FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of Police Department.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /confiscate <player>");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot confiscate yourself.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[temp_id][account_faction] == FACTION_LSPD) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot consfiscate a Cop.");
		} else {
			
			if (playerData[playerid][confiscate_to] != temp_id) return SendClientMessage(playerid, COLOR_SERVER, "Error: You have not frisked that player.");

			if (playerData[temp_id][account_materials] <= 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player has no illegal materials.");

			new Float: tempx, Float: tempy, Float: tempz;
			GetPlayerPos(playerid, tempx, tempy, tempz);
			if (!IsPlayerInRangeOfPoint(temp_id, 10.0, tempx, tempy, tempz)) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not near you.");

			new temp[128];

			format(temp, sizeof(temp), "Cop %s want to confiscate your %d materials.\nIf you accept you will pay a fine of $1500. If not, you will get wanted.", playerData[playerid][account_name], playerData[temp_id][account_materials]);
			Dialog_Show(temp_id, DLG_CONFISCATE, DIALOG_STYLE_MSGBOX, "Confiscate", temp, "ACCEPT", "NO");

			playerData[temp_id][confiscate_by] = playerid;

			format(temp, sizeof(temp), "%s has been notified. Wait for his answer.", playerData[temp_id][account_name]);
			SendClientMessage(playerid, COLOR_INFO, temp);

		}
	}

	return 1;
}


CMD:arrest(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (playerData[playerid][account_faction] != FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of Police Department.");
	} else if ( !(vehicleid >= SPAWN_LSPD_CARS[0] && vehicleid <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1]) ) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a LSPD vehicle in order to use this command.");
	} else {
		if (!IsPlayerInRangeOfPoint(playerid, 10.0, 1568.4164,-1691.9011,5.8906)) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not at the parking of LSPD with a wanted player inside your vehicle.");
		new found = 0;
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][logged] == 1 && GetPlayerVehicleID(i) == vehicleid && playerData[i][account_wanted] > 0) {
				killWanted(i, playerid, 1);
				found = 1;
			}
		}
		if (found == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are not at the parking of LSPD with a wanted player inside your vehicle.");
		}
	}

	return 1;
}



CMD:cuff(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (playerData[playerid][account_faction] != FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of Police Department.");
	} else if ( !(vehicleid >= SPAWN_LSPD_CARS[0] && vehicleid <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1]) ) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a LSPD vehicle in order to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /cuff <player>");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot cuff yourself.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[temp_id][account_faction] == FACTION_LSPD) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot cuff a Cop.");
		} else if (GetPlayerVehicleID(temp_id) != vehicleid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Player is not in your car.");
		} else {
			GameTextForPlayer(temp_id, "~r~CUFFED", 2000, 3);
			new temp[128];
			format(temp, sizeof(temp), "* %s has cuffed you.", playerData[playerid][account_name]);
			SendClientMessage(temp_id, COLOR_INFO, temp);
			format(temp, sizeof(temp), "* You have cuffed %s." ,playerData[temp_id][account_name]);
			SendClientMessage(playerid, COLOR_INFO, temp);
			RemovePlayerAttachedObject(temp_id, 1); // money bug
			SetPlayerAttachedObject(temp_id, 2, 19418, 6, -0.011000, 0.028000, -0.022000, -15.600012, -33.699977,-81.700035, 0.891999, 1.000000, 1.168000);
			SetPlayerSpecialAction(temp_id,SPECIAL_ACTION_CUFFED);
		}

	}

	return 1;
}



CMD:uncuff(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (playerData[playerid][account_faction] != FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of Police Department.");
	} else if ( !(vehicleid >= SPAWN_LSPD_CARS[0] && vehicleid <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1]) ) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a LSPD vehicle in order to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /uncuff <player>");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot uncuff yourself.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			GameTextForPlayer(temp_id, "~g~UNCUFFED", 2000, 3);
			new temp[128];
			format(temp, sizeof(temp), "* %s has uncuffed you.", playerData[playerid][account_name]);
			SendClientMessage(temp_id, COLOR_INFO, temp);
			format(temp, sizeof(temp), "* You have uncuffed %s." ,playerData[temp_id][account_name]);
			SendClientMessage(playerid, COLOR_INFO, temp);
			
			SetPlayerSpecialAction(temp_id, SPECIAL_ACTION_NONE);
			RemovePlayerAttachedObject(temp_id, 2);
		}

	}

	return 1;
}

Dialog:DLG_CONFISCATE(playerid, response, listitem, inputtext[])
{
	if (response) {
	
		new temp_id = playerData[playerid][confiscate_by];

		playerData[playerid][account_materials] = 0;

		playerData[temp_id][confiscate_by] = -1;

		giveMoney(temp_id, 1500);
		giveMoney(playerid, -1500);

		new temp[654];
		format(temp, sizeof(temp), "%s has accepted the confiscation and the ticket of $1500.", playerData[playerid][account_name]);
		SendClientMessage(temp_id, COLOR_INFO, temp);

		format(temp, sizeof(temp),"INSERT INTO `activity_reports` (`r_player`, `r_faction`, `r_type`, `r_serviced_player`, `r_date`, `r_amount`) VALUES ('%d', '%d', 'confiscate', '%d', '%d', '%d')", playerData[temp_id][account_id], FACTION_LSPD, playerData[playerid][account_id], gettime(), 1500);
		mysql_query(Database, temp, false);

	} else {
		reportCrime(playerid, 6, "Deny confiscate");
	}
	return 1;
}


CMD:track(playerid, params[])
{
	if (playerData[playerid][account_jailed] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail.")
	} else if (playerData[playerid][account_escaped] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are escaping.");
	} else if (playerData[playerid][robbing_state] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");
	} else if (playerData[playerid][am_working] > 0 ) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are working.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /track <player>");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot track yourself.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			playerData[playerid][tracking_mode] = 1;
			playerData[playerid][tracking_player] = temp_id;

			new temp[128];
			format(temp, sizeof(temp), "You are now tracking %s (%d).", playerData[temp_id][account_name], temp_id);
			SendClientMessage(playerid, COLOR_INFO, temp);
		}
	}
	return 1;
}


CMD:trackoff(playerid, params[])
{
	if (playerData[playerid][tracking_mode] != 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not tracking any player.");
	} else {
		SendClientMessage(playerid, COLOR_SERVER, "Tracking has been disabled.");
		playerData[playerid][tracking_mode] = 0;
		playerData[playerid][checkpoint] = 0;
		DisablePlayerCheckpoint(playerid);
	}
	return 1;
}

CMD:changespawn(playerid, params[])
{
	new temp[512];
	format(temp, sizeof(temp), "Main Spawn (Faction)");
	new temp_houses = 0;
	for (new i = 0; i < sizeof(houseData); i++) {
		if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {
			temp_houses += 1;
			format(temp, sizeof(temp), "%s\nOwn House %d", temp, temp_houses);
		}
	}
	Dialog_Show(playerid, DLG_CHANGESPAWN, DIALOG_STYLE_LIST, "Change Spawn", temp, "Set", "Cancel");
	return 1;
}


CMD:resetskin(playerid, params[])
{
	playerData[playerid][account_skin] = -1;
	SendClientMessage(playerid, COLOR_INFO, "When you die or login again, you will be able to change your skin.");
	return 1;
}

Dialog:DLG_CHANGESPAWN(playerid, response, listitem, inputtext[])
{
	if (response) {
		playerData[playerid][account_spawnInHouse] = listitem;
		SendClientMessage(playerid, COLOR_INFO, "You have updated your spawn point.");
	}
	return 1;
}

CMD:locations(playerid, params[])
{
	if (playerData[playerid][account_jailed] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	} else if (playerData[playerid][account_escaped] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	} else if (playerData[playerid][robbing_state] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");
	}  else if (playerData[playerid][tracking_mode] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are tracking a player. Use /trackoff first.");
	}  else if (playerData[playerid][am_working] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are working right now.");
	} else {
		new temp[512];
		format(temp, sizeof(temp), "");
		new temp_houses = 0;
		for (new i = 0; i < sizeof(houseData); i++) {
			if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {
				temp_houses += 1;
				format(temp, sizeof(temp), "%s\n{b3cc72}Own House %d", temp, temp_houses);
			}
		}
		new temp_cars = 0;
		for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
			if (carData[i][vehicle_owner_ID] == playerid && carData[i][vehicle_owner] == playerData[playerid][account_id]) {
				temp_cars += 1;
				format(temp, sizeof(temp), "%s\n{cc7272}Own Car %d (%s)", temp, temp_cars, VehicleNames[GetVehicleModel(i) - 400]);
			}
		}


		if (strlen(temp) == 0) {
			format(temp, sizeof(temp), "{ffffff}Car Shop SF\nGrove Street\nHitman\nParamedics\nPolice Department\nTaxi\n{72cc80}Farmer Job\n{72cc80}Dealer Job");
		} else {
			format(temp, sizeof(temp), "{ffffff}Car Shop SF\nGrove Street\nHitman\nParamedics\nPolice Department\nTaxi\n{72cc80}Farmer Job\n{72cc80}Dealer Job%s", temp);
		}
		Dialog_Show(playerid, DLG_LOCATIONS, DIALOG_STYLE_LIST, "Locations", temp, "Locate", "Cancel");
	}
	return 1;
}

Dialog:DLG_LOCATIONS(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (listitem >= 8) {
			new temp_houses = 0;
			for (new i = 0; i < sizeof(houseData); i++) {
				if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {
					if (listitem-8 == temp_houses) {
						setCheckpoint(playerid, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z], 3.0);
						return 1;
					}
					temp_houses += 1;
				}
			}
			new temp_cars = 0;
			for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
				if (carData[i][vehicle_owner_ID] == playerid && carData[i][vehicle_owner] == playerData[playerid][account_id]) {
					if (temp_houses > 0) {
						if (listitem-8-temp_houses == temp_cars) {
							if (GetVehicleDriverID(i) != -1) {
								SendClientMessage(playerid, COLOR_SERVER, "Error: Could not locate the car, because someone is driving it.");
								return 1;
							}
							new Float:vehx, Float:vehy, Float:vehz;
         					GetVehiclePos(i, vehx, vehy, vehz);
							setCheckpoint(playerid, vehx, vehy, vehz, 3.0);
							return 1;
						}
					} else {
						if (listitem-8 == temp_cars) {
							if (GetVehicleDriverID(i) != -1) {
								SendClientMessage(playerid, COLOR_SERVER, "Error: Could not locate the car, because someone is driving it.");
								return 1;
							}
							new Float:vehx, Float:vehy, Float:vehz;
         					GetVehiclePos(i, vehx, vehy, vehz);
							setCheckpoint(playerid, vehx, vehy, vehz, 3.0);
							return 1;
						}
					}
					temp_cars += 1;
				}
			}
		} else {
			if (listitem == 0) {
				setCheckpoint(playerid, -1966.5516,293.9211,35.4688, 3.0);
			} else if (listitem == 1) {
				setCheckpoint(playerid, 2495.7231,-1685.2386,13.5137, 3.0);
			} else if (listitem == 2) {
				setCheckpoint(playerid, 734.2955,-1355.4347,15.1563, 3.0);
			} else if (listitem == 3) {
				setCheckpoint(playerid, 1177.4180,-1324.2224,14.0697, 3.0);
			} else if (listitem == 4) {
				setCheckpoint(playerid, 1553.4355,-1675.1517,16.1953, 3.0);
			} else if (listitem == 5) {
				setCheckpoint(playerid, 1754.2646,-1894.3219,13.5570, 3.0);
			} else if (listitem == 6) {
				setCheckpoint(playerid, -377.0287,-1426.8264,25.7266, 3.0);
			} else if (listitem == 7) {
				setCheckpoint(playerid, 2770.7419,-1628.3348,12.1775, 3.0);
			}
		}
	}
	return 1;
}

CMD:bg(playerid, params[])
{
	return cmd_buygun(playerid, params);
}


CMD:buygun(playerid, params[])
{
	if (playerData[playerid][account_jailed] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail.");
	} else if (playerData[playerid][account_escaped] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are escaping.");
	} else if (playerData[playerid][paintball_joined] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are playing paintball.");
	} else if (bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_GUNSHOP1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in a gun shop. Find one in /biz.");
	} else {
		new temp[512];
		new temp_count;
		for(new i = 0; i < sizeof(BUYGUNS); i++) {
			if (temp_count == 0) {
				format(temp, sizeof(temp), "1\tArmor\t25\t$%s", formatMoney(BUYGUNS[i][3]));
			} else {
				format(temp, sizeof(temp), "%s\n%d\t%s\t%d\t$%s", temp, BUYGUNS[i][0], GunNames[BUYGUNS[i][0]], BUYGUNS[i][1], formatMoney(BUYGUNS[i][3]));
			}
			temp_count++;
		}

		format(temp, sizeof(temp), "ID\tWeapon\tMin Score\tPrice\n%s", temp);

		Dialog_Show(playerid, DLG_BUYGUN, DIALOG_STYLE_TABLIST_HEADERS, "Buy Gun",temp, "Buy", "Close");
	}

	return 1;
}

COMMAND:buyweapon(playerid,params[])
{
     return cmd_buygun(playerid,params);
}

COMMAND:buyguns(playerid,params[])
{
     return cmd_buygun(playerid,params);
}

Dialog:DLG_BUYGUN(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (strval(inputtext) == 1) {
			if (playerData[playerid][account_money] < BUYGUNS[0][3]) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for this weapon.");
			} else if (playerData[playerid][account_score] < BUYGUNS[0][1]) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: Your score is not enough for this weapon.");
			} else {
				new temp[256];

				SetPlayerArmour(playerid, 100);

				giveMoney(playerid, -BUYGUNS[0][3]);

				new temp_biz = playerData[playerid][enteredBiz];
				format(temp, sizeof(temp), "UPDATE `business` SET `biz_profit` = `biz_profit` + '%d' WHERE `biz_id` = %d;", bizData[temp_biz][biz_id], BUYGUNS[0][3]);
				mysql_query(Database, temp, false);
			}
		} else {
			for(new i = 0; i < sizeof(BUYGUNS); i++) {
				if (strval(inputtext) == BUYGUNS[i][0]) {
					if (playerData[playerid][account_money] < BUYGUNS[i][3]) {
						SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for this weapon.");
					} else if (playerData[playerid][account_score] < BUYGUNS[i][1]) {
						SendClientMessage(playerid, COLOR_SERVER, "Error: Your score is not enough for this weapon.");
					} else {

						if (BUYGUNS[i][0] == 35) {
							new weapon_rpg[2];
							GetPlayerWeaponData(playerid, 7, weapon_rpg[0], weapon_rpg[1]);
							if (weapon_rpg[1] >= 2) {
								SendClientMessage(playerid, COLOR_SERVER, "Error: You can not hold more ammo of that weapon.");
								break;
							}
						}

						GivePlayerWeaponSafe(playerid, BUYGUNS[i][0], BUYGUNS[i][2]);
						new temp[256];
						format(temp, sizeof(temp), "You bought the weapon %s for $%s.", GunNames[BUYGUNS[i][0]], formatMoney(BUYGUNS[i][3]));
						SendClientMessage(playerid, COLOR_INFO, temp);
						giveMoney(playerid, -BUYGUNS[i][3]);

						new temp_biz = playerData[playerid][enteredBiz];
						format(temp, sizeof(temp), "UPDATE `business` SET `biz_profit` = `biz_profit` + '%d' WHERE `biz_id` = %d;", bizData[temp_biz][biz_id], BUYGUNS[i][3]);
						mysql_query(Database, temp, false);

					}
					break;
				}
			}
		}

		cmd_buygun(playerid, "");
	}
	return 1;
}

CMD:cmembers(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#cinvite1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");

	new temp[128];
	format(temp, sizeof(temp), "SELECT * FROM `accounts` WHERE account_clan = %d ORDER BY account_rank DESC", playerData[playerid][account_clan]);
	mysql_tquery(Database, temp, "showClanMembers", "i", playerid);

	return 1;
}

forward showClanMembers(playerid);
public showClanMembers(playerid)
{
	new temp_clanIndex = getClanIndex(playerid);
	new temp[1024];

	format(temp, sizeof(temp), "Player\tRank\tStatus");

	new temp_count = 0;
	for (new r, k = cache_num_rows(); r != k; r++) {

		new temp_name[32], temp_rank, temp_playerid, temp_offon = 0;
		cache_get_value_name_int(r, "account_id", temp_playerid);
		cache_get_value_name_int(r, "account_clanRank", temp_rank);
		cache_get_value_name(r, "account_name", temp_name);

		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][logged] == 1 && playerData[i][account_id] == temp_playerid) {
				temp_offon = 1;
			}
		}

		if (temp_offon == 1) {
			if (temp_rank == 7) {
				format(temp, sizeof(temp), "%s\n{FFFFFF}%s\tOwner\t{1dd14a}Online", temp, temp_name);
			} else {
				format(temp, sizeof(temp), "%s\n{FFFFFF}%s\t%d\t{1dd14a}Online", temp, temp_name, temp_rank);
			}
		} else {
			if (temp_rank == 7) {
				format(temp, sizeof(temp), "%s\n{FFFFFF}%s\tOwner\t{d93030}Offline", temp, temp_name);
			} else {
				format(temp, sizeof(temp), "%s\n{FFFFFF}%s\t%d\t{d93030}Offline", temp, temp_name, temp_rank);
			}
		}

		temp_count++;
	}

	new temp_title[64];
	format(temp_title, sizeof(temp_title), "Members (%d/%d)", temp_count, clanData[temp_clanIndex][clan_slots]);
	Dialog_Show(playerid, DLG_INFO, DIALOG_STYLE_TABLIST_HEADERS, temp_title, temp, "OK", "");
	return 1;
}



CMD:cinvite(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#cinvite1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");

	if (playerData[playerid][account_clanRank] != 7) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the clan owner.");


	new temp_id;
	if(sscanf(params, "u", temp_id)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /cinvite <player>");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else if (playerData[temp_id][account_clan] == playerData[playerid][account_clan]) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is already in your clan.");
	} else if (playerData[temp_id][account_clan] != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is a member of another clan.");
	} else if (playerData[temp_id][account_wanted] != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is currently wanted.");
	} else if (playerData[temp_id][account_jailed] != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is currently in jail.");
	} else {

		if (playerData[temp_id][account_faction] == FACTION_LSPD) return SendClientMessage(playerid, COLOR_SERVER, "Error: You can not invite Cops to your clan.");

		new temp[128];
		format(temp, sizeof(temp), "SELECT COUNT(account_id) as counted_players FROM `accounts` WHERE account_clan = %d", playerData[playerid][account_clan]);
		mysql_tquery(Database, temp, "clanInvite", "iii", playerid, temp_id, temp_clanIndex);

	}
	
	return 1;
}

forward clanInvite(playerid, invitedplayer, clanIndex);
public clanInvite(playerid, invitedplayer, clanIndex)
{
	if (cache_num_rows() == 1) {
		new temp_counted;

		cache_get_value_name_int(0, "counted_players", temp_counted);

		if (clanData[clanIndex][clan_slots] <= temp_counted) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You have used all your clan's slots. You can not invite new members.");
		} else {
			new temp[564];
			format(temp, sizeof(temp), "%s has invited you to his clan %s.", playerData[playerid][account_name], clanData[clanIndex][clan_name]);
			SendClientMessage(invitedplayer, 0x00C3FFFF, temp);
			format(temp, sizeof(temp), "You have invited %s to your clan. Slots: (%d/%d)", playerData[invitedplayer][account_name], temp_counted + 1, clanData[clanIndex][clan_slots]);
			SendClientMessage(playerid, 0x00C3FFFF, temp);

			playerData[invitedplayer][account_clan] = playerData[playerid][account_clan];
			playerData[invitedplayer][account_clanRank] = 1;

			if (playerData[invitedplayer][account_faction] != FACTION_CIVIL) {
				format(temp, sizeof(temp), "%s can not get the clan's skin because he is a member of a faction.", playerData[invitedplayer][account_name]);
				SendClientMessage(playerid, COLOR_SERVER, temp);
				SendClientMessage(invitedplayer, COLOR_SERVER, "You can not get the clan's skin because you are a member of a faction.");
			} else {
				if (clanData[clanIndex][clan_skin1] != -1) {
					playerData[invitedplayer][account_skin] = clanData[clanIndex][clan_skin1];
				}
			}

			format(temp, sizeof(temp), "* Clan owner %s has refreshed your skin. Once you get spawned again, skin will get loaded.", playerData[playerid][account_name]);
			SendClientMessage(invitedplayer, COLOR_INFO, temp);
			
			
			format(temp, sizeof(temp),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'clan_rank', '%d', '%d', '%d', '', '%d')", playerData[invitedplayer][account_id], 1, playerData[playerid][account_id], gettime(), playerData[playerid][account_clan]);
			mysql_query(Database, temp, false);

			savePlayerData(invitedplayer);
		}

	} else {
		SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#cinvite2).");
	}
}



CMD:refreshskin(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#cinvite1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");

	if (playerData[playerid][account_clanRank] != 7) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the clan owner.");


	new temp_id;
	if(sscanf(params, "u", temp_id)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /refreshskin <player>");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else if (playerData[temp_id][account_clan] != playerData[playerid][account_clan]) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not in your clan.");
	} else {

		new temp[182];

		if (playerData[temp_id][account_faction] != FACTION_CIVIL) {
			format(temp, sizeof(temp), "%s can not get the clan's skin because he is a member of a faction.", playerData[temp_id][account_name]);
			SendClientMessage(playerid, COLOR_SERVER, temp);
		} else {
			if (clanData[temp_clanIndex][clan_skin1] != -1 && playerData[temp_id][account_clanRank] == 1) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin1];
			}
			if (clanData[temp_clanIndex][clan_skin2] != -1 && playerData[temp_id][account_clanRank] == 2) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin2];
			}
			if (clanData[temp_clanIndex][clan_skin3] != -1 && playerData[temp_id][account_clanRank] == 3) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin3];
			}
			if (clanData[temp_clanIndex][clan_skin4] != -1 && playerData[temp_id][account_clanRank] == 4) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin4];
			}
			if (clanData[temp_clanIndex][clan_skin5] != -1 && playerData[temp_id][account_clanRank] == 5) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin5];
			}
			if (clanData[temp_clanIndex][clan_skinL6] != -1 && playerData[temp_id][account_clanRank] >= 6) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skinL6];
			}

			format(temp, sizeof(temp), "* You have refreshed %s's clan skin. Once he gets spawned again, skin will get loaded.", playerData[temp_id][account_name]);
			SendClientMessage(playerid, COLOR_INFO, temp);
			format(temp, sizeof(temp), "* Clan owner %s has refreshed your skin. Once you get spawned again, skin will get loaded.", playerData[playerid][account_name]);
			SendClientMessage(temp_id, COLOR_INFO, temp);
		}

	}
	
	return 1;
}


CMD:cgiverank(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#cinvite1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");

	if (playerData[playerid][account_clanRank] != 7) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the clan owner.");


	new temp_id, temp_rank, temp_reason[32];
	if(sscanf(params, "uis[32]", temp_id, temp_rank, temp_reason) || temp_rank <= 0 || temp_rank > 6) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /cgiverank <player> <rank 1-6> <reason>");
	} else if (strlen(temp_reason) > 30 || !isOnlyLetter(temp_reason)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: Reason message is too big. Max Characters: 30 and only letters are accepted.");
	} else if (playerid == temp_id) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You can not change your rank.");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else if (playerData[temp_id][account_clan] != playerData[playerid][account_clan]) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not in your clan.");
	} else if (playerData[temp_id][account_clanRank] == temp_rank) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player has already this rank.");
	} else {

		new temp_old_rank = playerData[temp_id][account_clanRank];
		playerData[temp_id][account_clanRank] = temp_rank;

		new temp[546];

		if (temp_rank > temp_old_rank) {
			format(temp, sizeof(temp), "%s has been promoted to Rank %d by clan owner %s. Reason: %s", playerData[temp_id][account_name], temp_rank, playerData[playerid][account_name], temp_reason);
		}

		if (temp_rank < temp_old_rank) {
			format(temp, sizeof(temp), "%s has been demoted to Rank %d by clan owner %s. Reason: %s", playerData[temp_id][account_name], temp_rank, playerData[playerid][account_name], temp_reason);
		}

		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][logged] == 1 && playerData[i][account_clan] == playerData[playerid][account_clan]) {
				SendClientMessage(i, 0x00C3FFFF, temp);
			}
		}

		if (playerData[temp_id][account_faction] != FACTION_CIVIL) {
			format(temp, sizeof(temp), "%s can not get the clan's skin because he is a member of a faction.", playerData[temp_id][account_name]);
			SendClientMessage(playerid, COLOR_SERVER, temp);
			SendClientMessage(temp_id, COLOR_SERVER, "You can not get the clan's skin because you are a member of a faction.");
		} else {
			if (clanData[temp_clanIndex][clan_skin1] != -1 && temp_rank == 1) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin1];
			}
			if (clanData[temp_clanIndex][clan_skin2] != -1 && temp_rank == 2) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin2];
			}
			if (clanData[temp_clanIndex][clan_skin3] != -1 && temp_rank == 3) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin3];
			}
			if (clanData[temp_clanIndex][clan_skin4] != -1 && temp_rank == 4) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin4];
			}
			if (clanData[temp_clanIndex][clan_skin5] != -1 && temp_rank == 5) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skin5];
			}
			if (clanData[temp_clanIndex][clan_skinL6] != -1 && temp_rank == 6) {
				playerData[temp_id][account_skin] = clanData[temp_clanIndex][clan_skinL6];
			}
		}

		format(temp, sizeof(temp), "* Clan owner %s has refreshed your skin. Once you get spawned again, skin will get loaded.", playerData[playerid][account_name]);
		SendClientMessage(temp_id, COLOR_INFO, temp);


		mysql_format(Database, temp, sizeof(temp),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'clan_rank', '%d', '%d', '%d', '%e', '%d')", playerData[temp_id][account_id], temp_rank, playerData[playerid][account_id], gettime(), temp_reason, playerData[playerid][account_clan]);
		mysql_query(Database, temp, false);

		savePlayerData(temp_id);
	}
	
	return 1;
}

CMD:cuninvite(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#cinvite1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");

	if (playerData[playerid][account_clanRank] != 7) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the clan owner.");


	new temp_id, temp_reason[32];
	if(sscanf(params, "us[32]", temp_id, temp_reason)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /cuninvite <player> <reason>");
	} else if (strlen(temp_reason) > 30) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: Reason message is too big. Max Characters: 30");
	} else if (playerid == temp_id) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You can not uninvite yourself.");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else if (playerData[temp_id][account_clan] != playerData[playerid][account_clan]) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not in your clan.");
	} else {

		playerData[temp_id][account_clanRank] = 0;
		playerData[temp_id][account_clan] = 0;

		if (playerData[temp_id][account_faction] == FACTION_CIVIL) {
			playerData[temp_id][account_skin] = -1;
		}

		SetPlayerHealth(temp_id, 0);

		new temp[546];

		format(temp, sizeof(temp), "%s has uninvited you from his clan. Reason: %s", playerData[playerid][account_name], temp_reason);
		SendClientMessage(temp_id, 0x00C3FFFF, temp);
		format(temp, sizeof(temp), "You have uninvited %s from your clan. Reason: %s", playerData[temp_id][account_name], temp_reason);
		SendClientMessage(playerid, 0x00C3FFFF, temp);


		mysql_format(Database, temp, sizeof(temp),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'clan_rank', '%d', '%d', '%d', '%e', '%d')", playerData[temp_id][account_id], 0, playerData[playerid][account_id], gettime(), temp_reason, playerData[playerid][account_clan]);
		mysql_query(Database, temp, false);

		savePlayerData(temp_id);
	}
	
	return 1;
}


CMD:renewclan(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#c1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");

	if (playerData[playerid][account_clanRank] != 7) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the clan owner.");


	new temp_price;
	if (clanData[temp_clanIndex][clan_slots] == 3) temp_price = 18000;
	if (clanData[temp_clanIndex][clan_slots] == 5) temp_price = 30000;
	if (clanData[temp_clanIndex][clan_slots] == 20) temp_price = 75000;

	playerData[playerid][shop_clanPrice] = temp_price;
	
	new temp[128];
	new tempD, tempM, tempY, tempH, tempI, tempS;
	TimestampToDate(clanData[temp_clanIndex][clan_until] + 2592000, tempY, tempM, tempD, tempH, tempI, tempS, serverTimeZoneKey);
	format(temp, sizeof(temp), "Do you want to extend your clan's life until %02d/%02d/%02d %02d:%02d:%02d?\nPrice: $%s",tempD, tempM, tempY, tempH, tempI, tempS, formatMoney(temp_price));
	Dialog_Show(playerid, DLG_RENEWCLAN, DIALOG_STYLE_MSGBOX, "Confirmation", temp, "Yes", "Cancel");
	return 1;
}


Dialog:DLG_RENEWCLAN(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (playerData[playerid][account_money] < playerData[playerid][shop_clanPrice]) return SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for renewal.");
		SendClientMessage(playerid, COLOR_INFO, "* You have renewed your clan.");

		giveMoney(playerid, -playerData[playerid][shop_clanPrice]);
		
		new tempE[512];
		format(tempE, sizeof(tempE),"UPDATE `clans` SET `clan_until` = `clan_until` + 2592000 WHERE `clan_id` = %d;", playerData[playerid][account_clan]);
		mysql_query(Database, tempE, false);

		loadClans(2);
		SetTimerEx("loadClans", 600, 0, "i", 0);

		format(tempE, sizeof(tempE),"INSERT INTO `shop_transactions` (`s_player`, `s_item`, `s_date`, `s_cost`) VALUES ('%d', 'Renew Clan (#%d)', '%d', '$%s')", playerData[playerid][account_clan], playerData[playerid][account_id], gettime(), formatMoney(playerData[playerid][shop_clanPrice]));
		mysql_query(Database, tempE, false);
	}
	return 1;
}



CMD:spray(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#c1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");

	if (!isWarTime()) return SendClientMessage(playerid, COLOR_SERVER, "Error: It is not spraying time: 15:00-15:30, 20:00-20:30");

	if (GetPlayerVehicleID(playerid) != 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be outside your vehicle.");

	for (new tt=0; tt < MAX_TURFS; tt++) {
		if (IsPlayerInRangeOfPoint(playerid, 4.0, turfData[tt][turf_posX], turfData[tt][turf_posY], turfData[tt][turf_posZ])) {
			if (turfData[tt][turf_owner_clan] == playerData[playerid][account_clan]) return SendClientMessage(playerid, COLOR_SERVER, "You already own this turf.");
			GivePlayerWeaponSafe(playerid, WEAPON_SPRAYCAN, 99999);
			playerData[playerid][am_spraying] = turfData[tt][turf_id];
			playerData[playerid][am_spraying_sprays] = 25;
			new temp[128];
			format(temp, sizeof(temp), "* %s has started spraying %s's turf. Go and support him.", playerData[playerid][account_name], turfData[tt][turf_owner_clanName]);
			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged] == 1 && playerData[i][account_clan] == playerData[playerid][account_clan]) {
					SendClientMessage(i, 0xd8c2a9FF, temp);
				}
			}
			format(temp, sizeof(temp), "* %s has started spraying on our turf. Go and stop him.", playerData[playerid][account_name]);
			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged] == 1 && playerData[i][account_clan] == turfData[tt][turf_owner_clan]) {
					SendClientMessage(i, 0xc29159FF, temp);
				}
			}
			return 1;
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "Error: You are not near a spray point. Find one in /turfs.");
	return 1;
}



CMD:turfs(playerid, params[])
{
	new temp[546];
	format(temp, sizeof(temp), "Turf ID\tOwned By");
	for(new i=0; i < MAX_TURFS; i++) {
		format(temp, sizeof(temp), "%s\n%d\t%s", temp, turfData[i][turf_id], turfData[i][turf_owner_clanName]);
	}
	Dialog_Show(playerid, DLG_TURFS, DIALOG_STYLE_TABLIST_HEADERS, "Turfs", temp, "Spray", "Cancel");
	return 1;
}
Dialog:DLG_TURFS(playerid, response, listitem, inputtext[])
{

	if (response) {
		if (playerData[playerid][account_jailed] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
		} else if (playerData[playerid][account_escaped] > 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
		} else if (playerData[playerid][robbing_state] > 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");
		}  else if (playerData[playerid][tracking_mode] == 1) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are tracking a player. Use /trackoff first.");
		}  else if (playerData[playerid][am_working] > 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are working right now.");
		} else {
			for (new i=0 ; i < MAX_TURFS; i++) {
				if (strval(inputtext) == turfData[i][turf_id]) {
					setCheckpoint(playerid, turfData[i][turf_posX], turfData[i][turf_posY], turfData[i][turf_posZ], 3.0);
					return 1;
				}
			}
		}
	}

	return 1;
}

CMD:c(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#c1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");


	new temp[144];
	if(sscanf(params, "s[144]", temp)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /c <message>");
	} else if (strlen(temp) > 100) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: Message too big. Max characters: 100");
	} else {
		if(playerData[playerid][account_clanRank] == 7) {
			format(temp, 144, "[CLAN] [Leader] %s: %s", playerData[playerid][account_name], temp);
		} else {
			format(temp, 144, "[CLAN] [%d] %s: %s", playerData[playerid][account_clanRank], playerData[playerid][account_name], temp);
		}
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][logged] == 1 && playerData[i][account_clan] == playerData[playerid][account_clan]) {
				SendClientMessage(i, 0xd8c2a9FF, temp);
			}
		}
	}
	return 1;
}


CMD:f(playerid, params[])
{

	if (playerData[playerid][account_faction] == FACTION_CIVIL) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a faction.");

	new temp[144];
	if(sscanf(params, "s[144]", temp)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /f <message>");
	} else {
		if(playerData[playerid][account_rank] == 7) {
			format(temp, 144, "[FACTION] [Leader] %s: %s", playerData[playerid][account_name], temp);
		} else {
			format(temp, 144, "[FACTION] [%d] %s: %s", playerData[playerid][account_rank], playerData[playerid][account_name], temp);
		}
		SendClientMessageToFaction(playerData[playerid][account_faction], COLOR_FACTION, temp);
	}
	return 1;
}

CMD:stoppaintball(playerid, params[])
{
	if (playerData[playerid][account_admin] < 3 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		PaintballStartedOn = 0;
		SendClientMessage(playerid, COLOR_INFO, "You have stopped paintball.");
	}
	return 1;
}

CMD:h(playerid, params[])
{
	if (playerData[playerid][account_helper] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[144];
		if(sscanf(params, "s[144]", temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /h <message>");
		} else {
			format(temp, sizeof(temp), "[HELPER] %s: %s", playerData[playerid][account_name], temp);
			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged] == 1 && playerData[i][account_helper] >=1) {
					SendClientMessage(i,0x9ebf95FF, temp);
				}
			}
		}
	}
	return 1;
}


CMD:l(playerid, params[])
{
	if (playerData[playerid][account_rank] < 7) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[144];
		if(sscanf(params, "s[144]", temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /l <message>");
		} else {
			format(temp, sizeof(temp), "[LEADER] [%s] %s: %s", getFactionName(playerData[playerid][account_faction]), playerData[playerid][account_name], temp);
			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged] == 1 && playerData[i][account_rank] >=7) {
					SendClientMessage(i,0xed8d5cFF, temp);
				}
			}
		}
	}
	return 1;
}


CMD:fmotd(playerid, params[])
{
	if (playerData[playerid][account_rank] < 7) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[128];
		if(sscanf(params, "s[110]", temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /fmotd <message>");
		} else if (strlen(temp) > 100 || !isOnlyLetter(temp)) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Max characters: 100, Only Letters are allowed.");
		} else {

			new temp2[1024];
			mysql_format(Database, temp2, sizeof(temp2),"UPDATE `motd` SET `motd_message` = '%e', `motd_by_name`='%s', `motd_date`='%d' WHERE motd_group='faction' AND motd_group_variable='%d'", temp, playerData[playerid][account_name], gettime(), playerData[playerid][account_faction]);
			mysql_query(Database, temp2, false);

			format(temp, sizeof(temp), "%s has updated faction's MOTD: %s", playerData[playerid][account_name], temp);
			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged] == 1 && playerData[i][account_faction]==playerData[playerid][account_faction]) {
					SendClientMessage(i,0x00C3FFFF, temp);
				}
			}
		}
	}
	return 1;
}

forward printFactionMOTD(playerid, step);
public printFactionMOTD(playerid, step)
{
	if (step == 0) {
		if (playerData[playerid][account_faction] == 0) return 1;

		new temp[128];
		format(temp, sizeof(temp), "SELECT * FROM `motd` WHERE `motd_group`='faction' AND `motd_group_variable`='%d'", playerData[playerid][account_faction]);
		mysql_tquery(Database, temp, "printFactionMOTD", "ii", playerid, 1);
	} else if (step == 1) {
		if (cache_num_rows() == 1) {
			new temp[256];
			new temp_name[32];

			cache_get_value_name(0, "motd_message", temp);
			cache_get_value_name(0, "motd_by_name", temp_name);

			format(temp, sizeof(temp), "FACTION MOTD by %s: %s", temp_name, temp);
			SendClientMessage(playerid, 0x00C3FFFF, temp);
		}
	}
	return 1;
}



CMD:cmotd(playerid, params[])
{
	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex == NO_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not a member of a clan.");
	if (temp_clanIndex == CLAN_NOT_FOUND) return SendClientMessage(playerid, COLOR_SERVER, "Error: There is an internal error. Please try again in a few seconds or contact server administrator (#cinvite1).");
	if (temp_clanIndex == EXPIRED_CLAN) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your clan has been expired. You cannot use this command.");

	if (playerData[playerid][account_clanRank] != 7) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the clan owner.");


	new temp[128];
	if(sscanf(params, "s[110]", temp)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /cmotd <message>");
	} else if (strlen(temp) > 100 || !isOnlyLetter(temp)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: Max characters: 100, Only Letters are allowed.");
	} else {

		new temp2[1024];
		mysql_format(Database, temp2, sizeof(temp2),"INSERT INTO `motd` (`motd_group`, `motd_group_variable`, `motd_by_name`, `motd_message`, `motd_date`) VALUES ('clan', '%d', '%s', '%e', '%d') ON DUPLICATE KEY UPDATE motd_message ='%e', motd_by_name='%s', motd_date='%d'", playerData[playerid][account_clan], playerData[playerid][account_name], temp, gettime(), temp, playerData[playerid][account_name], gettime());
		mysql_query(Database, temp2, false);

		format(temp, sizeof(temp), "%s has updated clan's MOTD: %s", playerData[playerid][account_name], temp);
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][logged] == 1 && playerData[i][account_clan]==playerData[playerid][account_clan]) {
				SendClientMessage(i,0x00C3FFFF, temp);
			}
		}
	}

	return 1;
}

forward printClanMOTD(playerid, step);
public printClanMOTD(playerid, step)
{
	if (step == 0) {
		if (playerData[playerid][account_clan] == 0) return 1;

		new temp[128];
		format(temp, sizeof(temp), "SELECT * FROM `motd` WHERE `motd_group`='clan' AND `motd_group_variable`='%d'", playerData[playerid][account_clan]);
		mysql_tquery(Database, temp, "printClanMOTD", "ii", playerid, 1);
	} else if (step == 1) {
		if (cache_num_rows() == 1) {
			new temp[256];
			new temp_name[32];

			cache_get_value_name(0, "motd_message", temp);
			cache_get_value_name(0, "motd_by_name", temp_name);

			format(temp, sizeof(temp), "CLAN MOTD by %s: %s", temp_name, temp);
			SendClientMessage(playerid, 0x00C3FFFF, temp);
		}
	}
	return 1;
}


CMD:a(playerid, params[])
{
	if (playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[144];
		if(sscanf(params, "s[144]", temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /a <message>");
		} else {
			format(temp, sizeof(temp), "[ADMIN] %d %s: %s", playerData[playerid][account_admin], playerData[playerid][account_name], temp);
			SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
		}
	}
	return 1;
}

CMD:setcameraip(playerid, params[])
{
	if (playerData[playerid][account_admin] < 6 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp[128];
		if(sscanf(params, "s[32]", temp)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /setcameraip <ip>");
		} else {
			format(STRM_CAMERA_IP, sizeof(STRM_CAMERA_IP), "%s", temp);
			format(temp, sizeof(temp), "You have set a new Stream Camera IP: %s", temp);
			SendClientMessage(playerid, 0x55705cFF, temp);
		}
	}
	return 1;
}

CMD:escape(playerid, params[])
{

	if (playerData[playerid][account_jailed] <= 60) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You can not escape right now.");
	} else {
		if (playerData[playerid][account_escaped] == 1) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You have already attempted to escape.");
		} else {
			Dialog_Show(playerid, DLG_ESCAPE, DIALOG_STYLE_MSGBOX, "Escape Confirmation", "Do you want to escape jail?\n\nPlease stay away from cops, otherwise your escape will fail.", "Confirm","Cancel");
		}
	}
	return 1;
}


Dialog:DLG_ESCAPE(playerid, response, listitem, inputtext[])
{
	if (response) {
		playerData[playerid][account_escaped] = 1;
		playerData[playerid][escape_state] = 1;
		playerData[playerid][escape_digging] = 15;
		SetPlayerCheckpoint(playerid, 1548.4712,-1665.2664,-14.3242, 3.0);
		GivePlayerWeaponSafe(playerid, 6, 1);
		SendClientMessage(playerid, COLOR_INFO, "Go to the checkpoint and start digging!");
	}
	return 1;
}


CMD:engine(playerid, params[])
{
	if (GetPlayerVehicleID(playerid) == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a vehicle.");
	} else {
		new vehicleid = GetPlayerVehicleID(playerid);
		if (!isBike(vehicleid)){
			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
			if (engine == -1) {
				engine = VEHICLE_PARAMS_OFF;
			}
			if (engine == VEHICLE_PARAMS_ON) {
				lights = VEHICLE_PARAMS_OFF;
			} else {
				lights = VEHICLE_PARAMS_ON;
			}
			SetVehicleParamsEx(vehicleid, !engine, lights, alarm, doors, bonnet, boot, objective);
		}
	}
	return 1;
}


CMD:eject(playerid, params[])
{
	if (GetPlayerVehicleID(playerid) == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a vehicle.");
	} else if (GetPlayerVehicleSeat(playerid) != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be the driver of the vehicle.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /eject <playerid>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You can not eject yourself.");
		} else if(GetPlayerVehicleID(temp_id) != GetPlayerVehicleID(playerid)) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not in your vehicle.");
		} else {
			new temp[128];
			format(temp, sizeof(temp), "*You have thrown %s out from your vehicle.", playerData[temp_id][account_name]);
			SendClientMessage(playerid, COLOR_INFO, temp);
			format(temp, sizeof(temp), "*%s has thrown you out from his vehicle.", playerData[playerid][account_name]);
			SendClientMessage(temp_id, COLOR_BADINFO, temp);

			RemovePlayerFromVehicle(temp_id);

			printf("%s thrown %s out for his vehicle.", playerData[playerid][account_name], playerData[temp_id][account_name]);
		}

	}
	return 1;
}



CMD:park(playerid, params[])
{
	if (playerData[playerid][account_wanted] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are wanted.");
	} else if (GetPlayerVehicleID(playerid) == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in your vehicle, so you can park it.");
	} else if (GetPlayerVehicleSeat(playerid) != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be the driver of your vehicle.");
	} else {
		new temp_found, temp_vehicledID;
		new vehicleid = GetPlayerVehicleID(playerid);


		if (carData[vehicleid][vehicle_owner] == playerData[playerid][account_id] && carData[vehicleid][vehicle_owner_ID] == playerid) {
			temp_found = 1;
			temp_vehicledID = carData[vehicleid][vehicle_id];
		}

		if (temp_found == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the owner of this vehicle.");
		} else {
			new temp_passengers;
			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (GetPlayerVehicleID(i) == vehicleid) {
					temp_passengers += 1;
				}
			}

			if (temp_passengers != 1) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be alone in your vehicle, so you can park it.");
			} else if (gettime() - playerData[playerid][park_cooldown] < 60 * 5) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You can use /park only one time every 5 minutes.");
			} else {

				new Float:health;
				GetVehicleHealth(vehicleid, health);

				if (health < 850) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your vehicle needs to be fully repaired before you park it.");

				playerData[playerid][park_cooldown] = gettime();


				new Float:temp_x, Float:temp_y, Float:temp_z, Float:temp_a;
				GetVehiclePos(vehicleid, temp_x, temp_y, temp_z);
				GetVehicleZAngle(vehicleid, temp_a);

				new temp[256];
				format(temp, sizeof(temp),"'%f','%f','%f','%f'", temp_x, temp_y, temp_z, temp_a);
				format(temp, sizeof(temp),"UPDATE `vehicles` SET `vehicle_parkX` = '%f', `vehicle_parkY` = '%f', `vehicle_parkZ` = '%f', `vehicle_parkA` = '%f' WHERE `vehicle_id` = %d", temp_x, temp_y, temp_z, temp_a, temp_vehicledID);
				mysql_query(Database, temp, false);

				new temp_model;
				temp_model = GetVehicleModel(vehicleid);
				DestroyVehicle(vehicleid);
				new old_vehicleid = vehicleid;
				vehicleid = CreateVehicle(temp_model, temp_x, temp_y, temp_z, temp_a, -1, -1, -1);

				carData[old_vehicleid][vehicle_owner] = 0;
				carData[old_vehicleid][vehicle_owner_ID] = -1;

				carData[vehicleid][vehicle_owner_ID] = playerid;
				carData[vehicleid][vehicle_owner] = playerData[playerid][account_id];
				carData[vehicleid][vehicle_id] = temp_vehicledID;
				carData[vehicleid][playerCar] = 1;
				
				format(temp, sizeof(temp), "SELECT `vehicle_plate`, `vehicle_color1`, `vehicle_color2` FROM `vehicles` WHERE `vehicle_id`='%d'", temp_vehicledID);
				mysql_tquery(Database, temp, "updateParkedVehicle", "ii", playerid, vehicleid);

				// Player will be put in the vehicle on thread: updateParkedVehicle
				
				format(temp, sizeof(temp), "You have parked your %s.", VehicleNames[temp_model - 400]);
				SendClientMessage(playerid, COLOR_INFO, "You have parked your vehicle.");
				printf("VEHICLE: Player %s parked his %s at %f, %f, %f, %f.", playerData[playerid][account_name], VehicleNames[temp_model - 400], temp_x, temp_y, temp_z, temp_a)
			}
		}
	}
	return 1;
}


CMD:carcolor(playerid, params[])
{
	if (GetPlayerVehicleID(playerid) == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in your vehicle.");
	} else if (GetPlayerVehicleSeat(playerid) != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be the driver of your vehicle.");
	} else {
		new temp_found, temp_vehicledID;
		new vehicleid = GetPlayerVehicleID(playerid);
		if (carData[vehicleid][vehicle_owner_ID] == playerid && carData[vehicleid][vehicle_owner] == playerData[playerid][account_id]){
			temp_found = 1;
			temp_vehicledID = carData[vehicleid][vehicle_id];
		}

		if (temp_found == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the owner of this vehicle.");
		} else {

			new temp_c1, temp_c2;
			if(sscanf(params, "ii", temp_c1, temp_c2) || temp_c1 < 0 || temp_c1 > 255 || temp_c2 < 0 || temp_c2 > 255) {
				SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /carcolor <color 1> <color 2>");
			} else {
				new temp[256];
				format(temp, sizeof(temp), "You have changed your %s's colors to %d,%d.", VehicleNames[GetVehicleModel(vehicleid) - 400], temp_c1, temp_c2);
				SendClientMessage(playerid,COLOR_INFO, temp);

				printf("CARCOLOR: %s changed his %s's colors to %d,%d", playerData[playerid][account_name], VehicleNames[GetVehicleModel(vehicleid) - 400], temp_c1, temp_c2)

				format(temp, sizeof(temp),"UPDATE `vehicles` SET `vehicle_color1` = '%d', `vehicle_color2` = '%d' WHERE `vehicle_id` = %d", temp_c1, temp_c2, temp_vehicledID);
				mysql_query(Database, temp, false);

				ChangeVehicleColor(vehicleid, temp_c1, temp_c2);
			}

		}
	}
	return 1;
}



CMD:removetuning(playerid, params[])
{
	if (GetPlayerVehicleID(playerid) == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in your vehicle.");
	} else if (GetPlayerVehicleSeat(playerid) != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be the driver of your vehicle.");
	} else {
		new temp_found, temp_vehicledID;
		new vehicleid = GetPlayerVehicleID(playerid);
		if (carData[vehicleid][vehicle_owner_ID] == playerid && carData[vehicleid][vehicle_owner] == playerData[playerid][account_id]){
			temp_found = 1;
			temp_vehicledID = carData[vehicleid][vehicle_id];
		}

		if (temp_found == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the owner of this vehicle.");
		} else {

			new temp[256];
			format(temp, sizeof(temp), "DELETE FROM `components` WHERE `component_car_id` = %d", temp_vehicledID);
			mysql_query(Database, temp, false);

			SendClientMessage(playerid, COLOR_INFO, "You have removed all of your vehicles components.");

			removeTuning(vehicleid);
		}
	}
	return 1;
}

forward modAndWanted(playerid);
public modAndWanted(playerid)
{
	if (playerData[playerid][mod_and_wanted] == 1) {
		kickAdmBot(playerid, "In a mod shop while being wanted");
	}
}


public OnEnterExitModShop(playerid, enterexit, interiorid)
{
    if(enterexit == 1) // If enterexit is 0, this means they are exiting
    {
        if (playerData[playerid][account_wanted] > 0) {
			playerData[playerid][mod_and_wanted] = 1;
			SendClientMessage(playerid, COLOR_BADINFO, "You are wanted. You have 10 seconds to leave this mod shop, or you will get kicked.");
			SetTimerEx("modAndWanted", 11000, false, "i", playerid);
		}
    } else {
		playerData[playerid][mod_and_wanted] = 0;
	}
    return 1;
}

// Solves the problem with the Plate Text that won't be changed until player respawns the vehicle.
forward updateParkedVehicle(playerid, vehicleid);
public updateParkedVehicle(playerid, vehicleid)
{
	if (cache_num_rows() == 1) {
		new temp_plate[32];
		cache_get_value_name(0, "vehicle_plate", temp_plate);
		SetVehicleNumberPlate(vehicleid, temp_plate);
		SetVehicleToRespawn(vehicleid);
		PutPlayerInVehicle(playerid, vehicleid, 0);

		new temp_c1, temp_c2;
		cache_get_value_name_int(0, "vehicle_color1", temp_c1);
		cache_get_value_name_int(0, "vehicle_color2", temp_c2);
		ChangeVehicleColor(vehicleid, temp_c1, temp_c2);

	}
}

CMD:tow(playerid, params[])
{
	new temp_count, temp[512];

	for(new i = 0, j = GetVehiclePoolSize(); i <= j; i++) {
		if (carData[i][vehicle_owner] == playerData[playerid][account_id] && carData[i][vehicle_owner_ID] == playerid) {
			if (temp_count == 0) {
				format(temp, sizeof(temp), "{bccce0}%d\t%s", i, VehicleNames[GetVehicleModel(i)-400]);
			} else {
				format(temp, sizeof(temp), "%s\n{bccce0}%d\t%s", temp, i, VehicleNames[GetVehicleModel(i)-400]);
			}

			temp_count++;
		}
	}

	if (temp_count == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You have no personal vehicles to tow.");
	} else {
		format(temp, sizeof(temp), "Vehicle ID\tVehicle Model\n%s", temp);
		Dialog_Show(playerid, DLG_TWO_VEHICLES, DIALOG_STYLE_TABLIST_HEADERS, "Tow your vehicles", temp, "Tow", "Close");
	}
	return 1;
}

Dialog:DLG_TWO_VEHICLES(playerid, response, listitem, inputtext[])
{
	if (response) {

		if (GetVehicleDriverID(strval(inputtext)) == -1) {
			SetVehicleToRespawn(strval(inputtext));
		} else {
			new temp[128];
			format(temp, sizeof(temp), "Error: You cannot tow your %s because someone is using it right now.", VehicleNames[GetVehicleModel(strval(inputtext)) - 400]);
			SendClientMessage(playerid, COLOR_BADINFO, temp);
		}

	}
	return 1;
}

/*CMD:lock(playerid, params[])
{
	new temp_count, temp[512];

	for (new c = 0; c <= MAX_VEHICLES_PER_PLAYER - 1; c++) {
		if (vehicleData[playerid][c][0] != 0 && vehicleData[playerid][c][1] != 0) {
			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(vehicleData[playerid][c][1], engine, lights, alarm, doors, bonnet, boot, objective);
			if (doors == 1) {
				if (temp_count == 0) {
					format(temp, sizeof(temp), "{bccce0}%d\t%s\t{e62c2c}Locked{bccce0}", vehicleData[playerid][c][1], VehicleNames[GetVehicleModel(vehicleData[playerid][c][1])-400]);
				} else {
					format(temp, sizeof(temp), "%s\n{bccce0}%d\t%s\t{e62c2c}Locked{bccce0}", temp, vehicleData[playerid][c][1], VehicleNames[GetVehicleModel(vehicleData[playerid][c][1])-400]);
				}
			} else {
				if (temp_count == 0) {
					format(temp, sizeof(temp), "{bccce0}%d\t%s\t{59d459}Unlocked{bccce0}", vehicleData[playerid][c][1], VehicleNames[GetVehicleModel(vehicleData[playerid][c][1])-400]);
				} else {
					format(temp, sizeof(temp), "%s\n{bccce0}%d\t%s\t{59d459}Unlocked{bccce0}", temp, vehicleData[playerid][c][1], VehicleNames[GetVehicleModel(vehicleData[playerid][c][1])-400]);
				}
			}
			temp_count++;
		}
	}

	if (temp_count == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You have no personal vehicles to lock.");
	} else {
		SendClientMessage(playerid, COLOR_INFO, "You can also press the `N` button to lock your vehicles, when you are close to them.");
		format(temp, sizeof(temp), "Vehicle ID\tVehicle Model\tStatus\n%s", temp);
		Dialog_Show(playerid, DLG_LOCK_VEHICLES, DIALOG_STYLE_TABLIST_HEADERS, "Lock your vehicles", temp, "(Un)lock", "Close");
	}
	return 1;
}*/
CMD:lock(playerid, params[])
{
	SendClientMessage(playerid, COLOR_INFO, "This command has been removed. You can lock your vehicle with `N` and list all your vehicles with /locations");
	return 1;
}

Dialog:DLG_LOCK_VEHICLES(playerid, response, listitem, inputtext[])
{
	if (response) {
		new engine, lights, alarm, doors, bonnet, boot, objective;
		GetVehicleParamsEx(strval(inputtext), engine, lights, alarm, doors, bonnet, boot, objective);

		doors = !doors;
		SetVehicleParamsEx(strval(inputtext), engine, lights, alarm, doors, bonnet, boot, objective);

		new temp[128];
		if (doors == 1) {
			format(temp, sizeof(temp), "Your %s is now locked.", VehicleNames[GetVehicleModel(strval(inputtext)) - 400]);
		} else {
			format(temp, sizeof(temp), "Your %s is now unlocked.", VehicleNames[GetVehicleModel(strval(inputtext)) - 400]);
		}
		SendClientMessage(playerid, COLOR_INFO, temp);
		textLockVehicle(strval(inputtext));

		cmd_lock(playerid, "");
	}
	return 1;
}

CMD:pay(playerid, params[])
{
	new temp_id, temp_amount;
	if(sscanf(params, "ui", temp_id, temp_amount) || temp_amount <= 0) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /pay <player> <amount>");
	} else if (temp_id == playerid) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot send money to yourself.");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else {
		if (playerData[playerid][account_money] < temp_amount) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have that amount of money.");
		} else {
			new temp[128];
			format(temp, 128, "\nAre you sure you want to send $%s to %s (%d)?", formatMoney(temp_amount), playerData[temp_id][account_name], temp_id);
			playerData[playerid][pay_id] = temp_id;
			playerData[playerid][pay_amount] = temp_amount;
			Dialog_Show(playerid, DLG_PAY_CONFIRMATION, DIALOG_STYLE_MSGBOX, "Pay: Confirmation", temp, "Confirm","Cancel");
		}
	}
	return 1;
}

Dialog:DLG_PAY_CONFIRMATION(playerid, response, listitem, inputtext[])
{
	if (response) {
		new temp_id = playerData[playerid][pay_id], temp_amount = playerData[playerid][pay_amount];
		if (playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online anymore.");
		} else {
			new temp[128];
			format(temp, 128, "You have given $%s to %s (%d).", formatMoney(temp_amount), playerData[temp_id][account_name], temp_id);
			SendClientMessage(playerid, COLOR_INFO, temp);
			format(temp, 128, "%s (%d) has given to you $%s.", playerData[playerid][account_name], playerid, formatMoney(temp_amount));
			SendClientMessage(temp_id, COLOR_INFO, temp);
			giveMoney(playerid, -temp_amount);
			giveMoney(temp_id, temp_amount);
			printf("Pay: %s paid %s %s$.", playerData[playerid][account_name], playerData[temp_id][account_name], formatMoney(temp_amount));
		}
	}
	return 1;
}

/*
CMD:paintball(playerid, params[])
{
	if(!IsPlayerInRangeOfPoint(playerid, 3.0, 1109.8433, -1796.7095, 16.5938) && ServerInProduction) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not near at the entrance of Paintball.");
	} else if (playerData[playerid][account_wanted] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are wanted.");
	} else {
		if (PAINTBALL_STATE == 0) {
			PAINTBALL_STATE = 1;
			PaintballStartedOn = gettime();
			new temp[128];
			format(temp, 128, "%s (%d) has started a new Paintball match. Join him within the next 20 seconds.", playerData[playerid][account_name], playerid);
			SendClientMessageToAll(COLOR_PUBLIC, temp);
			printf("%s", temp);
			playerData[playerid][paintball_joined] = 1;

			SetPlayerPos(playerid, 1788.0723,3152.8696,133.6369);
			SetPlayerFacingAngle(playerid, 260.3904);
			TogglePlayerControllable(playerid, 0);
			SetPlayerVirtualWorld(playerid, 5);

		} else if (PAINTBALL_STATE == 1) {

			playerData[playerid][paintball_joined] = 1;
			SetPlayerPos(playerid, 1788.0723,3152.8696,133.6369);
			SetPlayerFacingAngle(playerid, 260.3904);
			TogglePlayerControllable(playerid, 0);
			SetPlayerVirtualWorld(playerid, 5);

			new temp[128];
			format(temp, 128, "Player %s (%d) joined the match.", playerData[playerid][account_name], playerid);
			SendClientMessageToPaintballers(COLOR_PAINTBALL, temp);

		} else {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You can not join right now. Wait for the next match.");
		}
	}
	return 1;
}*/


Dialog:DLG_PAINTBALL_CLASS(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (listitem == 1 && playerData[playerid][account_score] < 5 || listitem == 2 && playerData[playerid][account_score] < 15 || listitem == 3 && playerData[playerid][account_score] < 30 || listitem == 4 && playerData[playerid][account_score] < 40 || listitem == 5 && playerData[playerid][account_score] < 80) {
			Dialog_Show(playerid, DLG_PAINTBALL_CLASS, DIALOG_STYLE_TABLIST_HEADERS, "Paintball: Weapon Class", PAINTBALL_CLASS_STRING,	"Confirm", "");
		} else {
			playerData[playerid][paintball_class] = listitem;
		}
	} else {
		Dialog_Show(playerid, DLG_PAINTBALL_CLASS, DIALOG_STYLE_TABLIST_HEADERS, "Paintball: Weapon Class", PAINTBALL_CLASS_STRING, "Confirm", "");
	}
	return 1;
}

CMD:togcolorchat(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[128];
		chatIsOff = !chatIsOff;
		if (chatIsOff) {
			format(temp, 128, "Admin %s has disabled public chat.", playerData[playerid][account_name]);
		} else {
			format(temp, 128, "Admin %s has enabled public chat.", playerData[playerid][account_name]);
		}
		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
	}
	return 1;
}

CMD:togmodechat(playerid, params[])
{
	if(playerData[playerid][account_admin] < 5) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[128];
		modeChat = !modeChat;

		format(temp, 128, "Admin %s has changed chat mode.", playerData[playerid][account_name]);

		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
	}
	return 1;
}


CMD:tagchat(playerid, params[])
{
	if(playerData[playerid][account_admin] < 5) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[128];
		colorTagInChat = !colorTagInChat;
		format(temp, sizeof(temp), "colorTagInChat: %d", colorTagInChat);
		SendClientMessage(playerid, -1, temp);
	}
	return 1;
}


CMD:enter(playerid, params[])
{
	door_enter(playerid);
	return 1;
}

CMD:exit(playerid, params[])
{
	door_exit(playerid);
	return 1;
}

CMD:ahelp(playerid,params[])
{
	if(playerData[playerid][account_admin]<1) return SendClientMessage(playerid, 0x5CAD5CFF, "Error: Your admin level isn't high enough.");

	SendClientMessage(playerid, 0x33AA33AA,"____________________________________________________________________________");
	SendClientMessage(playerid, 0xB4B5B7FF, "*1* ADMIN *** /a /cr /goto /gotoin /stopevent /acceptevent /slap /kick /warn /ban");
	SendClientMessage(playerid, 0xB4B5B7FF, "*1* ADMIN *** /pm /spec(off) /getweapons");
	SendClientMessage(playerid, 0xB4B5B7FF, "*2* ADMIN *** /gethere /cc /check /respawn /(un)freeze");
	SendClientMessage(playerid, 0xB4B5B7FF, "*3* ADMIN *** /stoppaintball /sethp /setarmour");
	SendClientMessage(playerid, 0xB4B5B7FF, "*4* ADMIN *** /togcolorchat /sinvite /rac /setskin /setjail /makeleader /givescoreall /givemoneyall /healall");
	SendClientMessage(playerid, 0xB4B5B7FF, "*5* ADMIN *** /tagchat /makehelper /reloadbiz /reloadhouses /reloadcars /setmoney /reloadclans /addhouse /togmodechat");
	SendClientMessage(playerid, 0xB4B5B7FF, "*6* ADMIN *** /makeadmin /kickall");

	return CMD_SUCCESS;
}


CMD:hhelp(playerid,params[])
{
	if(playerData[playerid][account_helper]<1) return SendClientMessage(playerid, 0x5CAD5CFF, "Error: Your helper level isn't high enough.");

	SendClientMessage(playerid, 0x33AA33AA,"____________________________________________________________________________");
	SendClientMessage(playerid, 0xB4B5B7FF, "*1* HELPER *** /h /pm /hanswer");
	SendClientMessage(playerid, 0xB4B5B7FF, "*2* HELPER *** /goto /stopevent /acceptevent /slap /gotoin");

	return CMD_SUCCESS;
}

CMD:giverank(playerid, params[])
{
	if(playerData[playerid][account_rank] < 7 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_level, temp_reason[32];
		if(sscanf(params, "uis[32]", temp_id, temp_level,temp_reason) || temp_level <= 0 || temp_level >= 7) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /giverank <player> <level 1-6> <reason>");
		} else if (strlen(temp_reason) > 32 || !isOnlyLetter(temp_reason)) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Reason text is too large. Only letters are accepted.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot change your rank.");
		} else if (playerData[temp_id][account_rank] == temp_level) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player has already that rank.");
		} else if (playerData[temp_id][account_faction] != playerData[playerid][account_faction]) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not in your faction.");
		} else {
			new temp[128], tempE[512];

			new temp_old_level = playerData[temp_id][account_rank];

			if (temp_level > temp_old_level) {
				format(temp, sizeof(temp), "%s has been promoted to Rank %d by %s. Reason: %s", playerData[temp_id][account_name], temp_level, playerData[playerid][account_name], temp_reason);
			}

			if (temp_level < temp_old_level) {
				format(temp, sizeof(temp), "%s has been demoted to Rank %d by %s. Reason: %s", playerData[temp_id][account_name], temp_level, playerData[playerid][account_name], temp_reason);
			}

			SendClientMessageToFaction(playerData[playerid][account_faction], 0x00C3FFFF, temp);

			playerData[temp_id][account_rank] = temp_level;

			mysql_format(Database, tempE, sizeof(tempE),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'rank', '%d', '%d', '%d', '%e', '%d')", playerData[temp_id][account_id], temp_level, playerData[playerid][account_id], gettime(), temp_reason, playerData[playerid][account_faction]);
			mysql_query(Database, tempE, false);
		}
	}
	return 1;
}


CMD:makehelper(playerid, params[])
{
	if(playerData[playerid][account_admin] < 5 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_level;
		if(sscanf(params, "ui", temp_id, temp_level)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /makehelper <player> <level>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[temp_id][account_helper] == temp_level) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player has already that helper level.");
		} else {
			new temp[128], temp2[128], tempE[512], temp_old_level;
			temp_old_level = playerData[temp_id][account_helper];

			if (temp_level == 0) {
				format(temp, sizeof(temp), "You have been removed from helpers's position by %s.", playerData[playerid][account_name]);
				format(temp2, sizeof(temp2), "You have removed %s from helpers's position.", playerData[temp_id][account_name]);
			} else if (temp_level > temp_old_level) {
				format(temp, sizeof(temp), "You have been promoted to Helper Level %d by %s.", temp_level, playerData[playerid][account_name]);
				format(temp2, sizeof(temp2), "You have promoted %s to Helper Level %d.", playerData[temp_id][account_name], temp_level);
			} else if (temp_level < temp_old_level) {
				format(temp, sizeof(temp), "You have been demoted to Helper Level %d by %s.", temp_level, playerData[playerid][account_name]);
				format(temp2, sizeof(temp2), "You have demoted %s to Helper Level %d.", playerData[temp_id][account_name], temp_level);
			}

			SendClientMessage(temp_id, 0x00C3FFFF, temp);
			SendClientMessage(playerid, 0x00C3FFFF, temp2);

			playerData[temp_id][account_helper] = temp_level;

			format(tempE, sizeof(tempE),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'helper', '%d', '%d', '%d', '', '0')", playerData[temp_id][account_id], temp_level, playerData[playerid][account_id], gettime());
			mysql_query(Database, tempE, false);
		}
	}
	return 1;
}


CMD:makeadmin(playerid, params[])
{
	if(playerData[playerid][account_admin] < 6 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_level;
		if(sscanf(params, "ui", temp_id, temp_level)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /makeadmin <player> <level>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[temp_id][account_admin] == temp_level) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player has already that admin level.");
		} else {
			new temp[128], temp2[128], tempE[512], temp_old_level;
			temp_old_level = playerData[temp_id][account_admin];

			if (temp_level == 0) {
				format(temp, sizeof(temp), "You have been removed from admin's position by %s.", playerData[playerid][account_name]);
				format(temp2, sizeof(temp2), "You have removed %s from admin's position.", playerData[temp_id][account_name]);
			} else if (temp_level > temp_old_level) {
				format(temp, sizeof(temp), "You have been promoted to Admin Level %d by %s.", temp_level, playerData[playerid][account_name]);
				format(temp2, sizeof(temp2), "You have promoted %s to Admin Level %d.", playerData[temp_id][account_name], temp_level);
			} else if (temp_level < temp_old_level) {
				format(temp, sizeof(temp), "You have been demoted to Admin Level %d by %s.", temp_level, playerData[playerid][account_name]);
				format(temp2, sizeof(temp2), "You have demoted %s to Admin Level %d.", playerData[temp_id][account_name], temp_level);
			}

			SendClientMessage(temp_id, 0x00C3FFFF, temp);
			SendClientMessage(playerid, 0x00C3FFFF, temp2);

			playerData[temp_id][account_admin] = temp_level;

			format(tempE, sizeof(tempE),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'admin', '%d', '%d', '%d', '', '0')", playerData[temp_id][account_id], temp_level, playerData[playerid][account_id], gettime());
			mysql_query(Database, tempE, false);
		}
	}
	return 1;
}

CMD:contract(playerid, params[])
{
	if (playerData[playerid][account_faction] == FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: Cops cannot send contracts.");
	} else if (playerData[playerid][account_faction] == FACTION_HITMAN) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: As a hitman you cannot send contracts.");
	} else {

		new temp_id, temp_price;
		if (sscanf(params, "ui", temp_id, temp_price)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /contract <player> <price>");
		} else if (temp_price < 1000) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Minimum price is $1.000.");
		} else if (playerData[temp_id][account_faction] == FACTION_HITMAN) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot send a contract on a hitman.")
		} else if (playerid == temp_id) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot send a contract on yourself.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[playerid][account_money] < temp_price) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money send a contract for that price.");
		} else {
			new temp[128];

			SendClientMessage(playerid, COLOR_SERVER, "Your contract has been sent.");

			playerData[temp_id][account_contracts] += 1;
			playerData[temp_id][account_contracts_price] += temp_price;

			giveMoney(playerid, -temp_price);

			format(temp, sizeof(temp), "A new contract has been sent for %s (%d). Contracts: %d, Reward: $%s", playerData[temp_id][account_name], temp_id, playerData[temp_id][account_contracts], formatMoney(playerData[temp_id][account_contracts_price]));

			SendClientMessageToFaction(FACTION_HITMAN, COLOR_FACTION, temp);
		}
	}
	return 1;
}


CMD:contracts(playerid, params[])
{
	if (playerData[playerid][account_faction] != FACTION_HITMAN) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: Only a hitman can use this command.");
	} else {
		new temp[512];
		new temp_count = 0;
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][account_contracts] > 0) {
				if (temp_count == 0) {
					format(temp, sizeof(temp), "%s (%d)\t%d\t%d", playerData[i][account_name], i, playerData[i][account_contracts], playerData[i][account_contracts_price]);
				} else {
					format(temp, sizeof(temp), "%s\n%s (%d)\t%d\t%d", temp, playerData[i][account_name], i, playerData[i][account_contracts], playerData[i][account_contracts_price]);
				}
				temp_count++;
			}
		}
		if (temp_count > 0) {
			format(temp, sizeof(temp), "Player\tContracts\tReward\n%s", temp);
			Dialog_Show(playerid, DLG_CONTRACTS, DIALOG_STYLE_TABLIST_HEADERS, "Contracts", temp, "OK", "");
		} else {
			Dialog_Show(playerid, DLG_CONTRACTS, DIALOG_STYLE_MSGBOX, "Contracts", "There is no online player with a contract.", "OK", "");
		}
	}
	return 1;
}


CMD:respawn(playerid, params[])
{
	if(playerData[playerid][account_admin] < 2 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /respawn <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			format(temp, 128, "Admin %s respawned %s.", playerData[playerid][account_name], playerData[temp_id][account_name]);
			SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
			printf("%s", temp);

			SpawnPlayer(temp_id);

			SendClientMessage(temp_id, COLOR_SERVER, "An admin has respawned you.");
		}
	}
	return 1;
}


CMD:gotoin(playerid, params[])
{
	if(playerData[playerid][account_helper] < 2 && playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		playerData[playerid][enteredBiz] = 0;
		playerData[playerid][enteredHouse] = 0;

		SetPlayerPos(playerid, 1412.639892,-1.787510,1000.924377);
		SetPlayerInterior(playerid, 1);

		new temp[128];
		if (!IsPlayerAdmin(playerid)) {
			if (playerData[playerid][account_admin] > 0) {
				format(temp, sizeof(temp), "%s teleported to gotoin.", playerData[playerid][account_name]);
				SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
			} else if (playerData[playerid][account_helper] > 0) {
				format(temp, sizeof(temp), "%s teleported to gotoin.", playerData[playerid][account_name]);
				for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
					if (playerData[i][logged] == 1 && playerData[i][account_helper] >=1) {
						SendClientMessage(i,COLOR_ADMIN, temp);
					}
				}
			}
		}
	}
	return 1;
}

CMD:goto(playerid, params[])
{
	if(playerData[playerid][account_helper] < 2 && playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /goto <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {

			if (playerData[playerid][account_admin] < 5 && (GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(temp_id) || GetPlayerInterior(playerid) != GetPlayerInterior(temp_id))) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not in the same VW or Interior with you. Use /spec or /respawn him.");

			new temp[128];

			format(temp, 128, "Admin %s teleported to %s's position.", playerData[playerid][account_name], playerData[temp_id][account_name]);
			SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
			printf("%s", temp);

			new Float:temp_x, Float:temp_y, Float:temp_z;
			GetPlayerPos(temp_id, temp_x, temp_y, temp_z);
			SetPlayerPos(playerid, temp_x + 2, temp_y + 3, temp_z+1);

			SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(temp_id));
			SetPlayerInterior(playerid, GetPlayerInterior(temp_id));
		}
	}
	return 1;
}


CMD:gethere(playerid, params[])
{
	if(playerData[playerid][account_admin] < 2 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /getere <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			format(temp, 128, "Admin %s teleported %s's to his position.", playerData[playerid][account_name], playerData[temp_id][account_name]);
			SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
			printf("%s", temp);

			SendClientMessage(temp_id, COLOR_SERVER, "You have been teleported.");

			new Float:temp_x, Float:temp_y, Float:temp_z;
			GetPlayerPos(playerid, temp_x, temp_y, temp_z);
			SetPlayerPos(temp_id, temp_x + 2, temp_y + 3, temp_z+1);

			SetPlayerInterior(temp_id, GetPlayerInterior(playerid));
			SetPlayerVirtualWorld(temp_id, GetPlayerVirtualWorld(playerid));
		}
	}
	return 1;
}

CMD:cc(playerid, params[])
{
	if(playerData[playerid][account_admin] < 2 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		for (new i=0; i < 80; i++) {
			SendClientMessageToAll(-1, " ");
		}
		new temp[128];
		format(temp, 128, "Admin %s cleared the chat.", playerData[playerid][account_name]);
		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
		printf("%s", temp);
	}
	return 1;
}



forward putPlayerInNewCar(playerid, modelid);
public putPlayerInNewCar(playerid, modelid)
{
	for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
		if (carData[i][vehicle_owner] == playerData[playerid][account_id] && carData[i][vehicle_owner_ID] == playerid) {
			if (GetVehicleModel(i) == modelid) {
				PutPlayerInVehicle(playerid, i, 0);
			}
		}
	}

	return 1;
}

CMD:reloadbiz(playerid, params[])
{
	if(playerData[playerid][account_admin] < 5 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[128];
		format(temp, 128, "Admin %s reloaded all server's businesses.", playerData[playerid][account_name]);
		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
		loadBiz(2);
		SetTimerEx("loadBiz", 600, 0, "i", 0);
	}
	return 1;
}


CMD:reloadclans(playerid, params[])
{
	if(playerData[playerid][account_admin] < 5 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[128];
		format(temp, 128, "Admin %s reloaded all server's clans.", playerData[playerid][account_name]);
		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
		loadClans(2);
		SetTimerEx("loadClans", 600, 0, "i", 0);
	}
	return 1;
}

CMD:reloadhouses(playerid, params[])
{
	if(playerData[playerid][account_admin] < 5 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp[128];
		format(temp, 128, "Admin %s reloaded all server's houses.", playerData[playerid][account_name]);
		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
		houseTogUpdate = 1;
		loadHouses(2);
		SetTimerEx("loadHouses", 600, 0, "i", 0);
	}
	return 1;
}

CMD:reloadcars(playerid, params[])
{
	if(playerData[playerid][account_admin] < 5 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /reloadcars <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];
			format(temp, 128, "Admin %s reloaded %s's vehicles.", playerData[playerid][account_name], playerData[temp_id][account_name]);
			SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
			
			unloadPlayerVehicles(temp_id);
			SetTimerEx("loadPlayerVehicles", 1000, 0, "ii", temp_id, 0);
		}
	}
	return 1;
}

CMD:addhouse(playerid, params[])
{
	if (playerData[playerid][account_admin] < 5 && !IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");

	new temp_interior, temp_sell;
	if (sscanf(params, "ii", temp_interior, temp_sell) || temp_interior <= 0 || temp_interior >= sizeof(BUYHOUSE_INTERIORS)) return SendClientMessage(playerid, COLOR_SERVER, "Syntax: /addhouse <interior> <sell price>");
	new temp[1024];
	format(temp, sizeof(temp), "You have added a new house. Interior: %d, Sell Price: $%s", temp_interior, formatMoney(temp_sell));
	SendClientMessage(playerid, COLOR_INFO, temp);

	new Float:temp_x, Float:temp_y, Float: temp_z;
	GetPlayerPos(playerid, temp_x, temp_y, temp_z);

	format(temp, sizeof(temp),"INSERT INTO `houses` (`house_owner`, `house_interior`, `house_exteriorX`, `house_exteriorY`, `house_exteriorZ`, `house_owner_name`, `house_date`, `house_price`, `house_sell`, `house_locked`) VALUES ('-1', '%d', '%f', '%f', '%f', 'Server', '%d', '%d', '%d', '0')", temp_interior, temp_x, temp_y, temp_z, gettime(), temp_sell, temp_sell);
	mysql_query(Database, temp, false);
	print(temp);

	houseTogUpdate = 1;
	loadHouses(2);
	SetTimerEx("loadHouses", 600, 0, "i", 0);
	return 1;
}

/*CMD:accepthouse(playerid, params[])
{
	if(playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /accepthouse <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[temp_id][buyhouse_confirmed] != 1) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player does not have an active house request.");
		} else {

			playerData[temp_id][buyhouse_confirmed] = 0;

			new temp[512], tempE[256];
			format(temp, sizeof(temp), "Admin %s has accepted %s's new House request.", playerData[playerid][account_name], playerData[temp_id][account_name]);
			SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
			if (playerData[temp_id][account_admin] < 1) {
				SendClientMessage(temp_id, COLOR_ADMIN, temp);
			}

			giveMoney(temp_id, -playerData[temp_id][buyhouse_price]);
			giveMoney(playerid, 4000);

			PlayerPlaySound(temp_id, 182, 0.0,0.0,0.0);
			SetTimerEx("stopPlayerSound", 7400, 0, "i", temp_id);

			Dialog_Close(temp_id);

			new Float:temp_x, Float:temp_y, Float:temp_z;
			GetPlayerPos(temp_id, temp_x, temp_y, temp_z);

			playerData[temp_id][account_score] += 15;
			printf("SCORE: Player %s received 15 Score point for buying new house.", playerData[temp_id][account_name]);

			format(temp, sizeof(temp),"INSERT INTO `houses` (`house_owner`, `house_interior`, `house_date`, `house_price`, `house_exteriorX`, `house_exteriorY`, `house_exteriorZ`, `house_owner_name`) VALUES ('%d', '%d', '%d', '%d', '%f', '%f', '%f', '%s')", playerData[temp_id][account_id], playerData[temp_id][buyhouse_interior], gettime(), playerData[temp_id][buyhouse_price], temp_x, temp_y, temp_z, playerData[temp_id][account_name]);
			mysql_query(Database, temp, false);

			format(temp, sizeof(temp),"{\"interior\":%d,\"admin\":%d,\"happened\":%d}", playerData[temp_id][buyhouse_interior], playerData[playerid][account_id], gettime());
			mysql_escape_string(temp, tempE);
			format(tempE, sizeof(tempE),"INSERT INTO `logs` (`log_player`, `log_type`, `log_info`) VALUES ('%d', 'buyhouse', '%s')", playerData[temp_id][account_id], tempE);
			mysql_query(Database, tempE, false);

			loadHouses(2);
			SetTimerEx("loadHouses", 600, 0, "i", 0);

		}
	}
	return 1;
}*/


CMD:rob(playerid, params[])
{
	if (playerData[playerid][account_faction] == FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: Members from Police Department are not allowed to rob or steal cars.");
	} else if (playerData[playerid][robbing_state] > 0) {
		SendClientMessage(playerid, COLOR_BADINFO, "Error: You are already robbing a bank.");
	} else if (playerData[playerid][account_escaped] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are escaping.");
	} else {
		if (playerData[playerid][special_interior] == INTERIOR_BANK_LS || playerData[playerid][special_interior] == INTERIOR_BANK_SF) {

			if (playerData[playerid][special_interior] == INTERIOR_BANK_LS && gettime() - playerData[playerid][account_robLS_cooldown] < ROB_PER_CITY_COOL) {

				new temp[128];
				format(temp, sizeof(temp), "You need to wait %d more seconds before you rob this bank again. Rob one from the other available banks (/biz).", ROB_PER_CITY_COOL - (gettime() - playerData[playerid][account_robLS_cooldown]));
				SendClientMessage(playerid, COLOR_BADINFO, temp);
			} else if (playerData[playerid][special_interior] == INTERIOR_BANK_SF && gettime() - playerData[playerid][account_robSF_cooldown] < ROB_PER_CITY_COOL) {

				new temp[128];
				format(temp, sizeof(temp), "You need to wait %d more seconds before you rob this bank again. Rob one from the other available banks (/biz).", ROB_PER_CITY_COOL - (gettime() - playerData[playerid][account_robSF_cooldown]));
				SendClientMessage(playerid, COLOR_BADINFO, temp);

			} else {

				if(playerData[playerid][special_interior] == INTERIOR_BANK_LS) {
					playerData[playerid][account_robLS_cooldown] = gettime();
					playerData[playerid][robbing_inbank] = INTERIOR_BANK_LS;
					
					new query_temp[256];
					format(query_temp, sizeof(query_temp), "**%s** is robbing the LS Bank!", playerData[playerid][account_name]);
					mysql_format(Database, query_temp, sizeof(query_temp),"INSERT INTO `discord_message` (`message_content`, `webhook_name`, `added_on`) VALUES ( '%s', 'welcome', '%d')", query_temp, gettime());
					mysql_query(Database, query_temp, false);

					reportCrime(playerid, 6, "Robbing the bank LS");
				}
				if(playerData[playerid][special_interior] == INTERIOR_BANK_SF) {
					playerData[playerid][account_robSF_cooldown] = gettime();
					playerData[playerid][robbing_inbank] = INTERIOR_BANK_SF;

					new query_temp[256];
					format(query_temp, sizeof(query_temp), "**%s** is robbing the SF Bank!", playerData[playerid][account_name]);
					mysql_format(Database, query_temp, sizeof(query_temp),"INSERT INTO `discord_message` (`message_content`, `webhook_name`, `added_on`) VALUES ( '%s', 'welcome', '%d')", query_temp, gettime());
					mysql_query(Database, query_temp, false);

					reportCrime(playerid, 6, "Robbing the bank SF");
				}

				new temp_countPD = 0;
				for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
					if (playerData[i][account_faction] == FACTION_LSPD && !IsPlayerAfk(i)) {
						temp_countPD++;
					}
				}

				if (temp_countPD == 0) {
					playerData[playerid][robbing_max_money] = 1000;
					SendClientMessage(playerid, COLOR_INFO, "You can collect approximately $1.000.");
				} else {
					playerData[playerid][robbing_max_money] = 5000;
					SendClientMessage(playerid, COLOR_INFO, "You can collect approximately $5.000.");
				}

				SetPlayerAttachedObject(playerid,1,1550,1,0.000000,-0.315000,0.000000,0.000000,87.099960,0.000000,1.000000,1.000000,1.000000);

				playerData[playerid][robbing_state] = 1;
				playerData[playerid][robbing_money] = 0;
				playerData[playerid][robbing_msg_flag] = 0;


			}

		} else {
			new Float: temp_x, Float: temp_y, Float: temp_z;

			new temp_vehicleid;
			for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {

				GetVehiclePos(i, temp_x, temp_y, temp_z);
				if (IsPlayerInRangeOfPoint(playerid, 4.0, temp_x, temp_y, temp_z)) {
					temp_vehicleid = i;
					break;
				}
			}

			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(temp_vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);

			if (temp_vehicleid == 0 || doors == 0) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You are not near a locked car or in the bank.");
			} else if (GetVehicleDriverID(temp_vehicleid) != -1){
				SendClientMessage(playerid, COLOR_SERVER, "Error: This vehicle is being currntly driven.");
			} else {
				new temp_ownerid = -1;

				if (carData[temp_vehicleid][playerCar] == 1 && carData[temp_vehicleid][vehicle_owner] != 0) {
					temp_ownerid = carData[temp_vehicleid][vehicle_owner_ID];
				} else {
					temp_ownerid = -1;
				}

				if (temp_ownerid == -1) {
					SendClientMessage(playerid, COLOR_SERVER, "Error: You are not near a locked car.");
				} else if (temp_ownerid == playerid) {
					SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot steal your own car.");
				} else if (random(2) == 1) {
					SendClientMessage(playerid, COLOR_SERVER, "Error: Your rob attempt failed with this car. You can try again.");

					reportCrime(playerid, 1, "Attempting to rob a car");
				} else {
					new temp[128];
					format(temp, sizeof(temp), "%s (%d) stole your %s. He has been reported to Police Department.", playerData[playerid][account_name], playerid, VehicleNames[GetVehicleModel(temp_vehicleid) - 400]);
					SendClientMessage(temp_ownerid, COLOR_BADINFO, temp);

					SetVehicleParamsEx(temp_vehicleid, engine, lights, alarm, 0, bonnet, boot, objective);

					reportCrime(playerid, 4, "Robbing a car");

					textLockVehicle(temp_vehicleid);
				}
			}
		}
	}
	return 1;
}

CMD:crash(playerid,params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new targetid;

	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_SERVER, "Syntax: /crash <player>");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_SERVER, "Error: Player is offline.");

	GameTextForPlayer(targetid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 1000, 0);
	GameTextForPlayer(targetid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 2000, 1);
	GameTextForPlayer(targetid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 3000, 2);
	GameTextForPlayer(targetid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 4000, 3);
	GameTextForPlayer(targetid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 5000, 4);
	GameTextForPlayer(targetid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 6000, 5);
	GameTextForPlayer(targetid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 7000, 6);
	GameTextForPlayer(targetid, "???�!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 12000, 6);
	
	SendClientMessage(playerid, -1, "OK");
	return 1;
}


CMD:getmat(playerid, params[])
{
	return cmd_getmaterials(playerid, params);
}

CMD:getmats(playerid, params[])
{
	return cmd_getmaterials(playerid, params);
}

CMD:getmaterials(playerid, params[])
{
	if (playerData[playerid][account_faction] == FACTION_LSPD) return SendClientMessage(playerid, COLOR_SERVER, "Error: You can not deliver materials as a Cop.");

	if (playerData[playerid][account_jailed] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	} else if (playerData[playerid][account_escaped] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	} else if (playerData[playerid][robbing_state] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");
	}  else if (playerData[playerid][tracking_mode] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are tracking a player. Use /trackoff first.");
	}  else if (playerData[playerid][am_working] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are working right now. Stop your current work and try again.");
	} else {
		if (!IsPlayerInRangeOfPoint(playerid, 3.0, 2770.7419,-1628.3348,12.1775)) return SendClientMessage(playerid, COLOR_SERVER, "You are not near the /getmaterials place.");

		SendClientMessage(playerid, COLOR_INFO, "Deliver the materials at the checkpoint and get your half there.");

		playerData[playerid][am_working] = WORKING_DEALER;

		setCheckpoint(playerid, 1712.9161,913.1354,10.8203, 3.0);
	}
	return 1;
}

CMD:delivermat(playerid, params[])
{
	return cmd_delivermaterials(playerid, params);
}

CMD:delivermats(playerid, params[])
{
	return cmd_delivermaterials(playerid, params);
}

CMD:delivermaterials(playerid, params[])
{
	if (playerData[playerid][am_working] != WORKING_DEALER) return SendClientMessage(playerid, COLOR_SERVER, "You are not working as a dealer right now.");

	if (!IsPlayerInRangeOfPoint(playerid, 3.0, 1712.9161,913.1354,10.8203)) return SendClientMessage(playerid, COLOR_SERVER, "You are not near the /delivermaterials place.");

	playerData[playerid][account_skillMaterials] ++;

	if (playerData[playerid][account_skillMaterials] < 10) {
		playerData[playerid][account_materials] +=  200 + random(100);
	} else if (playerData[playerid][account_skillMaterials] == 10 ) {
		SendClientMessage(playerid, COLOR_INFO, "You have delivered materials 10 times. You will now get more materials.");
		playerData[playerid][account_materials] +=  350 + random(100);
	} else if (playerData[playerid][account_skillMaterials] < 30) {
		playerData[playerid][account_materials] +=  350 + random(100);
	} else if (playerData[playerid][account_skillMaterials] == 30) {
		playerData[playerid][account_materials] +=  450 + random(100);
		SendClientMessage(playerid, COLOR_INFO, "You have delivered materials 30 times. You will now get more materials.");
	} else if (playerData[playerid][account_skillMaterials] < 60) {
		playerData[playerid][account_materials] +=  450 + random(100);
	} else if (playerData[playerid][account_skillMaterials] == 60) {
		playerData[playerid][account_materials] +=  650 + random(100);
		SendClientMessage(playerid, COLOR_INFO, "You have delivered materials 60 times. You will now get more materials.");
	} else if (playerData[playerid][account_skillMaterials] < 120) {
		playerData[playerid][account_materials] +=  650 + random(100);
	} else if (playerData[playerid][account_skillMaterials] == 120) {
		playerData[playerid][account_materials] +=  1200 + random(100);
		SendClientMessage(playerid, COLOR_INFO, "You have delivered materials 120 times. You will now get more materials.");
	} else {
		playerData[playerid][account_materials] +=  1200 + random(100);
	}

	new temp[128];
	format(temp, sizeof(temp), "* You have delivered the materials. You have now %d materials (/materialshelp).", playerData[playerid][account_materials]);
	SendClientMessage(playerid, COLOR_INFO, temp);

	playerData[playerid][am_working] = 0;

	return 1;
}

CMD:sellgun(playerid, params[])
{
	if (playerData[playerid][account_faction] == FACTION_LSPD) return SendClientMessage(playerid, COLOR_SERVER, "Error: You can not sell guns as a Cop.");

	if (playerData[playerid][account_jailed] > 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	
	if (playerData[playerid][account_escaped] > 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");

	if (playerData[playerid][account_skillMaterials] < 10) return  SendClientMessage(playerid, COLOR_SERVER, "You need at least 10 delivieries to unlock this command.");

	if (playerData[playerid][account_materials] < 500) return SendClientMessage(playerid, COLOR_SERVER, "You need at least 500 materials in order to sell a gun.");

	new temp_id, temp_var[32], temp_price;
	if(sscanf(params, "uis[32]", temp_id, temp_price, temp_var) || temp_price > 500 || temp_price < 10) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /sellgun <player> <price $10-$500> <gun: deagle, mp5, ak47, uzi>");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else if (temp_id == playerid) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You can not sell a gun to yourself.");
	} else {

		new Float: tempx, Float: tempy, Float: tempz;
		GetPlayerPos(playerid, tempx, tempy, tempz);
		if (!IsPlayerInRangeOfPoint(temp_id, 10.0, tempx, tempy, tempz)) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not near you."); 
		new temp_gun = 0;
		if (strcmp(temp_var, "deagle") == 0) {
			temp_gun = 24;
		} else if (strcmp(temp_var, "mp5") == 0) {
			temp_gun = 29;
		} else if (strcmp(temp_var, "ak47") == 0) {
			temp_gun = 30;
		} else if (strcmp(temp_var, "uzi") == 0) {
			temp_gun = 28;
		} else {
			return SendClientMessage(playerid, COLOR_SERVER, "Error: Invalid weapon.");
		}

		new temp[128];
		format(temp, sizeof(temp), "* You are offering a %s to %s for $%s.", GunNames[temp_gun], playerData[temp_id][account_name], formatMoney(temp_price));
		SendClientMessage(playerid, COLOR_INFO, temp);
		format(temp, sizeof(temp), "* %s is offering you a %s for $%s. Use /acceptgun %d", playerData[playerid][account_name], GunNames[temp_gun], formatMoney(temp_price), playerid);
		SendClientMessage(temp_id, COLOR_INFO, temp);

		playerData[playerid][sellgun_weapon] = temp_gun;
		playerData[playerid][sellgun_price] = temp_price;
		playerData[playerid][sellgun_account_id] = playerData[temp_id][account_id];
	}

	return 1;
}


CMD:acceptgun(playerid, params[])
{
	if (playerData[playerid][account_faction] == FACTION_LSPD) return SendClientMessage(playerid, COLOR_SERVER, "Error: You can not accept guns as a Cop.");

	if (playerData[playerid][account_jailed] > 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");

	if (playerData[playerid][account_escaped] > 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");

	new temp_id;
	if(sscanf(params, "i", temp_id)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /acceptgun <player>");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else if (playerid == temp_id) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot accept a gun from yourself.");
	} else {

		if (playerData[temp_id][sellgun_account_id] != playerData[playerid][account_id]) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not offering you anything right now.");

		new Float: tempx, Float: tempy, Float: tempz;
		GetPlayerPos(playerid, tempx, tempy, tempz);
		if (!IsPlayerInRangeOfPoint(temp_id, 10.0, tempx, tempy, tempz)) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not near you."); 
		
		GivePlayerWeaponSafe(playerid, playerData[temp_id][sellgun_weapon], 350);

		giveMoney(playerid, -playerData[temp_id][sellgun_price]);
		giveMoney(temp_id, playerData[temp_id][sellgun_price]);

		playerData[temp_id][account_materials] -= 400 + random(100);

		new temp[128];
		format(temp, sizeof(temp), "* %s has accepted your gun offer.", playerData[playerid][account_name]);
		SendClientMessage(temp_id, COLOR_INFO, temp);
		format(temp, sizeof(temp), "* You have accepted %s's gun offer.", playerData[temp_id][account_name]);
		SendClientMessage(playerid, COLOR_INFO, temp);

		playerData[temp_id][sellgun_account_id] = 0;
	}

	return 1;
}

CMD:buycar(playerid, params[])
{
	if (IsPlayerInRangeOfPoint(playerid, 3.0, -1966.5516,293.9211,35.4688)) {
		if (playerData[playerid][account_wanted] > 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are wanted.");
		} else { 
			SendClientMessage(playerid, COLOR_INFO, "Use `ESC` to get out from the car shop.");
			buyCar_show(playerid);
		}
	} else {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not near the Car Shop.");
		if (!ServerInProduction && IsPlayerAdmin(playerid)) {
			SetPlayerPos(playerid, -1966.5516,293.9211,35.4688);
		}
	}
	return 1;
}

CMD:generatenumber(playerid, params[])
{
	if (!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		generatePhoneNumber(playerid);
	}
	return 1;
}


CMD:requestevent(playerid, params[])
{
	if (EVENT_OWNER != 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: There is no ongoing event.");
	} else {
		new temp_prize, temp_title[32];
		if(sscanf(params, "is[32]", temp_prize, temp_title)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /requestevent <prize $50-$50.000> <title>");
		} else {
			if (playerData[playerid][requested_event] == 1) {
				SendClientMessage(playerid, COLOR_BADINFO, "Your last request has been cancelled.");
			}
			format(playerData[playerid][requested_event_title], 32, "%s", temp_title);
			playerData[playerid][requested_event_prize] = temp_prize;

			playerData[playerid][requested_event] = 1;

			new temp[128];
			format(temp, sizeof(temp), "*%s requested an event. Title: %s, Prize: $%s. Use /acceptevent %d", playerData[playerid][account_name], temp_title, formatMoney(temp_prize), playerid);

			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][account_helper] >= 2 || playerData[i][account_admin] >= 1) {
					SendClientMessage(i, COLOR_ADMIN, temp);
				}
			}

			SendClientMessage(playerid, COLOR_INFO, "Your request has been sent to online administrators and helpers.");
		}
	}
	return 1;
}

CMD:e(playerid, params[])
{
	if (EVENT_OWNER != playerData[playerid][account_id]) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the event organizer.");
	} else {
		new temp_message[95];
		if(sscanf(params, "s[95]", temp_message)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /e <message>");
		} else {
			new temp[128];
			format(temp, sizeof(temp), "*Event Organizer %s: %s", playerData[playerid][account_name], temp_message);
			SendClientMessageToAll(0xbf6f06FF, temp);
		}
	}
	return 1;
}

CMD:stopevent(playerid, params[])
{
	if (EVENT_OWNER != playerData[playerid][account_id] && playerData[playerid][account_helper] < 2 && playerData[playerid][account_admin] <= 0 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the event organizer.");
	} else {

		if (EVENT_OWNER == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: There is no ongoing event.");
		} else {
			EVENT_OWNER = 0;
			SendClientMessageToAll(0xbf6f06FF, "Event is over.");
		}
	}
	return 1;
}

CMD:acceptevent(playerid, params[])
{
	if (playerData[playerid][account_helper] < 2 && playerData[playerid][account_admin] <= 0 && !IsPlayerAdmin(playerid)){
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else if (EVENT_OWNER != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: There is an ongoing event.");
	} else {
		new temp_id;
		if(sscanf(params, "i", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /acceptevent <playerid>");
		} else {
			if (playerData[temp_id][requested_event] == 0) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: That player has not requested any event.");
			} else {
				format(EVENT_TITLE, 32, "%s", playerData[temp_id][requested_event_title]);
				EVENT_PRIZE = playerData[temp_id][requested_event_prize];
				EVENT_OWNER = playerData[temp_id][account_id];

				new temp[128];
				format(temp, sizeof(temp), "* A new event has been started. Organizer: %s, Title: %s, Prize: $%s.", playerData[temp_id][account_name], playerData[temp_id][requested_event_title], formatMoney(playerData[temp_id][requested_event_prize]));
				SendClientMessageToAll(0xbf6f06FF, temp);

				SendClientMessage(temp_id, COLOR_INFO, "You can talk through /e and when you are ready /stopevent.");
			}
		}
	}
	return 1;
}

CMD:event(playerid, params[])
{
	if (EVENT_OWNER == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: There is no ongoing event.");
	} else {
		new temp_found = -1;
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][account_id] == EVENT_OWNER) {
				temp_found = i;
			}
		}

		new temp[128];

		if (temp_found == -1) {
			format(temp, sizeof(temp), "Event Info: Organizer: OFFLINE, Title: %s, Prize: $%s.", EVENT_TITLE, formatMoney(EVENT_PRIZE));
		} else {
			format(temp, sizeof(temp), "Event Info: Organizer: %s, Title: %s, Prize: $%s.", playerData[temp_found][account_name], EVENT_TITLE, formatMoney(EVENT_PRIZE));
		}

		SendClientMessage(playerid, COLOR_INFO, temp);

	}
	return 1;
}



/*CMD:buyhouse(playerid, params[])
{
	new temp_interior;
	if(sscanf(params, "i", temp_interior)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /buyhouse <interior id>");
		SendClientMessage(playerid, COLOR_SERVER, "Info: Find all available interior ids at our website.");
	} else if(playerData[playerid][account_score] < 8) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to have at least Score 8 to buy a new house.")
	} else {
		if (temp_interior <= 0 || temp_interior >= sizeof(BUYHOUSE_INTERIORS)) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Invalid interior id.");
		} else {
			new temp_houses = 0;
			for (new i = 0; i < sizeof(houseData); i++) {
				if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {
					temp_houses += 1;
				}
			}
			if (temp_houses == 3) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: You already have 3 houses.");
			} else {
				new temp_admins = 0;
				for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
					if (playerData[i][account_admin] > 0) {
						temp_admins++;
					}
				}
				
				if (temp_admins == 0) {
					SendClientMessage(playerid, COLOR_SERVER, "There is no online administrator to accept your request at this moment.");
				} else {
					new temp_price = floatround(BUYHOUSE_INTERIORS[temp_interior][4]);

					if (temp_price > playerData[playerid][account_money]) {
						SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money to buy this interior.");
					} else {
						new temp[256];
						format(temp, 256, "Are you sure you want to buy the house with interior id %d?\n\nInterior Price: $%s\n\nThe house entrace will be placed at your current position.", temp_interior, formatMoney(temp_price));

						playerData[playerid][buyhouse_price] = temp_price;
						playerData[playerid][buyhouse_interior] = temp_interior;

						Dialog_Show(playerid, DLG_BUYHOUSE_CONFIRM, DIALOG_STYLE_MSGBOX, "Buy House: Confirmation", temp, "Confirm","Cancel");
					}
				}
			}
		}
	}
	return 1;
}*/

Dialog:DLG_BUYHOUSE_CONFIRM(playerid, response, listitem, inputtext[])
{
	if (response) {

		playerData[playerid][buyhouse_confirmed] = 1;

		new temp[128];
		format(temp, 128, "Player %s wants to buy a new House (interior %d). Check his position and use /accepthouse %d",  playerData[playerid][account_name], playerData[playerid][buyhouse_interior], playerid);

		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);

		Dialog_Show(playerid, DLG_BUYHOUSE_WAIT, DIALOG_STYLE_MSGBOX, "Buy House: Wait an admin", "Your request has been sent to online administrators.\n\n{eb4034}Please wait and do not close this dialog.", "Cancel", "");

		printf("BUYHOUSE: Player %s requested interior %d.", playerData[playerid][account_name], playerData[playerid][buyhouse_interior]);
	}
	return 1;
}

Dialog:DLG_BUYHOUSE_WAIT(playerid, response, listitem, inputtext[])
{
	if (response) {
		// Here means he clicked Cancel

		playerData[playerid][buyhouse_confirmed] = 0;

		new temp[128];
		format(temp, 128, "Player %s cancelled his request for a new House.", playerData[playerid][account_name]);
		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);

		SendClientMessage(playerid, COLOR_BADINFO, "You have cancelled your request for a new House.");
		printf("BUYHOUSE: Player %s cancelled his House request.", playerData[playerid][account_name]);
	}
	return 1;
}

CMD:invite(playerid, params[])
{
	if(playerData[playerid][account_rank] < 7 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /invite <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[temp_id][account_faction] == playerData[playerid][account_faction]) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is already in your faction.");
		} else if (playerData[temp_id][account_faction] != 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is a member of another faction.");
		} else if (playerData[temp_id][account_wanted] != 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is currently wanted.");
		} else if (playerData[temp_id][account_jailed] != 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is currently in jail.");
		} else if (gettime() - playerData[temp_id][account_inviteCooldown] < 60 * 60 * 24 * 2) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player got invited to a faction less than 2 days ago. He needs to wait.");
		} else {

			if (playerData[playerid][account_faction] == FACTION_LSPD && playerData[temp_id][account_clan] != 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is in a clan. He can not join LSPD.");

			playerData[playerid][invite_id] = temp_id;

			new temp[128];
			format(temp, 128, "Are you sure you want to invite %s (%d) to your faction?", playerData[temp_id][account_name], temp_id);
			Dialog_Show(playerid, DLG_INVITE_CONFIRM, DIALOG_STYLE_MSGBOX, "Confirmation", temp, "Yes", "Cancel");
		}
	}
	return 1;
}



CMD:respawncars(playerid, params[])
{
	if(playerData[playerid][account_rank] < 6 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		if (playerData[playerid][account_faction] == FACTION_MEDICS) {
			for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
				if (GetVehicleDriverID(i) == -1 && i >= SPAWN_PARAMEDICS_CARS[0] && i <= SPAWN_PARAMEDICS_CARS[sizeof(SPAWN_PARAMEDICS_CARS)-1]) {
					SetVehicleToRespawn(i);
				}
			}
		}
		if (playerData[playerid][account_faction] == FACTION_LSPD) {
			for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
				if (GetVehicleDriverID(i) == -1 && i >= SPAWN_LSPD_CARS[0] && i <= SPAWN_LSPD_CARS[sizeof(SPAWN_LSPD_CARS)-1]) {
					SetVehicleToRespawn(i);
				}
			}
		}
		if (playerData[playerid][account_faction] == FACTION_HITMAN) {
			for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
				if (GetVehicleDriverID(i) == -1 && i >= SPAWN_HITMAN_CARS[0] && i <= SPAWN_HITMAN_CARS[sizeof(SPAWN_HITMAN_CARS)-1]) {
					SetVehicleToRespawn(i);
				}
			}
		}
		if (playerData[playerid][account_faction] == FACTION_TAXILS) {
			for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
				if (GetVehicleDriverID(i) == -1 && i >= SPAWN_TAXI_CARS[0] && i <= SPAWN_TAXI_CARS[sizeof(SPAWN_TAXI_CARS)-1]) {
					SetVehicleToRespawn(i);
				}
			}
		}
		new temp[128];
		format(temp, sizeof(temp), "%s respawned all faction's vehicles.", playerData[playerid][account_name]);
		SendClientMessageToFaction(playerData[playerid][account_faction], COLOR_FACTION, temp);
	}
	return 1;
}


CMD:sinvite(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_faction;
		if(sscanf(params, "ui", temp_id, temp_faction)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /sinvite <player> <faction id>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (temp_faction == playerData[temp_id][account_faction]) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is already in your faction.");
		} else if (playerData[temp_id][account_wanted] != 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is currently wanted.");
		} else if (playerData[temp_id][account_jailed] != 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is currently in jail.");
		} else {

			new tempF;

			tempF = temp_faction;

			if (playerData[temp_id][logged] == 0) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online anymore.");
			} else {
				
				new temp[128], tempE[512];

				playerData[temp_id][account_faction] = tempF;
				playerData[temp_id][account_rank] = 1;

				playerData[temp_id][account_skin] = -1;
				
				SpawnPlayer(temp_id);

				format(temp, 128, "Leader %s has invited %s to the faction %s.", playerData[playerid][account_name], playerData[temp_id][account_name], getFactionName(tempF));
				SendClientMessageToFaction(tempF, COLOR_FACTION, temp);
				printf("%s", temp);

				SendClientMessage(playerid, COLOR_INFO, temp);


				format(tempE, sizeof(tempE),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'rank', '1', '%d', '%d', '', '%d')", playerData[temp_id][account_id], playerData[playerid][account_id], gettime(), playerData[playerid][account_faction]);
				mysql_query(Database, tempE, false);
			}
		}
	}
	return 1;
}


CMD:drink(playerid, params[])
{
	if (bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_CLUB) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in club or a restaurant. Find one in /biz.");
	} else {
		new temp_drink[32];
		if(sscanf(params, "s[32]", temp_drink)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /drink <type: beer/wine/water>");
		} else {
			if (strcmp(temp_drink, "beer") == 0) {
				SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DRINK_BEER);
			} else if (strcmp(temp_drink, "wine") == 0) {
				SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DRINK_WINE);
			} else if (strcmp(temp_drink, "water") == 0) {
				SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DRINK_SPRUNK);
				SetPlayerHealth(playerid, 100);
			} else {
				SendClientMessage(playerid, COLOR_SERVER,"Error: Invalid drink");
				return 1;
			}

			new temp[128];
			format(temp, sizeof(temp), "%s just drunk a %s at %s's %s (/biz).", playerData[playerid][account_name], temp_drink, bizData[playerData[playerid][enteredBiz]][biz_owner_name], BIZ_INTERIORS[bizData[playerData[playerid][enteredBiz]][biz_type]][bi_name]);
			SendClientMessageToAll(COLOR_PUBLIC, temp);
		}
	}

	return 1;
}

CMD:deposit(playerid, params[])
{
	if (bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_BANKLS && bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_BANKSF) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in bank. Find one in /biz.");
	} else {

		new temp_price;
		if(sscanf(params, "i", temp_price) || temp_price <= 0) {
			return SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /deposit <amount>");
		} else if (playerData[playerid][account_money] < temp_price ) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have that much money to deposit.");
		} else {
			playerData[playerid][account_bank] += temp_price;
			playerData[playerid][account_money] -= temp_price;

			new temp[128];
			format(temp, sizeof(temp), "You have deposited $%s to your bank account. New balance: $%s.", formatMoney(temp_price), formatMoney(playerData[playerid][account_bank]));
			SendClientMessage(playerid, 0x32a858FF, temp);
		}
	}

	return 1;
}


CMD:withdraw(playerid, params[])
{
	if (bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_BANKLS && bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_BANKSF) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in bank. Find one in /biz.");
	} else {

		new temp_price;
		if(sscanf(params, "i", temp_price) || temp_price <= 0) {
			return SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /withdraw <amount>");
		} else if (playerData[playerid][account_bank] < temp_price ) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have that much money to withdraw.");
		} else {
			playerData[playerid][account_bank] -= temp_price;
			playerData[playerid][account_money] += temp_price;

			new temp[128];
			format(temp, sizeof(temp), "You have withdrawn $%s from your bank account. New balance: $%s.", formatMoney(temp_price), formatMoney(playerData[playerid][account_bank]));
			SendClientMessage(playerid, 0x32a858FF, temp);
		}
	}

	return 1;
}


CMD:transfer(playerid, params[])
{
	if (bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_BANKLS && bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_BANKSF) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in bank. Find one in /biz.");
	} else {

		new temp_price, temp_id;
		if(sscanf(params, "ui", temp_id, temp_price) || temp_price <= 0) {
			return SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /transfer <player> <amount>");
		} else if (playerData[playerid][account_bank] < temp_price ) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have that much money to transfer from your bank account.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			playerData[playerid][account_bank] -= temp_price;
			playerData[temp_id][account_bank] += temp_price;

			new temp[128];
			format(temp, sizeof(temp), "You have transfered $%s to %s's bank account. New balance: $%s.", formatMoney(temp_price), playerData[temp_id][account_name], formatMoney(playerData[playerid][account_bank]));
			SendClientMessage(playerid, 0x32a858FF, temp);
			format(temp, sizeof(temp), "%s has transfered $%s to your bank account. New balance: $%s.", playerData[playerid][account_name], formatMoney(temp_price), formatMoney(playerData[temp_id][account_bank]));
			SendClientMessage(temp_id, 0x32a858FF, temp);
		}
	}

	return 1;
}

CMD:eat(playerid, params[])
{
	if (bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_FASTFOOD1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in fast food or a restaurant. Find one in /biz.");
	} else {
		new temp[128];
		format(temp, sizeof(temp), "%s just ate a hamburger at %s's %s (/biz).", playerData[playerid][account_name], bizData[playerData[playerid][enteredBiz]][biz_owner_name], BIZ_INTERIORS[bizData[playerData[playerid][enteredBiz]][biz_type]][bi_name]);
		SendClientMessageToAll(COLOR_PUBLIC, temp);
		ApplyAnimation(playerid, "FOOD", "EAT_Burger",4.1,0,1,1,0,0);
		SetPlayerHealth(playerid, 100);
	}

	return 1;
}


CMD:buycigarette(playerid, params[])
{
	if (bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_247_1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in a 24/7 Shop. Find one in /biz.");
	} else {
		new temp[128];
		format(temp, sizeof(temp), "%s just bought a cigarette at %s's %s (/biz).", playerData[playerid][account_name], bizData[playerData[playerid][enteredBiz]][biz_owner_name], BIZ_INTERIORS[bizData[playerData[playerid][enteredBiz]][biz_type]][bi_name]);
		SendClientMessageToAll(COLOR_PUBLIC, temp);
		
		playerData[playerid][have_cigarettes]++;
	}

	return 1;
}

CMD:smoke(playerid,params[])
{
	if (playerData[playerid][have_cigarettes] > 0) {
		SetPlayerSpecialAction(playerid,SPECIAL_ACTION_SMOKE_CIGGY);
		playerData[playerid][have_cigarettes]--;

		new temp[128];
		format(temp, sizeof(temp), "%s just smoke a cigarette.", playerData[playerid][account_name]);
		SendClientMessageToAll(COLOR_PUBLIC, temp);
	} else {
		SendClientMessage(playerid, COLOR_SERVER,"You need to buy cigarette from a 24/7 Shop. Find one in /biz.");
	}
	return 1;
}

CMD:buyphone(playerid, params[])
{
	if (bizData[playerData[playerid][enteredBiz]][biz_type] != BIZ_TYPE_247_1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in a 24/7 Shop. Find one in /biz.");
	} else if (gettime() - playerData[playerid][buyphone_cooldown] < 60) {
		SendClientMessage(playerid, COLOR_BADINFO, "You can not change your phone number that often.");
	} else {
		playerData[playerid][buyphone_cooldown] = gettime();

		new temp[128];
		format(temp, sizeof(temp), "%s just bough a new phone number at %s's %s (/biz).", playerData[playerid][account_name], bizData[playerData[playerid][enteredBiz]][biz_owner_name], BIZ_INTERIORS[bizData[playerData[playerid][enteredBiz]][biz_type]][bi_name]);
		SendClientMessageToAll(COLOR_PUBLIC, temp);
		
		generatePhoneNumber(playerid);
	}

	return 1;
}

CMD:heal(playerid, params[])
{
	new temp_id = playerData[playerid][enteredHouse];

	if (playerData[playerid][enteredHouse] != 0 && houseData[temp_id][house_owner_id] == playerData[playerid][account_id]) {

		SetPlayerHealth(playerid, 100);

	} else if (playerData[playerid][account_faction] == FACTION_LSPD && playerData[playerid][special_interior] == INTERIOR_PRISON) {
		SetPlayerHealth(playerid, 100);
	} else {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot heal here.");
	}
	return 1;
}


Dialog:DLG_INVITE_CONFIRM(playerid, response, listitem, inputtext[])
{
	if (response) {
		new temp_id, tempF;

		tempF = playerData[playerid][account_faction];
		temp_id = playerData[playerid][invite_id];

		if (playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online anymore.");
		} else {
			
			new temp[128], tempE[256];

			playerData[temp_id][account_inviteCooldown]  = gettime();

			playerData[temp_id][account_faction] = tempF;
			playerData[temp_id][account_rank] = 1;

			playerData[temp_id][account_skin] = -1;
			
			SpawnPlayer(temp_id);

			if (tempF != FACTION_CIVIL) {
				format(temp, 128, "Leader %s has invited %s to the faction %s.", playerData[playerid][account_name], playerData[temp_id][account_name], getFactionName(tempF));
				SendClientMessageToFaction(tempF, COLOR_FACTION, temp);
			}
			printf("%s", temp);

			format(tempE, sizeof(tempE),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'rank', '1', '%d', '%d', '', '%d')", playerData[temp_id][account_id], playerData[playerid][account_id], gettime(), playerData[playerid][account_faction]);
			mysql_query(Database, tempE, false);
		}
	}
	return 1;
}

CMD:fill(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (vehicleid == 0) {
		return SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a vehicle, so you can fill it.");
	} else if (GetPlayerVehicleSeat(playerid) != 0) {
		return SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be the driver of the vehicle.");
	}


	for (new i; i < MAX_BIZ; i++) {
		if (bizData[i][biz_type] != 0 && IsPlayerInRangeOfPoint(playerid, 10.0, bizData[i][biz_x], bizData[i][biz_y], bizData[i][biz_z])) {

			if (bizData[i][biz_type] == BIZ_TYPE_GASSTATION) {

				if (100 - carData[vehicleid][vehicle_fuel] < 10) return SendClientMessage(playerid, COLOR_SERVER, "Error: Your vehicle is already full of gas.");

				new price = (100 - carData[vehicleid][vehicle_fuel]) * bizData[i][biz_entrance];
				if (playerData[playerid][account_money] < price) return SendClientMessage(playerid, COLOR_BADINFO, "You do not have enough money to fill your vehicle.");

				new temp[256];
				format(temp, sizeof(temp), "UPDATE `business` SET `biz_profit` = `biz_profit` + %d WHERE `biz_id` = %d;", price, bizData[i][biz_id]);
				mysql_query(Database, temp, false);

				giveMoney(playerid, -price);

				printf("%s filled his car at %s's biz %d", playerData[playerid][account_name], bizData[i][biz_owner_name], bizData[i][biz_id]);

				new engine, lights, alarm, doors, bonnet, boot, objective;
				GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
				SetVehicleParamsEx(vehicleid, 0, 0, alarm, doors, bonnet, boot, objective);

				TogglePlayerControllable(playerid, 0);

				SetTimerEx("finishFill", 5000 + 1000 * random(7), false, "i", playerid);

				SendClientMessage(playerid, COLOR_INFO, "* Please wait...");

				return 1;
			}
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "Error: You are not at a Gas Station (/biz).");

	return 1;
}

forward finishFill(playerid);
public finishFill(playerid)
{
	new vehicleid = GetPlayerVehicleID(playerid);
	carData[vehicleid][vehicle_fuel] = 100;
	TogglePlayerControllable(playerid, 1);
	SendClientMessage(playerid, COLOR_INFO, "* You are ready. You have filled up your car.");
	printf("%s filled up his car.", playerData[playerid][account_name]);
}

CMD:need(playerid, params[])
{
	Dialog_Show(playerid, DGL_NEED, DIALOG_STYLE_LIST, "Need", "Medic\nTaxi", "Request", "Cancel");

	return 1;
}

Dialog:DGL_NEED(playerid, response, listitem, inputtext[])
{
	if (response) {
		new temp[128];
		new temp_faction = 0;
		if (listitem == 0) {
			format(temp, sizeof(temp), "* %s (%d) needs a Medic. Use /track %d to locate him.", playerData[playerid][account_name], playerid, playerid);
			temp_faction = FACTION_MEDICS;
		} else if (listitem == 1) {
			format(temp, sizeof(temp), "* %s (%d) needs a Taxi. Use /track %d to locate him.", playerData[playerid][account_name], playerid, playerid);
			temp_faction = FACTION_TAXILS;
		}
		SendClientMessage(playerid, COLOR_INFO, "Your request has been sent.");
		SendClientMessageToFaction(temp_faction, COLOR_FACTION, temp);
	}
	return 1;
}

CMD:progress(playerid, params[])
{
	if (playerData[playerid][account_faction] == FACTION_MEDICS) {
		new temp[128];
		format(temp, sizeof(temp), "You have healed %d / 15 players during this session.\nHeal %d more times and you will get 1 Score point.", playerData[playerid][heal_ups], 15-playerData[playerid][heal_ups]);
		Dialog_Show(playerid, DLG_PROGRESS, DIALOG_STYLE_MSGBOX, "Progress", temp, "Ok", "");

	} else if (playerData[playerid][account_faction] == FACTION_TAXILS) {
		new temp[128];
		format(temp, sizeof(temp), "You have earned %d / 50 fares during this session.\nEarn %d more times and you will get 1 Score point.", playerData[playerid][tarifs], 50-playerData[playerid][tarifs]);
		Dialog_Show(playerid, DLG_PROGRESS, DIALOG_STYLE_MSGBOX, "Progress", temp, "Ok", "");
	} else {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You can not use this command.");
	}
	return 1;
}

CMD:uninvite(playerid, params[])
{
	if(playerData[playerid][account_rank] < 7 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_reason[64];
		if(sscanf(params, "us[64]", temp_id, temp_reason)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /uninvite <player> <reason>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (playerData[temp_id][account_faction] != playerData[playerid][account_faction]) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not in your faction.");
		} else if (playerData[temp_id][account_rank] == 7) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is the leader of the faction.");
		} else if (playerData[temp_id][account_wanted] != 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is currently wanted.");
		} else if (playerData[temp_id][account_jailed] != 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is currently in jail.");
		} else {

			new temp[128], tempE[512];

			new tempF = playerData[playerid][account_faction];

			format(temp, 128, "Leader %s has uninvited %s from the faction %s.", playerData[playerid][account_name], playerData[temp_id][account_name], getFactionName(tempF));
			SendClientMessageToFaction(tempF, COLOR_FACTION, temp);
			printf("%s", temp);
			
			playerData[temp_id][account_faction] = 0;
			playerData[temp_id][account_rank] = 0;

			playerData[temp_id][account_skin] = -1;
			SpawnPlayer(temp_id);

			mysql_format(Database, tempE, sizeof(tempE),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'rank', '0', '%d', '%d', '%e', '%d')", playerData[temp_id][account_id], playerData[playerid][account_id], gettime(), temp_reason, playerData[playerid][account_faction]);
			mysql_query(Database, tempE, false);
		}
	}
	return 1;
}

CMD:sleep(playerid, params[])
{
	if (playerData[playerid][enteredHouse] == 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in your own house.");

	new temp_id = playerData[playerid][enteredHouse];

	if (houseData[temp_id][house_owner_id] != playerData[playerid][account_id]) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in your own house.");

	if (playerData[playerid][account_jailed] > 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	if (playerData[playerid][account_escaped] > 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	if (playerData[playerid][robbing_state] > 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");


	playerData[playerid][am_sleeping] = !playerData[playerid][am_sleeping];

	new temp[128];

	if (playerData[playerid][am_sleeping] == 0) {
		format(temp, sizeof(temp), "%s(%d) is not sleeping anymore.", playerData[playerid][account_name], playerid);


		ClearAnimations(playerid);

		TogglePlayerControllable(playerid, 1);

		ClearAnimations(playerid);

		SendClientMessageToAll(COLOR_PUBLIC, temp);
		print(temp);

		SetPlayerHealth(playerid, 100);

	} else {
		format(temp, sizeof(temp), "%s(%d) is now sleeping in his house.", playerData[playerid][account_name], playerid);


		TogglePlayerControllable(playerid, 0);

		ApplyAnimation(playerid, "INT_HOUSE", "BED_Loop_R",4.1,0,0,0,1,1);

		SendClientMessageToAll(COLOR_PUBLIC, temp);
		print(temp);

		SetPlayerHealth(playerid, 999999999);

		if (playerData[playerid][session_activeSeconds] <  60 * 20) {
			format(temp, sizeof(temp), "* You have played %d minutes in this session. You will NOT receive any paycheck.", floatround(playerData[playerid][session_activeSeconds]/ 60.0));
		} else {
			format(temp, sizeof(temp), "* You have played %d minutes in this session. You will receive paychecks.", floatround(playerData[playerid][session_activeSeconds]/ 60.0));
		}

		SendClientMessage(playerid, COLOR_INFO, temp);
	}
	return 1;
}

CMD:sellhouse(playerid, params[])
{
	
	if (houseTogUpdate == 1) return SendClientMessage(playerid, COLOR_SERVER, "Please wait a few seconds and try again.");
	
	for (new i=0; i < MAX_HOUSES; i++){
		if(IsPlayerInRangeOfPoint(playerid, 3.0, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z])){
			if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {
				new temp_price;
				if(sscanf(params, "i", temp_price) || temp_price<0 || temp_price > 9000000) {
					return SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /sellhouse <price, 0 - $9.000.000>");
				} else {
					new temp[512];
					format(temp, sizeof(temp), "UPDATE `houses` SET `house_sell` = '%d' WHERE `house_id` = %d;", temp_price, houseData[i][house_id]);
					mysql_query(Database, temp, false);
					houseTogUpdate = 1;
					loadHouses(2);
					SetTimerEx("loadHouses", 600, 0, "i", 0);
					return 1;
				}
			}
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "You are not at the entrance of your house.");

	return 1;
}



CMD:buyhouse(playerid, params[])
{
	
	if (houseTogUpdate == 1) return SendClientMessage(playerid, COLOR_SERVER, "Please wait a few seconds and try again.");

	new temp_houses = 0;
	for (new i = 0; i < sizeof(houseData); i++) {
		if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {
			temp_houses += 1;
		}
	}
	if (temp_houses == 3) {
		return SendClientMessage(playerid, COLOR_SERVER, "Error: You already have 3 houses.");
	}
	
	for (new i=0; i < MAX_HOUSES; i++){
		if(IsPlayerInRangeOfPoint(playerid, 3.0, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z])){
			if (houseData[i][house_sell] > 0) {
				if (playerData[playerid][account_money] < houseData[i][house_sell]) return SendClientMessage(playerid, COLOR_SERVER, "You do not have enough money to buy this house.");
				if (playerData[playerid][account_id] == houseData[i][house_owner_id]) return SendClientMessage(playerid, COLOR_SERVER, "You can not buy your own house.");

				new temp[512];

				new temp_found = 0;
				for(new k = 0, j = GetPlayerPoolSize(); k <= j; k++) {
					if (playerData[k][logged] == 1 && playerData[k][account_id] == houseData[i][house_owner_id]) {
						temp_found = 1;
						format(temp, sizeof(temp), "%s has bought your house for $%s.", playerData[playerid][account_name], formatMoney(houseData[i][house_sell]));
						SendClientMessage(k, COLOR_INFO, temp);
						giveMoney(k, houseData[i][house_sell]);
						break;
					}
				}

				if (temp_found == 0) {
					format(temp, sizeof(temp), "UPDATE `accounts` SET `account_money` = `account_money` + %d WHERE `account_id` = %d;", houseData[i][house_sell], houseData[i][house_owner_id]);
					mysql_query(Database, temp, false);
				}

				giveMoney(playerid, -houseData[i][house_sell]);

				format(temp, sizeof(temp), "Congratulations! You just bought %s's house for $%s.", houseData[i][house_owner_name], formatMoney(houseData[i][house_sell]));
				SendClientMessage(playerid, COLOR_INFO, temp);

				printf("%s bought %s's house (%d) for ($%s)", playerData[playerid][account_name], houseData[i][house_owner_name], houseData[i][house_id], formatMoney(houseData[i][house_sell]));

				format(temp, sizeof(temp), "UPDATE `houses` SET `house_sell` = '0', `house_owner` = '%d', `house_owner_name` = '%s' WHERE `house_id` = %d;", playerData[playerid][account_id], playerData[playerid][account_name], houseData[i][house_id]);
				mysql_query(Database, temp, false);
				houseTogUpdate = 1;
				loadHouses(2);
				SetTimerEx("loadHouses", 600, 0, "i", 0);

				PlayerPlaySound(playerid, 182, 0.0,0.0,0.0);
				SetTimerEx("stopPlayerSound", 7400, 0, "i", playerid);
				return 1;
			}
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "You are not at the entrance of house that is for sale.");

	return 1;
}


CMD:lockhouse(playerid, params[])
{
	
	if (houseTogUpdate == 1) return SendClientMessage(playerid, COLOR_SERVER, "Please wait a few seconds and try again.");
	
	for (new i=0; i < MAX_HOUSES; i++){
		if(IsPlayerInRangeOfPoint(playerid, 3.0, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z])){
			if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {

				new temp_locked = !houseData[i][house_locked];
				if (temp_locked == 1) SendClientMessage(playerid, COLOR_INFO, "You have locked the door of your house.");
				if (temp_locked == 0) SendClientMessage(playerid, COLOR_INFO, "You have unlocked the door of your house.");
				new temp[512];

				format(temp, sizeof(temp), "UPDATE `houses` SET `house_locked` = '%d' WHERE `house_id` = %d;", temp_locked, houseData[i][house_id]);
				mysql_query(Database, temp, false);
				houseTogUpdate = 1;
				loadHouses(2);
				SetTimerEx("loadHouses", 600, 0, "i", 0);

				return 1;
				
			}
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "You are not at the entrance of your house.");

	return 1;
}


CMD:drophouse(playerid, params[])
{
	
	if (houseTogUpdate == 1) return SendClientMessage(playerid, COLOR_SERVER, "Please wait a few seconds and try again.");
	
	for (new i=0; i < MAX_HOUSES; i++){
		if(IsPlayerInRangeOfPoint(playerid, 3.0, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z])){
			if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {

				playerData[playerid][drop_house_id] = i;

				Dialog_Show(playerid, DLG_DROPHOUSE, DIALOG_STYLE_MSGBOX, "Confirmation", "\nAre you sure you want to drop your house?\nYour house will belong to the server and you will get nothing.\n", "Yes", "Cancel");
				
			}
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "You are not at the entrance of your house.");

	return 1;
}

Dialog:DLG_DROPHOUSE(playerid, response, listitem, inputtext[])
{
	if (response) {
		new temp_id = playerData[playerid][drop_house_id];
		new temp[512];

		printf("%s has dropped his house (%d).", playerData[playerid][account_name], houseData[temp_id][house_id]);

		format(temp, sizeof(temp), "UPDATE `houses` SET `house_sell` = '0', `house_owner` = '-1', `house_owner_name` = 'Server' WHERE `house_id` = %d;", houseData[temp_id][house_id]);
		mysql_query(Database, temp, false);
		houseTogUpdate = 1;
		loadHouses(2);
		SetTimerEx("loadHouses", 600, 0, "i", 0);
	}
	return 1;
}


CMD:sellbiz(playerid, params[])
{

	for (new i; i < MAX_BIZ; i++) {
		if (bizData[i][biz_type] != 0 && IsPlayerInRangeOfPoint(playerid, 3.0, bizData[i][biz_x], bizData[i][biz_y], bizData[i][biz_z])) {

			if (bizData[i][biz_owner] != playerData[playerid][account_id]) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: That is not your business.");
			} else {

				new temp_price;
				if(sscanf(params, "i", temp_price) || temp_price<0 || temp_price > 9000000) {
					SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /sellbiz <price, 0 - $9.000.000>");
				} else {
					new temp[512];
					format(temp, sizeof(temp), "UPDATE `business` SET `biz_sell` = '%d' WHERE `biz_id` = %d;", temp_price, bizData[i][biz_id]);
					mysql_query(Database, temp, false);

				
					UPDATE_BIZ_STATE = 1;
				}
			}
			return 1;
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "You are not at the entrance of a business.");

	return 1;
}



CMD:setentrance(playerid, params[])
{

	for (new i; i < MAX_BIZ; i++) {
		if (bizData[i][biz_type] != 0 && IsPlayerInRangeOfPoint(playerid, 3.0, bizData[i][biz_x], bizData[i][biz_y], bizData[i][biz_z])) {

			if (bizData[i][biz_owner] != playerData[playerid][account_id]) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: That is not your business.");
			} else {

				new temp_price;
				if(sscanf(params, "i", temp_price) || temp_price <= 0 || temp_price > 199) {
					SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /setentrance <price, $1 - $199>");
				} else {

					if (bizData[i][biz_type] == BIZ_TYPE_GASSTATION && temp_price > 4) return SendClientMessage(playerid, COLOR_SERVER, "Error: Maximum value for Gas Stations is 4.");

					new temp[512];
					format(temp, sizeof(temp), "UPDATE `business` SET `biz_entrance` = '%d' WHERE `biz_id` = %d;", temp_price, bizData[i][biz_id]);
					mysql_query(Database, temp, false);

			
					UPDATE_BIZ_STATE = 1;
				}
			}
			return 1;
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "You are not at the entrance of a business.");

	return 1;
}


CMD:withdrawprofit(playerid, params[])
{

	for (new i; i < MAX_BIZ; i++) {
		if (bizData[i][biz_type] != 0 && IsPlayerInRangeOfPoint(playerid, 3.0, bizData[i][biz_x], bizData[i][biz_y], bizData[i][biz_z])) {

			if (bizData[i][biz_owner] != playerData[playerid][account_id]) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: That is not your business.");
			} else {
				if (bizData[i][biz_profit] == 0) return SendClientMessage(playerid, COLOR_INFO, "There is no profit to withdraw.");
				new temp[256];
				format(temp, sizeof(temp), "\nYour business has $%s profit. Do you want to withdrow that amount of money?\n\nYou might need to wait a few minutes until business profit gets fully updated.", formatMoney(bizData[i][biz_profit]));

				playerData[playerid][withdrawprofit] = bizData[i][biz_profit];
				playerData[playerid][withdrawprofit_id] = bizData[i][biz_id];

				Dialog_Show(playerid, DLG_PROFIT_CONFIRM, DIALOG_STYLE_MSGBOX, "Confirmation", temp, "Yes", "Cancel");
			}
			return 1;
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "You are not at the entrance of a business.");

	return 1;
}

Dialog:DLG_PROFIT_CONFIRM(playerid, response, listitem, inputtext[])
{
	if (response) {

		new temp[256];

		printf("%s withdrew $%s from his business.", playerData[playerid][account_name], formatMoney(playerData[playerid][withdrawprofit]));

		format(temp, sizeof(temp), "UPDATE `business` SET `biz_profit` = `biz_profit` - '%d' WHERE `biz_id` = %d;", playerData[playerid][withdrawprofit], playerData[playerid][withdrawprofit_id]);
		mysql_query(Database, temp, false);

		giveMoney(playerid, playerData[playerid][withdrawprofit]);

		UPDATE_BIZ_STATE = 1;
	}
	return 1;
}

CMD:buybiz(playerid, params[])
{
	new temp_biz_numbers = 0;
	for (new i = 0; i < sizeof(bizData); i++) {
		if (bizData[i][biz_owner] == playerData[playerid][account_id]) {
			temp_biz_numbers += 1;
		}
	}
	if (temp_biz_numbers >= 4) {
		return SendClientMessage(playerid, COLOR_SERVER, "Error: You already have 4 businesses.");
	}

	for (new i; i < MAX_BIZ; i++) {
		if (bizData[i][biz_type] != 0 && IsPlayerInRangeOfPoint(playerid, 3.0, bizData[i][biz_x], bizData[i][biz_y], bizData[i][biz_z])) {

			if (bizData[i][biz_sell] == 0) {
				SendClientMessage(playerid, COLOR_SERVER, "This business is not for sale.");
			} else if (bizData[i][biz_sell] > playerData[playerid][account_money]) {
				SendClientMessage(playerid, COLOR_SERVER, "You do not have enough money to buy this business.");
			} else if (bizData[i][biz_owner] == playerData[playerid][account_id]) {
				SendClientMessage(playerid, COLOR_SERVER, "You already own this business.");
			} else {
				new temp[512];

				giveMoney(playerid, -bizData[i][biz_sell]);

				new temp_found = 0;
				for(new k = 0, j = GetPlayerPoolSize(); k <= j; k++) {
					if (playerData[k][logged] == 1 && playerData[k][account_id] == bizData[i][biz_owner]) {
						temp_found = 1;
						format(temp, sizeof(temp), "%s has bought your business for $%s.", playerData[playerid][account_name], formatMoney(bizData[i][biz_sell]));
						SendClientMessage(k, COLOR_INFO, temp);
						giveMoney(k, bizData[i][biz_sell]);
						break;
					}
				}

				if (temp_found == 0) {
					format(temp, sizeof(temp), "UPDATE `accounts` SET `account_money` = `account_money` + %d WHERE `account_id` = %d;", bizData[i][biz_sell], bizData[i][biz_owner]);
					mysql_query(Database, temp, false);
				}

		
				format(temp, sizeof(temp), "UPDATE `business` SET `biz_owner` = '%d', `biz_owner_name` = '%s', `biz_sell` = '0' WHERE `biz_id` = %d;", playerData[playerid][account_id], playerData[playerid][account_name], bizData[i][biz_id]);
				mysql_query(Database, temp, false);

				printf("BUYBIZ: %s bought biz %d.", playerData[playerid][account_name], bizData[i][biz_id]);
				
				UPDATE_BIZ_STATE = 1;
			}
			return 1;
		}
	}

	SendClientMessage(playerid, COLOR_SERVER, "You are not at the entrance of a business.");

	return 1;
}

CMD:acceptcar(playerid, params[])
{
	new temp_id;
	if(sscanf(params, "u", temp_id)) {
		SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /acceptcar <player>");
	} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
	} else if (playerData[temp_id][sellcar_to] != playerid || playerData[temp_id][sellcar_price] == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not offering you his car right now.");
	} else if (playerData[playerid][account_money] < playerData[temp_id][sellcar_price]) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You do not have enough money for his offer.");
	} else {
		new Float:temp_x, Float:temp_y, Float:temp_z;
		GetPlayerPos(temp_id, temp_x, temp_y, temp_z);
		if (!IsPlayerInRangeOfPoint(playerid, 10.0, temp_x, temp_y, temp_z)) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be close to that player.");
		} else {
			new temp_found;
			new vehicleid = GetPlayerVehicleID(temp_id);
			
			if (carData[vehicleid][vehicle_id] == playerData[temp_id][sellcar_uid]) {
				temp_found = 1;
			}

			if (temp_found == 0) {
				SendClientMessage(playerid, COLOR_BADINFO, "That player is not in his offered car anymore.");
			} else {
				new temp_model = GetVehicleModel(vehicleid);
				new temp_found2, temp_count;
				for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
					if (carData[i][vehicle_owner] == playerData[playerid][account_id] && carData[i][vehicle_owner_ID] == playerid) {
						if (GetVehicleModel(i) == temp_model) {
							temp_found2 = 1;
						}
						temp_count++;
					}
				}

				if (temp_count >= MAX_VEHICLES_PER_PLAYER) {
					SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot buy more personal vehicles.");
				} else if (temp_found2 == 1) {
					SendClientMessage(playerid, COLOR_SERVER, "Error: You already own a vehicle of that model id.");
				} else {
					new temp[512];
					format(temp, sizeof(temp), "UPDATE `vehicles` SET `vehicle_owner` = '%d' WHERE `vehicle_id` = %d", playerData[playerid][account_id], playerData[temp_id][sellcar_uid]);
					mysql_query(Database, temp, false);

					printf("ACCEPTCAR: %s bought %s from %s for $%s", playerData[playerid][account_name], VehicleNames[GetVehicleModel(vehicleid) - 400], playerData[temp_id][account_name], formatMoney(playerData[temp_id][sellcar_price]));

					format(temp, sizeof(temp), "You bought the %s from %s for $%s. Congratulations!", VehicleNames[GetVehicleModel(vehicleid) - 400], playerData[temp_id][account_name], formatMoney(playerData[temp_id][sellcar_price]));
					SendClientMessage(playerid, COLOR_INFO, temp);

					format(temp, sizeof(temp), "You sold your %s to %s for $%s. Congratulations!", VehicleNames[GetVehicleModel(vehicleid) - 400], playerData[playerid][account_name], formatMoney(playerData[temp_id][sellcar_price]));
					SendClientMessage(temp_id, COLOR_INFO, temp);

					PlayerPlaySound(playerid, 182, 0.0,0.0,0.0);
					SetTimerEx("stopPlayerSound", 7400, 0, "i", playerid);

					PlayerPlaySound(temp_id, 182, 0.0,0.0,0.0);
					SetTimerEx("stopPlayerSound", 7400, 0, "i", temp_id);

					giveMoney(playerid, -playerData[temp_id][sellcar_price]);
					giveMoney(temp_id, playerData[temp_id][sellcar_price]);

					playerData[temp_id][sellcar_price] = 0;


					GetPlayerPos(temp_id, temp_x, temp_y, temp_z);
					SetPlayerPos(temp_id, temp_x, temp_y, temp_z+4);
					TogglePlayerControllable(temp_id, 1);
					ClearAnimations(temp_id);

					unloadPlayerVehicles(playerid);
					loadPlayerVehicles(playerid, 0);

					unloadPlayerVehicles(temp_id);
					loadPlayerVehicles(temp_id, 0);
				}
			}

		}
	}
	return 1;
}

CMD:cancelsellcar(playerid, params[])
{
	if (playerData[playerid][sellcar_price] == 0) {
		SendClientMessage(playerid, COLOR_INFO, "You do not have an open offer.");
	} else {
		new temp[128];
		format(temp, sizeof(temp), "Your offer to %s has been canceled.", playerData[playerData[playerid][sellcar_to]][account_name]);
		SendClientMessage(playerid, COLOR_INFO, temp);
		playerData[playerid][sellcar_price] = 0;
	}
	return 1;
}

CMD:sellcarserver(playerid, params[])
{

	if (GetPlayerVehicleID(playerid) == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in your vehicle.");
	} else if (GetPlayerVehicleSeat(playerid) != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be the driver of your vehicle.");
	} else {
		new temp_found;
		new vehicleid = GetPlayerVehicleID(playerid);

		if (carData[vehicleid][vehicle_owner] == playerData[playerid][account_id] && carData[vehicleid][vehicle_owner_ID] == playerid) {
			temp_found = 1;
		}

		if (temp_found == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the owner of this vehicle.");
		} else {

			new temp[256];

			new temp_model = GetVehicleModel(GetPlayerVehicleID(playerid));
			new temp_price;

			for (new i; i < sizeof(BUYCAR_CARS); i++) {
				if (BUYCAR_CARS[i][0] == temp_model) {
					temp_price = BUYCAR_CARS[i][1];
				}
			}

			temp_price = temp_price / 2;

			format(temp, sizeof(temp), "\n\nAre you sure you want to sell your %s back to the server for $%s?\n\n", VehicleNames[temp_model - 400], formatMoney(temp_price));
			Dialog_Show(playerid, DLG_SELLCARSERVER, DIALOG_STYLE_MSGBOX, "Confirmation", temp, "Yes", "Cancel");

			
		}
	}

	return 1;
}

Dialog:DLG_SELLCARSERVER(playerid, response, listitem, inputtext[])
{
	if (response) {
		new temp_found, temp_vehicledID;
		new vehicleid = GetPlayerVehicleID(playerid);

		if (carData[vehicleid][vehicle_owner] == playerData[playerid][account_id] && carData[vehicleid][vehicle_owner_ID] == playerid) {
			temp_found = 1;
			temp_vehicledID = carData[vehicleid][vehicle_id];
		}

		if (temp_found) {
			new temp[512];

			new temp_model = GetVehicleModel(GetPlayerVehicleID(playerid));
			new temp_price;

			for (new i; i < sizeof(BUYCAR_CARS); i++) {
				if (BUYCAR_CARS[i][0] == temp_model) {
					temp_price = BUYCAR_CARS[i][1];
				}
			}

			temp_price = temp_price / 2;

			format(temp, sizeof(temp), "You have sold your %s back to the server for $%s.", VehicleNames[temp_model - 400], formatMoney(temp_price));
			printf("%s sold his %s back to the server for $%s", playerData[playerid][account_name], VehicleNames[temp_model - 400], formatMoney(temp_price));

			giveMoney(playerid, temp_price);

			format(temp, sizeof(temp), "UPDATE `vehicles` SET `vehicle_owner` = '-1' WHERE `vehicle_id` = %d", temp_vehicledID);
			mysql_query(Database, temp, false);

			unloadPlayerVehicles(playerid);
			loadPlayerVehicles(playerid, 0);
		}
	}
	return 1;
}


CMD:sellcar(playerid, params[])
{

	if (GetPlayerVehicleID(playerid) == 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in your vehicle.");
	} else if (GetPlayerVehicleSeat(playerid) != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be the driver of your vehicle.");
	} else {
		new temp_found, temp_vehicledID;
		new vehicleid = GetPlayerVehicleID(playerid);
		
		if (carData[vehicleid][vehicle_owner] == playerData[playerid][account_id] && carData[vehicleid][vehicle_owner_ID] == playerid) {
			temp_found = 1;
			temp_vehicledID = carData[vehicleid][vehicle_id];
		}

		if (temp_found == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are not the owner of this vehicle.");
		} else {

			new temp_id, temp_var;
			if(sscanf(params, "ui", temp_id, temp_var) || temp_var==0) {
				SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /sellcar <player> <price>");
			} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
				SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
			} else {

				new Float:temp_x, Float:temp_y, Float:temp_z;
				GetPlayerPos(temp_id, temp_x, temp_y, temp_z);
				if (!IsPlayerInRangeOfPoint(playerid, 10.0, temp_x, temp_y, temp_z)) {
					SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be close to that player.");
				} else {
					new temp[128];
					if (playerData[playerid][sellcar_price] > 0) {
						format(temp, sizeof(temp), "Your previous offer to %s has been canceled.", playerData[playerData[playerid][sellcar_to]][account_name]);
						SendClientMessage(playerid, COLOR_BADINFO, temp);
					}

					playerData[playerid][sellcar_to] = temp_id;
					playerData[playerid][sellcar_price] = temp_var;
					playerData[playerid][sellcar_uid] = temp_vehicledID;

					format(temp, sizeof(temp), "* You have offered your %s to %s for $%s.", VehicleNames[GetVehicleModel(vehicleid) - 400], playerData[temp_id][account_name], formatMoney(temp_var));
					SendClientMessage(playerid, COLOR_INFO, temp);

					format(temp, sizeof(temp), "* %s is offering you his %s for $%s. Use /acceptcar %d", playerData[playerid][account_name], VehicleNames[GetVehicleModel(vehicleid) - 400], formatMoney(temp_var), playerid);
					SendClientMessage(temp_id, COLOR_INFO, temp);
				}
			}
		}
	}

	return 1;
}


CMD:kick(playerid, params[])
{
	if(playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_reason[64];
		if(sscanf(params, "us[64]", temp_id, temp_reason)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /kick <player> <reason text>");
		} else if (strlen(temp_reason) > 32  ||  !isOnlyLetter(temp_reason)) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Max 32 Characters and only letters.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];
			
			format(temp, 128, "AdmCmd: %s got kicked from the server by admin %s. Reason: %s", playerData[temp_id][account_name], playerData[playerid][account_name], temp_reason);
			SendClientMessageToAll(COLOR_PUNISH, temp);

			printf("KICK: Player %s got kicked by %s. Reason: %s", playerData[temp_id][account_name], playerData[playerid][account_name], temp_reason);

			SetTimerEx("DelayedKick", 1000, 0, "i", temp_id);

			
			new tempE[512];
			mysql_format(Database, tempE, sizeof(tempE),"INSERT INTO `sanctions` (`sanction_player`, `sanction_date`, `sanction_admin_id`, `sanction_type`, `sanction_variable`, `sanction_reason`) VALUES ('%d', '%d', '%d', 'kick', '0', '%e');", playerData[temp_id][account_id], gettime(), playerData[playerid][account_id], temp_reason);
			mysql_query(Database, tempE, false);
		}
	}
	return 1;
}


CMD:warn(playerid, params[])
{
	if(playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_reason[64];
		if(sscanf(params, "us[64]", temp_id, temp_reason)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /warn <player> <reason text>");
		} else if ( strlen(temp_reason) > 40 ) {
			SendClientMessage(playerid, COLOR_SERVER, "Reason text is too big. Max Characters: 40");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			playerData[temp_id][account_warns]++;
			
			format(temp, 128, "AdmCmd: %s warned by admin %s. Reason: %s (%d/5)", playerData[temp_id][account_name], playerData[playerid][account_name], temp_reason, playerData[temp_id][account_warns]);
			SendClientMessageToAll(COLOR_PUNISH, temp);

			new tempE[512];
			format(tempE, sizeof(tempE),"INSERT INTO `sanctions` (`sanction_player`, `sanction_date`, `sanction_admin_id`, `sanction_type`, `sanction_variable`, `sanction_reason`) VALUES ('%d', '%d', '%d', 'warn', '0', '%s');", playerData[temp_id][account_id], gettime(), playerData[playerid][account_id], temp_reason);
			mysql_query(Database, tempE, false);

			if (playerData[temp_id][account_warns] == 5) {
				format(temp, 128, "AdmBot: %s has been banned from the server for 30 days. Reason: 5/5 Warns", playerData[temp_id][account_name]);
				SendClientMessageToAll(COLOR_PUNISH, temp);

				playerData[temp_id][account_warns] = 0;

				playerData[temp_id][account_ban] = 30;
				playerData[temp_id][account_ban_by] = playerData[playerid][account_id];
				playerData[temp_id][account_ban_date] = gettime();
				format(playerData[temp_id][account_ban_reason], 64, "5/5 Warns");

				format(tempE, sizeof(tempE),"INSERT INTO `sanctions` (`sanction_player`, `sanction_date`, `sanction_admin_id`, `sanction_type`, `sanction_variable`, `sanction_reason`) VALUES ('%d', '%d', '%d', 'ban', '30', '5/5 Warns');", playerData[temp_id][account_id], gettime(), playerData[playerid][account_id]);
				mysql_query(Database, tempE, false);
				
				SetTimerEx("DelayedKick", 1000, 0, "i", temp_id);
			}

			
		}
	}
	return 1;
}


CMD:ban(playerid, params[])
{
	if(playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_days, temp_reason[64];
		if(sscanf(params, "uis[64]", temp_id, temp_days, temp_reason)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /ban <player> <days, 0=permanent> <reason text>");
		} else if (strlen(temp_reason) > 32  ||  !isOnlyLetter(temp_reason)) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Max 32 Characters and only letters.");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];
			
			if (temp_days == 0) {
				format(temp, sizeof(temp), "AdmCmd: %s has been permanently banned by admin %s. Reason: %s", playerData[temp_id][account_name], playerData[playerid][account_name], temp_reason);
				temp_days = 99;
			} else {
				format(temp, sizeof(temp), "AdmCmd: %s has been banned for %d days by admin %s. Reason: %s", playerData[temp_id][account_name], temp_days, playerData[playerid][account_name], temp_reason);
			}

			SendClientMessageToAll(COLOR_PUNISH, temp);

			playerData[temp_id][account_ban] = temp_days;
			playerData[temp_id][account_ban_by] = playerData[playerid][account_id];
			playerData[temp_id][account_ban_date] = gettime();
			format(playerData[temp_id][account_ban_reason], 64, "%s", temp_reason);

			SetTimerEx("DelayedKick", 1000, 0, "i", temp_id);

			new tempE[512];
			mysql_format(Database, tempE, sizeof(tempE),"INSERT INTO `sanctions` (`sanction_player`, `sanction_date`, `sanction_admin_id`, `sanction_type`, `sanction_variable`, `sanction_reason`) VALUES ('%d', '%d', '%d', 'ban', '%d', '%e');", playerData[temp_id][account_id], gettime(), playerData[playerid][account_id], temp_days, temp_reason);
			mysql_query(Database, tempE, false);
			mysql_format(Database, tempE, sizeof(tempE),"INSERT INTO `banned_ips` (`b_ip`, `b_date`, `b_variable`, `b_reason`, `b_admin`) VALUES ( '%s', '%d', '%d', '%e', '%d');", playerData[temp_id][ip_address], gettime(), temp_days, temp_reason, playerData[playerid][account_id]);
			mysql_query(Database, tempE, false);
		}
	}
	return 1;
}


CMD:unbanip(playerid, params[])
{
	if(playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_ip[32];
		if(sscanf(params, "s[32]", temp_ip)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /unbanip <ip>");
		} else {
			
			new temp[128];
			format(temp, sizeof(temp), "unbanip %s", temp_ip);
			SendRconCommand(temp);
			SendRconCommand("reloadbans");

			format(temp, sizeof(temp), "Admin %s unbanned the IP %s and reloaded the banlog.", playerData[playerid][account_name], temp_ip);
			SendClientMessageToAdmins(1, COLOR_ADMIN, temp);

			printf("\nUNBAN: %s unbanned the IP %s\n", playerData[playerid][account_name], temp_ip);
		}
	}
	return 1;
}

CMD:kickall(playerid, params[])
{
	if(playerData[playerid][account_admin] < 6 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (i != playerid) {
				Kick(i);
			}
		}
	}
	return 1;
}

CMD:check(playerid, params[])
{
	if(playerData[playerid][account_admin] < 2 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /check <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			playerStats(temp_id, playerid, 1);
			printf("Admin %s checked %s's stats.", playerData[playerid][account_name], playerData[temp_id][account_name]);
		}
	}
	return 1;
}


CMD:getweapons(playerid, params[])
{
	if(playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /getweapons <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {	
			new temp[128];

			format(temp, sizeof(temp), "|________________ %s's WEAPONS ________________|", playerData[temp_id][account_name]);
			SendClientMessage(playerid, -1, temp);
			for (new i = 0; i <= 12; i++) {
				new weaponid, weaponammo;
				GetPlayerWeaponData(temp_id, i, weaponid, weaponammo);

				if (weaponid == 0 && i != 0) {
					format(temp, sizeof(temp), "SLOT %d: Empty", i);
				} else {
					format(temp, sizeof(temp), "SLOT %d: %s (Ammo: %d)", i, GunNames[weaponid], weaponammo);
				}
				SendClientMessage(playerid, 0xc9c9c9FF, temp);

			}
		}
	}
	return 1;
}

CMD:freeze(playerid,params[])
{
    if(playerData[playerid][account_admin]<2) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	new targetid;

	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /freeze <player>");
	if(!IsPlayerConnected(targetid) || playerData[targetid][logged] == 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");

	TogglePlayerControllable(targetid, 0);
	
	new temp[128];
	
	format(temp, sizeof(temp), "AdmCmd: %s was frozen by %s.", playerData[targetid][account_name], playerData[playerid][account_name]);

	SendClientMessageToAll(0xFF6347AA, temp);

	print(temp);
	return 1;
}


CMD:unfreeze(playerid,params[])
{
    if(playerData[playerid][account_admin]<2) return SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	new targetid;

	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /unfreeze <player>");
	if(!IsPlayerConnected(targetid) || playerData[targetid][logged] == 0) return SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");

	TogglePlayerControllable(targetid, 1);
	
	new temp[128];
	
	format(temp, sizeof(temp), "AdmCmd: %s was unfrozen by %s.", playerData[targetid][account_name], playerData[playerid][account_name]);

	SendClientMessageToAll(0xFF6347AA, temp);

	print(temp);
	return 1;
}

CMD:slap(playerid, params[])
{
	if(playerData[playerid][account_helper] < 2 && playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_reason[64];
		if(sscanf(params, "us[64]", temp_id, temp_reason)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /slap <player> <reason text>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];
			
			format(temp, 128, "AdmCmd: %s got slapped by %s. Reason: %s", playerData[temp_id][account_name], playerData[playerid][account_name], temp_reason);
			SendClientMessageToAll(COLOR_PUNISH, temp);

			printf("SLAP: Player %s got slapped by %s. Reason: %s", playerData[temp_id][account_name], playerData[playerid][account_name], temp_reason);

			new Float:temp_x, Float:temp_y, Float:temp_z;
			GetPlayerPos(temp_id, temp_x, temp_y, temp_z);
			SetPlayerPos(temp_id, temp_x, temp_y, temp_z+4);
			TogglePlayerControllable(temp_id, 1);
			ClearAnimations(temp_id);
		}
	}
	return 1;
}

CMD:rac(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {

		new temp[128], temp_count;

		for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
			if (GetVehicleDriverID(i) == -1) {
				SetVehicleToRespawn(i);
				temp_count++;
			}
		}

		format(temp, 128, "Admin %s respawned %d vehicles.", playerData[playerid][account_name], temp_count);
		SendClientMessageToAdmins(1, COLOR_ADMIN, temp);

		printf("%s", temp);
	}
	return 1;
}


CMD:setskin(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp_id, temp_skin;
		if(sscanf(params, "ui", temp_id, temp_skin)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /setskin <player> <skin>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			format(temp, sizeof(temp), "You have set %s's skin to %d", playerData[temp_id][account_name], temp_skin);

			SendClientMessage(playerid, COLOR_SERVER, temp);

			SetPlayerSkinFix(temp_id, temp_skin);
			playerData[temp_id][account_skin] = temp_skin;
		}
	}
	return 1;
}


CMD:givescoreall(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp[128];
		format(temp,sizeof(temp), "Admin %s has given 1 Score point to all players.", playerData[playerid][account_name]);
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][logged]) {
				SendClientMessage(i, 0x1dcedbFF, temp);
				playerData[i][account_score]++;
			}
		}
	}
	return 1;
}

CMD:givemoneyall(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp_amount;
		if(sscanf(params, "i", temp_amount)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /givemoneyall <amount>");
		} else {
			new temp[128];
			format(temp,sizeof(temp), "Admin %s has given $%s to all players.", playerData[playerid][account_name], formatMoney(temp_amount));
			for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
				if (playerData[i][logged]) {
					SendClientMessage(i, 0x1dcedbFF, temp);
					playerData[i][account_money]+= temp_amount;
				}
			}
		}
	}
	return 1;
}

CMD:healall(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp[128];
		format(temp,sizeof(temp), "Admin %s has healed up all players.", playerData[playerid][account_name]);
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
			if (playerData[i][logged]) {
				SendClientMessage(i, 0x1dcedbFF, temp);
				SetPlayerHealth(i, 100);
			}
		}
	}
	return 1;
}


CMD:setjail(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp_id, temp_var;
		if(sscanf(params, "ui", temp_id, temp_var)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /setjail <player> <jail time>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			format(temp, sizeof(temp), "You have set %s's jail time to %d", playerData[temp_id][account_name], temp_var);

			SendClientMessage(playerid, COLOR_SERVER, temp);

			playerData[temp_id][account_jailed] = temp_var;
		}
	}
	return 1;
}



CMD:clearrob(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		playerData[playerid][account_robLS_cooldown] = 0;
		playerData[playerid][account_robSF_cooldown] = 0;
	}
	return 1;
}


CMD:gopos(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new Float:tempx, Float:tempy, Float:tempz, tempi;
		if(sscanf(params, "ifff", tempi, tempx, tempy, tempz )) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /gopos tempi, tempx, tempy, tempz");
		} else {
			SetPlayerInterior(playerid, tempi);
			SetPlayerPos(playerid, tempx, tempy, tempz);
			
		}
	}
	return 1;
}

CMD:gotoint(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new tempi;
		if(sscanf(params, "i", tempi )) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /gotoint tempi");
		} else {

			SetPlayerPos(playerid, BUYHOUSE_INTERIORS[tempi][0], BUYHOUSE_INTERIORS[tempi][1], BUYHOUSE_INTERIORS[tempi][2]);
			SetPlayerInterior(playerid, floatround(BUYHOUSE_INTERIORS[tempi][3]));

		}
	}
	return 1;
}

CMD:gotobiz(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new tempi;
		if(sscanf(params, "i", tempi )) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /gotobiz tempi");
		} else {

			SetPlayerPos(playerid, bizData[tempi][biz_x], bizData[tempi][biz_y], bizData[tempi][biz_z]);
			
		}
	}
	return 1;
}


CMD:setfuel(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new tempi;
		if(sscanf(params, "i", tempi )) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /setfuel temp");
		} else {

			carData[GetPlayerVehicleID(playerid)][vehicle_fuel] = tempi;
			
		}
	}
	return 1;
}
CMD:givemeseconds(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		playerData[playerid][session_activeSeconds] += 60*20;
	}
	return 1;
}

CMD:forcepayday(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		FORCE_PAYDAY = true;
	}
	return 1;
}

CMD:forcewartime(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		FORCE_WARTIME = !FORCE_WARTIME;
	}
	return 1;
}

CMD:biz(playerid, params[])
{
	if (playerData[playerid][account_jailed] > 0 && (playerData[playerid][account_escaped] != 1 && playerData[playerid][escape_state] != 2)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	} else if (playerData[playerid][robbing_state] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");
	}  else if (playerData[playerid][tracking_mode] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are tracking a player. Use /trackoff first.");
	}  else if (playerData[playerid][am_working] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are working right now.");
	} else {
		new temp[1024];
		new count;
		for (new i; i < MAX_BIZ; i++) {
			if (bizData[i][biz_type] != 0) {
				if (count == 0) {
					format(temp, sizeof(temp), "%d\t%s\t%s\t$%s", i, bizData[i][biz_owner_name], BIZ_INTERIORS[bizData[i][biz_type]][bi_name], formatMoney(bizData[i][biz_profit]));
				} else {
					format(temp, sizeof(temp), "%s\n%d\t%s\t%s\t$%s", temp, i, bizData[i][biz_owner_name], BIZ_INTERIORS[bizData[i][biz_type]][bi_name], formatMoney(bizData[i][biz_profit]));
				}
				count++;
			}
		}
		format(temp, sizeof(temp), "id\tOwner\tType\tProfit\n%s", temp);
		Dialog_Show(playerid, DLG_BIZ, DIALOG_STYLE_TABLIST_HEADERS, "Business", temp, "Locate", "Close");
	}
	return 1;
}


Dialog:DLG_BIZ(playerid, response, listitem, inputtext[])
{
	if (response) {
		new tempi = strval(inputtext);
		setCheckpoint(playerid, bizData[tempi][biz_x], bizData[tempi][biz_y], bizData[tempi][biz_z], 3.0);
	}
	return 1;
}


CMD:house(playerid, params[])
{
	if (playerData[playerid][account_jailed] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	} else if (playerData[playerid][account_escaped] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are in jail or escaping.");
	} else if (playerData[playerid][robbing_state] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot use this command while you are robbing.");
	}  else if (playerData[playerid][tracking_mode] == 1) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are tracking a player. Use /trackoff first.");
	}  else if (playerData[playerid][am_working] > 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are working right now.");
	} else {
		new temp[2048];
		new count;
		for (new i; i < MAX_HOUSES; i++) {
			if (houseData[i][house_id] != 0 && houseData[i][house_sell] > 0) {
				if (count == 0) {
					if (playerData[playerid][account_money] >= houseData[i][house_sell]) {
						format(temp, sizeof(temp), "%d\t%s\t%d\t{1dd14a}$%s", houseData[i][house_id], houseData[i][house_owner_name], houseData[i][house_interior], formatMoney(houseData[i][house_sell]));
					} else {
						format(temp, sizeof(temp), "%d\t%s\t%d\t{d93030}$%s", houseData[i][house_id], houseData[i][house_owner_name], houseData[i][house_interior], formatMoney(houseData[i][house_sell]));
					}
				} else {
					if (playerData[playerid][account_money] >= houseData[i][house_sell]) {
						format(temp, sizeof(temp), "%s\n%d\t%s\t%d\t{1dd14a}$%s", temp, houseData[i][house_id], houseData[i][house_owner_name], houseData[i][house_interior], formatMoney(houseData[i][house_sell]));
					} else {
						format(temp, sizeof(temp), "%s\n%d\t%s\t%d\t{d93030}$%s", temp, houseData[i][house_id], houseData[i][house_owner_name], houseData[i][house_interior], formatMoney(houseData[i][house_sell]));
					}
				}
				count++;
			}
		}
		if (count > 0) {
			new temp_title[32];
			format(temp_title, sizeof(temp_title), "Houses for sale (%d)", count);
			format(temp, sizeof(temp), "id\tOwner\tInterior\tPrice\n%s", temp);
			Dialog_Show(playerid, DLG_FREEHOUSE, DIALOG_STYLE_TABLIST_HEADERS, temp_title, temp, "Locate", "Close");
		} else {
			Dialog_Show(playerid, DLG_INFO, DIALOG_STYLE_MSGBOX, "No House for sale", "There is no house of sale.", "OK", "");
		}
	}
	return 1;
}



Dialog:DLG_FREEHOUSE(playerid, response, listitem, inputtext[])
{
	if (response) {
		new tempi = strval(inputtext);
		for (new i; i < MAX_HOUSES; i++) {
			if (houseData[i][house_id] == tempi) {
				setCheckpoint(playerid, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z], 3.0);
			}
		}
	}
	return 1;
}


CMD:gotohouse(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new tempi;
		if(sscanf(params, "i", tempi )) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /house tempi");
		} else {

			SetPlayerPos(playerid, houseData[tempi][house_x], houseData[tempi][house_y], houseData[tempi][house_z]);
			
		}
	}
	return 1;
}


CMD:sethp(playerid, params[])
{
	if(playerData[playerid][account_admin] < 3 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp_id, temp_var;
		if(sscanf(params, "ui", temp_id, temp_var)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /sethp <player> <hp>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			format(temp, sizeof(temp), "You have set %s's HP to %d", playerData[temp_id][account_name], temp_var);

			SendClientMessage(playerid, COLOR_SERVER, temp);

			SetPlayerHealth(temp_id, temp_var);
		}
	}
	return 1;
}


CMD:setclan(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp_id, temp_var;
		if(sscanf(params, "ui", temp_id, temp_var)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /setclan <player> <clan id>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			format(temp, sizeof(temp), "You have set %s's clan to %d", playerData[temp_id][account_name], temp_var);

			SendClientMessage(playerid, COLOR_SERVER, temp);

			playerData[temp_id][account_clan] = temp_var;
			playerData[temp_id][account_clanRank] = 1;
		}
	}
	return 1;
}



CMD:setarmour(playerid, params[])
{
	if(playerData[playerid][account_admin] < 3 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp_id, temp_var;
		if(sscanf(params, "ui", temp_id, temp_var)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /sethp <player> <hp>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			format(temp, sizeof(temp), "You have set %s's Armour to %d", playerData[temp_id][account_name], temp_var);

			SendClientMessage(playerid, COLOR_SERVER, temp);

			SetPlayerArmour(temp_id, temp_var);
		}
	}
	return 1;
}


CMD:setmoney(playerid, params[])
{
	if(playerData[playerid][account_admin] < 5 && !IsPlayerAdmin(playerid)) {
		return 0;
	} else {
		new temp_id, temp_var;
		if(sscanf(params, "ui", temp_id, temp_var)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /money <player> <money>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else {
			new temp[128];

			new before = playerData[temp_id][account_money];

			format(temp, sizeof(temp), "You have set %s's money to %d (before: %d)", playerData[temp_id][account_name], temp_var, before);

			SendClientMessage(playerid, COLOR_SERVER, temp);

			playerData[temp_id][account_money] = temp_var;
		}
	}
	return 1;
}

CMD:car(playerid, params[])
{
	if (!IsPlayerAdmin(playerid)) {
		return 0;
	}
	new temp_var;
	if(!sscanf(params, "i", temp_var)) {
		new Float:tempx,Float:tempy,Float:tempz,Float:tempa;
		GetPlayerPos(playerid, tempx, tempy, tempz);
		GetPlayerFacingAngle(playerid, tempa);
		new temp_car = CreateVehicle(temp_var, tempx, tempy, tempz, tempa, -1, -1, -1);
		PutPlayerInVehicle(playerid, temp_car, 0);
	}

	return 1;
}


CMD:spec(playerid, params[])
{
	if(playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id;
		if(sscanf(params, "u", temp_id)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /spec <player>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (temp_id == playerid) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You cannot spectate yourself.");
		} else {
			new temp[128];

			if (playerData[playerid][spec_mode] == 0) {
				GetPlayerPos(playerid, playerData[playerid][spec_goback_x], playerData[playerid][spec_goback_y], playerData[playerid][spec_goback_z]);
				playerData[playerid][spec_goback_int] = GetPlayerInterior(playerid);
				playerData[playerid][spec_goback_house] = playerData[playerid][enteredHouse];
				playerData[playerid][spec_goback_biz] = playerData[playerid][enteredBiz];
			}

			if (playerData[playerid][spec_player] == 0 || playerData[playerid][spec_player] != temp_id && !IsPlayerAdmin(playerid)) {
				format(temp, 128, "Admin %s is now spectating %s (%d).", playerData[playerid][account_name], playerData[temp_id][account_name], temp_id);
				SendClientMessageToAdmins(1, COLOR_ADMIN, temp);
			}

			playerData[playerid][spec_player] = temp_id;
			playerData[playerid][spec_mode] = 1;

			printf("SPEC: %s", temp);

			SetPlayerInterior(playerid, GetPlayerInterior(temp_id));
			SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(temp_id));

			if (GetPlayerVehicleID(temp_id) != 0) {
				TogglePlayerSpectating(playerid, 1);
				PlayerSpectateVehicle(playerid, GetPlayerVehicleID(temp_id));
			} else {
				TogglePlayerSpectating(playerid, 1);
				PlayerSpectatePlayer(playerid, temp_id);
			}

			SendClientMessage(playerid, COLOR_INFO,"You can press CLICK button to refresh the spectation.")
		}
	}
	return 1;
}

CMD:specoff(playerid, params[])
{
	if(playerData[playerid][account_admin] < 1 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		if (playerData[playerid][spec_mode] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: You are not in spectator mode.");
		} else {
			playerData[playerid][spec_mode] = 0;
			playerData[playerid][spec_goback_flag] = 1;
			TogglePlayerSpectating(playerid, 0);
			SendClientMessage(playerid, COLOR_SERVER, "You are not in spectator mode anymore.");
		}
	}
	return 1;
}

CMD:makeleader(playerid, params[])
{
	if(playerData[playerid][account_admin] < 4 && !IsPlayerAdmin(playerid)) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You are not authorized to use this command.");
	} else {
		new temp_id, temp_faction;
		if(sscanf(params, "ui", temp_id, temp_faction)) {
			SendClientMessage(playerid, COLOR_SYNTAX, "Syntax: /makeleader <player> <faction>");
		} else if (!IsPlayerConnected(temp_id) || playerData[temp_id][logged] == 0) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: That player is not online.");
		} else if (IsPlayerInAnyVehicle(temp_id)) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Get the player out of that vehicle first. His skin will change.");
		} else if (temp_faction < 0 || temp_faction > 5) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Invalid Faction ID.");
		} else {
			new temp[128], tempE[512];

			if (temp_faction == 0) {
				playerData[temp_id][account_faction] = 0;
				playerData[temp_id][account_rank] = 0;

				format(temp, sizeof(temp), "You have been removed from the Leader's position by admin %s.", playerData[playerid][account_name]);
				SendClientMessage(temp_id, 0x00C3FFFF, temp);
				format(temp, sizeof(temp), "You have removed %s from the Leader's position.", playerData[temp_id][account_name]);
				SendClientMessage(playerid, 0x00C3FFFF, temp);

				playerData[temp_id][account_skin] = -1;
				SpawnPlayer(temp_id);

			} else {
				new tempF[32], tempS;
				if (temp_faction == 1) {
					tempS = 259;
				} else if (temp_faction == 2) {
					tempS = 288;
				} else if (temp_faction == 3) {
					tempS = 270;
				} else if (temp_faction == 4) {
					tempS = 290;
				} else if (temp_faction == 5) {
					tempS = 186;
				}

				format(tempF, 32, "%s", getFactionName(temp_faction));

				playerData[temp_id][account_faction] = temp_faction;
				playerData[temp_id][account_rank] = 7;
				playerData[temp_id][account_skin] = tempS;
				playerData[temp_id][currentFactionPredef] = 0;
				
				SpawnPlayer(temp_id);

				format(temp, sizeof(temp), "You have been promoted as the Leader of %s by admin %s.", tempF, playerData[playerid][account_name]);
				SendClientMessage(temp_id, 0x00C3FFFF, temp);
				format(temp, sizeof(temp), "You have promoted %s as the Leader of %s.", playerData[temp_id][account_name], tempF);
				SendClientMessage(playerid, 0x00C3FFFF, temp);
			}

			format(tempE, sizeof(tempE),"INSERT INTO `promotions` (`promotion_player`, `promotion_type`, `promotion_new_level`, `promotion_by`, `promotion_date`, `promotion_reason`, `promotion_variable`) VALUES ( '%d', 'rank', '%d', '%d', '%d', '', '%d')", playerData[temp_id][account_id], 7, playerData[playerid][account_id], gettime(), temp_faction);
			mysql_query(Database, tempE, false);
		}
	}
	return 1;
}


CMD:togcamera(playerid, params[]) {
	playerData[playerid][dont_want_stream] = !playerData[playerid][dont_want_stream];

	if (playerData[playerid][dont_want_stream]) {
		SendClientMessage(playerid, COLOR_BADINFO, "From now on server will not spectate you during the live streaming.");
	} else {
		SendClientMessage(playerid, COLOR_INFO, "From now on server will spectate you during the live streaming.");
	}
	return 1;
}


CMD:stats(playerid, params[]) {
	playerStats(playerid, playerid, 0);
	return 1;
}

CMD:help(playerid, params[]) {
	new temp[952];
	strcat(temp, "/stats\tAll your account's information\n");
	strcat(temp, "/locations\tAll basic server's and own properties locations\n");
	strcat(temp, "/shop\tServer's Shop\n");
	strcat(temp, "/bizhelp\tAll server's businesses\n");
	strcat(temp, "/factionhelp\tCommands regarding the factions\n");
	strcat(temp, "/clanhelp\tCommands regarding the clans\n");
	strcat(temp, "/househelp\tCommands regarding the house system\n");
	strcat(temp, "/carhelp\tCommands regarding the car system\n");
	strcat(temp, "/robhelp\tInformation regarding the rob system\n");
	strcat(temp, "/eventhelp\tInformation regarding the event system\n");
	strcat(temp, "/animlist\tAvailable animations\n");
	strcat(temp, "/morehelp\tMore available commands");
	Dialog_Show(playerid, DLG_HELP, DIALOG_STYLE_TABLIST, "Help", temp, "Select", "Cancel");
	return 1;
}

CMD:bizhelp(playerid, params[]) {
	SendClientMessage(playerid, COLOR_SERVER, "BIZ HELP: /biz, /buybiz, /setentrance, /withdrawprofit, /sellbiz");
	return 1;
}

CMD:materialshelp(playerid, params[]) {
	SendClientMessage(playerid, COLOR_SERVER, "MATERIALS HELP: /locations, /getmaterials, /delivermaterials, /sellgun");
	return 1;
}

CMD:bankhelp(playerid, params[]) {
	SendClientMessage(playerid, COLOR_SERVER, "BANK HELP: /deposit, /withdraw, /transfer, /stats");
	return 1;
}


CMD:clanhelp(playerid, params[]) {
	SendClientMessage(playerid, COLOR_SERVER, "CLAN HELP: /c, /spray, /cinvite, /cgiverank, /cuninvite, /cmembers, /refreshskin, /renewclan, /turfs, /cmotd");
	return 1;
}

CMD:factionhelp(playerid, params[]) {
	if (playerData[playerid][account_faction]==FACTION_CIVIL) {
		SendClientMessage(playerid, COLOR_SERVER, "You are not a member of any faction.");
	}
	if (playerData[playerid][account_faction]==FACTION_TAXILS) {
		SendClientMessage(playerid, COLOR_SERVER, "FACTION HELP: /f, /progress, /leaderhelp");
	}
	if (playerData[playerid][account_faction]==FACTION_LSPD) {
		SendClientMessage(playerid, COLOR_SERVER, "FACTION HELP: /f, /wanted, /leaderhelp, /frisk, /confiscate, /cuff, /uncuff, /arrest, /shout");
	}
	if (playerData[playerid][account_faction]==FACTION_MEDICS) {
		SendClientMessage(playerid, COLOR_SERVER, "FACTION HELP: /f, /progress, /leaderhelp");
	}
	if (playerData[playerid][account_faction]==FACTION_HITMAN) {
		SendClientMessage(playerid, COLOR_SERVER, "FACTION HELP: /f, /contracts");
	}
	return 1;
}

CMD:leaderhelp(playerid, params[]) {
	if (playerData[playerid][account_rank] < 7) {
		SendClientMessage(playerid, COLOR_SERVER, "You are not a leader.");
	} else {
		SendClientMessage(playerid, COLOR_SERVER, "LEADER HELP: /invite, /uninvite, /giverank, /l");
	}
	return 1;
}

CMD:househelp(playerid, params[]) {
	SendClientMessage(playerid, COLOR_SERVER, "HOUSE HELP: /locations, /house, /sellhouse, /buyhouse, /changespawn, /lockhouse, /drophouse, /heal, /shop, /enter, /exit");
	return 1;
}


CMD:carhelp(playerid, params[]) {
	SendClientMessage(playerid, COLOR_SERVER, "CAR HELP: /locations, /buycar, /lock, /sellcarserver, /sellcar, /radio, /cw");
	SendClientMessage(playerid, COLOR_SERVER, "CAR HELP: /removetuning, /park, /tow");

	return 1;
}

CMD:eventhelp(playerid, params[]) {
	Dialog_Show(playerid, DLG_INFO, DIALOG_STYLE_MSGBOX, "Event Help", 
	"\n\
	- /requestevent Request a new event to online administrators\n\
	- /e Talk to the public chat as event organizer\n\
	- /stopevent Stop the ongoing event", "OK", "");
	return 1;
}


CMD:robhelp(playerid, params[]) {
	Dialog_Show(playerid, DLG_INFO, DIALOG_STYLE_MSGBOX, "Rob Help", 
	"\n\
	 Rob a car:\n\
	Go close to a locked car and /rob it. Your attempt might fail, but you can try again until you unlock the car.\n\
	\n\
	Rob a bank:\n\
	Find a bank in /locations and get inside. Then start /rob and collect as much money as you can.\n\
	When you are ready get out and deliver your collected money at the checkpoint on the map.", "OK", "");
	return 1;
}

CMD:morehelp(playerid, params[]) {
	new temp[952];
	strcat(temp, "- /eat Eat a food and heal up\n");
	strcat(temp, "- /buygun Buy a weapon\n");
	strcat(temp, "- /buyphone Buy a new phone number\n");
	strcat(temp, "- /track(off) Track a player on the map\n");
	strcat(temp, "- /wanted See the wanted players on the map\n");
	strcat(temp, "- /eject Eject a player from your vehicle.\n");
	strcat(temp, "- /sms Send an sms message to a players.\n");
	strcat(temp, "- /findnumber Find the phone number of a player\n");
	strcat(temp, "- /pay Give money to a player\n");
	strcat(temp, "- /contract Send a contract to hitmen\n");
	strcat(temp, "- /contracts See all active contracts\n");
	strcat(temp, "- /heal Get healed in your own house\n");
	strcat(temp, "- /admin See online administrators\n");
	strcat(temp, "- /disablecheckpoint Cancel a set checkpoints\n");
	strcat(temp, "- /escape Escape from the jail\n");
	strcat(temp, "- /need Send a request for a service\n");
	Dialog_Show(playerid, DLG_INFO, DIALOG_STYLE_MSGBOX, "More Help", temp, "OK", "");
	return 1;
}

CMD:animlist(playerid,params[])
{
	SendClientMessage(playerid,-1,"/fall /injured /push /handsup /bomb /drunk /getarrested /laugh /chairsit2");
	SendClientMessage(playerid,-1,"/medic /robman /taichi /lookout /kiss /cellin /cellout /crossarms /lay");
	SendClientMessage(playerid,-1,"/deal /crack /smokem /smokef /groundsit /chatnow /dance /fucku /strip /hide");
	SendClientMessage(playerid,-1,"/rollfall /bat /lifejump /lay2 /chant /aim /lowthrow /highthrow /lean");
	SendClientMessage(playerid,-1,"/gsign1 /gsign2 /gsign3 /gsign4 /gsign5 /gift /sit /vomit /chairsit");
	SendClientMessage(playerid,-1,"/slapass /slapped /celebrate /animsex /bj /wave /eatsit /reload");
	SendClientMessage(playerid,-1," /animlist2...");
	return 1;
}


CMD:animhelp(playerid, params[]) {
	return cmd_animlist(playerid, params);
}


CMD:animlist2(playerid,params[])
{
	SendClientMessage(playerid,-1,"/follow /greet /stand /injured2 /piss");
	SendClientMessage(playerid,-1,"/hitch /bitchslap /cpr /rap /wankoff");
	SendClientMessage(playerid,-1,"/dance /fsit /msit /relax /win /win2");
	SendClientMessage(playerid,-1,"/yes /deal2 /thankyou /invite1 /invite2");
	SendClientMessage(playerid,-1,"/celebrate2 /scratch /gangwalk /shake");
	SendClientMessage(playerid,-1,"/crossarms2 /crossarms3");
	return 1;
}

CMD:cmds(playerid, params[]) {
	return cmd_help(playerid, params);
}

CMD:radio(playerid, params[]) {
	if (GetPlayerVehicleSeat(playerid) != 0) {
		SendClientMessage(playerid, COLOR_SERVER, "Error: You need to be in a vehicle as the driver.");
	} else {
		Dialog_Show(playerid, DLG_RADIO, DIALOG_STYLE_LIST, "Radio",
		"Sfera 102.2\n\
		Kiss FM\n\
		Thema 104.6\n\
		Love Radio 97.5\n\
		Sport FM\n\
		Athens Deejay 95.2\n\
		MAD Radio 106.2\n\
		Laknicek Radio\n\
		{B3B3B3}Stop Radio", "OK", "Cancel");
	}
	return 1;
}

Dialog:DLG_RADIO(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (strcmp(inputtext, "Sfera 102.2") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "sfera102.2");
		if (strcmp(inputtext, "Kiss FM") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "kissfm");
		if (strcmp(inputtext, "Thema 104.6") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "thema");
		if (strcmp(inputtext, "Love Radio 97.5") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "loveradio");
		if (strcmp(inputtext, "Sport FM") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "sportfm");
		if (strcmp(inputtext, "Athens Deejay 95.2") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "adj");
		if (strcmp(inputtext, "MAD Radio 106.2") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "mad");
		if (strcmp(inputtext, "Laknicek Radio") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "lak");
		if (strcmp(inputtext, "Stop Radio") == 0) format(vehicleRadio[GetPlayerVehicleID(playerid)], 32, "");

		if (strcmp(inputtext, "Stop Radio") != 0) {
			new temp[128];
			format(temp, sizeof(temp), "%s changed the radio station in his vehicle to %s.", playerData[playerid][account_name], inputtext);
			SendClientMessageToAll(COLOR_PUBLIC, temp);
		} else {
			new temp[128];
			format(temp, sizeof(temp), "%s stopped the radio in his vehicle.", playerData[playerid][account_name]);
			SendClientMessageToAll(COLOR_PUBLIC, temp);
		}
	}
	return 1;
}



Dialog:DLG_HELP(playerid, response, listitem, inputtext[])
{
	if (response) {
		if (strcmp(inputtext, "/stats") == 0) {
			return cmd_stats(playerid, "");
		}

		if (strcmp(inputtext, "/locations") == 0) {
			return cmd_locations(playerid, "");
		}

		if (strcmp(inputtext, "/shop") == 0) {
			return cmd_shop(playerid, "");
		}

		if (strcmp(inputtext, "/bizhelp") == 0) {
			return cmd_bizhelp(playerid, "");
		}

		if (strcmp(inputtext, "/factionhelp") == 0) {
			return cmd_factionhelp(playerid, "");
		}

		if (strcmp(inputtext, "/clanhelp") == 0) {
			return cmd_clanhelp(playerid, "");
		}

		if (strcmp(inputtext, "/househelp") == 0) {
			return cmd_househelp(playerid, "");
		}

		if (strcmp(inputtext, "/carhelp") == 0) {
			return cmd_carhelp(playerid, "");
		}

		if (strcmp(inputtext, "/robhelp") == 0) {
			return cmd_robhelp(playerid, "");
		}

		if (strcmp(inputtext, "/eventhelp") == 0) {
			return cmd_eventhelp(playerid, "");
		}

		if (strcmp(inputtext, "/animlist") == 0) {
			return cmd_animlist(playerid, "");
		}

		if (strcmp(inputtext, "/morehelp") == 0) {
			return cmd_morehelp(playerid, "");
		}
	}
	return 1;
}




stock SendClientMessageToPaintballers(color, message[])
{
	for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
		if (playerData[i][logged] && playerData[i][paintball_joined] == 1) {
			SendClientMessage(i, color, message);
		}
	}
}

stock SendClientMessageToAdmins(level, color, message[])
{
	for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
		if ((playerData[i][logged] && playerData[i][account_admin] >= level) || IsPlayerAdmin(i)) {
			SendClientMessage(i, color, message);
		}
	}
}

stock SendClientMessageToFaction(faction, color, message[])
{
	for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++) {
		if (playerData[i][logged] && playerData[i][account_faction] == faction) {
			SendClientMessage(i, color, message);
		}
	}
}

stock isValidEmail(gotemail[])
{
	new len=strlen(gotemail);
	new cstate=0;
	for(new i=0;i<len;i++)
	{
		if ((cstate==0 || cstate==1) && (gotemail[i]>='A' && gotemail[i]<='Z') || (gotemail[i]>='a' && gotemail[i]<='z') || (gotemail[i]>='0' && gotemail[i]<='9') || (gotemail[i]=='.')  || (gotemail[i]=='-')  || (gotemail[i]=='_'))
		{
		}
		else
		{
			if ((cstate==0) &&(gotemail[i]=='@'))
			{
				cstate=1;
			}
			else
			{
				return false;
			}
		}
	}
	if (cstate<1)
	{
		return false;
	}
	if (len<6)
	{
		return false;
	}
	if ((gotemail[len-3]=='.') || (gotemail[len-4]=='.') || (gotemail[len-5]=='.'))
	{
		return true;
	}
	return false;
}

stock Cal_Month(month,year)
{
	new days;
	if(month == 4 || month == 6 || month == 9 || month == 11) {
		days = 30;
	} else if(month == 02) {
			new leapyear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

			if(leapyear == 0) {
				days = 28;
			} else {
				days = 29;
			}
	} else {
		days = 31;
	}
	return days;
}

stock getTimeString(part = 3){
	new H,m,s;
	new Year, Month, Day;
	gettime(H, m, s);
	getdate(Year, Month, Day);
	H += serverTimeZoneKey;
	if (H == 24) {
		H = 0;
		Day = Day + 1;
		if(Day > Cal_Month(Month, Year)) {
			Day = 1;
		}
	}
	new returnText[32];
	if(part == 1) format(returnText,sizeof(returnText),"%02d/%02d/%d",Day,Month,Year);
	if(part == 2) format(returnText,sizeof(returnText),"%02d:%02d",H,m);
	if(part == 3) format(returnText,sizeof(returnText),"%02d/%02d/%d %d:%02d",Day,Month,Year,H,m);
	return returnText;
	
}

stock isWarTime()
{

	if (FORCE_WARTIME) {
	
		return true;
	
	} else {
		
		new H,m,s;
		new Year, Month, Day;
		gettime(H, m, s);
		getdate(Year, Month, Day);
		H += serverTimeZoneKey;
		if (H == 24) {
			H = 0;
			Day = Day + 1;
			if(Day > Cal_Month(Month, Year)) {
				Day = 1;
			}
		}
		if ( (H == 20 && (m >= 0 && m < 30)) || (H == 15 && (m >= 0 && m < 30)) ) {
			return true;
		}
		return false;
		
	}
}

stock formatMoney(iNum, const szChar[] = ".")
{
    new
        szStr[16]
    ;
    format(szStr, sizeof(szStr), "%d", iNum);
    
    for(new iLen = strlen(szStr) - 3; iLen > 0; iLen -= 3)
    {
        strins(szStr, szChar, iLen);
    }
    return szStr;
}

stock GetVehicleDriverID(vehicleid)
{
    for(new i,l=GetPlayerPoolSize()+1; i<l; i++) if(GetPlayerState(i) == PLAYER_STATE_DRIVER && IsPlayerInVehicle(i,vehicleid)) return i;
    return -1;
} 

stock SetPlayerSkinFix(playerid, skinid)
{
	new
	    Float:tmpPos[4],
		vehicleid = GetPlayerVehicleID(playerid),
		seatid = GetPlayerVehicleSeat(playerid);
	GetPlayerPos(playerid, tmpPos[0], tmpPos[1], tmpPos[2]);
	GetPlayerFacingAngle(playerid, tmpPos[3]);
	if(skinid < 0 || skinid > 299) return 0;
	if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_DUCK)
	{
	    SetPlayerPos(playerid, tmpPos[0], tmpPos[1], tmpPos[2]);
		SetPlayerFacingAngle(playerid, tmpPos[3]);
		TogglePlayerControllable(playerid, 1); // preventing any freeze - optional
		return SetPlayerSkin(playerid, skinid);
	}
	else if(IsPlayerInAnyVehicle(playerid))
	{
	    new
	        tmp;
	    RemovePlayerFromVehicle(playerid);
	    SetPlayerPos(playerid, tmpPos[0], tmpPos[1], tmpPos[2]);
		SetPlayerFacingAngle(playerid, tmpPos[3]);
		TogglePlayerControllable(playerid, 1); // preventing any freeze - important - because of doing animations of exiting vehicle
		tmp = SetPlayerSkin(playerid, skinid);
		PutPlayerInVehicle(playerid, vehicleid, (seatid == 128) ? 0 : seatid);
		return tmp;
	}
	else
	{
	    return SetPlayerSkin(playerid, skinid);
	}
}

stock getFactionName(faction)
{
	new tempF[32];
	if (faction == 0) {
		format(tempF, 32, "Civil");
	} else if (faction == 1) {
		format(tempF, 32, "Taxi LS");
	} else if (faction == 2) {
		format(tempF, 32, "LSPD");
	} else if (faction == 3) {
		format(tempF, 32, "Grove Street Family");
	} else if (faction == 4) {
		format(tempF, 32, "Paramedics");
	} else if (faction == 5) {
		format(tempF, 32, "Hitman");
	}

	return tempF;
}

stock getFactionNameWithColor(faction, inputColor)
{
	new tempF[32];
	if (faction == 0) {
		format(tempF, 32, "{FFFFFF}Civil{%06x}", inputColor >>> 8);
	} else if (faction == 1) {
		format(tempF, 32, "{ced459}Taxi LS{%06x}", inputColor >>> 8);
	} else if (faction == 2) {
		format(tempF, 32, "{2429b5}LSPD{%06x}", inputColor >>> 8);
	} else if (faction == 3) {
		format(tempF, 32, "{189e1a}Grove Street Family{%06x}", inputColor >>> 8);
	} else if (faction == 4) {
		format(tempF, 32, "{e34949}Paramedics{%06x}", inputColor >>> 8);
	} else if (faction == 5) {
		format(tempF, 32, "{5c4646}Hitman{%06x}", inputColor >>> 8);
	}

	return tempF;
}


stock getFactionColor(faction)
{
	new tempF[16];
	if (faction == 0) {
		format(tempF, 16, "FFFFFF");
	} else if (faction == 1) {
		format(tempF, 16, "ced459");
	} else if (faction == 2) {
		format(tempF, 16, "2429b5");
	} else if (faction == 3) {
		format(tempF, 16, "189e1a");
	} else if (faction == 4) {
		format(tempF, 16, "e34949");
	} else if (faction == 5) {
		format(tempF, 16, "5c4646");
	}

	return tempF;
}


stock playerStats(playerid, showerid, detailed)
{
	new tempC[64], tempI[1024];
	format(tempC, 64, "Stats: %s (%d)", playerData[playerid][account_name], playerid);

	new tempY, tempM, tempD, temp_;
	TimestampToDate(playerData[playerid][account_registered], tempY, tempM, tempD, temp_, temp_, temp_, serverTimeZoneKey);

	new phonenumber[32];
	if (playerData[playerid][account_phoneNumber] == 0) {
		format(phonenumber, sizeof(phonenumber), "none");
	} else {
		format(phonenumber, sizeof(phonenumber), "%d-%d", playerData[playerid][account_phoneNumber], playerData[playerid][account_id]);
	}

	format(tempI, sizeof(tempI), "- Basic Info:\nID: [%d], Email: [%s], Registered: [%02d/%02d/%02d], Phone Number: [%s]\n\n- Player Stats:\nScore: [%d]", playerData[playerid][account_id], playerData[playerid][account_email], tempD, tempM, tempY, phonenumber, playerData[playerid][account_score]);
	format(tempI,  sizeof(tempI), "%s, Deaths: [%d], Kills: [%d], Wanted Level: [%d]\n", tempI, playerData[playerid][account_deaths], playerData[playerid][account_kills], playerData[playerid][account_wanted]);
	format(tempI,  sizeof(tempI), "%sCash: [$%s], Bank: [$%s], Active Hours: [%d], Active Minutes: [%d]", tempI, formatMoney(playerData[playerid][account_money]),formatMoney(playerData[playerid][account_bank]), floatround(playerData[playerid][account_activeSeconds]/3600.0, floatround_floor), floatround(playerData[playerid][account_activeSeconds]/60.0));
	format(tempI, sizeof(tempI), "%s\nEscapes: [%d], Materials: [%d]\n\n- Factions:\nFaction: [%s]", tempI, playerData[playerid][account_succ_escapes],
	playerData[playerid][account_materials], getFactionName(playerData[playerid][account_faction]))
	if (playerData[playerid][account_rank] == 7) {
		format(tempI,  sizeof(tempI), "%s, Leader: [Yes]", tempI);
	} else {
		format(tempI,  sizeof(tempI), "%s, Rank: [%d]", tempI, playerData[playerid][account_rank]);
	}
	format(tempI,  sizeof(tempI), "%s, Admin: [%d], Helper: [%d]", tempI, playerData[playerid][account_admin], playerData[playerid][account_helper]);

	new temp_clanIndex = getClanIndex(playerid);
	if (temp_clanIndex != NO_CLAN && temp_clanIndex != CLAN_NOT_FOUND) {
		if ( playerData[playerid][account_clanRank] == 7) {
			format(tempI,  sizeof(tempI), "%s\n\nClan: [%s], Rank: [Owner]", tempI, clanData[temp_clanIndex][clan_name]);
		} else {
			format(tempI,  sizeof(tempI), "%s\n\nClan: [%s], Rank: [%d]", tempI, clanData[temp_clanIndex][clan_name], playerData[playerid][account_clanRank]);
		}
	}

	if (detailed == 1) {
		format(tempI,  sizeof(tempI), "%s\n\nIP: [%s], VW: [%d], Interior: [%d], SkinGet: [%d], SkinPre: [%d], SessionSeconds: [%d - %d]\nSpecInt: [%d], Paintball: [%d], Rob LS: [%d], Rob SF: [%d], Jailed: [%d]", tempI, playerData[playerid][ip_address], GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid), GetPlayerSkin(playerid), playerData[playerid][account_skin], playerData[playerid][session_activeSeconds],
		playerData[playerid][session_lastReward], playerData[playerid][special_interior], playerData[playerid][paintball_joined], playerData[playerid][account_robLS_cooldown], playerData[playerid][account_robSF_cooldown], playerData[playerid][account_jailed]);
	}
	Dialog_Show(showerid, DLG_STATS, DIALOG_STYLE_MSGBOX, tempC, tempI, "Close","");
}

stock getVehicleName(vname[])
{
	for(new i = 0; i < 211; i++) {
		if(strfind(VehicleNames[i], vname, true) != -1)
		return i + 400;
	}
	return -1;
}


stock isBike(carid)
{
	switch(GetVehicleModel(carid))
	{
		case 481,509,510: return 1;
	}
	return 0;
}

stock isMotoBike(carid){
	switch(GetVehicleModel(carid))
	{
		case 448,461,462,463,468,471,521,522,523,581,586: return 1;
	}
	return 0;
}

stock isBoat(carid)
{
	switch(GetVehicleModel(carid))
	{
		case 430,446,452,453,454,472,473,484,493,595: return 1;
	}
	return 0;
}

stock isPlane(carid)
{
	switch(GetVehicleModel(carid))
	{
		case 460,476,511,512,513,519,520,553,577,592,593,487,488,497,548,563,417,425,447,469: return 1;
	}
	return 0;
}

stock skinSelector_init(playerid)
{
	
	// Textdraws for skin selector
	new PlayerText:Textdraw0;
	new PlayerText:Textdraw1;
	new PlayerText:Textdraw2;
	new PlayerText:Textdraw3;
	new PlayerText:Textdraw4;
	new PlayerText:Textdraw5;
	new PlayerText:Textdraw6;
	new PlayerText:Textdraw7;

	Textdraw0 = CreatePlayerTextDraw(playerid,544.000000, 140.000000, "CIVIL");
	PlayerTextDrawAlignment(playerid,Textdraw0, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw0, 255);
	PlayerTextDrawFont(playerid,Textdraw0, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw0, 0.499998, 2.499998);
	PlayerTextDrawColor(playerid,Textdraw0, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw0, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw0, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw0, 1);
	PlayerTextDrawUseBox(playerid,Textdraw0, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw0, 255);
	PlayerTextDrawTextSize(playerid,Textdraw0, 20.000000, 159.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw0, 1);

	Textdraw1 = CreatePlayerTextDraw(playerid,544.000000, 170.000000, "TAXI");
	PlayerTextDrawAlignment(playerid,Textdraw1, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw1, 255);
	PlayerTextDrawFont(playerid,Textdraw1, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw1, 0.499998, 2.499998);
	PlayerTextDrawColor(playerid,Textdraw1, -254518785);
	PlayerTextDrawSetOutline(playerid,Textdraw1, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw1, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw1, 1);
	PlayerTextDrawUseBox(playerid,Textdraw1, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw1, 255);
	PlayerTextDrawTextSize(playerid,Textdraw1, 20.000000, 159.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw1, 1);

	Textdraw2 = CreatePlayerTextDraw(playerid,544.000000, 201.000000, "LSPD");
	PlayerTextDrawAlignment(playerid,Textdraw2, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw2, 255);
	PlayerTextDrawFont(playerid,Textdraw2, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw2, 0.499998, 2.499998);
	PlayerTextDrawColor(playerid,Textdraw2, 606844415);
	PlayerTextDrawSetOutline(playerid,Textdraw2, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw2, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw2, 1);
	PlayerTextDrawUseBox(playerid,Textdraw2, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw2, 255);
	PlayerTextDrawTextSize(playerid,Textdraw2, 20.000000, 159.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw2, 1);

	Textdraw3 = CreatePlayerTextDraw(playerid,544.000000, 232.000000, "PARAMEDICS");
	PlayerTextDrawAlignment(playerid,Textdraw3, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw3, 255);
	PlayerTextDrawFont(playerid,Textdraw3, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw3, 0.499998, 2.499998);
	PlayerTextDrawColor(playerid,Textdraw3, -481736193);
	PlayerTextDrawSetOutline(playerid,Textdraw3, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw3, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw3, 1);
	PlayerTextDrawUseBox(playerid,Textdraw3, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw3, 255);
	PlayerTextDrawTextSize(playerid,Textdraw3, 20.000000, 159.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw3, 1);

	Textdraw4 = CreatePlayerTextDraw(playerid,544.000000, 263.000000, "HITMAN");
	PlayerTextDrawAlignment(playerid,Textdraw4, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw4, 255);
	PlayerTextDrawFont(playerid,Textdraw4, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw4, 0.499998, 2.499998);
	PlayerTextDrawColor(playerid,Textdraw4, 2084980479);
	PlayerTextDrawSetOutline(playerid,Textdraw4, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw4, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw4, 1);
	PlayerTextDrawUseBox(playerid,Textdraw4, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw4, 255);
	PlayerTextDrawTextSize(playerid,Textdraw4, 20.000000, 159.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw4, 1);

	Textdraw5 = CreatePlayerTextDraw(playerid,544.000000, 331.000000, "SAVE");
	PlayerTextDrawAlignment(playerid,Textdraw5, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw5, 255);
	PlayerTextDrawFont(playerid,Textdraw5, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw5, 0.499998, 2.499998);
	PlayerTextDrawColor(playerid,Textdraw5, 16711935);
	PlayerTextDrawSetOutline(playerid,Textdraw5, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw5, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw5, 1);
	PlayerTextDrawUseBox(playerid,Textdraw5, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw5, 255);
	PlayerTextDrawTextSize(playerid,Textdraw5, 20.000000, 159.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw5, 1);

	Textdraw6 = CreatePlayerTextDraw(playerid,385.000000, 320.000000, ">");
	PlayerTextDrawAlignment(playerid,Textdraw6, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw6, 255);
	PlayerTextDrawFont(playerid,Textdraw6, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw6, 1.100000, 5.099998);
	PlayerTextDrawColor(playerid,Textdraw6, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw6, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw6, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw6, 1);
	//PlayerTextDrawUseBox(playerid,Textdraw6, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw6, 255);
	PlayerTextDrawTextSize(playerid,Textdraw6, 41.000000, 23.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw6, 1);

	Textdraw7 = CreatePlayerTextDraw(playerid,256.000000, 320.000000, "<");
	PlayerTextDrawAlignment(playerid,Textdraw7, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw7, 255);
	PlayerTextDrawFont(playerid,Textdraw7, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw7, 1.100000, 5.099998);
	PlayerTextDrawColor(playerid,Textdraw7, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw7, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw7, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw7, 1);
	//PlayerTextDrawUseBox(playerid,Textdraw7, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw7, 255);
	PlayerTextDrawTextSize(playerid,Textdraw7, 39.000000, 20.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw7, 1);


	playerData[playerid][skinSelector_civil] = Textdraw0;
	playerData[playerid][skinSelector_taxi] = Textdraw1;
	playerData[playerid][skinSelector_lspd] = Textdraw2;
	playerData[playerid][skinSelector_paramedics] = Textdraw3;
	playerData[playerid][skinSelector_hitman] = Textdraw4;
	playerData[playerid][skinSelector_save] = Textdraw5;
	playerData[playerid][skinSelector_next] = Textdraw6;
	playerData[playerid][skinSelector_prev] = Textdraw7;
}
stock skinSelector_destroy(playerid)
{
	PlayerTextDrawDestroy(playerid, playerData[playerid][skinSelector_civil]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][skinSelector_taxi]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][skinSelector_lspd]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][skinSelector_paramedics]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][skinSelector_hitman]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][skinSelector_save]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][skinSelector_next]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][skinSelector_prev]);
}
stock skinSelector_show(playerid)
{
	PlayerTextDrawShow(playerid, playerData[playerid][skinSelector_civil]);
	PlayerTextDrawShow(playerid, playerData[playerid][skinSelector_taxi]);
	PlayerTextDrawShow(playerid, playerData[playerid][skinSelector_lspd]);
	PlayerTextDrawShow(playerid, playerData[playerid][skinSelector_paramedics]);
	PlayerTextDrawShow(playerid, playerData[playerid][skinSelector_hitman]);
	PlayerTextDrawShow(playerid, playerData[playerid][skinSelector_save]);
	PlayerTextDrawShow(playerid, playerData[playerid][skinSelector_next]);
	PlayerTextDrawShow(playerid, playerData[playerid][skinSelector_prev]);

	if (playerData[playerid][skinSelector] == 0) {
		playerData[playerid][skinSelector] = 1;
		playerData[playerid][skinSelector_index] = 0;
		SetPlayerSkin(playerid, SERVER_SKINS[0]);
		SelectTextDraw(playerid, 0xab5e5eFF);
	}
}

stock skinSelector_hide(playerid)
{
	playerData[playerid][skinSelector] = 0;
	CancelSelectTextDraw(playerid);

	PlayerTextDrawHide(playerid, playerData[playerid][skinSelector_civil]);
	PlayerTextDrawHide(playerid, playerData[playerid][skinSelector_taxi]);
	PlayerTextDrawHide(playerid, playerData[playerid][skinSelector_lspd]);
	PlayerTextDrawHide(playerid, playerData[playerid][skinSelector_paramedics]);
	PlayerTextDrawHide(playerid, playerData[playerid][skinSelector_hitman]);
	PlayerTextDrawHide(playerid, playerData[playerid][skinSelector_save]);
	PlayerTextDrawHide(playerid, playerData[playerid][skinSelector_next]);
	PlayerTextDrawHide(playerid, playerData[playerid][skinSelector_prev]);
}

stock buyCar_init(playerid)
{
	new PlayerText:Textdraw0;
	new PlayerText:Textdraw1;
	new PlayerText:Textdraw2;
	new PlayerText:Textdraw3;
	new PlayerText:Textdraw4;
	new PlayerText:Textdraw5;

	Textdraw0 = CreatePlayerTextDraw(playerid,444.000000, 210.000000, "Model: Sultan");
	PlayerTextDrawBackgroundColor(playerid,Textdraw0, 255);
	PlayerTextDrawFont(playerid,Textdraw0, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw0, 0.410000, 1.799999);
	PlayerTextDrawColor(playerid,Textdraw0, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw0, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw0, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw0, 1);
	PlayerTextDrawSetSelectable(playerid,Textdraw0, 0);

	Textdraw1 = CreatePlayerTextDraw(playerid,445.000000, 229.000000, "Price: $100.000");
	PlayerTextDrawBackgroundColor(playerid,Textdraw1, 255);
	PlayerTextDrawFont(playerid,Textdraw1, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw1, 0.410000, 1.799999);
	PlayerTextDrawColor(playerid,Textdraw1, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw1, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw1, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw1, 1);
	PlayerTextDrawSetSelectable(playerid,Textdraw1, 0);

	Textdraw2 = CreatePlayerTextDraw(playerid,445.000000, 277.000000, "TEST DRIVE");
	PlayerTextDrawBackgroundColor(playerid,Textdraw2, 255);
	PlayerTextDrawFont(playerid,Textdraw2, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw2, 0.409999, 1.500000);
	PlayerTextDrawColor(playerid,Textdraw2, 0x949494FF);
	PlayerTextDrawSetOutline(playerid,Textdraw2, 1);
	PlayerTextDrawSetProportional(playerid,Textdraw2, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw2, 1);
	PlayerTextDrawUseBox(playerid,Textdraw2, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw2, 0);
	PlayerTextDrawTextSize(playerid,Textdraw2, 522.000000, 14.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw2, 1);

	Textdraw3 = CreatePlayerTextDraw(playerid,530.000000, 277.000000, "BUY CAR");
	PlayerTextDrawBackgroundColor(playerid,Textdraw3, 255);
	PlayerTextDrawFont(playerid,Textdraw3, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw3, 0.409999, 1.500000);
	PlayerTextDrawColor(playerid,Textdraw3, 0x595959FF);
	PlayerTextDrawSetOutline(playerid,Textdraw3, 1);
	PlayerTextDrawSetProportional(playerid,Textdraw3, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw3, 1);
	PlayerTextDrawUseBox(playerid,Textdraw3, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw3, 0);
	PlayerTextDrawTextSize(playerid,Textdraw3, 589.000000, 14.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw3, 1);

	Textdraw4 = CreatePlayerTextDraw(playerid,258.000000, 347.000000, "<");
	PlayerTextDrawBackgroundColor(playerid,Textdraw4, 255);
	PlayerTextDrawFont(playerid,Textdraw4, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw4, 0.770000, 3.499999);
	PlayerTextDrawColor(playerid,Textdraw4, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw4, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw4, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw4, 1);
	PlayerTextDrawUseBox(playerid,Textdraw4, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw4, 0);
	PlayerTextDrawTextSize(playerid,Textdraw4, 277.000000, 24.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw4, 1);

	Textdraw5 = CreatePlayerTextDraw(playerid,358.000000, 347.000000, ">");
	PlayerTextDrawBackgroundColor(playerid,Textdraw5, 255);
	PlayerTextDrawFont(playerid,Textdraw5, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw5, 0.770000, 3.499999);
	PlayerTextDrawColor(playerid,Textdraw5, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw5, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw5, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw5, 1);
	PlayerTextDrawUseBox(playerid,Textdraw5, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw5, 0);
	PlayerTextDrawTextSize(playerid,Textdraw5, 376.000000, 25.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw5, 1);

	playerData[playerid][buycar_model] = Textdraw0;
	playerData[playerid][buycar_price] = Textdraw1;
	playerData[playerid][buycar_textdrive] = Textdraw2;
	playerData[playerid][buycar_buycar] = Textdraw3;
	playerData[playerid][buycar_prev] = Textdraw4;
	playerData[playerid][buycar_next] = Textdraw5;
}

stock buyCar_destroy(playerid)
{
	PlayerTextDrawDestroy(playerid, playerData[playerid][buycar_model]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][buycar_price]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][buycar_textdrive]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][buycar_buycar]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][buycar_prev]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][buycar_next]);

	if (playerData[playerid][buycar_car] != 0) {
		DestroyVehicle(playerData[playerid][buycar_car]);
		playerData[playerid][buycar_car] = 0;
	}
}

stock buyCar_show(playerid)
{
	if (playerData[playerid][buycar_state] == 0) {
		playerData[playerid][buycar_state] = 1;
		playerData[playerid][buycar_index] = 0;

		SetPlayerVirtualWorld(playerid, 1 + playerid);

	}

	SetPlayerHealth(playerid, 100);

	SelectTextDraw(playerid, 0xab5e5eFF);

	if (playerData[playerid][buycar_car] != 0) {
		DestroyVehicle(playerData[playerid][buycar_car]);
	}

	playerData[playerid][buycar_car] = CreateVehicle(BUYCAR_CARS[playerData[playerid][buycar_index]][0], -1948.2795,259.8907,40.6722,345.9435, -1, -1, 60);

	SetVehicleVirtualWorld(playerData[playerid][buycar_car], 1 + playerid);

	PutPlayerInVehicle(playerid, playerData[playerid][buycar_car], 0);

	SetPlayerCameraPos(playerid,-1955.0055,266.9672,41.8800);
	SetPlayerCameraLookAt(playerid, -1948.2795,259.8907,40.6722);


	new temp[64];
	format(temp, sizeof(temp), "Model: %s", VehicleNames[BUYCAR_CARS[playerData[playerid][buycar_index]][0] -400]);
	PlayerTextDrawSetString(playerid, playerData[playerid][buycar_model], temp);
	
	if (BUYCAR_CARS[playerData[playerid][buycar_index]][1] > playerData[playerid][account_money]) {
		format(temp, sizeof(temp), "Price: ~r~$%s", formatMoney(BUYCAR_CARS[playerData[playerid][buycar_index]][1]));
		PlayerTextDrawHide(playerid, playerData[playerid][buycar_buycar]);
	} else {
		format(temp, sizeof(temp), "Price: $%s", formatMoney(BUYCAR_CARS[playerData[playerid][buycar_index]][1]));
		PlayerTextDrawShow(playerid, playerData[playerid][buycar_buycar]);
	}
	PlayerTextDrawSetString(playerid, playerData[playerid][buycar_price], temp);

	PlayerTextDrawShow(playerid, playerData[playerid][buycar_model]);
	PlayerTextDrawShow(playerid, playerData[playerid][buycar_price]);
	PlayerTextDrawShow(playerid, playerData[playerid][buycar_textdrive]);
	PlayerTextDrawShow(playerid, playerData[playerid][buycar_prev]);
	PlayerTextDrawShow(playerid, playerData[playerid][buycar_next]);
}

stock buyCar_hide(playerid)
{
	if (playerData[playerid][buycar_state] == 1) {
		playerData[playerid][buycar_state] = 0;

		DestroyVehicle(playerData[playerid][buycar_car]);

		playerData[playerid][buycar_car] = 0;

		SetPlayerVirtualWorld(playerid, 0);

		SetCameraBehindPlayer(playerid);
	}

	CancelSelectTextDraw(playerid);

	PlayerTextDrawHide(playerid, playerData[playerid][buycar_model]);
	PlayerTextDrawHide(playerid, playerData[playerid][buycar_price]);
	PlayerTextDrawHide(playerid, playerData[playerid][buycar_textdrive]);
	PlayerTextDrawHide(playerid, playerData[playerid][buycar_buycar]);
	PlayerTextDrawHide(playerid, playerData[playerid][buycar_prev]);
	PlayerTextDrawHide(playerid, playerData[playerid][buycar_next]);

}

stock door_enter(playerid)
{
	if (playerData[playerid][am_sleeping] == 1) return 0;

	if (IsPlayerInRangeOfPoint(playerid, 3.0, 1564.9336,-1666.5422,28.3956)) {
		if (playerData[playerid][account_faction] != FACTION_LSPD) {
			SendClientMessage(playerid, COLOR_SERVER, "Error: Only members of Police Department have the keys for this door.");
		} else {
			SetPlayerPos(playerid, 1563.7126,-1647.6243,-14.3242);
			playerData[playerid][special_interior] = INTERIOR_PRISON;
		}
		return 1;
	}

	for (new i=0; i < MAX_HOUSES; i++){
		if(IsPlayerInRangeOfPoint(playerid, 3.0, houseData[i][house_x], houseData[i][house_y], houseData[i][house_z])){
			new temp[128];
			if (houseData[i][house_locked] == 1 && (houseData[i][house_owner_id] != playerData[playerid][account_id] && playerData[playerid][account_faction] != FACTION_LSPD)) return SendClientMessage(playerid, COLOR_SERVER, "The door of this house is locked.");
			if (houseData[i][house_owner_id] == playerData[playerid][account_id]) {
				format(temp, 128, "You have entered your house.");
				printf("ENTER: Player %s entered his own house.", playerData[playerid][account_name]);
			} else {
				format(temp, 128, "You have entered %s's house.", houseData[i][house_owner_name]);
				printf("ENTER: Player %s entered at %s's house.", playerData[playerid][account_name], houseData[i][house_owner_name]);
			}
			SendClientMessage(playerid, COLOR_INFO, temp);
			new temp_interior = houseData[i][house_interior];
			SetPlayerInterior(playerid, floatround(BUYHOUSE_INTERIORS[temp_interior][3]));
			SetPlayerPos(playerid, BUYHOUSE_INTERIORS[temp_interior][0], BUYHOUSE_INTERIORS[temp_interior][1], BUYHOUSE_INTERIORS[temp_interior][2]);
			SetPlayerVirtualWorld(playerid, 1000+houseData[i][house_id]);

			playerData[playerid][enteredHouse] = i;

			updateSpectators(playerid);

			return 1;
		}
	}

	new temp_biz = playerData[playerid][enteredBiz];
	if (bizData[temp_biz][biz_type] == BIZ_TYPE_GUNSHOP1) {
		if (IsPlayerInRangeOfPoint(playerid, 2.0, 305.7246,-141.9838,1004.0547)) {
			SetPlayerPos(playerid, 303.5598,-141.6759,1004.0625); // small room practice
		} else if (IsPlayerInRangeOfPoint(playerid, 2.0, 300.0557,-141.8702,1004.0625)) {
			SetPlayerPos(playerid, 298.9916,-141.8995,1004.0547); // main practice room
		}
	} else if (temp_biz == 0) {
		for (new i; i < MAX_BIZ; i++) {
			if (bizData[i][biz_type] != 0 && IsPlayerInRangeOfPoint(playerid, 3.0, bizData[i][biz_x], bizData[i][biz_y], bizData[i][biz_z])) {

				if (bizData[i][biz_type] == BIZ_TYPE_GASSTATION) continue;

				if (playerData[playerid][account_money] >= bizData[i][biz_entrance]) {
					if (bizData[i][biz_type] == BIZ_TYPE_CLOTHES) {

						if (playerData[playerid][account_jailed] > 0) {
							if (playerData[playerid][escape_state] == 2) {
								playerData[playerid][in_jail] = 0;
								playerData[playerid][account_jailed] = 0;
								playerData[playerid][account_escaped] = 0;
								playerData[playerid][escape_state] = 0;
								playerData[playerid][account_wanted] = 0;
								SetPlayerSkinFix(playerid, playerData[playerid][account_skin]);
								GameTextForPlayer(playerid, "~g~FREE!", 2000, 4);
								DisablePlayerCheckpoint(playerid);
								new temp[128];
								format(temp, sizeof(temp), "Player %s (%d) is not wanted anymore.", playerData[playerid][account_name], playerid);
								SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp);
								playerData[playerid][account_succ_escapes]++;
								SendClientMessage(playerid, COLOR_INFO, "* You are not wanted anymore.");
							}
							
						} else {

							GetPlayerHealth(playerid, playerData[playerid][hp_entered_clothesShop]);
							GetPlayerArmour(playerid, playerData[playerid][armour_entered_clothesShop]);

							SetPlayerInterior(playerid,11);
							SetPlayerPos(playerid,508.7362,-87.4335,998.9609);
							SetPlayerFacingAngle(playerid,0.0);
							SetPlayerCameraPos(playerid,508.7362,-83.4335,998.9609);
							SetPlayerCameraLookAt(playerid,508.7362,-87.4335,998.9609);

							SetPlayerVirtualWorld(playerid, 1000 + bizData[i][biz_id] + playerid);

							skinSelector_show(playerid);

							giveMoney(playerid, -bizData[i][biz_entrance]);

							new temp[256];
							format(temp, sizeof(temp), "UPDATE `business` SET `biz_profit` = `biz_profit` + `biz_entrance` WHERE `biz_id` = %d;", bizData[i][biz_id]);
							mysql_query(Database, temp, false);

							printf("%s entered %s's biz %d", playerData[playerid][account_name], bizData[i][biz_owner_name], bizData[i][biz_id]);

							playerData[playerid][enteredBiz] = i;

						}

					} else if (bizData[i][biz_type] == BIZ_TYPE_PAINTBALL) {

						if (playerData[playerid][account_wanted] > 0) {
							SendClientMessage(playerid, COLOR_SERVER, "Error: You are wanted.");
						} else {
							if (PAINTBALL_STATE == 0) {
								PAINTBALL_STATE = 1;
								PaintballStartedOn = gettime();
								new temp[256];
								format(temp, 128, "%s (%d) has started a new Paintball match. Join him within the next 20 seconds.", playerData[playerid][account_name], playerid);
								SendClientMessageToAll(COLOR_PUBLIC, temp);
								printf("%s", temp);
								playerData[playerid][paintball_joined] = 1;

								SetPlayerPos(playerid, 1788.0723,3152.8696,133.6369);
								SetPlayerFacingAngle(playerid, 260.3904);
								TogglePlayerControllable(playerid, 0);
								SetPlayerVirtualWorld(playerid, 5);

								giveMoney(playerid, -bizData[i][biz_entrance]);

								format(temp, sizeof(temp), "UPDATE `business` SET `biz_profit` = `biz_profit` + `biz_entrance` WHERE `biz_id` = %d;", bizData[i][biz_id]);
								mysql_query(Database, temp, false);

								printf("%s entered %s's biz %d", playerData[playerid][account_name], bizData[i][biz_owner_name], bizData[i][biz_id]);

								playerData[playerid][enteredBiz] = i;


							} else if (PAINTBALL_STATE == 1) {

								playerData[playerid][paintball_joined] = 1;
								SetPlayerPos(playerid, 1788.0723,3152.8696,133.6369);
								SetPlayerFacingAngle(playerid, 260.3904);
								TogglePlayerControllable(playerid, 0);
								SetPlayerVirtualWorld(playerid, 5);

								new temp[256];
								format(temp, 128, "Player %s (%d) joined the match.", playerData[playerid][account_name], playerid);
								SendClientMessageToPaintballers(COLOR_PAINTBALL, temp);

								giveMoney(playerid, -bizData[i][biz_entrance]);

								format(temp, sizeof(temp), "UPDATE `business` SET `biz_profit` = `biz_profit` + `biz_entrance` WHERE `biz_id` = %d;", bizData[i][biz_id]);
								mysql_query(Database, temp, false);

								printf("%s entered %s's biz %d", playerData[playerid][account_name], bizData[i][biz_owner_name], bizData[i][biz_id]);

								playerData[playerid][enteredBiz] = i;

							} else {
								SendClientMessage(playerid, COLOR_SERVER, "Error: You can not join right now. Wait for the next match.");
							}
						}

					} else if ((bizData[i][biz_type] == BIZ_TYPE_BANKLS || bizData[i][biz_type] == BIZ_TYPE_BANKLS) && playerData[playerid][robbing_state] == 2) {
						SendClientMessage(playerid, COLOR_BADINFO, "You cannot get in. You need to go at the safe checkpoint to deliver the money.");
					} else {

						if (bizData[i][biz_type] == BIZ_TYPE_BANKLS) {
							playerData[playerid][special_interior] = INTERIOR_BANK_LS;
						}
						if (bizData[i][biz_type] == BIZ_TYPE_BANKSF) {
							playerData[playerid][special_interior] = INTERIOR_BANK_SF;
						}


						if (bizData[i][biz_type] == BIZ_TYPE_FASTFOOD1) {
							SendClientMessage(playerid, COLOR_INFO, "You can use /eat to get healed up.");
						}

						if (bizData[i][biz_type] == BIZ_TYPE_247_1) {
							SendClientMessage(playerid, COLOR_INFO, "Available commands: /buyphone, /buycigarette (for /smoke).");
						}

						if (bizData[i][biz_type] == BIZ_TYPE_CLUB) {
							SendClientMessage(playerid, COLOR_INFO, "Available commands: /drink, /dance.");
						}

						if (bizData[i][biz_type] == BIZ_TYPE_BANKLS || bizData[i][biz_type] == BIZ_TYPE_BANKSF) {
							SendClientMessage(playerid, COLOR_INFO, "Available commands: /bankhelp.");
						}

						new temp_type = bizData[i][biz_type];
						giveMoney(playerid, -bizData[i][biz_entrance]);
						SetPlayerInterior(playerid, BIZ_INTERIORS[temp_type][bi_interior]);
						SetPlayerPos(playerid, BIZ_INTERIORS[temp_type][bi_x], BIZ_INTERIORS[temp_type][bi_y], BIZ_INTERIORS[temp_type][bi_z]);
						SetPlayerFacingAngle(playerid, BIZ_INTERIORS[temp_type][bi_a]);
						SetCameraBehindPlayer(playerid);
						SetPlayerVirtualWorld(playerid, 1000 + bizData[i][biz_id]);

						new temp[256];
						format(temp, sizeof(temp), "UPDATE `business` SET `biz_profit` = `biz_profit` + `biz_entrance` WHERE `biz_id` = %d;", bizData[i][biz_id]);
						mysql_query(Database, temp, false);

						printf("%s entered %s's biz %d", playerData[playerid][account_name], bizData[i][biz_owner_name], bizData[i][biz_id]);

						playerData[playerid][enteredBiz] = i;

					}

					updateSpectators(playerid);

					return 1;
				} else {
					SendClientMessage(playerid, COLOR_BADINFO, "You do not have enough money to get in here.");
				}
			}
		}

	}

	return 0;
}

stock door_exit(playerid)
{
	if (playerData[playerid][am_sleeping] == 1) return 0;

	if (playerData[playerid][special_interior] == INTERIOR_PRISON) {
		SetPlayerPos(playerid, 1564.9336,-1666.5422,28.3956);
		playerData[playerid][special_interior] = 0;
		return 1;
	}

	if (playerData[playerid][enteredHouse] != 0) {
		new temp_id = playerData[playerid][enteredHouse];
		new temp_house_interior = houseData[temp_id][house_interior];
		if (IsPlayerInRangeOfPoint(playerid, 4.0, BUYHOUSE_INTERIORS[temp_house_interior][0], BUYHOUSE_INTERIORS[temp_house_interior][1], BUYHOUSE_INTERIORS[temp_house_interior][2])) {
			new temp[128];
			if (houseData[temp_id][house_owner_id] == playerData[playerid][account_id]) {
				format(temp, 128, "You have exited your house.");
				printf("ENTER: Player %s exited his own house.", playerData[playerid][account_name]);
			} else {
				format(temp, 128, "You have exited %s's house.", houseData[temp_id][house_owner_name]);
				printf("ENTER: Player %s exited at %s's house.", playerData[playerid][account_name], houseData[temp_id][house_owner_name]);
			}
			SetPlayerInterior(playerid, 0);
			SetPlayerPos(playerid, houseData[temp_id][house_x], houseData[temp_id][house_y], houseData[temp_id][house_z]);
			SetPlayerVirtualWorld(playerid, 0);
			SendClientMessage(playerid, COLOR_INFO, temp);
			playerData[playerid][enteredHouse] = 0;
		} else {
			SendClientMessage(playerid, COLOR_BADINFO, "You are not near the door. You can not get out.");
		}

		updateSpectators(playerid);

		return 1;
	}

	new temp_biz = playerData[playerid][enteredBiz];
	if (temp_biz != 0) {
		if (bizData[temp_biz][biz_type] == BIZ_TYPE_CLOTHES) {
			SendClientMessage(playerid, COLOR_SERVER, "You need to select a skin to get out.");
		} else if (bizData[temp_biz][biz_type] == BIZ_TYPE_GUNSHOP1) {
			if (IsPlayerInRangeOfPoint(playerid, 0.5, 298.9916,-141.8995,1004.0547)) {
				SetPlayerPos(playerid, 300.2590,-141.8009,1004.0625);
			} else if (IsPlayerInRangeOfPoint(playerid, 0.5, 304.3021,-141.9487,1004.0625)) {
				SetPlayerPos(playerid, 305.9179,-141.8815,1004.0547);
			} else if (IsPlayerInRangeOfPoint(playerid, 3.0, BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_x], BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_y], BIZ_INTERIORS[BIZ_TYPE_GUNSHOP1][bi_z])) {
				playerData[playerid][enteredBiz] = 0;
				SetPlayerInterior(playerid, 0);
				SetPlayerPos(playerid, bizData[temp_biz][biz_x], bizData[temp_biz][biz_y], bizData[temp_biz][biz_z]);
				SetPlayerVirtualWorld(playerid, 0);
			}
		} else {
			new temp_biz_type = bizData[temp_biz][biz_type];

			if (IsPlayerInRangeOfPoint(playerid, 4.0, BIZ_INTERIORS[temp_biz_type][bi_x], BIZ_INTERIORS[temp_biz_type][bi_y], BIZ_INTERIORS[temp_biz_type][bi_z])) {
				playerData[playerid][enteredBiz] = 0;
				SetPlayerInterior(playerid, 0);
				SetPlayerPos(playerid, bizData[temp_biz][biz_x], bizData[temp_biz][biz_y], bizData[temp_biz][biz_z]);
				SetPlayerVirtualWorld(playerid, 0);
				playerData[playerid][special_interior] = 0;
			} else {
				SendClientMessage(playerid, COLOR_BADINFO, "You are not near the door. You can not get out.");
			}
		}

		updateSpectators(playerid);

		return 1;
	}
	return 0;
}


stock removeTuning(vehicleid)
{
	new componentid;

	for (new i; i < 14; i++)
	{
		componentid = GetVehicleComponentInSlot(vehicleid, i);
		if (componentid != 0) {
			RemoveVehicleComponent(vehicleid, componentid);
			ChangeVehiclePaintjob(vehicleid, 3);
		}
	}
}

stock IsALetter(string)
{
	if(string == 'q') return 1;
	else if(string == 'Q') return 1;
	else if(string == 'w') return 1;
	else if(string == 'W') return 1;
	else if(string == 'e') return 1;
	else if(string == 'E') return 1;
	else if(string == 'R') return 1;
	else if(string == 'r') return 1;
	else if(string == 't') return 1;
	else if(string == 'T') return 1;
	else if(string == 'y') return 1;
	else if(string == 'Y') return 1;
	else if(string == 'u') return 1;
	else if(string == 'U') return 1;
	else if(string == 'i') return 1;
	else if(string == 'I') return 1;
	else if(string == 'o') return 1;
	else if(string == 'O') return 1;
	else if(string == 'P') return 1;
	else if(string == 'p') return 1;
	else if(string == 'A') return 1;
	else if(string == 'a') return 1;
	else if(string == 'S') return 1;
	else if(string == 's') return 1;
	else if(string == 'D') return 1;
	else if(string == 'd') return 1;
	else if(string == 'F') return 1;
	else if(string == 'f') return 1;
	else if(string == 'G') return 1;
	else if(string == 'g') return 1;
	else if(string == 'H') return 1;
	else if(string == 'h') return 1;
	else if(string == 'J') return 1;
	else if(string == 'j') return 1;
	else if(string == 'k') return 1;
	else if(string == 'K') return 1;
	else if(string == 'l') return 1;
	else if(string == 'L') return 1;
	else if(string == 'z') return 1;
	else if(string == 'Z') return 1;
	else if(string == 'X') return 1;
	else if(string == 'x') return 1;
	else if(string == 'C') return 1;
	else if(string == 'c') return 1;
	else if(string == 'V') return 1;
	else if(string == 'v') return 1;
	else if(string == 'b') return 1;
	else if(string == 'B') return 1;
	else if(string == 'N') return 1;
	else if(string == 'n') return 1;
	else if(string == 'M') return 1;
	else if(string == 'm') return 1;
	else if(string == '0') return 1;
	else if(string == '1') return 1;
	else if(string == '2') return 1;
	else if(string == '3') return 1;
	else if(string == '4') return 1;
	else if(string == '5') return 1;
	else if(string == '6') return 1;
	else if(string == '7') return 1;
	else if(string == '8') return 1;
	else if(string == '9') return 1;
	else return 0;
}

stock isGreeklish(word[])
{
	for(new i; i<strlen(word); i++){
		if(!IsALetter(word[i]) && word[i] != '#' && word[i] != '-' && word[i] != '+' && word[i] != '&' && word[i] != '`' && word[i] != '~' && word[i] != '_' && word[i] != '!' && word[i] != '"' && word[i] != '*' && word[i] != ',' && word[i] != '.'  && word[i] != ':' && word[i] != '?' && word[i] != '$' && word[i] != '%' && word[i] != '(' && word[i] != ')' && word[i] != '/' && word[i] != '{' && word[i] != '}' && word[i] != '[' && word[i] != ']' && word[i] != '<' && word[i] != '>' && word[i] != ' ') return false;
	}
	return true;
}

stock isOnlyLetter(word[])
{
	for(new i; i<strlen(word); i++){
		if(!IsALetter(word[i]) && word[i] != ' ') return false;
	}
	return true;
}

stock generatePhoneNumber(playerid)
{
	new temp[128];
	new timestamp = gettime();
	new playeruid = playerData[playerid][account_id];
	
	new unumber = timestamp % 100000;

	format(temp, sizeof(temp), "Your new phone number is: %d-%d", unumber, playeruid);
	SendClientMessage(playerid, 0xffe96eFF, temp);

	playerData[playerid][account_phoneNumber] = unumber;
}

stock carRadio(playerid, radio_station[])
{
	new temp_to[128], temp[512];
	format(temp_to, sizeof(temp_to), "%d%s%s", gettime(), radio_station, radioHashSalt);
	SHA256_PassHash(temp_to, "", temp, sizeof(temp));
	format(temp, sizeof(temp), "https://www.greeksamp.info/radio.php?time=%d&station=%s&jw=%s", gettime(), radio_station, temp);

	PlayAudioStreamForPlayer(playerid, temp);
	GameTextForPlayer(playerid, "~g~Loading Radio...", 2000, 4);

	format(playerData[playerid][current_radio], 32, "%s", radio_station);

}

stock kickAdmBot(playerid, reason[])
{
	new temp[128];
	format(temp, sizeof(temp), "AdmBot: %s (%d) has been kicked from the server. Reason: %s",playerData[playerid][account_name], playerid, reason);
	SendClientMessageToAll(COLOR_PUNISH, temp);

	SetTimerEx("DelayedKick", 1000, 0, "i", playerid);

	printf("%s", temp);


	new tempE[512];
	mysql_format(Database, tempE, sizeof(tempE),"INSERT INTO `sanctions` (`sanction_player`, `sanction_date`, `sanction_admin_id`, `sanction_type`, `sanction_variable`, `sanction_reason`) VALUES ('%d', '%d', '%d', 'kick', '0', '%e');", playerData[playerid][account_id], gettime(), -1, reason);
	mysql_query(Database, tempE, false);
}

stock reportCrime(playerid, add_wanted, reason[])
{
	if (playerData[playerid][account_wanted] < 6) {
		playerData[playerid][account_wanted]+= add_wanted;
		if (playerData[playerid][account_wanted] >= 6) {
			playerData[playerid][account_wanted] = 6;
		}
	}

	new temp[128];

	format(temp, sizeof(temp), "Police Report: Player %s (%d). Reported for: %s. Current Wanted Level: %d", playerData[playerid][account_name], playerid, reason, playerData[playerid][account_wanted]);
	SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp);
	format(temp, sizeof(temp), "You have been reported to police department. Reported for: %s. Wanted Level: %d", reason, playerData[playerid][account_wanted]);
	SendClientMessage(playerid, COLOR_BADINFO, temp);
}

stock killWanted(playerid, killerid, arrest = 0)
{
	new temp_jail;
	new temp[564];
	new temp_pd_reward;
	new temp_wanted = playerData[playerid][account_wanted];
	if (temp_wanted == 1) {
		temp_jail = 60;
	} else if (temp_wanted == 2) {
		temp_jail = 120;
	} else if (temp_wanted == 3) {
		temp_jail = 300;
	} else if (temp_wanted == 4) {
		temp_jail = 450;
	} else if (temp_wanted == 5) {
		temp_jail = 500;
	} else if (temp_wanted == 6) {
		temp_jail = 550;
	}

	temp_pd_reward = 1000 - (playerData[playerid][account_wanted] * 158) + (2 * playerData[playerid][account_score]);

	if (arrest == 1) {
		temp_jail = temp_jail * 70 / 100;
		temp_pd_reward = temp_pd_reward + 750;

		format(temp, sizeof(temp), "LSPD Member %s (%d) arrested you and you have been jailed for %d seconds.", playerData[killerid][account_name], killerid, temp_jail);
		SendClientMessage(playerid, COLOR_BADINFO, temp);
		format(temp, sizeof(temp), "LSPD Member %s (%d) arrested the wanted player %s (%d) and he jailed him for %d seconds.", playerData[killerid][account_name], killerid, playerData[playerid][account_name], playerid, temp_jail);
		SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp);
	} else {


		format(temp, sizeof(temp), "LSPD Member %s (%d) killed you while you were wanted. You have been jailed for %d seconds.", playerData[killerid][account_name], killerid, temp_jail);
		SendClientMessage(playerid, COLOR_BADINFO, temp);
		format(temp, sizeof(temp), "LSPD Member %s (%d) killed the wanted player %s (%d), who got jailed for %d seconds.", playerData[killerid][account_name], killerid, playerData[playerid][account_name], playerid, temp_jail);
		SendClientMessageToFaction(FACTION_LSPD, COLOR_FACTION, temp);

	}

	if (playerData[playerid][account_escaped] == 0) {
		if (temp_jail > 120) {
			SendClientMessage(playerid, COLOR_INFO, "You have one chance to escape jail! Use /escape to escape.");
		} else {
			SendClientMessage(playerid, COLOR_BADINFO, "Your jail time is not enough so you can escape. You need to wait your full jail time.");
		}
	} else {
		// We show this message onplayerdeath now.
		// SendClientMessage(playerid, COLOR_BADINFO, "You cannot attempt to escape again. You need to wait your full jail time now.")
	}

	playerData[playerid][account_jailed] = temp_jail;

	playerData[playerid][account_wanted] = 0;

	playerData[playerid][escape_state] = 0;

	giveMoney(killerid, temp_pd_reward);

	if (arrest == 1) {
		SetPlayerPos(playerid, 1568.4164,-1691.9011,5.8906);
		SpawnPlayer(playerid);

		format(temp, sizeof(temp),"INSERT INTO `activity_reports` (`r_player`, `r_faction`, `r_type`, `r_serviced_player`, `r_date`, `r_amount`) VALUES ('%d', '%d', 'arrest wanted', '%d', '%d', '%d')", playerData[killerid][account_id], FACTION_LSPD, playerData[playerid][account_id], gettime(), temp_pd_reward);
		mysql_query(Database, temp, false);
	} else {
		format(temp, sizeof(temp),"INSERT INTO `activity_reports` (`r_player`, `r_faction`, `r_type`, `r_serviced_player`, `r_date`, `r_amount`) VALUES ('%d', '%d', 'kill wanted', '%d', '%d', '%d')", playerData[killerid][account_id], FACTION_LSPD, playerData[playerid][account_id], gettime(), temp_pd_reward);
		mysql_query(Database, temp, false);
	}

	printf("JAIL: LSPD Member %s - player %s with wanted %d. Jail Time: %d, Escape: %d, Arrest: %d", playerData[killerid][account_name], playerData[playerid][account_name], temp_wanted, temp_jail, playerData[playerid][account_escaped], arrest);
}

stock updateSpectators(playerid)
{
	for (new j = 0, k = GetPlayerPoolSize(); j <= k; j++) {
		if (playerData[j][logged] == 1) {
			if (playerData[j][spec_mode] == 1 && playerData[j][spec_player] == playerid) {

				if (playerData[playerid][logged] == 0) {
					playerData[j][spec_mode] = 0;
					playerData[j][spec_goback_flag] = 1;
					TogglePlayerSpectating(j, 0);
					SendClientMessage(j, COLOR_SERVER, "The player that you were spectating has left the server.");
				} else {
					if (GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(j) || GetPlayerInterior(playerid) != GetPlayerInterior(j)) {
						SendClientMessage(j, COLOR_INFO, "Spectated player changed his vw and/or interior. Refresh with CLICK.");
					} else {
						SetPlayerInterior(j, GetPlayerInterior(playerid));
						SetPlayerVirtualWorld(j, GetPlayerVirtualWorld(playerid));
						
						
						if (GetPlayerVehicleID(playerid) != 0) {
							TogglePlayerSpectating(j, 1);
							PlayerSpectateVehicle(j, GetPlayerVehicleID(playerid));
						} else {
							TogglePlayerSpectating(j, 1);
							PlayerSpectatePlayer(j, playerid);
						}
					}
				}
			}
		}

	}
}

stock createTXDActiveReports(playerid)
{
	new PlayerText:Textdraw0;
	// In OnPlayerConnect prefferably, we procced to create our textdraws:
	Textdraw0 = CreatePlayerTextDraw(playerid,419.000000, 22.000000, "Active Reports: 0");
	PlayerTextDrawBackgroundColor(playerid,Textdraw0, 255);
	PlayerTextDrawFont(playerid,Textdraw0, 2);
	PlayerTextDrawLetterSize(playerid,Textdraw0, 0.160000, 1.200000);
	PlayerTextDrawColor(playerid,Textdraw0, -855177217);
	PlayerTextDrawSetOutline(playerid,Textdraw0, 1);
	PlayerTextDrawSetProportional(playerid,Textdraw0, 1);
	PlayerTextDrawSetSelectable(playerid,Textdraw0, 0);

	playerData[playerid][active_reportsTXD] = Textdraw0;
}

stock destroyTXDActiveReports(playerid)
{
	PlayerTextDrawDestroy(playerid, playerData[playerid][active_reportsTXD]);
}

forward Float:GetDistanceBetweenPlayers(playerid,targetplayerid);
public Float:GetDistanceBetweenPlayers(playerid,targetplayerid)
{
    if(!IsPlayerConnected(playerid) || !IsPlayerConnected(targetplayerid) || playerData[playerid][logged] == 0 || playerData[targetplayerid][logged] == 0) {
        return -1.00;
    }
	new Float:x1,Float:y1,Float:z1,Float:x2,Float:y2,Float:z2;

    GetPlayerPos(playerid,x1,y1,z1);

	if (playerData[targetplayerid][enteredBiz] != 0) {

		new temp_biz_id = playerData[targetplayerid][enteredBiz];
		x2 = bizData[temp_biz_id][biz_x];
		y2 = bizData[temp_biz_id][biz_y];
		z2 = bizData[temp_biz_id][biz_z];

	} else if (playerData[targetplayerid][enteredHouse] != 0) {

		new temp_house_id = playerData[targetplayerid][enteredHouse];
		x2 = houseData[temp_house_id][house_x];
		y2 = houseData[temp_house_id][house_y];
		z2 = houseData[temp_house_id][house_z];

	} else {
		GetPlayerPos(targetplayerid,x2,y2,z2);
	}
	
    return floatsqroot(floatpower(floatabs(floatsub(x2,x1)),2)+floatpower(floatabs(floatsub(y2,y1)),2)+floatpower(floatabs(floatsub(z2,z1)),2));
}

stock isInArray(value, array[])
{
	for(new i=0; i<sizeof(array);i++) {
		if (array[i] == value) {
			return true;
		}
	}
	return false;
}


stock getClanIndex(playerid) {
	if (playerData[playerid][account_clan] == 0) return NO_CLAN;

	new timestamp = gettime();

	for (new i = 0; i < MAX_CLANS ; i++) {
		if (clanData[i][clan_id] == 0) continue;

		if (clanData[i][clan_id] == playerData[playerid][account_clan]) {
			if (clanData[i][clan_until] < timestamp) {
				return EXPIRED_CLAN;
			} else {
				return i;
			}
		}
	}

	return CLAN_NOT_FOUND;
}

stock clanColors(colorName[])
{
	if (strcmp(colorName, "red a") == 0) return 0xbf3d3d70;
	if (strcmp(colorName, "red b") == 0) return 0xcc161670;
	if (strcmp(colorName, "red c") == 0) return 0xff000070;
	if (strcmp(colorName, "orange a") == 0) return 0xff950070;
	if (strcmp(colorName, "orange b") == 0) return 0xd99a4170;
	if (strcmp(colorName, "orange c") == 0) return 0xb8700b70;
	if (strcmp(colorName, "yellow a") == 0) return 0xded71d70;
	if (strcmp(colorName, "yellow b") == 0) return 0xd9d44e70;
	if (strcmp(colorName, "yellow c") == 0) return 0xede97e70;
	if (strcmp(colorName, "green a") == 0) return 0x76e80c70;
	if (strcmp(colorName, "green b") == 0) return 0x58a31270;
	if (strcmp(colorName, "green c") == 0) return 0x8ed44c70;
	if (strcmp(colorName, "blue a") == 0) return 0x0ac98670;
	if (strcmp(colorName, "blue b") == 0) return 0x048d9170;
	if (strcmp(colorName, "blue c") == 0) return 0x56d8db70;
	if (strcmp(colorName, "blue d") == 0) return 0x5680db70;
	if (strcmp(colorName, "blue e") == 0) return 0x2531d970;
	if (strcmp(colorName, "purple a") == 0) return 0x9425d970;
	if (strcmp(colorName, "pink a") == 0) return 0xff05f770;
	if (strcmp(colorName, "grey") == 0) return 0xe3e3e399;
	return 0xe3e3e399;
}

stock GivePlayerWeaponSafe(playerid, weaponid, ammo)
{
	SAFE_GUNS[playerid][GetWeaponSlot(weaponid)] = weaponid;
	GivePlayerWeapon(playerid, weaponid, ammo);

	printf("GivePlayerWeaponSafe(%s, %s, %d)", playerData[playerid][account_name], GunNames[weaponid],ammo);

	for (new j = 0, k = GetPlayerPoolSize(); j <= k; j++) {
		if (playerData[j][logged] == 1) {
			if (playerData[j][spec_mode] == 1 && playerData[j][spec_player] == playerid) {
				new temp[128];
				format(temp, sizeof(temp), "GivePlayerWeaponSafe(%s, %s, %d)", playerData[playerid][account_name], GunNames[weaponid],ammo);
				SendClientMessage(j, -1, temp);				
			}
		}
	}
}

stock ClearPlayerWeaponSafe(playerid)
{
	for(new i=0; i <= 12; i++) {
		SAFE_GUNS[playerid][i] = 0;
	}
}

stock GetWeaponSlot(weaponid)
{
	new slot;
	switch(weaponid) {
		case 0,1: slot = 0;
		case 2 .. 9: slot = 1;
		case 10 .. 15: slot = 10;
		case 16 .. 18, 39: slot = 8;
		case 22 .. 24: slot =2;
		case 25 .. 27: slot = 3;
		case 28, 29, 32: slot = 4;
		case 30, 31: slot = 5;
		case 33, 34: slot = 6;
		case 35 .. 38: slot = 7;
		case 40: slot = 12;
		case 41 .. 43: slot = 9;
		case 44 .. 46: slot = 11;
	}
	return slot;
}

stock carInstrumentsCreate(playerid)
{
	new PlayerText:Textdraw0;
	new PlayerText:Textdraw1;
	new PlayerText:Textdraw2;

	// In OnPlayerConnect prefferably, we procced to create our textdraws:
	Textdraw0 = CreatePlayerTextDraw(playerid,278.000000, 399.000000, "Speed: 120 km/h");
	PlayerTextDrawBackgroundColor(playerid,Textdraw0, 255);
	PlayerTextDrawFont(playerid,Textdraw0, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw0, 0.330000, 1.299999);
	PlayerTextDrawColor(playerid,Textdraw0, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw0, 1);
	PlayerTextDrawSetProportional(playerid,Textdraw0, 1);
	PlayerTextDrawSetSelectable(playerid,Textdraw0, 0);

	Textdraw1 = CreatePlayerTextDraw(playerid,289.000000, 411.000000, "Fuel: ~r~0%");
	PlayerTextDrawBackgroundColor(playerid,Textdraw1, 255);
	PlayerTextDrawFont(playerid,Textdraw1, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw1, 0.330000, 1.299999);
	PlayerTextDrawColor(playerid,Textdraw1, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw1, 1);
	PlayerTextDrawSetProportional(playerid,Textdraw1, 1);
	PlayerTextDrawSetSelectable(playerid,Textdraw1, 0);

	Textdraw2 = CreatePlayerTextDraw(playerid,255.000000, 423.000000, "Odometer: 100 km");
	PlayerTextDrawBackgroundColor(playerid,Textdraw2, 255);
	PlayerTextDrawFont(playerid,Textdraw2, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw2, 0.330000, 1.299999);
	PlayerTextDrawColor(playerid,Textdraw2, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw2, 1);
	PlayerTextDrawSetProportional(playerid,Textdraw2, 1);
	PlayerTextDrawSetSelectable(playerid,Textdraw2, 0);

	playerData[playerid][carIntrumentSpeed] = Textdraw0;
	playerData[playerid][carIntrumentFuel] = Textdraw1;
	playerData[playerid][carIntrumentOdometer] = Textdraw2;
}

stock carInstrumentsRemove(playerid)
{
	PlayerTextDrawDestroy(playerid, playerData[playerid][carIntrumentSpeed]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][carIntrumentFuel]);
	PlayerTextDrawDestroy(playerid, playerData[playerid][carIntrumentOdometer]);
}

stock carInstrumentsUpdate(playerid)
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if (vehicleid != 0 && playerData[playerid][buycar_state] != 1) {

		new Float:x,Float:y,Float:z,temp_speed[32];
		GetVehicleVelocity(vehicleid,x,y,z);
		new Float:km = floatsqroot(((x*x)+(y*y))+(z*z))*181.5;
		format(temp_speed, sizeof(temp_speed),"Speed: %d km/h",floatround(km));
		PlayerTextDrawSetString(playerid, playerData[playerid][carIntrumentSpeed], temp_speed);
		PlayerTextDrawShow(playerid, playerData[playerid][carIntrumentSpeed]);

		if (carData[vehicleid][vehicle_fuel] < 10) {
			format(temp_speed, sizeof(temp_speed),"Fuel: ~r~%d", carData[vehicleid][vehicle_fuel]);
		} else {
			format(temp_speed, sizeof(temp_speed),"Fuel: %d%", carData[vehicleid][vehicle_fuel]);
		}
		PlayerTextDrawSetString(playerid, playerData[playerid][carIntrumentFuel], temp_speed);
		PlayerTextDrawShow(playerid, playerData[playerid][carIntrumentFuel]);

		if (carData[vehicleid][playerCar]) {
			format(temp_speed, sizeof(temp_speed),"Odometer: %d km", carData[vehicleid][vehicle_odometer]);
			PlayerTextDrawSetString(playerid, playerData[playerid][carIntrumentOdometer], temp_speed);
			PlayerTextDrawShow(playerid, playerData[playerid][carIntrumentOdometer]);
		} else {
			PlayerTextDrawHide(playerid, playerData[playerid][carIntrumentOdometer]);
		}

	} else {

		PlayerTextDrawHide(playerid, playerData[playerid][carIntrumentSpeed]);
		PlayerTextDrawHide(playerid, playerData[playerid][carIntrumentFuel]);
		PlayerTextDrawHide(playerid, playerData[playerid][carIntrumentOdometer]);

	}

	if (isBike(vehicleid)) {
		PlayerTextDrawHide(playerid, playerData[playerid][carIntrumentFuel]);
	}
}

stock fillUpAllCars()
{
	for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++) {
		carData[i][vehicle_fuel] = 100;
	}
}

stock gunGolder(playerid)
{

	for (new i = 1; i <= 6; i++) { // 6 here
		new weaponid, weaponammo;
		GetPlayerWeaponData(playerid, i, weaponid, weaponammo);

		if ((GetPlayerWeapon(playerid) == weaponid || weaponammo <= 0)) {
			if (IsPlayerAttachedObjectSlotUsed(playerid, i)) {
				RemovePlayerAttachedObject(playerid, i);
			}
			continue;
		}

		if (i == 1) {
			SetPlayerAttachedObject(playerid, 1, getWeaponModel(weaponid), 1, -0.3339, 0.1099, 0.1400, 31.7000, -83.3000, -69.9000, 1.0000, 1.0000, 1.0000, 0xFFFFFFFF, 0xFFFFFFFF);
		} else if (i == 2) {
			SetPlayerAttachedObject(playerid, 2, getWeaponModel(weaponid), 1, -0.1279, 0.0419, -0.2529, 95.3999, 175.1999, 0.0000, 1.0000, 1.0000, 1.0000, 0xFFFFFFFF, 0xFFFFFFFF); 
		} else if (i == 3) {
			SetPlayerAttachedObject(playerid, 3, getWeaponModel(weaponid), 1, 0.2970, -0.1539, 0.2910, 0.0000, 171.9999, 0.0000, 1.0000, 1.0000, 1.0000, 0xFFFFFFFF, 0xFFFFFFFF);
		} else if (i == 4) {
			SetPlayerAttachedObject(playerid, 4, getWeaponModel(weaponid), 1, -0.2349, 0.0149, -0.2349, 34.5000, 0.0000, -176.2999, 1.0000, 1.0000, 1.0000, 0xFFFFFFFF, 0xFFFFFFFF);
		} else if (i == 5) {
			SetPlayerAttachedObject(playerid, 5, getWeaponModel(weaponid), 1, 0.2440, -0.1319, -0.2150, 170.5000, 178.0999, 3.1999, 1.0000, 1.0000, 1.0000, 0xFFFFFFFF, 0xFFFFFFFF);
		} else if (i == 6) {
			SetPlayerAttachedObject(playerid, 6, getWeaponModel(weaponid), 1, 0.2890, -0.1630, 0.0759, 0.0000, -173.2999, 0.0000, 1.0000, 1.0000, 1.0000, 0xFFFFFFFF, 0xFFFFFFFF);
		}

	}
}


stock getWeaponModel(weaponid)
{
	
	switch(weaponid) {

		case WEAPON_GOLFCLUB: {return 333;}
		case WEAPON_NITESTICK: {return 334;}
		case WEAPON_KNIFE: {return 335;}
		case WEAPON_BAT: {return 336;}
		case WEAPON_SHOVEL: {return 337;}
		case WEAPON_POOLSTICK: {return 338;}
		case WEAPON_KATANA: {return 339;}
		case WEAPON_CHAINSAW: {return 341;}
		case WEAPON_COLT45: {return 333;}
		case WEAPON_SILENCED: {return 347;}
		case WEAPON_DEAGLE: {return 348;}
		case WEAPON_SHOTGUN: {return 349;}
		case WEAPON_SAWEDOFF: {return 350;}
		case WEAPON_SHOTGSPA: {return 351;}
		case WEAPON_UZI: {return 352;}
		case WEAPON_MP5: {return 353;}
		case WEAPON_AK47: {return 355;}
		case WEAPON_M4: {return 356;}
		case WEAPON_TEC9: {return 372;}
		case WEAPON_RIFLE: {return 357;}
		case WEAPON_SNIPER: {return 358;}
	}

	return -1;
}


stock TXDLoadScreen_init(playerid)
{
	new PlayerText:Textdraw0;
	new temp_random = random(5);
	if (temp_random == 0) {
		Textdraw0 = CreatePlayerTextDraw(playerid,-1.000000, -1.000000, "loadsc8:loadsc8");
	} else if (temp_random == 1) {
		Textdraw0 = CreatePlayerTextDraw(playerid,-1.000000, -1.000000, "loadsc9:loadsc9");
	}  else if (temp_random == 2) {
		Textdraw0 = CreatePlayerTextDraw(playerid,-1.000000, -1.000000, "loadsc6:loadsc6");
	}  else if (temp_random == 3) {
		Textdraw0 = CreatePlayerTextDraw(playerid,-1.000000, -1.000000, "loadsc10:loadsc10");
	}  else if (temp_random == 4) {
		Textdraw0 = CreatePlayerTextDraw(playerid,-1.000000, -1.000000, "loadsc12:loadsc12");
	}
	PlayerTextDrawBackgroundColor(playerid,Textdraw0, 255);
	PlayerTextDrawFont(playerid,Textdraw0, 4);
	PlayerTextDrawLetterSize(playerid,Textdraw0, -0.579999, 14.499999);
	PlayerTextDrawColor(playerid,Textdraw0, -1);
	PlayerTextDrawSetOutline(playerid,Textdraw0, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw0, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw0, 1);
	PlayerTextDrawUseBox(playerid,Textdraw0, 1);
	PlayerTextDrawBoxColor(playerid,Textdraw0, 255);
	PlayerTextDrawTextSize(playerid,Textdraw0, 641.000000, 450.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw0, 0);

	playerData[playerid][loadScreen_txd] = Textdraw0;
}

stock TXDLoadScreen_destroy(playerid)
{
	PlayerTextDrawDestroy(playerid, playerData[playerid][loadScreen_txd]);
}


stock TXDInfoMessage_init(playerid)
{
	new PlayerText:Textdraw0;

	// In OnPlayerConnect prefferably, we procced to create our textdraws:
	Textdraw0 = CreatePlayerTextDraw(playerid,334.000000, 350.000000, " ");
	PlayerTextDrawAlignment(playerid,Textdraw0, 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw0, 255);
	PlayerTextDrawFont(playerid,Textdraw0, 1);
	PlayerTextDrawLetterSize(playerid,Textdraw0, 0.350000, 1.299999);
	PlayerTextDrawColor(playerid,Textdraw0, -168700417);
	PlayerTextDrawSetOutline(playerid,Textdraw0, 0);
	PlayerTextDrawSetProportional(playerid,Textdraw0, 1);
	PlayerTextDrawSetShadow(playerid,Textdraw0, 1);
	PlayerTextDrawSetSelectable(playerid,Textdraw0, 0);

	playerData[playerid][infoMessage_txd] = Textdraw0;
}

stock TXDInfoMessage_destroy(playerid)
{
	PlayerTextDrawDestroy(playerid, playerData[playerid][infoMessage_txd]);
}

stock TXDInfoMessage_update(playerid, message[])
{
	if (strlen(message) == 0) {
		PlayerTextDrawHide(playerid, playerData[playerid][infoMessage_txd]);
	} else {
		PlayerTextDrawSetString(playerid, playerData[playerid][infoMessage_txd], message);
		PlayerTextDrawShow(playerid, playerData[playerid][infoMessage_txd]);
	}
}
