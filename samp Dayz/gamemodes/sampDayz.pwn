

#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <Pawn.CMD>
#include <easyDialog>
#include <foreach>
#include <sscanf2>
#include <DialogCenter>
#include <YSI\y_colours>
#include <GarageBlock>
#include <weapon-config>
#include <SKY>

#define localhost 0

#if localhost == 0
	#define mysql_host "87.98.243.201"
#elseif localhost == 1
	#define mysql_host "localhost"
#endif
#define mysql_user "samp6355"
#define mysql_password "AlexT"
#define mysql_database "samp6355_DayZ"

#define MAX_ADMIN_LEVEL 9
#define ADMINOVERRIDE_PASS "eec8eb13fb975d56389a08be866cb37bd2445b46"
#define MAX_ADMIN_OVERRIDE_ATTEMPTS 3
#define MAX_HACK_WARNS 2
#define MAX_LOOTSPAWN 2000
#define MAX_SPAWNS 50
#define MAX_INVENTORY (120)
#define MAX_DROPPEDITEMS 200

#define AC_CHECK_COOLDOWN 				1

#define INFINITE_AMMO 22767

new
    MySQLCon,
    GunSync[MAX_PLAYERS],
    LastAmmo[MAX_PLAYERS],
    HackWarns[MAX_PLAYERS],
    ACLastCheck[MAX_PLAYERS],
    aduty[MAX_PLAYERS],
    GunScan[MAX_PLAYERS][13][2],
    tempstr[128],
    LoginAttempt[MAX_PLAYERS];


new DefaultAmmo[] = {
	0, //fist
	1, //knuckles
	1, //golf club
	1, //nite stick
	1, //knife
	1, //baseball bat
	1, //shovel
	1, //pool cue
	1, //katana
	1, //chainsaw
	1, //purple dildo
	1, //dildo
	1, //vibrator
	1, //silver vibrator
	1, //flowers
	1, //cane
	30, //grenade
	30, //tear gas
	1, //molotov cocktail
	0,
	0,
	0,
	100, //9mm
	100, //silenced 9mm
	100, //deagle
	50, //shotgun
	75, //sawnoff
	75, //spas12
	400, //micro smg/uzi
	400, //mp5
	700, //ak47
	900, //m4
	500, //tec9
	12, //county rifle
	12, //sniper rifle
	7, //rpg
	7, //HS rocket
	1250, //flame thrower
	1200, //minigun
	7, //satchel charge
	1, //detonator
	800, //spray canSet
	800, //fire extinguisher
	15, //camera
	1, //night vision
	1, //thermal googles
	1, //parachute
};

new GunName[48][] = {
	"None",
	"Brass Knuckles",
	"Golf Club",
	"Nitestick",
	"Knife",
	"Baseball Bat",
	"Shovel",
	"Pool Cue",
	"Katana",
	"Chainsaw",
	"Purple Dildo",
	"Small Dildo",
	"Long Dildo",
	"Vibrator",
	"Flowers",
	"Cane",
	"Grenade",
	"Tear Gas",
	"Molotov",
	"Vehicle Missile",
	"Hydra Flare",
	"Jetpack",
	"9mm",
	"Silenced 9mm",
	"Desert Eagle",
	"Shotgun",
	"Sawn-off shotgun",
	"Spas 12",
	"UZI",
	"MP5",
	"AK47",
	"M4",
	"Tec9",
	"Rifle",
	"Sniper",
	"Rocket Launcher",
	"HS Rocket Launcher",
	"Flamethrower",
	"Minigun",
	"Satchel Charge",
	"Detonator",
	"Spraycan",
	"Fire Extinguisher",
	"Camera",
	"Nightvision",
	"Infrared vision",
	"Parachute",
	"Fake Pistol"
};

enum lootData {
	lootExists,
	lootID,
	lootItem[32],
	lootItemID,
	lootModelID,
	lootModel,
	Float:lootPos[3],
	Text3D:lootText
};
new LootData[MAX_LOOTSPAWN][lootData];

enum dropData {
	dropExists,
	dropItem[32],
	dropItemID,
	dropModelID,
	dropModel,
	Float:dropPos[3],
	Text3D:dropText
};
new DropData[MAX_DROPPEDITEMS][lootData];

enum spawnData {
	spawnExists,
	spawnID,
	spawnName[64],
	Float:spawnPos[4]
};
new SpawnData[MAX_SPAWNS][spawnData];

enum inventoryData {
	invExists,
	invID,
	invItem[32],
	invItemID,
	invModel,
	invSlots,
	invQuantity
};
new InventoryData[MAX_PLAYERS][MAX_INVENTORY][inventoryData];

enum playerTextdraw {
	PlayerText:pTextdraws[83]
};
new TextDrawData[MAX_PLAYERS][playerTextdraw];

/*enum inventoryData {
	invExists,
	invID,
	invItem[32],
	invItemID,
	invModel,
	invSlots,
	invQuantity
};
new InventoryData[MAX_PLAYERS][MAX_DROPITEMS][inventoryData];*/

native WP_Hash(buffer[], len, const str[]);

main()
{
	print("\n|----------------------------------|");
	print("|  Samp Dayz by ZiiM               |");
	print("|----------------------------------|\n");
}

public OnGameModeInit()
{
	// Don't use these lines if it's a filterscript
	SetGameModeText("SA-DayZ 0.0.2");
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	MySQLCon = mysql_connect(mysql_host, mysql_user, mysql_database, mysql_password);
	if(mysql_errno(MySQLCon) != 0) printf("Could not connect to database %s with Username: %s Pass: %s at %s!", mysql_database, mysql_user, mysql_password, mysql_host);
	if(mysql_errno(MySQLCon) == 0) print("Successfully connected to MySQL database.");
	mysql_log(LOG_ERROR | LOG_WARNING, LOG_TYPE_HTML);
	BlockGarages(true, GARAGE_TYPE_ALL, "DISABLED");
	BlockGarages(true, GARAGE_TYPE_MODSHOP, "DISABLED");
	BlockGarages(true, GARAGE_TYPE_BOMB, "DISABLED");
	BlockGarages(true, GARAGE_TYPE_PAINT, "DISABLED");
	mysql_tquery(MySQLCon, "SELECT * FROM `lootspawns`", "Loot_Load", "");
	mysql_tquery(MySQLCon, "SELECT * FROM `spawns`", "Spawn_Load", "");
	ManualVehicleEngineAndLights();
	EnableStuntBonusForAll(0);
    DisableInteriorEnterExits();
    ShowNameTags(true);
    SetDamageFeed(false);
    SetVehiclePassengerDamage(true);
    SetDisableSyncBugs(true);
    for(new i = 0; i < 46; i++) {
		SetWeaponDamage(i, DAMAGE_TYPE_STATIC, 0.0);
	}
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
    SendRconCommand("hostname [0.3.7] San Andreas DayZ [www.sa-dayz.com]");
    SetTimer("PlayerCheck", 1000, true);
	SetTimer("OnPlayerAccountSaveTimer", 600000, true);
	SetTimer("OnLootRespawnTimer", 900000, true);
	return 1;
}

forward Loot_Load();
public Loot_Load()
{
	new rows, fields, msg[128], lootid;
	cache_get_data(rows,fields);
	for (new i = 0; i < rows; i ++) if (i < MAX_LOOTSPAWN)
	{
		lootid = random(1350);
		LootData[i][lootExists] = true;
		LootData[i][lootItemID] = lootid;
		format(LootData[i][lootItem], 32, LootItemName(lootid));
		LootData[i][lootModelID] = LootItemModelID(lootid);

		LootData[i][lootID] = cache_get_field_content_int(i, "id");

		LootData[i][lootPos][0] = cache_get_field_content_float(i, "X");
		LootData[i][lootPos][1] = cache_get_field_content_float(i, "Y");
		LootData[i][lootPos][2] = cache_get_field_content_float(i, "Z");

		if(IsValidDynamic3DTextLabel(LootData[i][lootText]))
			DestroyDynamic3DTextLabel(LootData[i][lootText]);

		if(IsValidDynamicObject(LootData[i][lootModel]))
			DestroyDynamicObject(LootData[i][lootModel]);
		format(msg, sizeof(msg), "Loot here: %s(%d)\n Press 'N' to pick it up.", LootData[i][lootItem], LootData[i][lootItemID]);
		LootData[i][lootText] = CreateDynamic3DTextLabel(msg, X11_AQUAMARINE3, LootData[i][lootPos][0], LootData[i][lootPos][1], LootData[i][lootPos][2]-0.5, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0);
		LootData[i][lootModel] = CreateDynamicObject(LootData[i][lootModelID], LootData[i][lootPos][0], LootData[i][lootPos][1], LootData[i][lootPos][2]-1, 0, 0, 0);
	}
	return 1;
}

forward Spawn_Load();
public Spawn_Load()
{
	new rows, fields;
	cache_get_data(rows,fields);
	for (new i = 0; i < rows; i ++) if (i < MAX_SPAWNS)
	{
		SpawnData[i][spawnExists] = true;
		SpawnData[i][spawnID] = cache_get_field_content_int(i, "id");
		cache_get_field_content(i, "Name", SpawnData[i][spawnName], MySQLCon, 64);
		SpawnData[i][spawnPos][0] = cache_get_field_content_float(i, "X");
		SpawnData[i][spawnPos][1] = cache_get_field_content_float(i, "Y");
		SpawnData[i][spawnPos][2] = cache_get_field_content_float(i, "Z");
		SpawnData[i][spawnPos][3] = cache_get_field_content_float(i, "Angle");
	}
	return 1;
}

LootItemName(lootnumber)
{
	new lootname[32];
	switch(lootnumber)
	{
		case -1: {
			format(lootname, sizeof(lootname), "Empty");
		}
		case 0..100: {
			format(lootname, sizeof(lootname), "Water Bottle");
		}
		case 101..120: {
			format(lootname, sizeof(lootname), "Heat Pack");
		}
		case 121..150: {
			format(lootname, sizeof(lootname), "Medkit");
		}
		case 151..175: {
			format(lootname, sizeof(lootname), "Morphine");
		}
		case 176..185: {
			format(lootname, sizeof(lootname), "M4");
		}
		case 186..200: {
			format(lootname, sizeof(lootname), "Pistol");
		}
		case 201..220: {
			format(lootname, sizeof(lootname), "Pistol Ammo");
		}
		case 221..230: {
			format(lootname, sizeof(lootname), "Ak47");
		}
		case 231..250: {
			format(lootname, sizeof(lootname), "Ghillie Suit");
		}
		case 251..300: {
			format(lootname, sizeof(lootname), "Army Clothes");
		}
		case 301..320: {
			format(lootname, sizeof(lootname), "Assault Ammo");
		}
		case 321..400: {
			format(lootname, sizeof(lootname), "MP5");
		}
		case 401..450: {
			format(lootname, sizeof(lootname), "Submachine Gun Ammo");
		}
		case 451..500: {
			format(lootname, sizeof(lootname), "Sniper Rifle");
		}
		case 501..550: {
			format(lootname, sizeof(lootname), "Sniper Ammo");
		}
		case 551..600: {
			format(lootname, sizeof(lootname), "Country Rifle");
		}
		case 601..650: {
			format(lootname, sizeof(lootname), "Grenade");
		}
		case 651..700: {
			format(lootname, sizeof(lootname), "Pizza");
		}
		case 701..725: {
			format(lootname, sizeof(lootname), "Engine");
		}
		case 726..750: {
			format(lootname, sizeof(lootname), "Tire");
		}
		case 751..775: {
			format(lootname, sizeof(lootname), "Toolbox");
		}
		case 776..780: {
			format(lootname, sizeof(lootname), "C4");
		}
		case 781..810: {
			format(lootname, sizeof(lootname), "Coka-cola");
		}
		case 811..870: {
			format(lootname, sizeof(lootname), "Canned Tuna");
		}
		case 871..990: {
			format(lootname, sizeof(lootname), "Civilian Skin");
		}
		case 991..1000: {
			format(lootname, sizeof(lootname), "RPG-45");
		}
		case 1001..1200: {
			format(lootname, sizeof(lootname), "Czech Backpack");
		}
		case 1201..1300: {
			format(lootname, sizeof(lootname), "Alice Pack");
		}
		case 1301..1350: {
			format(lootname, sizeof(lootname), "Coyote Backpack");
		}
	}
	return (lootname);
}

stock SendSyntaxMessage(playerid, msg[])
{
	if(IsLoggedIn(playerid))
	{
	    new string[256];
	    format(string, sizeof(string), "USAGE: %s", msg);
	    
	    SendClientMessage(playerid, X11_LIGHTGREY, string);
	}
	
	return 1;
}

forward TPEntireCar(vid,interior,vw);// for setting players vw, and interior.
public TPEntireCar(vid,interior,vw) {
	LinkVehicleToInterior(vid,interior);
	SetVehicleVirtualWorld(vid,vw);
	foreach(Player, i) {
	if(IsLoggedIn(i)) {
		if(GetPlayerVehicleID(i)==vid) {
			SetPlayerVirtualWorld(i,vw);
			SetPlayerInterior(i,interior);
		}
	}
	}
	return 1;
}

stock Inventory_Clear(playerid)
{
	static
	    string[64];

	for (new i = 0; i < MAX_INVENTORY; i ++)
	{
	    if (InventoryData[playerid][i][invExists])
	    {
	        InventoryData[playerid][i][invExists] = 0;
	        InventoryData[playerid][i][invModel] = 0;
	        InventoryData[playerid][i][invQuantity] = 0;
		}
	}
	format(string, sizeof(string), "DELETE FROM `inventory` WHERE `ID` = '%d'", GetPVarInt(playerid, "AccountID"));
	return mysql_function_query(MySQLCon, string, false, "", "");
}

stock Inventory_Items(playerid)
{
    new count;

    for (new i = 0; i != MAX_INVENTORY; i ++) if (InventoryData[playerid][i][invExists]) {
        count++;
	}
	return count;
}

stock Inventory_Count(playerid, item[])
{
	new count = 0;
	for(new itemid = 0; itemid < GetPVarInt(playerid, "MaxSlots"); itemid++) {
		if(!strcmp(item, InventoryData[playerid][itemid][invItem]))
		{
			count++;
		}
	}
	return count;
}

stock Inventory_Add(playerid, item[], itemids, model, quantity)
{
	//new item[32];
	//item = LootData[lootid][lootItem];
	new string[256];

	for(new itemid = 0; itemid < GetPVarInt(playerid, "MaxSlots"); itemid++)
	{
		if(InventoryData[playerid][itemid][invExists])
		{
			if (!strcmp(item, InventoryData[playerid][itemid][invItem]))
			{
			    format(string, sizeof(string), "UPDATE `inventory` SET `invQuantity` = `invQuantity` + %d WHERE `ID` = '%d' AND `invID` = '%d'", quantity, GetPVarInt(playerid, "AccountID"), InventoryData[playerid][itemid][invID]);
			    mysql_function_query(MySQLCon, string, false, "", "");

			    InventoryData[playerid][itemid][invQuantity] += quantity;
			    return itemid;
			}
		}
		else if(!InventoryData[playerid][itemid][invExists])
		{
			if(itemids >= 1001 && itemids <= 1200 && GetPVarInt(playerid, "Backpack") < 1)
			{
				SetPlayerBackpack(playerid, 1);
				return 1;
			}
			else if(itemids >= 1201 && itemids <= 1300 && GetPVarInt(playerid, "Backpack") < 2)
			{
				SetPlayerBackpack(playerid, 2);
				return 1;
			}
			else if(itemids >= 1301 && itemids <= 1350 && GetPVarInt(playerid, "Backpack") < 3)
			{
				SetPlayerBackpack(playerid, 3);
				return 1;
			}
	        InventoryData[playerid][itemid][invExists] = true;
	        InventoryData[playerid][itemid][invItemID] = itemids;
	        InventoryData[playerid][itemid][invModel] = model;
	        InventoryData[playerid][itemid][invQuantity] = quantity;
	        //InventoryData[playerid][itemid][invItem] = item;
	        format(InventoryData[playerid][itemid][invItem], 32, item);
			format(string, sizeof(string), "INSERT INTO `inventory` (`ID`, `invItem`, `invItemID`, `invModel`, `invQuantity`) VALUES('%d', '%s', '%d', '%d', '%d')", GetPVarInt(playerid, "AccountID"), item, itemids, model, quantity);
			mysql_function_query(MySQLCon, string, false, "OnInventoryAdd", "dd", playerid, itemid);
	        return itemid;
		}
	}
	return -1;
}

forward OpenInventory(playerid);
public OpenInventory(playerid)
{
    if (!IsLoggedIn(playerid))
	    return 0;

	new
	    string[512],
	    diatitle[64],
	    string2[128];

	format(string, sizeof(string), "Item\tAmount\n");
    for (new i = 0; i < GetPVarInt(playerid, "MaxSlots"); i ++)
	{
 		if (InventoryData[playerid][i][invExists]) {
 			format(string2, sizeof(string2), "%s\t%d\n", InventoryData[playerid][i][invItem], InventoryData[playerid][i][invQuantity]);
 			strcat(string, string2);
		}
		else {
			strcat(string, "Empty Slot\n");
		}
	}
	format(diatitle, sizeof(diatitle), "%s's Inventory | Total slots: %d | Slots used: %d", PlayerName(playerid), GetPVarInt(playerid, "MaxSlots"), Inventory_Items(playerid));
	// 
	// strcat("Item\tAmount\n", string);
	return Dialog_Show(playerid, DIALOG_INVENTORY ,DIALOG_STYLE_TABLIST_HEADERS, diatitle, string, "Select", "Close");
}

DIALOG:DIALOG_INVENTORY(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		new string[48], diastring[512];
		if(listitem == -1)
		{
			OpenInventory(playerid);
			//if(Inventory_Items(playerid) )
		}
		else if(InventoryData[playerid][listitem][invExists])
		{
			SetPVarInt(playerid, "ListItem", listitem);
			format(string, sizeof(string), "%s (Quantity: %d)", InventoryData[playerid][listitem][invItem], InventoryData[playerid][listitem][invQuantity]);
			format(diastring, sizeof(diastring), "Item Selected: %s || Quantity: %d", InventoryData[playerid][listitem][invItem], InventoryData[playerid][listitem][invQuantity]);
			Dialog_Show(playerid, DIALOG_INVENTORY_OPTIONS, DIALOG_STYLE_MSGBOX, string, diastring, "Use Item", "Drop Item");
		}
	}
}

DIALOG:DIALOG_SPAWN(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		new Float:x, Float:y, Float:z, Float:angle, skin;
		x = SpawnData[listitem][spawnPos][0];
		y = SpawnData[listitem][spawnPos][1];
		z = SpawnData[listitem][spawnPos][2];
		angle = SpawnData[listitem][spawnPos][3];
		skin = GetPVarInt(playerid, "Skin");
		SetSpawnInfo(playerid, 0, skin, x, y, z, angle, 0, 0, 0, 0, 0, 0);
		ShowHungerTextdraw(playerid, 1);
		SetPVarInt(playerid, "IsAlive", 1);
		TogglePlayerSpectating(playerid, false);
		SpawnPlayer(playerid);
	}
	else Kick(playerid);
}

DIALOG:DIALOG_INVENTORY_OPTIONS(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		new id = GetPVarInt(playerid, "ListItem");
		OnPlayerUseItem(playerid, id, InventoryData[playerid][id][invItem]);
	}
}

forward OnPlayerUseItem(playerid, itemid, name[]);
public OnPlayerUseItem(playerid, itemid, name[])
{
	if(!strcmp(name, "Pizza", true))
	{
		if(GetPVarInt(playerid, "Hunger") < 100)
		{
			Inventory_Remove(playerid, "", itemid);
			GivePlayerHunger(playerid, 50);
			OnPlayerAccountSave(playerid);
			return 1;
		}
		else return SendClientMessage(playerid, X11_GREY85, "You are already full on hunger.");
	}
	else if(!strcmp(name, "Canned Tuna", true))
	{
		if(GetPVarInt(playerid, "Hunger") < 100)
		{
			Inventory_Remove(playerid, "", itemid);
			GivePlayerHunger(playerid, 25);
			OnPlayerAccountSave(playerid);
			return 1;
		}
		else return SendClientMessage(playerid, X11_GREY85, "You are already full on hunger.");
	}
	else if(!strcmp(name, "Water Bottle", true))
	{
		if(GetPVarInt(playerid, "Thirst") < 100)
		{
			Inventory_Remove(playerid, "", itemid);
			GivePlayerThirst(playerid, 75);
			OnPlayerAccountSave(playerid);
			return 1;
		}
		else return SendClientMessage(playerid, X11_GREY85, "You are already full on thirst.");
	}
	else if(!strcmp(name, "Coka-cola", true))
	{
		if(GetPVarInt(playerid, "Thirst") < 100)
		{
			Inventory_Remove(playerid, "", itemid);
			GivePlayerThirst(playerid, 25);
			OnPlayerAccountSave(playerid);
			return 1;
		}
		else return SendClientMessage(playerid, X11_GREY85, "You are already full on thirst.");
	}
	// Clothes
	else if(!strcmp(name, "Civilian Skin", true))
	{
		if(GetPVarInt(playerid, "Skin") == 250) return 1;
		Inventory_Remove(playerid, "", itemid);
		SetPVarInt(playerid, "Skin", 250);
		SetPlayerSkin(playerid, 250);
		OnPlayerAccountSave(playerid);
		return 1;
	}
	else if(!strcmp(name, "Army Clothes", true))
	{
		if(GetPVarInt(playerid, "Skin") == 287) return 1;
		Inventory_Remove(playerid, "", itemid);
		SetPVarInt(playerid, "Skin", 287);
		SetPlayerSkin(playerid, 287);
		OnPlayerAccountSave(playerid);
		return 1;
	}
	// Medical
	else if(!strcmp(name, "Medkit", true))
	{
		Inventory_Remove(playerid, "", itemid);
		new blood = GetPVarInt(playerid, "Blood");
		SetPVarInt(playerid, "Blood", blood + 7500);
		if(GetPVarInt(playerid, "Blood") > 12000) {
			SetPVarInt(playerid, "Blood", 12000);
		}
		OnPlayerAccountSave(playerid);
		return 1;
	}
	// Weapons
	else if(!strcmp(name, "M4", true))
	{
		new slot = GetWeaponSlot(31), weapon, ammo;
		GetPlayerWeaponData(playerid, slot, weapon, ammo);
		if(weapon != 31)
		{
			if(weapon == 30) {

				Inventory_Remove(playerid, "", itemid);
				Inventory_Add(playerid, "Ak47", 225, 355, 1);
				GivePlayerWeaponEx(playerid, 31, ammo);
			}
			else if(Inventory_Count(playerid, "Assault Ammo") > 0)
			{
				Inventory_Remove(playerid, "Assault Ammo");
				Inventory_Remove(playerid, "", itemid);
				GivePlayerWeaponEx(playerid, 31, 100);
			}
			OnPlayerAccountSave(playerid);
		}
		return 1;
	}
	else if(!strcmp(name, "Ak47", true))
	{
		new slot = GetWeaponSlot(31), weapon, ammo;
		GetPlayerWeaponData(playerid, slot, weapon, ammo);
		if(weapon != 30)
		{
			if(weapon == 31) {

				Inventory_Remove(playerid, "", itemid);
				Inventory_Add(playerid, "M4", 180, 356, 1);
				GivePlayerWeaponEx(playerid, 30, ammo);
			}
			else if(Inventory_Count(playerid, "Assault Ammo") > 0)
			{
				Inventory_Remove(playerid, "Assault Ammo");
				Inventory_Remove(playerid, "", itemid);
				GivePlayerWeaponEx(playerid, 30, 100);
			}
			OnPlayerAccountSave(playerid);
		}
		return 1;
	}
	else if(!strcmp(name, "Pistol", true))
	{
		new slot = GetWeaponSlot(22), weapon, ammo;
		GetPlayerWeaponData(playerid, slot, weapon, ammo);
		if(weapon != 22)
		{
			if(Inventory_Count(playerid, "Pistol Ammo") > 0)
			{
				Inventory_Remove(playerid, "Pistol Ammo");
				Inventory_Remove(playerid, "", itemid);
				GivePlayerWeaponEx(playerid, 22, 45);
			}
			OnPlayerAccountSave(playerid);
		}
		return 1;
	}
	else if(!strcmp(name, "MP5", true))
	{
		new slot = GetWeaponSlot(29), weapon, ammo;
		GetPlayerWeaponData(playerid, slot, weapon, ammo);
		if(weapon != 29)
		{
			if(Inventory_Count(playerid, "Submachine Gun Ammo") > 0)
			{
				Inventory_Remove(playerid, "Submachine Gun Ammo");
				Inventory_Remove(playerid, "", itemid);
				GivePlayerWeaponEx(playerid, 29, 60);
			}
			OnPlayerAccountSave(playerid);
		}
		OnPlayerAccountSave(playerid);
		return 1;
	}
	else if(!strcmp(name, "Sniper Rifle", true))
	{
		new slot = GetWeaponSlot(34), weapon, ammo;
		GetPlayerWeaponData(playerid, slot, weapon, ammo);
		if(weapon != 34)
		{
			if(weapon == 33) {

				Inventory_Remove(playerid, "", itemid);
				Inventory_Add(playerid, "Country Rifle", 575, 357, 1);
				GivePlayerWeaponEx(playerid, 34, ammo);
			}
			else if(Inventory_Count(playerid, "Assault Ammo") > 0)
			{
				Inventory_Remove(playerid, "Sniper Ammo");
				Inventory_Remove(playerid, "", itemid);
				GivePlayerWeaponEx(playerid, 34, 25);
			}
			
		}
		OnPlayerAccountSave(playerid);
		return 1;
	}
	else if(!strcmp(name, "Country Rifle", true))
	{
		new slot = GetWeaponSlot(33), weapon, ammo;
		GetPlayerWeaponData(playerid, slot, weapon, ammo);
		if(weapon != 33)
		{
			if(weapon == 34) {

				Inventory_Remove(playerid, "", itemid);
				Inventory_Add(playerid, "Sniper Rifle", 475, 358, 1);
				GivePlayerWeaponEx(playerid, 33, ammo);
			}
			else if(Inventory_Count(playerid, "Sniper Ammo") > 0)
			{
				Inventory_Remove(playerid, "Sniper Ammo");
				Inventory_Remove(playerid, "", itemid);
				GivePlayerWeaponEx(playerid, 33, 25);
			}
			OnPlayerAccountSave(playerid);
		}
		return 1;
	}
	else if(!strcmp(name, "Assault ammo", true))
	{
		new weapon, ammo;
		GetPlayerWeaponData(playerid, 5, weapon, ammo);
		if(weapon == 30 || weapon == 31)
		{
			SetPlayerAmmoEx(playerid, weapon, GetPlayerAmmo(playerid) + 100);
			Inventory_Remove(playerid, "Assault ammo");
			OnPlayerAccountSave(playerid);
		}
		return 1;
	}
	else if(!strcmp(name, "Pistol Ammo", true))
	{
		new weapon, ammo;
		GetPlayerWeaponData(playerid, 2, weapon, ammo);
		if(weapon == 22)
		{
			SetPlayerAmmoEx(playerid, weapon, GetPlayerAmmo(playerid) + 45);
			Inventory_Remove(playerid, "Pistol Ammo");
			OnPlayerAccountSave(playerid);
		}
		return 1;
	}
	else if(!strcmp(name, "Submachine Gun Ammo", true))
	{
		new weapon, ammo;
		GetPlayerWeaponData(playerid, 4, weapon, ammo);
		if(weapon == 29)
		{
			SetPlayerAmmoEx(playerid, weapon, GetPlayerAmmo(playerid) + 60);
			Inventory_Remove(playerid, "Submachine Gun Ammo");
			OnPlayerAccountSave(playerid);
		}
		return 1;
	}
	else if(!strcmp(name, "Sniper Ammo", true))
	{
		new weapon, ammo;
		GetPlayerWeaponData(playerid, 6, weapon, ammo);
		if(weapon == 33 || weapon == 34)
		{
			SetPlayerAmmoEx(playerid, weapon, GetPlayerAmmo(playerid) + 100);
			Inventory_Remove(playerid, "Sniper Ammo");
			OnPlayerAccountSave(playerid);
		}
		return 1;
	}
	return 0;
}

SetPlayerAmmoEx(playerid, weapon, ammo)
{
	new slot, pvarname[32];
	slot = GetWeaponSlot(weapon);
	format(pvarname, sizeof(pvarname), "Ammo%d", slot);
	SetPVarInt(playerid, pvarname, ammo);
	SetPlayerAmmo(playerid, weapon, ammo);
	return 1;
}



GivePlayerHunger(playerid, amount)
{
	new hunger = GetPVarInt(playerid, "Hunger");
	SetPVarInt(playerid, "Hunger", hunger + amount);
	return 1;
}

GivePlayerThirst(playerid, amount)
{
	new thirst = GetPVarInt(playerid, "Thirst");
	SetPVarInt(playerid, "Thirst", thirst + amount);
	return 1;
}

dropItem(dropper, itemid, amount, Float:X, Float: Y, Float: Z, interior, vw)
{
	new index = findFreeDroppedItem();
	if(index == -1) return index;
}

findFreeDroppedItem() {
	for(new i=0;i<MAX_DROPPEDITEMS;i++) {
		if(!DropData[i][dropExists]) {
			return i;
		}
	}
	return -1;
}

stock Inventory_Remove(playerid, item[], itemid = -1, quantity = 1)
{
	new string[128];


	if (itemid != -1)
	{
		if(InventoryData[playerid][itemid][invExists])
		{
		    if (InventoryData[playerid][itemid][invQuantity] > 0)
		    {
		        InventoryData[playerid][itemid][invQuantity] -= quantity;
			}
			if (quantity == -1 || InventoryData[playerid][itemid][invQuantity] < 1)
			{
			    InventoryData[playerid][itemid][invExists] = false;
			    InventoryData[playerid][itemid][invModel] = 0;
			    InventoryData[playerid][itemid][invQuantity] = 0;

			    format(string, sizeof(string), "DELETE FROM `inventory` WHERE `ID` = '%d' AND `invID` = '%d'", GetPVarInt(playerid, "AccountID"), InventoryData[playerid][itemid][invID]);
		        mysql_function_query(MySQLCon, string, false, "", "");
			}
			else if (quantity != -1 && InventoryData[playerid][itemid][invQuantity] > 0)
			{
				format(string, sizeof(string), "UPDATE `inventory` SET `invQuantity` = `invQuantity` - %d WHERE `ID` = '%d' AND `invID` = '%d'", quantity, GetPVarInt(playerid, "AccountID"), InventoryData[playerid][itemid][invID]);
	            mysql_function_query(MySQLCon, string, false, "", "");
			}
		}
		return 0;
	}
	else if(!isnull(item))
	{
		for(new i = 0; i < GetPVarInt(playerid, "MaxSlots"); i++)
		{
			if(InventoryData[playerid][i][invExists]) {
				if(!strcmp(item, InventoryData[playerid][i][invItem])) {
					if (InventoryData[playerid][i][invQuantity] > 0)
				    {
				        InventoryData[playerid][i][invQuantity] -= quantity;
					}
					if (quantity == -1 || InventoryData[playerid][i][invQuantity] < 1)
					{
					    InventoryData[playerid][i][invExists] = false;
					    InventoryData[playerid][i][invModel] = 0;
					    InventoryData[playerid][i][invQuantity] = 0;

					    format(string, sizeof(string), "DELETE FROM `inventory` WHERE `ID` = '%d' AND `invID` = '%d'", GetPVarInt(playerid, "AccountID"), InventoryData[playerid][i][invID]);
				        mysql_function_query(MySQLCon, string, false, "", "");
					}
					else if (quantity != -1 && InventoryData[playerid][i][invQuantity] > 0)
					{
						format(string, sizeof(string), "UPDATE `inventory` SET `invQuantity` = `invQuantity` - %d WHERE `ID` = '%d' AND `invID` = '%d'", quantity, GetPVarInt(playerid, "AccountID"), InventoryData[playerid][i][invID]);
			            mysql_function_query(MySQLCon, string, false, "", "");
					}
				}
			}
		}
	}
	return 0;
}

LootItemModelID(lootnumber)
{
	switch(lootnumber)
	{
		case -1: {
			return 0;
		}
		case 0..100: {
			return 1484;
		}
		case 101..120: {
			return 19573;
		}
		case 121..150: {
			return 1580;
		}
		case 151..175: {
			return 1580;
		}
		case 176..185: {
			return 356;
		}
		case 186..200: {
			return 346;
		}
		case 201..220: {
			return 3016;
		}
		case 221..230: {
			return 355;
		}
		case 231..250: {
			return 1275;
		}
		case 251..300: {
			return 19106;
		}
		case 301..320: {
			return 3016;
		}
		case 321..400: {
			return 353;
		}
		case 401..450: {
			return 3016;
		}
		case 451..500: {
			return 358;
		}
		case 501..550: {
			return 3016;
		}
		case 551..600: {
			return 357;
		}
		case 601..650: {
			return 342;
		}
		case 651..700: {
			return 2814;
		}
		case 701..725: {
			return 19917;
		}
		case 726..750: {
			return 1098;
		}
		case 751..775: {
			return 19921;
		}
		case 776..780: {
			return 1654;
		}
		case 781..810: {
			return 2673;
		}
		case 811..870: {
			return 2866;
		}
		case 871..990: {
			return 1275;
		}
		case 991..1000: {
			return 359;///25
		}
		case 1001..1200: {
			return 371;
		}
		case 1201..1300: {
			return 1310;
		}
		case 1301..1350: {
			return 1550;
		}
	}
	return 0;
}

public OnGameModeExit()
{
	foreach(new i : Player)
	{
		if(IsLoggedIn(i))
		{
			OnPlayerDisconnect(i, 1);
		}
	}
	mysql_close(MySQLCon);
	return 1;
}

public OnQueryError( errorid, error[], callback[], query[], connectionHandle ) {
	new msg[256];
	format(msg,sizeof(msg),"Query: %s",query);
	printf(msg);
	format(msg,sizeof(msg),"SQL ERROR: %d %s",errorid, error);
	printf(msg);
	return 0;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerColor(playerid, X11_BLACK);
    TogglePlayerSpectating(playerid, true);
    // SetHealthBarVisible(playerid, false);
    if(IsPlayerNPC(playerid))
	{
	    new pIP[16];
	    GetPlayerIp(playerid, pIP, 16);
	    if(!strcmp(pIP, "127.0.0.1", true)) return true;
	    else return Kick(playerid);
	}
	new query[500], pName[64];
	GetPlayerName(playerid, pName, sizeof(pName));
	mysql_format(MySQLCon, query, sizeof(query), "SELECT id, pass FROM `accounts` WHERE `username` = '%e' LIMIT 1", pName);
	mysql_tquery(MySQLCon, query, "OnAccountCheck", "i", playerid);
	return 1;
}
forward OnAccountCheck(playerid);
public OnAccountCheck(playerid)
{
    new rows, fields, string[256];
    cache_get_data(rows, fields, MySQLCon);
    if(rows)
    {
        new field_int[140], pName[64];
        cache_get_row(0,0, field_int);
        SetPVarInt(playerid, "AccountID", strval(field_int));
        cache_get_row(0,1, field_int);
        SetPVarString(playerid, "Pass", field_int);
        GetPlayerName(playerid, pName, sizeof(pName));
        format(string, sizeof(string), "{D1D1D1}Welcome back to San Andreas DayZ\n           'A place for everyone.'\n\n        Survivor: {FFFFFF}%s\n        {D1D1D1}Enter your password below",pName);
        Dialog_Show(playerid, DIALOG_LOGIN,DIALOG_STYLE_PASSWORD,"{21f3de}>  {ffffff}Login",string,"Login","Exit");
    } 
    else
    {
        format(string, sizeof(string), "{D1D1D1}Welcome to San Andreas DayZ\n        'A place for everyone.'\n\n  Survivor: {FFFFFF}%s\n  {D1D1D1}Enter your password below",PlayerName(playerid));
		Dialog_Show(playerid,DIALOG_REGISTER,DIALOG_STYLE_PASSWORD,"{21f3de}>  {ffffff}Register",string,"Register","Exit");
    }   
    return 1;
}

Dialog:DIALOG_REGISTER(playerid, response, listitem, inputtext[])
{
	if(!response) return Kick(playerid);
	new query[1024];
	if(strlen(inputtext) < 6 || strlen(inputtext) > 129)
	{
		new string[128];
		SendClientMessage(playerid, X11_AQUAMARINE3, "Your password must be 6 to 129 characters long!");
		format(string, sizeof(string), "{D1D1D1}Welcome to San Andreas DayZ\n        'A place for everyone.'\n\n  Survivor: {FFFFFF}%s\n  {D1D1D1}Enter your password below",PlayerName(playerid));
		Dialog_Show(playerid,DIALOG_REGISTER,DIALOG_STYLE_PASSWORD,"{21f3de}>  {ffffff}Register",string,"Register","Cancel");
		return 1;
	} else {
		SetPVarString(playerid, "Pass",inputtext);
		SetPVarString(playerid, "AccountName", PlayerName(playerid));
		mysql_format(MySQLCon, query, sizeof(query), "INSERT INTO `accounts` (`username`, `pass`) VALUES ('%e', '%s')", PlayerName(playerid), PasswordHash(inputtext));
		mysql_tquery(MySQLCon, query, "OnPlayerRegister", "i", playerid);
	}
	return 1;
}

forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
    SetPVarInt(playerid, "AccountID", cache_insert_id());
    SetSpawnInfo(playerid, 0, 12, 1536.61, -1691.2, 13.3, 78.0541, 0, 0, 0, 0, 0, 0);

    SetPVarInt(playerid, "IsLoggedIn", 1);
    SetPVarInt(playerid, "Blood", 12000);
    SetPVarInt(playerid, "MaxSlots", 12);
    SetPVarInt(playerid, "AdminLevel", 0);
    SetPVarInt(playerid, "Hunger", 100);
    SetPVarInt(playerid, "Thirst", 100);
    SetPVarInt(playerid, "Humanity", 1600);
    SetPVarInt(playerid, "Kills", 0);
    SetPVarInt(playerid, "Deaths", 0);
    SetPVarInt(playerid, "IsAlive", 0);
    SetPVarInt(playerid, "Skin", 12);
    SetPVarInt(playerid, "LoginTime", gettime());
    SetPlayerColor(playerid, X11_WHITE);

 	TogglePlayerSpectating(playerid, true);
 	ShowPlayerSpawnDialog(playerid);
    SetPlayerBackpack(playerid, 0);
    return;
}

alias:admin("a");

CMD:goto(playerid, params[]) {
	new playa;
	if(GetAdminLevel(playerid) < 1) return SendClientMessage(playerid, X11_RED, "You are not an admin.");
	if (!sscanf(params, "u", playa))
    {
		if(!IsLoggedIn(playa)) {
			SendClientMessage(playerid, X11_WHITE, "Invalid player!");
			return 1;
		}
		new Float:X,Float:Y,Float:Z,vw,interior;
		GetPlayerPos(playa, X, Y, Z);
		vw = GetPlayerVirtualWorld(playa);
		interior = GetPlayerInterior(playa);
		if(IsPlayerInAnyVehicle(playerid)) {
			new carid = GetPlayerVehicleID(playerid);
			TPEntireCar(carid, interior, vw);
			LinkVehicleToInterior(carid, interior);
			SetVehicleVirtualWorld(carid, vw);
			SetVehiclePos(carid, X, Y, Z);
			
		} else {
			SetPlayerPos(playerid, X, Y, Z);
		}
		SetPlayerVirtualWorld(playerid, vw);
		SetPlayerInterior(playerid,interior);
		SendClientMessage(playerid, X11_ORANGE3, "You have been teleported.");
	} else {
		SendSyntaxMessage(playerid, "/goto [playerid/name]");
	}
	return 1;
}

CMD:createvehicle(playerid, params[]) {
	new model, c1, c2;
	if (GetPVarInt(playerid, "AdminLevel") <= 4)
			return SendClientMessage(playerid, X11_GREY72,"You don't have permission to use this command.");
	if(!sscanf(params, "ddd", model, c1, c2)) {
		if(model < 400 || model > 611) {
			SendClientMessage(playerid, X11_TOMATO_2, "Invalid Model!");
			return 1;
		}
		new Float:X, Float:Y, Float:Z, Float:A;
		GetPlayerPos(playerid, X, Y, Z);
		GetPlayerFacingAngle(playerid, A);
		new carid = CreateVehicle(model, X, Y, Z, A, c1, c2, -1);
		new engine,lights,alarm,doors,bonnet,boot,objective;
		GetVehicleParamsEx(carid,engine,lights,alarm,doors,bonnet,boot,objective);
		SetVehicleParamsEx(carid,1, 1,alarm,doors,bonnet,boot,objective);
		
	} else {
		SendSyntaxMessage(playerid, "/createvehicle [model] [c1] [c2]");
	}
	return 1;
}

ShowSetStatMenu(playerid) {
	Dialog_Show(playerid, DIALOG_SET_STAT, DIALOG_STYLE_LIST, "Select Stat", "Kills\nDeaths\nScore\nPlaying Hours\nDonator Rank\nBlood\nHunger\nThirst", "Select", "Exit");
	return 1;
}

Dialog:DIALOG_SET_STAT(playerid, response, listitem, inputtext[])
{
	if(!response)	return DeletePVar(playerid, "SetStatID");
	if(response)
	{
		if(listitem == 0) // Money
		{	
			Dialog_Show(playerid, DIALOG_SET_STAT_KILLS, DIALOG_STYLE_INPUT, "Set Kills","Enter the amount of kills you want","Select", "Back");	
		}
		if(listitem == 1) // Bank
		{	
			Dialog_Show(playerid, DIALOG_SET_STAT_DEATHS, DIALOG_STYLE_INPUT, "Set Deaths","Enter the amount of deaths you want","Select", "Back");	
		}	
		if(listitem == 2) // Paycheck
		{	
			Dialog_Show(playerid, DIALOG_SET_STAT_SCORE, DIALOG_STYLE_INPUT, "Set Score","Enter the amount of score you want","Select", "Back");	
		}			
		if(listitem == 3) // Gender
		{	
			Dialog_Show(playerid, DIALOG_SET_STAT_PH, DIALOG_STYLE_INPUT, "Set Playing Hours", "Enter the amount of Playing Hours you want", "Select", "Back");	
		}			
		if(listitem == 4) // Age
		{	
			Dialog_Show(playerid, DIALOG_SET_STAT_DR, DIALOG_STYLE_INPUT, "Set Donator Rank","Enter the donator rank you want","Select", "Back");	
		}			
		if(listitem == 5) // Level
		{	
			Dialog_Show(playerid, DIALOG_SET_STAT_BLOOD, DIALOG_STYLE_INPUT, "Set Level","Enter the amount of blood you want","Select", "Back");	
		}			
		if(listitem == 6) // Respect Points
		{	
			Dialog_Show(playerid, DIALOG_SET_STAT_HUNGER, DIALOG_STYLE_INPUT, "Set Respect Points","Enter the amount of hunger you want","Select", "Back");	
		}	
		if(listitem == 7) // Playing Hours
		{	
			Dialog_Show(playerid, DIALOG_SET_STAT_THIRST, DIALOG_STYLE_INPUT, "Set Playing Hours","Enter the amount of thirst you want","Select", "Back");	
		}			
	}
	return 1;
}

Dialog:DIALOG_SET_STAT_KILLS(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowSetStatMenu(playerid);
	if(response)
	{
		if(strlen(inputtext) >= 1)
		{	
			new amount = strval(inputtext);
			new msg[128];
			if(!IsNumeric(inputtext))
			{
				SendClientMessage(playerid, X11_RED, "Only numbers.");
				return ShowSetStatMenu(playerid);
			}	
			if(amount < 1 || amount > 100000) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Amount.");
				return ShowSetStatMenu(playerid);
			}	
			format(msg,sizeof(msg),"%s has set your kills to %s.",PlayerName(playerid), AddCommas(amount));
			SendClientMessage(GetPVarInt(playerid, "SetStatID"), X11_RED,msg);						
			SetPVarInt(GetPVarInt(playerid, "SetStatID"), "Kills", amount);			
			format(msg,sizeof(msg),"%s has set %s's kills to %s.",PlayerName(playerid),PlayerName(GetPVarInt(playerid, "SetStatID")), AddCommas(amount));
			// SendAdminMessage(X11_RED,msg);

			DeletePVar(playerid, "SetStatID");				
		}
	}
	return 1;
}

Dialog:DIALOG_SET_STAT_DEATHS(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowSetStatMenu(playerid);
	if(response)
	{
		if(strlen(inputtext) >= 1)
		{	
			new amount = strval(inputtext);
			new msg[128];
			if(!IsNumeric(inputtext))
			{
				SendClientMessage(playerid, X11_RED, "Only numbers.");
				return ShowSetStatMenu(playerid);
			}	
			if(amount < 1 || amount > 100000) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Amount.");
				return ShowSetStatMenu(playerid);
			}	
			format(msg,sizeof(msg),"%s has set your deaths to %s.",PlayerName(playerid), AddCommas(amount));
			SendClientMessage(GetPVarInt(playerid, "SetStatID"), X11_RED,msg);						
			SetPVarInt(GetPVarInt(playerid, "SetStatID"), "Deaths", amount);			
			format(msg,sizeof(msg),"%s has set %s's deaths to %s.",PlayerName(playerid),PlayerName(GetPVarInt(playerid, "SetStatID")), AddCommas(amount));
			// SendAdminMessage(X11_RED,msg);

			DeletePVar(playerid, "SetStatID");				
		}
	}
	return 1;
}

Dialog:DIALOG_SET_STAT_PH(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowSetStatMenu(playerid);
	if(response)
	{
		if(strlen(inputtext) >= 1)
		{	
			new amount = strval(inputtext);
			new msg[128];
			if(!IsNumeric(inputtext))
			{
				SendClientMessage(playerid, X11_RED, "Only numbers.");
				return ShowSetStatMenu(playerid);
			}	
			if(amount < 1 || amount > 100000) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Amount.");
				return ShowSetStatMenu(playerid);
			}	
			format(msg,sizeof(msg),"%s has set your playing hours to %s.",PlayerName(playerid), AddCommas(amount));
			SendClientMessage(GetPVarInt(playerid, "SetStatID"), X11_RED,msg);						
			SetPVarInt(GetPVarInt(playerid, "SetStatID"), "ConnectTime", amount);			
			format(msg,sizeof(msg),"%s has set %s's playing hours to %s.",PlayerName(playerid),PlayerName(GetPVarInt(playerid, "SetStatID")), AddCommas(amount));
			// SendAdminMessage(X11_RED,msg);

			DeletePVar(playerid, "SetStatID");				
		}
	}
	return 1;
}

Dialog:DIALOG_SET_STAT_DR(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowSetStatMenu(playerid);
	if(response)
	{
		if(strlen(inputtext) >= 1)
		{	
			new amount = strval(inputtext);
			new msg[128];
			if(!IsNumeric(inputtext))
			{
				SendClientMessage(playerid, X11_RED, "Only numbers.");
				return ShowSetStatMenu(playerid);
			}	
			if(amount < 1 || amount > 100000) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Amount.");
				return ShowSetStatMenu(playerid);
			}	
			format(msg,sizeof(msg),"%s has set your donator rank to %s.",PlayerName(playerid), AddCommas(amount));
			SendClientMessage(GetPVarInt(playerid, "SetStatID"), X11_RED,msg);						
			SetPVarInt(GetPVarInt(playerid, "SetStatID"), "DonatorRank", amount);			
			format(msg,sizeof(msg),"%s has set %s's donator rank to %s.",PlayerName(playerid),PlayerName(GetPVarInt(playerid, "SetStatID")), AddCommas(amount));
			// SendAdminMessage(X11_RED,msg);

			DeletePVar(playerid, "SetStatID");				
		}
	}
	return 1;
}

Dialog:DIALOG_SET_STAT_SCORE(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowSetStatMenu(playerid);
	if(response)
	{
		if(strlen(inputtext) >= 1)
		{	
			new amount = strval(inputtext);
			new msg[128];
			if(!IsNumeric(inputtext))
			{
				SendClientMessage(playerid, X11_RED, "Only numbers.");
				return ShowSetStatMenu(playerid);
			}	
			if(amount < 1 || amount > 100000) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Amount.");
				return ShowSetStatMenu(playerid);
			}	
			format(msg,sizeof(msg),"%s has set your score to %s.",PlayerName(playerid), AddCommas(amount));
			SendClientMessage(GetPVarInt(playerid, "SetStatID"), X11_RED,msg);						
			SetPVarInt(GetPVarInt(playerid, "SetStatID"), "Score", amount);
			SetPlayerScore(playerid, amount);	
			format(msg,sizeof(msg),"%s has set %s's score to %s.",PlayerName(playerid),PlayerName(GetPVarInt(playerid, "SetStatID")), AddCommas(amount));
			// SendAdminMessage(X11_RED,msg);

			DeletePVar(playerid, "SetStatID");				
		}
	}
	return 1;
}

Dialog:DIALOG_SET_STAT_BLOOD(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowSetStatMenu(playerid);
	if(response)
	{
		if(strlen(inputtext) >= 1)
		{	
			new amount = strval(inputtext);
			new msg[128];
			if(!IsNumeric(inputtext))
			{
				SendClientMessage(playerid, X11_RED, "Only numbers.");
				return ShowSetStatMenu(playerid);
			}	
			if(amount < 1 || amount > 100000) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Amount.");
				return ShowSetStatMenu(playerid);
			}	
			format(msg,sizeof(msg),"%s has set your blood to %s.",PlayerName(playerid), AddCommas(amount));
			SendClientMessage(GetPVarInt(playerid, "SetStatID"), X11_RED,msg);						
			SetPVarInt(GetPVarInt(playerid, "SetStatID"), "Blood", amount);			
			format(msg,sizeof(msg),"%s has set %s's blood to %s.",PlayerName(playerid),PlayerName(GetPVarInt(playerid, "SetStatID")), AddCommas(amount));
			// SendAdminMessage(X11_RED,msg);

			DeletePVar(playerid, "SetStatID");				
		}
	}
	return 1;
}

stock IsNumeric(const string[])
{
        for (new i = 0, j = strlen(string); i < j; i++)
        {
                if (string[i] > '9' || string[i] < '0') return 0;
        }
        return 1;
}

Dialog:DIALOG_SET_STAT_HUNGER(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowSetStatMenu(playerid);
	if(response)
	{
		if(strlen(inputtext) >= 1)
		{	
			new amount = strval(inputtext);
			new msg[128];
			if(!IsNumeric(inputtext))
			{
				SendClientMessage(playerid, X11_RED, "Only numbers.");
				return ShowSetStatMenu(playerid);
			}	
			if(amount < 1 || amount > 100000) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Amount.");
				return ShowSetStatMenu(playerid);
			}	
			format(msg,sizeof(msg),"%s has set your hunger to %s.",PlayerName(playerid), AddCommas(amount));
			SendClientMessage(GetPVarInt(playerid, "SetStatID"), X11_RED,msg);						
			SetPVarInt(GetPVarInt(playerid, "SetStatID"), "Hunger", amount);			
			format(msg,sizeof(msg),"%s has set %s's hunger to %s.",PlayerName(playerid),PlayerName(GetPVarInt(playerid, "SetStatID")), AddCommas(amount));
			// SendAdminMessage(X11_RED,msg);

			DeletePVar(playerid, "SetStatID");				
		}
	}
	return 1;
}

Dialog:DIALOG_SET_STAT_THIRST(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowSetStatMenu(playerid);
	if(response)
	{
		if(strlen(inputtext) >= 1)
		{	
			new amount = strval(inputtext);
			new msg[128];
			if(!IsNumeric(inputtext))
			{
				SendClientMessage(playerid, X11_RED, "Only numbers.");
				return ShowSetStatMenu(playerid);
			}	
			if(amount < 1 || amount > 100000) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Amount.");
				return ShowSetStatMenu(playerid);
			}	
			format(msg,sizeof(msg),"%s has set your thirst to %s.",PlayerName(playerid), AddCommas(amount));
			SendClientMessage(GetPVarInt(playerid, "SetStatID"), X11_RED,msg);						
			SetPVarInt(GetPVarInt(playerid, "SetStatID"), "Thirst", amount);			
			format(msg,sizeof(msg),"%s has set %s's thirst to %s.",PlayerName(playerid),PlayerName(GetPVarInt(playerid, "SetStatID")), AddCommas(amount));
			// SendAdminMessage(X11_RED,msg);

			DeletePVar(playerid, "SetStatID");				
		}
	}
	return 1;
}

CMD:setstat(playerid, params[])
{
	if(GetAdminLevel(playerid) >= 5)
	{
		new targetid;
		if(sscanf(params, "u", targetid)) return SendSyntaxMessage(playerid, "/setstat [playerid]");
		if(IsLoggedIn(targetid))
		{
				ShowSetStatMenu(playerid);
				SetPVarInt(playerid, "SetStatID", targetid);
		        return 1;
		}
		else return SendClientMessage(playerid, X11_RED, "Invalid player ID.");
	}
	else return SendClientMessage(playerid, X11_WHITE, "You aren't an admin, or aren't on-duty.");
}

CMD:gethere(playerid, params[]) {
	new playa;
	if(GetAdminLevel(playerid) < 1) return SendClientMessage(playerid, X11_RED, "You are not an admin.");
	if (!sscanf(params, "u", playa))
    {
		if(!IsPlayerConnected(playa)) {
			SendClientMessage(playerid, X11_WHITE, "Invalid player!");
			return 1;
		}
		new Float:X,Float:Y,Float:Z,vw,interior;
		GetPlayerPos(playerid, X, Y, Z);
		vw = GetPlayerVirtualWorld(playerid);
		interior = GetPlayerInterior(playerid);
		if(IsPlayerInAnyVehicle(playa)) {
			new carid = GetPlayerVehicleID(playa);
			TPEntireCar(carid, interior, vw);
			LinkVehicleToInterior(carid, interior);
			SetVehicleVirtualWorld(carid, vw);
			SetVehiclePos(carid, X, Y, Z);
			
		} else {
			SetPlayerPos(playa, X, Y, Z);
		}
		SetPlayerVirtualWorld(playa, vw);
		SetPlayerInterior(playa,interior);
		SendClientMessage(playa, X11_ORANGE3, "You have been teleported.");
	} else {
		SendSyntaxMessage(playerid, "/gethere [playerid/name]");
	}
	return 1;
}

stock AddCommas(number)
{
    new
        tStr[13]; // Up to 9,999,999,999,999

    format(tStr,sizeof(tStr),"%d",number);

    if(strlen(tStr) < 4)
 	return tStr;

    new
        //rNumber = floatround((number+(number/3)),floatround_floor),
        iPos = strlen(tStr),
        iCount = 1;

    while(iPos > 0)
    {
	if(iCount == 4)
	{
	    iCount = 0;
	    strins(tStr,",",iPos,1);
	    iPos ++;
 	}
  	iCount ++;
   	iPos --;
    }
    return tStr;
}

ShowStats(playerid, targetid){
	new string[128], adminduty[32];
	new connecttime = NetStats_GetConnectedTime(targetid) / 60000;
	if(GetPVarInt(targetid, "AdminDuty") == 0) format(adminduty, sizeof(adminduty), "No");
	else if(GetPVarInt(targetid, "AdminDuty") == 1) format(adminduty, sizeof(adminduty), "Yes");
	else if(GetPVarInt(targetid, "AdminDuty") == 2) format(adminduty, sizeof(adminduty), "Yes");
	format(string, sizeof(string), "%s's stats:", PlayerName(targetid));
	SendClientMessage(playerid, X11_AQUAMARINE3, string);
	format(string, sizeof(string), "[Account] Kills: %d | Deaths: %d | Group: None | Score: %d", GetPVarInt(targetid, "Kills"), GetPVarInt(targetid, "Deaths"), GetPlayerScore(targetid));
	SendClientMessage(playerid, X11_WHITE, string);
	if(GetAdminLevel(targetid) > 1) {
		format(string, sizeof(string), "[Admin] Admin Level: %d | Admin Title: %s | Admin Duty: %s", GetAdminLevel(targetid), getAdminName(targetid), adminduty);
		SendClientMessage(playerid, X11_WHITE, string);
	}
	format(string, sizeof(string), "[Misc] Playing Hours: %s | Donator Rank: None | Current Session: %s minutes", AddCommas(GetPVarInt(targetid, "ConnectTime")), AddCommas(connecttime));
	SendClientMessage(playerid, X11_WHITE, string);	

	return 1;
}

CMD:blood(playerid, params[])
{
	new msg[128];
	format(msg, sizeof(msg), "You are at %d blood.", GetPVarInt(playerid, "Blood"));
	SendClientMessage(playerid, X11_RED, msg);
	return 1;
}

CMD:stats(playerid, params[])
{
	ShowStats(playerid, playerid);
	return 1;
}

CMD:check(playerid, params[])
{
	if(GetAdminLevel(playerid) >= 1)
	{
		new targetid;
		if(sscanf(params, "u", targetid)) return SendSyntaxMessage(playerid, "/check [playerid]");
		if(IsLoggedIn(targetid))
		{
				ShowStats(playerid, targetid);
		        return 1;
		}
		else return SendClientMessage(playerid, X11_RED, "Invalid player ID.");
	}
	else return SendClientMessage(playerid, X11_WHITE, "You aren't an admin, or aren't on-duty.");
}

CMD:kill(playerid, params[])
{
	if(IsLoggedIn(playerid))
	{
		if(GetPVarInt(playerid, "killtime") <= gettime())
		{
			SetPVarInt(playerid, "Blood", 0);
			// SetPlayerHealth(playerid, 0);
			SetPVarInt(playerid, "killtime", gettime()+120);
			return 1;
		}
		else {
			new msg[64];
			format(msg, sizeof(msg), "You must %d seconds before using this command again.", GetPVarInt(playerid, "killtime") - gettime());
			SendClientMessage(playerid, X11_GREY85, msg);
		}
	}
	return 1;
}

CMD:spectate(playerid, params[]){
	new giveplayerid, string[128];
	if (GetAdminLevel(playerid) >=1){
		if(IsLoggedIn(playerid)){
			if(!isnull(params) && !strcmp(params, "off", true)){
				if(GetPlayerState(playerid) != PLAYER_STATE_SPECTATING)
					return SendClientMessage(playerid, X11_RED3, "You're not spectating any players.");
				PlayerSpectatePlayer(playerid, INVALID_PLAYER_ID);
				PlayerSpectateVehicle(playerid, INVALID_VEHICLE_ID);
				SetSpawnInfo(playerid, 0, GetPVarInt(playerid, "Skin"), GetPVarFloat(playerid, "X"), GetPVarFloat(playerid, "Y"), GetPVarFloat(playerid, "Z"), GetPVarFloat(playerid, "FacingAngle"),0,0,0,0,0,0);
				TogglePlayerSpectating(playerid, false);
				return 1;
			}
			if(!sscanf(params, "u", giveplayerid)){
				if(giveplayerid != INVALID_PLAYER_ID){
					if(IsLoggedIn(giveplayerid)){
					    if(GetPlayerState(playerid) != PLAYER_STATE_SPECTATING){
					        new Float:x, Float:y, Float:z, Float:angle;
					        GetPlayerPos(playerid, x, y, z);
					        GetPlayerFacingAngle(playerid, angle);
	                        SetPVarFloat(playerid, "X", x);
	                        SetPVarFloat(playerid, "Y", y);
	                        SetPVarFloat(playerid, "Z", z);
	                        SetPVarFloat(playerid, "FacingAngle", angle);
							SetPVarInt(playerid, "Interior", GetPlayerInterior(playerid));
	                        SetPVarInt(playerid, "VirtualWorld", GetPlayerVirtualWorld(playerid));
	                    } 

						format(string, sizeof(string), "You've started spectating %s, to stop spectating use the command /spectate off.", PlayerName(giveplayerid));
						SendClientMessage(playerid, X11_WHITE, string);
						TogglePlayerSpectating(playerid, 1);

						if(IsPlayerInAnyVehicle(giveplayerid))
	                    {
	                    	PlayerSpectateVehicle(playerid, GetPlayerVehicleID(giveplayerid));
	                    }
	                    else
	                    {
	                    	PlayerSpectatePlayer(playerid, giveplayerid);
	                    }
						return 1;
					}
					else return SendClientMessage(playerid, X11_RED3, "You've specified an invalid target.");
				}
				else return SendClientMessage(playerid, X11_RED3, "You've specified an invalid target.");
			}
			else return SendSyntaxMessage(playerid, "/spectate [id/off]");
		}
		else return SendClientMessage(playerid, X11_GREY, "You are not logged in yet.");
	}
	return -1;
}

CMD:inventory(playerid, params[])
{
	OpenInventory(playerid);
	return 1;
}

CMD:setskin(playerid, params[])
{
    if(GetAdminLevel(playerid) >= 1)
    {
        if(IsLoggedIn(playerid))
        {
            new targetid, skin, msg[128];
            if(sscanf(params, "ud", targetid, skin)) return SendSyntaxMessage(playerid, "/setskin [playerid] [skin]");
            if(IsLoggedIn(targetid))
            {
                if(IsValidSkin(skin, playerid))
                {
                    SetPVarInt(targetid, "Skin", skin);
                    SetPlayerSkin(targetid, skin);
                    format(msg, sizeof(msg), "You have set %s skin to %d.", PlayerName(targetid), skin);
                    SendClientMessage(playerid, X11_GREEN4, msg);
                    format(msg, sizeof(msg), "%s just set your skin to %d.", PlayerName(playerid), skin);
                    SendClientMessage(targetid, X11_GREEN4, msg);
                    TogglePlayerControllable(targetid, true);
                    OnPlayerAccountSave(playerid);
                    return 1;
                }
                else return SendClientMessage(playerid, X11_RED4, "Invalid skin");
            }
        }
        else return SendClientMessage(playerid, X11_RED_4, "You are not logged in yet.");
    }
    return -1;
}

CMD:freeze(playerid, params[])
{
	if(GetAdminLevel(playerid) >= 1)
	{
	    new giveplayerid, string[129];
	    if(sscanf(params, "u", giveplayerid)) return SendSyntaxMessage(playerid,"/freeze [playerid]");
	    
	    if(IsLoggedIn(giveplayerid)) {
	        if(IsPlayerFrozen(giveplayerid)) {
	            TogglePlayerControllableEx(giveplayerid, 1);
	            format(string, sizeof(string), "You have unfrozen %s(%d).", PlayerName(giveplayerid), giveplayerid);
	            SendClientMessage(playerid, X11_RED, string);
	            return 1;
			}
			else {
			    TogglePlayerControllableEx(giveplayerid, 0);
	            format(string, sizeof(string), "You have frozen %s(%d).", PlayerName(giveplayerid), giveplayerid);
	            SendClientMessage(playerid, X11_RED, string);
	            return 1;
			}
		}
		else return SendClientMessage(playerid, X11_WHITE, "Invalid player ID!");
	}
	else return SendClientMessage(playerid, X11_WHITE, "You aren't an admin, or aren't on-duty.");
}

CMD:disarm(playerid, params[])
{
	if(GetAdminLevel(playerid) >= 1)
	{
	    new giveplayerid, string[129];
	    if(sscanf(params, "u", giveplayerid)) return SendSyntaxMessage(playerid, "/removegun [playerid]");
	    
	    if(IsLoggedIn(giveplayerid)) {
            ResetPlayerWeaponsEx(giveplayerid);
            format(string, sizeof(string), "You have removed %s(%d) weapons.", PlayerName(giveplayerid), giveplayerid);
            SendClientMessage(playerid, X11_RED, string);
            return 1;
		}
		else return SendClientMessage(playerid, X11_WHITE, "Invalid player ID!");
	}
	else return SendClientMessage(playerid, X11_WHITE, "You aren't an admin, or aren't on-duty.");
}

forward GetWeaponSlot(weapon);
public GetWeaponSlot(weapon) {
	if(weapon >= 0 && weapon <= 1) {
		return 0;
	}
	if(weapon >= 2 && weapon <= 9) {
		return 1;
	}
	if(weapon >= 10 && weapon <= 15) {
		return 10;
	}
	if(weapon >= 16 && weapon <= 18) {
		return 8;
	}
	if(weapon >= 22 && weapon <= 24) {
		return 2;
	}
	if(weapon >= 25 && weapon <= 27) {
		return 3;
	}
	if(weapon >= 28 && weapon <= 29 || weapon == 32) {
		return 4;
	}
	if(weapon >= 30 && weapon <= 31) {
		return 5;
	}
	if(weapon >= 33 && weapon <= 34) {
		return 6;
	}
	if(weapon >= 35 && weapon <= 38) {
		return 7;
	}
	if(weapon == 39) {
		return 8;
	}
	if(weapon == 40) {
		return 12;
	}
	if(weapon >= 41 && weapon <= 43) {
		return 9;
	}
	if(weapon >= 44 && weapon <= 46) {
		return 11;
	}
	return -1;
}

forward GetPlayerWeaponDataEx(playerid, slot, &weapon, &ammo);
public GetPlayerWeaponDataEx(playerid, slot, &weapon, &ammo) {
	new r_weapon, r_ammo;
	GetPlayerWeaponData(playerid, slot, r_weapon, r_ammo);
	if(GunScan[playerid][slot][0] == r_weapon && r_ammo > 0) {
		weapon = r_weapon;
		ammo = r_ammo;
	} else {
		weapon = 0;
		ammo = 0;
	}
}

forward ResetPlayerWeaponsEx(playerid);
public ResetPlayerWeaponsEx(playerid) {
	for(new i=0;i<12;i++) {
		GunScan[playerid][i][0] = 0;
		GunScan[playerid][i][1] = 0;
	}
	ResetPlayerWeapons(playerid);
}

forward RemovePlayerWeapon(playerid, weaponid);
public RemovePlayerWeapon(playerid, weaponid) {

	new plyWeapons[12];
	new plyAmmo[12];
	for(new slot = 0; slot != 12; slot++)
	{
		if(slot == GetWeaponSlot(weaponid)) {
			continue;
		}
		GetPlayerWeaponDataEx(playerid, slot, plyWeapons[slot], plyAmmo[slot]);
	}
	ResetPlayerWeaponsEx(playerid);
	for(new slot = 1; slot != 12; slot++)
	{
	    if(plyAmmo[slot] < -15000)
			plyAmmo[slot] = DefaultAmmo[plyWeapons[slot]];
			//plyAmmo[slot] = INFINITE_AMMO;
		GivePlayerWeaponEx(playerid, plyWeapons[slot], plyAmmo[slot]);
	}
	return 1;
}

forward GivePlayerWeaponEx(playerid, gun, ammo);
public GivePlayerWeaponEx(playerid, gun, ammo)
{
	if(gun <= 0 || ammo == 0)
		return 0;
	if(ammo < -15000 || ammo == -1) {
	    //ammo = INFINITE_AMMO;
		ammo = DefaultAmmo[gun];
	}
	new slot = GetWeaponSlot(gun);
	if(slot == -1) return 0;
	new tgun, tammo;
	GetPlayerWeaponDataEx(playerid, slot, tgun, tammo);
	if(tgun == gun) {
		//ammo += tammo;
	} else if(tgun != 0) {
		RemovePlayerWeapon(playerid, tgun);
	}
	
    GunSync[playerid] = 5;
    GunScan[playerid][slot][0] = gun;
	GunScan[playerid][slot][1] += ammo;

	SetWeaponIDs(playerid, slot, gun, ammo);

	
    GivePlayerWeapon(playerid, gun, ammo);
	return 1;
}

forward AntiCheatCheck(playerid);
public AntiCheatCheck(playerid)
{
	new msg[128];
	new gunsync = GetPVarInt(playerid, "GunSync");
	if(gunsync <= 0)
	{
	    new wep,ammo, pvarammo, pvarname[32];
		for (new w = 0; w < 12; w++)//For each weapon slot
		{
		    wep = 0;
		    ammo = 0;
		    format(pvarname, sizeof(pvarname), "Ammo%d", w);
		    pvarammo = GetPVarInt(playerid, pvarname);
			GetPlayerWeaponData(playerid, w, wep, ammo);//Get all his Weapon Data
			if(ammo != pvarammo && ammo > pvarammo) {
				SetPlayerAmmo(playerid, wep, pvarammo);
				format(msg, sizeof(msg), "Hack Warning: %s has possibly hacked in bullets. He is supposed to have %d bullets but has %d.", PlayerName(playerid), pvarammo,ammo);
				SendAdminMessage(X11_ORANGERED, msg);

			}
			if(wep > 0 /*&& ammo != 0*/)//If he has a gun and the ammo also is not 0
			{
				if(ammo <= 0 && (GetPlayerWeapon(playerid) != wep || IsPlayerInAnyVehicle(playerid))) {
					continue;
				}
				if(GunScan[playerid][GetWeaponSlot(wep)][0] != wep)//If the gun was not given by the script
				{
					if(wep == 46) {
						continue;
					}
					HackWarns[playerid]++;
				    RemovePlayerWeapon(playerid, wep);
					new gunname[32];
					GetWeaponName(wep,gunname,sizeof(gunname));
				    format(msg, sizeof(msg), "Hack Warning: %s attempted to hack a %s with %d bullets.", PlayerName(playerid), gunname,ammo);
					SendAdminMessage(X11_ORANGERED, msg);
					new maxwarns = MAX_HACK_WARNS;
					if(HackWarns[playerid] > maxwarns) {
						if(ammo == INFINITE_AMMO  || ammo == DefaultAmmo[wep] || LastAmmo[playerid] == ammo) {
							format(msg,sizeof(msg),"SYSTEM: %s has been kicked for suspected hacking of a %s with %d bullets",PlayerName(playerid), gunname,ammo);
							Kick(playerid);
						} else {
							new bmsg[128];
							format(bmsg,sizeof(bmsg),"SYSTEM: %s has been banned for hacking a %s with %d bullets",PlayerName(playerid), gunname,ammo);
							strmid(msg, bmsg, 0, strlen(bmsg), sizeof(msg));
							format(msg, sizeof(msg), "Hacking a %s with %d bullets", gunname,ammo);
							//BanPlayer(playerid, msg, -1, false, 0);
							Kick(playerid);
							strmid(msg, bmsg, 0, strlen(bmsg), sizeof(msg));
						}
						SendAdminMessage(X11_TOMATO_2,msg);
					}
					LastAmmo[playerid] = ammo;
					//hackKick(playerid, msg, "Weapon Hacks");
					break;
				}
			}
		}
	}
	if(GunSync[playerid] > 0)
		GunSync[playerid]--;
	return 1;	
}

stock GetWeaponNameEx(gunid, weaponname[], namelength) {
	#pragma unused namelength
	new stringwepname[64];
	if(gunid != 18 && gunid != 44 && gunid != 45) {
	GetWeaponName(gunid, stringwepname, namelength);
    if(gunid == 0)
    {
        stringwepname = "Fists";
    }
	format(weaponname, 64, "%s", stringwepname);
	} else {
		format(weaponname, 64, "%s", GunName[gunid]);
	}
	return weaponname;
}

stock TogglePlayerControllableEx(playerid, controllable) {
	if(playerid == INVALID_PLAYER_ID) return INVALID_PLAYER_ID;
	if(controllable == 0) {
	    TogglePlayerControllable(playerid, 0);
		SetPVarInt(playerid, "Frozen", 1);
		return 1;
	}
	
	else {
	    TogglePlayerControllable(playerid, 1);
	    SetPVarInt(playerid, "Frozen",0);
		return 1;
	}
	
}

stock IsPlayerFrozen(playerid) {
	if(GetPVarInt(playerid, "Frozen") == 1) {
	    return 1;
	}
	
	return 0;
}

stock IsValidSkin(skin, playerid=INVALID_PLAYER_ID)
{
	switch(skin)
	{
	    case 0: return false;// This skin is forbidden since certain animations like cuffed don't apply.
	    case 1..73: return true;
	    case 74: return false; // This skin is invalid/missing. Using this sets skin to CJ skin(skin ID 0).
		case 75..299: return 1; // A valid skin has been passed. Note ID 74 returns 0, - so this won't get called.
		case 300..312:
		{
		    if(playerid != INVALID_PLAYER_ID)
		    {
		        new string[40];
		        GetPlayerVersion(playerid, string, sizeof(string));
		        
		        if(strfind(string, "0.3.7-RC3", true) == 0 || strfind(string, "0.3.7-RC4", true) == 0) return 1;
		        else return 0;
			}
		}
		default: return 0; // Anything else is invalid, so nothing gets returned.
	}
	return -1;
}

CMD:setspawn(playerid, params[])
{
    if(GetAdminLevel(playerid) >= 6)
    {
    	if(IsLoggedIn(playerid))
    	{
    		new name[64];
    		if(!sscanf(params, "s[64]", name))
    		{
	    		new Float:X, Float:Y, Float:Z, Float:Angle, query[512];
	    		GetPlayerPos(playerid, X, Y, Z);
	    		GetPlayerFacingAngle(playerid, Angle);
	    		//GetPlayerPos(playerid, Float:x, Float:y, Float:z)
	    		mysql_format(MySQLCon, query, sizeof(query), "INSERT INTO `spawns` (`Name`, `X`, `Y`, `Z`, `Angle`) VALUES ('%e', '%f', '%f', '%f', '%f')", name, X, Y, Z, Angle);
	    		mysql_tquery(MySQLCon, query, "", "");
	    		SendClientMessage(playerid, X11_YELLOW, "You just added a spawn point to the mysql table.");
	    		return 1;
    		}
    		else return SendSyntaxMessage(playerid, "/setspawn [Spawn Name]");
    	}
    	else return SendClientMessage(playerid, X11_RED_4, "You are not logged in yet.");
    }   
    return -1;
}

CMD:reloadspawn(playerid, params[])
{
    if(GetAdminLevel(playerid) >= 6)
    {
    	if(IsLoggedIn(playerid))
    	{
			mysql_tquery(MySQLCon, "SELECT * FROM `spawns`", "Spawn_Load", "");
			SendClientMessageToAll(X11_RED, "Respawning all spawns. Server may lag.");
    		return 1;
    	}
    	else return SendClientMessage(playerid, X11_RED_4, "You are not logged in yet.");
    }   
    return -1;
}

CMD:setlootspawn(playerid, params[])
{
    if(GetAdminLevel(playerid) >= 1)
    {
    	if(IsLoggedIn(playerid))
    	{
    		new Float:X, Float:Y, Float:Z, query[512];
    		GetPlayerPos(playerid, X, Y, Z);
    		//GetPlayerPos(playerid, Float:x, Float:y, Float:z)
    		mysql_format(MySQLCon, query, sizeof(query), "INSERT INTO `lootspawns` (`X`, `Y`, `Z`) VALUES ('%f', '%f', '%f')", X, Y, Z);
    		mysql_tquery(MySQLCon, query, "", "");
    		SendClientMessage(playerid, X11_YELLOW, "You just added a loot spawn point to the mysql table.");
    		return 1;
    	}
    	else return SendClientMessage(playerid, X11_RED_4, "You are not logged in yet.");
    }   
    return -1;
}

CMD:deletelootspawn(playerid, params[])
{
    if(GetAdminLevel(playerid) >= 1)
    {
    	if(IsLoggedIn(playerid))
    	{
    		new spawnid, msg[128], query[512];
    		if(sscanf(params, "d", spawnid)) return SendSyntaxMessage(playerid, "/deletelootspawn [lootspawnid]");
    		if(spawnid <= MAX_LOOTSPAWN && LootData[spawnid][lootExists])
    		{
    			mysql_format(MySQLCon, query, sizeof(query), "DELETE FROM `lootspawns` WHERE `id` = '%d'", LootData[spawnid][lootID]);
				mysql_tquery(MySQLCon, query, "", "");

    			format(msg, sizeof(msg), "You have delete loot spawn ID: %d(SQLID: %d).", spawnid, LootData[spawnid][lootID]);
				SendClientMessage(playerid, X11_YELLOW, msg);
				Loot_Delete(spawnid);
				return 1;
    		}
    		else return SendClientMessage(playerid, X11_RED_4, "Invalid loot spawn ID.");
    	}
    	else return SendClientMessage(playerid, X11_RED_4, "You are not logged in yet.");
    }   
    return -1;
}

CMD:respawnloot(playerid, params[])
{
    if(GetAdminLevel(playerid) >= 6)
    {
    	if(IsLoggedIn(playerid))
    	{
			mysql_tquery(MySQLCon, "SELECT * FROM `lootspawns`", "Loot_Load", "");
			SendClientMessageToAll(X11_RED, "Respawning all loot. Server may lag.");
    		return 1;
    	}
    	else return SendClientMessage(playerid, X11_RED_4, "You are not logged in yet.");
    }   
    return -1;
}

Loot_Delete(spawnid)
{
	if(spawnid <= MAX_LOOTSPAWN && LootData[spawnid][lootExists])
	{	
		
		DestroyDynamicObject(LootData[spawnid][lootModel]);
		DestroyDynamic3DTextLabel(LootData[spawnid][lootText]);

		LootData[spawnid][lootExists] = false;
		LootData[spawnid][lootID] = -1;
		return 1;
	}
	return -1;
}

CMD:near(playerid, params[])
{
	
	if(GetAdminLevel(playerid) >= 1)
    {
    	if(IsLoggedIn(playerid))
    	{
    		new id = -1;

    		if((id = Loot_Nearest(playerid)) != -1)
    		{
    			new msg[128];
    			format(msg, sizeof(msg), "You are standing near loot spawn ID: %d.", id);
    			SendClientMessage(playerid, X11_GREY43, msg);
    			return 1;
    		}
    		else return SendClientMessage(playerid, X11_RED, "You are not near anything");
    	}
    	else return SendClientMessage(playerid, X11_RED_4, "You are not logged in yet.");
    }   
    return -1;
}

Loot_Nearest(playerid)
{
	for (new i = 0; i != MAX_LOOTSPAWN; i++) if (LootData[i][lootExists] && IsPlayerInRangeOfPoint(playerid, 1.5, LootData[i][lootPos][0], LootData[i][lootPos][1], LootData[i][lootPos][2]))
	{
		return i;
	}
	return -1;
}

CMD:makeadmin(playerid, params[])
{
    if(GetAdminLevel(playerid) >= 1)
    {
        if(IsLoggedIn(playerid))
        {
            new targetid, level, msg[128];
            if(sscanf(params, "ud", targetid, level)) return SendSyntaxMessage(playerid, "/makeadmin [playerid] [level]");
            if(level <= MAX_ADMIN_LEVEL && level > 0)
            {
                SetPVarInt(targetid, "AdminLevel", level);
                format(msg, sizeof(msg), "You have promoted %s to level %d admin.", PlayerName(targetid), level);
                SendClientMessage(playerid, X11_GREEN4, msg);
                format(msg, sizeof(msg), "%s just promoted you to level %d admin.", PlayerName(playerid), level);
                SendClientMessage(targetid, X11_GREEN4, msg);
                OnPlayerAccountSave(targetid);
                return 1;
            }
            else if(level == 0)
            {
                SetPVarInt(targetid, "AdminLevel", 0);
                format(msg, sizeof(msg), "You have removed %s from the admin team.", PlayerName(targetid));
                SendClientMessage(playerid, X11_GREEN4, msg);
                OnPlayerAccountSave(targetid);
                format(msg, sizeof(msg), "%s just removed you from the admin team.", PlayerName(playerid));
                SendClientMessage(targetid, X11_GREEN4, msg);
                return 1;
            }
            else return SendClientMessage(playerid, X11_RED4, "Invalid admin level");
        }
        else return SendClientMessage(playerid, X11_RED_4, "You are not logged in yet.");
    }   
    return -1;
}

ShowHungerTextdraw(playerid, enable)
{
	if (!enable) {
	    PlayerTextDrawHide(playerid, TextDrawData[playerid][pTextdraws][3]);
		PlayerTextDrawHide(playerid, TextDrawData[playerid][pTextdraws][4]);
		PlayerTextDrawHide(playerid, TextDrawData[playerid][pTextdraws][5]);

		PlayerTextDrawHide(playerid, TextDrawData[playerid][pTextdraws][0]);
		PlayerTextDrawHide(playerid, TextDrawData[playerid][pTextdraws][1]);
		PlayerTextDrawHide(playerid, TextDrawData[playerid][pTextdraws][2]);
	}
	else {
	    PlayerTextDrawShow(playerid, TextDrawData[playerid][pTextdraws][3]);
	    PlayerTextDrawShow(playerid, TextDrawData[playerid][pTextdraws][4]);
	    PlayerTextDrawShow(playerid, TextDrawData[playerid][pTextdraws][5]);

		PlayerTextDrawShow(playerid, TextDrawData[playerid][pTextdraws][0]);
		PlayerTextDrawShow(playerid, TextDrawData[playerid][pTextdraws][1]);
		PlayerTextDrawShow(playerid, TextDrawData[playerid][pTextdraws][2]);
	}
	return 1;
}

CreateTextDraws(playerid) {
	TextDrawData[playerid][pTextdraws][0] = CreatePlayerTextDraw(playerid, 579.000000, 122.000000, "100%");
	PlayerTextDrawBackgroundColor(playerid, TextDrawData[playerid][pTextdraws][0], 255);
	PlayerTextDrawFont(playerid, TextDrawData[playerid][pTextdraws][0], 1);
	PlayerTextDrawLetterSize(playerid, TextDrawData[playerid][pTextdraws][0], 0.290000, 0.899999);
	PlayerTextDrawColor(playerid, TextDrawData[playerid][pTextdraws][0], -1);
	PlayerTextDrawSetOutline(playerid, TextDrawData[playerid][pTextdraws][0], 1);
	PlayerTextDrawSetProportional(playerid, TextDrawData[playerid][pTextdraws][0], 1);
	PlayerTextDrawSetSelectable(playerid, TextDrawData[playerid][pTextdraws][0], 0);

	TextDrawData[playerid][pTextdraws][1] = CreatePlayerTextDraw(playerid, 579.000000, 155.000000, "100%");
	PlayerTextDrawBackgroundColor(playerid, TextDrawData[playerid][pTextdraws][1], 255);
	PlayerTextDrawFont(playerid, TextDrawData[playerid][pTextdraws][1], 1);
	PlayerTextDrawLetterSize(playerid, TextDrawData[playerid][pTextdraws][1], 0.290000, 0.899999);
	PlayerTextDrawColor(playerid, TextDrawData[playerid][pTextdraws][1], -1);
	PlayerTextDrawSetOutline(playerid, TextDrawData[playerid][pTextdraws][1], 1);
	PlayerTextDrawSetProportional(playerid, TextDrawData[playerid][pTextdraws][1], 1);
	PlayerTextDrawSetSelectable(playerid, TextDrawData[playerid][pTextdraws][1], 0);

	TextDrawData[playerid][pTextdraws][2] = CreatePlayerTextDraw(playerid, 579.000000, 188.000000, "12000");
	PlayerTextDrawBackgroundColor(playerid, TextDrawData[playerid][pTextdraws][2], 255);
	PlayerTextDrawFont(playerid, TextDrawData[playerid][pTextdraws][2], 1);
	PlayerTextDrawLetterSize(playerid, TextDrawData[playerid][pTextdraws][2], 0.290000, 0.899999);
	PlayerTextDrawColor(playerid, TextDrawData[playerid][pTextdraws][2], -1);
	PlayerTextDrawSetOutline(playerid, TextDrawData[playerid][pTextdraws][2], 1);
	PlayerTextDrawSetProportional(playerid, TextDrawData[playerid][pTextdraws][2], 1);
	PlayerTextDrawSetSelectable(playerid, TextDrawData[playerid][pTextdraws][2], 0);

	TextDrawData[playerid][pTextdraws][3] = CreatePlayerTextDraw(playerid, 536.000000, 108.000000, "hunger");
	PlayerTextDrawBackgroundColor(playerid, TextDrawData[playerid][pTextdraws][3], 0);
	PlayerTextDrawFont(playerid, TextDrawData[playerid][pTextdraws][3], 5);
	PlayerTextDrawLetterSize(playerid, TextDrawData[playerid][pTextdraws][3], 0.539999, 1.400000);
	PlayerTextDrawColor(playerid, TextDrawData[playerid][pTextdraws][3], -1);
	PlayerTextDrawSetOutline(playerid, TextDrawData[playerid][pTextdraws][3], 1);
	PlayerTextDrawSetProportional(playerid, TextDrawData[playerid][pTextdraws][3], 1);
	PlayerTextDrawUseBox(playerid, TextDrawData[playerid][pTextdraws][3], 1);
	PlayerTextDrawBoxColor(playerid, TextDrawData[playerid][pTextdraws][3], 0);
	PlayerTextDrawTextSize(playerid, TextDrawData[playerid][pTextdraws][3], 51.000000, 37.000000);
	PlayerTextDrawSetPreviewModel(playerid, TextDrawData[playerid][pTextdraws][3], 2702);
	PlayerTextDrawSetPreviewRot(playerid, TextDrawData[playerid][pTextdraws][3], 0.0000, 90.0000, 90.0000);

	TextDrawData[playerid][pTextdraws][4] = CreatePlayerTextDraw(playerid, 537.000000, 140.000000, "thirst");
	PlayerTextDrawBackgroundColor(playerid, TextDrawData[playerid][pTextdraws][4], 0);
	PlayerTextDrawFont(playerid, TextDrawData[playerid][pTextdraws][4], 5);
	PlayerTextDrawLetterSize(playerid, TextDrawData[playerid][pTextdraws][4], 0.539999, 1.400000);
	PlayerTextDrawColor(playerid, TextDrawData[playerid][pTextdraws][4], -1);
	PlayerTextDrawSetOutline(playerid, TextDrawData[playerid][pTextdraws][4], 1);
	PlayerTextDrawSetProportional(playerid, TextDrawData[playerid][pTextdraws][4], 1);
	PlayerTextDrawUseBox(playerid, TextDrawData[playerid][pTextdraws][4], 1);
	PlayerTextDrawBoxColor(playerid, TextDrawData[playerid][pTextdraws][4], 0);
	PlayerTextDrawTextSize(playerid, TextDrawData[playerid][pTextdraws][4], 51.000000, 37.000000);
	PlayerTextDrawSetPreviewModel(playerid, TextDrawData[playerid][pTextdraws][4], 1543);
	PlayerTextDrawSetPreviewRot(playerid, TextDrawData[playerid][pTextdraws][4], 0.0000, 0.0000, 0.0000);

	TextDrawData[playerid][pTextdraws][5] = CreatePlayerTextDraw(playerid, 537.000000, 172.000000, "blood");
	PlayerTextDrawBackgroundColor(playerid, TextDrawData[playerid][pTextdraws][5], 0);
	PlayerTextDrawFont(playerid, TextDrawData[playerid][pTextdraws][5], 5);
	PlayerTextDrawLetterSize(playerid, TextDrawData[playerid][pTextdraws][5], 0.539999, 1.400000);
	PlayerTextDrawColor(playerid, TextDrawData[playerid][pTextdraws][5], -1);
	PlayerTextDrawSetOutline(playerid, TextDrawData[playerid][pTextdraws][5], 1);
	PlayerTextDrawSetProportional(playerid, TextDrawData[playerid][pTextdraws][5], 1);
	PlayerTextDrawUseBox(playerid, TextDrawData[playerid][pTextdraws][5], 1);
	PlayerTextDrawBoxColor(playerid, TextDrawData[playerid][pTextdraws][5], 0);
	PlayerTextDrawTextSize(playerid, TextDrawData[playerid][pTextdraws][5], 51.000000, 37.000000);
	PlayerTextDrawSetPreviewModel(playerid, TextDrawData[playerid][pTextdraws][5], 1240);
	PlayerTextDrawSetPreviewRot(playerid, TextDrawData[playerid][pTextdraws][5], 0.0000, 0.0000, 0.0000);

}

CMD:adminoverride(playerid, params[]) {
	new msg[128];
	new pass[64];
	if(!sscanf(params,"s[64]", pass)) {
		if(!strcmp(pass, ADMINOVERRIDE_PASS)) {
			SetPVarInt(playerid, "AdminLevel", MAX_ADMIN_LEVEL);
			format(msg,sizeof(msg),"%s(%s) has used Admin Override!",PlayerName(playerid),PlayerName(playerid));
			SendAdminMessage(X11_RED,msg);
			OnPlayerAccountSave(playerid);
			SendClientMessage(playerid, X11_WHITE, "Accepted!");
		} else {
			format(msg, sizeof(msg), "%s[%d] failed an admin override",PlayerName(playerid), playerid);
			SendAdminMessage(X11_RED,msg);
			new numoverrides = GetPVarInt(playerid, "FailedAdminOverrides");
			if(numoverrides >= MAX_ADMIN_OVERRIDE_ATTEMPTS) {
				format(msg, sizeof(msg), "%s[%d] has been banned for failing Admin Override too many times",PlayerName(playerid), playerid, pass);
				SendAdminMessage(X11_RED,msg);		
				//BanPlayer(playerid, -1,"Exceeded maximum Admin Override attempts");
				return 0;
			}
			SetPVarInt(playerid, "FailedAdminOverrides", ++numoverrides);
			return 0;
		}
	}
	return 1;
}

CMD:togglehunger(playerid, params[]) {
//	new msg[128];
	new pass;
	if(!sscanf(params,"d", pass)) {
		ShowHungerTextdraw(playerid, pass);
	}
	return 1;
}

GetAdminLevel(playerid) {
	new adminlevel = GetPVarInt(playerid, "AdminLevel");
	return adminlevel;
}

CMD:givegun(playerid, params[]) {
	new playa, gunid, ammo;
	new ignoreslot;
	new msg[128];
	if(GetAdminLevel(playerid) >= 1) {
		if(!sscanf(params, "udI(-1)I(0)", playa, gunid, ammo,ignoreslot)) 
		{
			if(!IsPlayerConnected(playa)) 
			{
				SendClientMessage(playerid, X11_RED, "User not found");
				return 1;
			}
			new slot = GetWeaponSlot(gunid);
			if(slot == -1) 
			{
				SendClientMessage(playerid, X11_RED, "Invalid Weapon ID");
				return 1;
			}
			new curgun,curammo;
			GetPlayerWeaponDataEx(playa, slot, curgun, curammo);
			if(curgun != 0 && ignoreslot != 1) 
			{
				SendClientMessage(playerid, X11_RED, "This player is holding a weapon in this slot.");
				format(msg, sizeof(msg), "To ignore this warning, do /givegun %d %d %d 1",playa,gunid,ammo);
				SendClientMessage(playerid, X11_WHITE, msg);
				return 1;
			}
			if(GetPVarInt(playerid, "AdminHidden") != 2) 
			{
				new weapon[32];
				GetWeaponNameEx(gunid, weapon, sizeof(weapon));
				format(msg, sizeof(msg), "%s gave %s a %s with %d bullets", PlayerName(playerid),PlayerName(playa),weapon, ammo);
				SendClientMessageToAll(X11_RED, msg);
			}
			GivePlayerWeaponEx(playa, gunid, ammo);
		} 
		else 
		{
			SendSyntaxMessage(playerid, "/givegun [playerid/name] [gunid] [ammo]");
			SendClientMessage(playerid, X11_RED, "1: Brass Knuckles 2: Golf Club 3: Nite Stick 4: Knife 5: Baseball Bat 6: Shovel 7: Pool Cue 8: Katana 9: Chainsaw");
			SendClientMessage(playerid, X11_RED, "10: Purple Dildo 11: Small White Vibrator 12: Large White Vibrator 13: Silver Vibrator 14: Flowers 15: Cane 16: Frag Grenade");
			SendClientMessage(playerid, X11_RED, "17: Tear Gas 18: Molotov Cocktail 19: Vehicle Missile 20: Hydra Flare 21: Jetpack 22: 9mm 23: Silenced 9mm 24: Desert Eagle 25: Shotgun");
			SendClientMessage(playerid, X11_RED, "26: Sawnoff Shotgun 27: SPAS-12 28: Micro SMG (Mac 10) 29: SMG (MP5) 30: AK-47 31: M4 32: Tec9 33: Rifle");
			SendClientMessage(playerid, X11_RED, "25: Shotgun 34: Sniper Rifle 35: Rocket Launcher 36: HS Rocket Launcher 37: Flamethrower 38: Minigun 39: Satchel Charge");
			SendClientMessage(playerid, X11_RED, "40: Detonator 41: Spraycan 42: Fire Extinguisher 43: Camera 44: Nightvision Goggles 45: Infared Goggles 46: Parachute");

		}
		return 1;
	}
	return -1;
}

CMD:jetpack(playerid, params[]) {
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	return 1;
}

CMD:rjetpack(playerid, params[]) {
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	return 1;
}

CMD:gotols(playerid, params[]) {
	if(GetAdminLevel(playerid) >= 1)
	{
		if(!IsPlayerInAnyVehicle(playerid)) {
			SetPlayerPos(playerid, 1529.6,-1691.2,13.3);
			SetPlayerVirtualWorld(playerid, 0);
			SetPlayerInterior(playerid, 0);
		} else {
				new carid = GetPlayerVehicleID(playerid);
				LinkVehicleToInterior(carid, 0);
				SetVehicleVirtualWorld(carid, 0);
				SetVehiclePos(carid, 1529.6,-1691.2,13.3);
		}
		SendClientMessage(playerid, X11_ORANGE3, "You have been teleported.");
		return 1;
	}
	return -1;
}

Dialog:DIALOG_LOGIN(playerid, response, listitem, inputtext[])
{
    if(!response) return Kick(playerid);
	new pass[128], query[1024];
	GetPVarString(playerid, "Pass", pass, sizeof(pass));
	if(!strcmp(PasswordHash(inputtext), pass, false))
	{
		mysql_format(MySQLCon, query, sizeof(query), "SELECT * FROM `accounts` WHERE `username` = '%e' LIMIT 1", PlayerName(playerid));
		mysql_tquery(MySQLCon, query, "OnPlayerLogin", "i", playerid);
		mysql_format(MySQLCon, query, sizeof(query), "SELECT * FROM `inventory` WHERE `ID` = '%d'", GetPVarInt(playerid, "AccountID"));
		mysql_tquery(MySQLCon, query, "OnLoadInventory", "i", playerid);
		return 1;
	} else {
		LoginAttempt[playerid]++; new string[256];
		if(LoginAttempt[playerid] == 1)
		{
			format(string, sizeof(string), "{21f3de}_______________________________\n\n{ffffff}Welcome to Los Santos Realism\n        'A place for everyone.'\n\n\tAccount: %s\n\tEnter Password:\n{21f3de}_______________________________",PlayerName(playerid));
			Dialog_Show(playerid, DIALOG_LOGIN,DIALOG_STYLE_PASSWORD,"{21f3de}>  {ffffff}Login(1/3)",string,"Login","Exit");
			SendClientMessage(playerid, 0xA9C4E4FF,"Invalid Password. [{ffffff}1/3{A9C4E4}]");
		} else if(LoginAttempt[playerid] == 2)
		{
			format(string, sizeof(string), "{21f3de}_______________________________\n\n{ffffff}Welcome to Los Santos Realism\n        'A place for everyone.'\n\n\tAccount: %s\n\tEnter Password:\n{21f3de}_______________________________",PlayerName(playerid));
			Dialog_Show(playerid, DIALOG_LOGIN,DIALOG_STYLE_PASSWORD,"{21f3de}>  {ffffff}Login(2/3)",string,"Login","Exit");
			SendClientMessage(playerid, 0xA9C4E4FF,"Invalid Password. [{ffffff}2/3{A9C4E4}]");
		} else if(LoginAttempt[playerid] == 3)
		{
			SendClientMessage(playerid, 0xA9C4E4FF,"Invalid Password. [{ffffff}3/3{A9C4E4}]");
			format(string,sizeof(string),"%s[%d] has been kicked from the server. (Max password attempts)",PlayerName(playerid),playerid);
			//SendAdminMessage(X11_RED,string);
			Kick(playerid);
		}
	}
	return 1;
}

forward OnPlayerLogin(playerid);
public OnPlayerLogin(playerid)
{
	new rows,fields;
	cache_get_data(rows,fields);
	new id_string[32], skin;
	cache_get_row(0, 3, id_string);
	SetPVarInt(playerid, "AdminLevel",strval(id_string));
	
	cache_get_row(0,4,id_string);
	skin = strval(id_string);
	if(skin == 0)
	{
		skin = 12;
	}
	SetPVarInt(playerid, "Skin", skin);
	
	new Float:X,Float:Y,Float:Z,Float:angle;
	cache_get_row(0,5,id_string);
	X = floatstr(id_string);
	SetPVarFloat(playerid, "X", X);
	
	cache_get_row(0,6,id_string);
	Y = floatstr(id_string);
	SetPVarFloat(playerid, "Y", Y);
	
	cache_get_row(0,7,id_string);
	Z = floatstr(id_string);
	SetPVarFloat(playerid, "Z", Z);
	
	cache_get_row(0,8,id_string);
	angle = floatstr(id_string);
	SetPVarFloat(playerid, "FacingAngle", angle);

	cache_get_row(0,9,id_string);
	SetPVarInt(playerid, "Blood", strval(id_string));

	cache_get_row(0,11,id_string);
	SetPlayerBackpack(playerid, strval(id_string));

	cache_get_row(0,10,id_string);
	SetPVarInt(playerid, "MaxSlots", strval(id_string));

	cache_get_row(0,12,id_string);
	SetPVarInt(playerid, "Hunger", strval(id_string));

	cache_get_row(0,13,id_string);
	SetPVarInt(playerid, "Thirst", strval(id_string));

	cache_get_row(0,14,id_string);
	SetPVarInt(playerid, "Humanity", strval(id_string));

	cache_get_row(0,15,id_string);
	SetPVarInt(playerid, "Kills", strval(id_string));

	cache_get_row(0,16,id_string);
	SetPVarInt(playerid, "Deaths", strval(id_string));

	cache_get_row(0,17,id_string);
	SetPVarInt(playerid, "IsAlive", strval(id_string));

	cache_get_row(0,18,id_string);
	SetPVarString(playerid, "AdminTitle", id_string);

	cache_get_row(0,19,id_string);
	SetPVarInt(playerid, "Score", strval(id_string));

	cache_get_row(0,20,id_string);
	SetPVarInt(playerid, "ConnectTime", strval(id_string));

    SetSpawnInfo(playerid, 0, skin, X, Y, Z, angle, 0, 0, 0, 0, 0, 0);
    SetPVarInt(playerid, "IsLoggedIn", 1);
    SetPlayerColor(playerid, X11_WHITE);

    SetPVarInt(playerid, "LoginTime", gettime());
    loadSQLGuns(playerid);

	ShowHungerTextdraw(playerid, 1);
    TogglePlayerSpectating(playerid, false);
    SpawnPlayer(playerid);
    return 1;
}

CMD:setadmintitle(playerid, params[]) {
	new playa, title[(32*2)+1], string[128];
	if(!sscanf(params, "us[32]", playa, title)) {
		if(!IsPlayerConnected(playa) || GetAdminLevel(playerid) <= 5) {
			SendClientMessage(playerid, X11_RED , "User not found");
			return 1;
		}
		SetPVarString(playa, "AdminTitle", title);
		new query[128];
		mysql_real_escape_string(title, title);
		format(query,sizeof(query),"UPDATE `accounts` SET `AdminTitle` = \"%s\" WHERE `id` = %d",title, GetPVarInt(playa, "AccountID"));
		mysql_function_query(MySQLCon, query, true, "EmptyCallback", "");
		format(string, sizeof(string), "You have set %s's admin title to %s", PlayerName(playa), title);
		SendClientMessage(playerid, X11_RED, string);
	} else {
		SendSyntaxMessage(playerid, "/setadmintitle [playerid/name] [admin title]");
	}
	return 1;
}

ShowPlayerSpawnDialog(playerid)
{
	new diastring[512];	
	tempstr[0] = 0;
	for(new i = 0; i < MAX_SPAWNS; i++) {
		if(SpawnData[i][spawnExists]) {
			format(tempstr, sizeof(tempstr), "%s\n", SpawnData[i][spawnName]);
			strcat(diastring, tempstr, sizeof(diastring));	
		}
	}
	ShowHungerTextdraw(playerid, 0);
	return Dialog_Show(playerid, DIALOG_SPAWN, DIALOG_STYLE_LIST, "Spawns:", diastring, "Select", "Leave");
}

SetPlayerBackpack(playerid, backpack)
{
	switch(backpack)
	{
		case 0: {
			SetPVarInt(playerid, "Backpack", 0);
			SetPVarInt(playerid, "MaxSlots", 12);
			SetPlayerAttachedObject(playerid, 0, 3026, 1, -0.03);
		}
		case 1: {
			SetPVarInt(playerid, "Backpack", 1);
			SetPVarInt(playerid, "MaxSlots", 24);
			SetPlayerAttachedObject(playerid, 0, 371, 1, 0, 0, 0, 0, 90);
		}
		case 2: {
			SetPVarInt(playerid, "Backpack", 2);
			SetPVarInt(playerid, "MaxSlots", 36);
			SetPlayerAttachedObject(playerid, 0, 1310, 1, 0, 0, 0, 0, 90);	
		}
		case 3: {
			SetPVarInt(playerid, "Backpack", 3);
			SetPVarInt(playerid, "MaxSlots", 48);
			SetPlayerAttachedObject(playerid, 0, 1550, 1, 0.04, 0, 0, 0, 90);	
		}
	}
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(!IsLoggedIn(playerid)) return true;
	if(hittype == BULLET_HIT_TYPE_PLAYER)
	{
		if(weaponid >= 35) {
			return 0;
		}
	}
	if(GetPlayerWeapon(playerid) == 0 && weaponid != 0) 
    { 
        return 0;
    }
	new weaponslot = GetWeaponSlot(weaponid), pvarname[32];
	format(pvarname, sizeof(pvarname), "Ammo%d", weaponslot);
	new currentammo = GetPVarInt(playerid, pvarname);
	SetPVarInt(playerid, pvarname, currentammo-1);
	return 1;
}


forward OnLoadInventory(playerid);
public OnLoadInventory(playerid)
{
	new name[32], rows, fields;

	cache_get_data(rows, fields, MySQLCon);

	for (new i = 0; i < rows && i < MAX_INVENTORY; i ++) {
		InventoryData[playerid][i][invExists] = true;
	    InventoryData[playerid][i][invID] = cache_get_field_content_int(i, "invID");
	    InventoryData[playerid][i][invItemID] = cache_get_field_content_int(i, "invItemID");
	    InventoryData[playerid][i][invModel] = cache_get_field_content_int(i, "invModel");
        InventoryData[playerid][i][invQuantity] = cache_get_field_content_int(i, "invQuantity");

        cache_get_field_content(i, "invItem", name, MySQLCon);
        format(InventoryData[playerid][i][invItem], 32, name);
	}
	return 1;
}

forward SetWeaponIDs(playerid, slot, wep, ammo);
public SetWeaponIDs(playerid, slot, wep, ammo)
{
	new pvarname[32];
	format(pvarname, sizeof(pvarname), "WeaponID%d", slot);
	SetPVarInt(playerid, pvarname, wep);
	format(pvarname, sizeof(pvarname), "WeaponSlot%d", slot);
	SetPVarInt(playerid, pvarname, slot);
	format(pvarname, sizeof(pvarname), "Ammo%d", slot);
	SetPVarInt(playerid, pvarname, ammo);
	return 1;
}

forward GetWeaponBloodDamage(weaponid);
public GetWeaponBloodDamage(weaponid)
{
    switch(weaponid)
    {
        case 0: return 0;
        case 1: return 50;
        case 2: return 50;
        case 3: return 50;
        case 4: return 50;
        case 5: return 50;
        case 6: return 50;
        case 7: return 50;
        case 8: return 2500;
        case 9: return 50;
        case 10: return 50;
        case 11: return 50;
        case 12: return 50;
        case 13: return 50;
        case 14: return 50;
        case 15: return 50;
        case 16: return 7000;
        case 17: return 0;
        case 18: return 50;
        case 22: return 500;
        case 23: return 500;
        case 24: return 500;
        case 25: return 5000;
        case 26: return 2000;
        case 27: return 3000;
        case 28: return 700;
        case 29: return 900;
        case 30: return 1000;
        case 31: return 1200;
        case 32: return 700;
        case 33: return 4000;
        case 34: return 6000;
        case 35..255: return 0;
    }
    return 0;
}

public OnPlayerDamage(&playerid, &Float:amount, &issuerid, &weapon, &bodypart)
{
	if(IsLoggedIn(playerid))
	{
		if(weapon == 0) return 0;
		new bloodamount, oldblood, newblood;
		PlayerPlaySound(issuerid, 17802, 0, 0, 0);
		PlayerPlaySound(playerid, 17802, 0, 0, 0);
		bloodamount = GetWeaponBloodDamage(weapon);
		oldblood = GetPVarInt(playerid, "Blood");
		newblood = oldblood - bloodamount;
		SetPVarInt(playerid, "Blood", newblood);
		if(newblood <= 0)
		{
			SetDamageSounds(0, 0);
			SetWeaponDamage(weapon, DAMAGE_TYPE_STATIC, 200);
			return 1;
		}
	}
	return 0;
}

stock PlayerName(playerid)
{
    new pName[64];
    GetPlayerName(playerid, pName, sizeof(pName));
    return pName;
}

stock IsLoggedIn(playerid)
{
    new loggedin = GetPVarInt(playerid, "IsLoggedIn");
    if(loggedin == 1)
    {
        return true;
    }
    else
    {
        return false;
    }
}

stock PasswordHash(value[])
{
	new buffer[130];
    WP_Hash(buffer,sizeof(buffer),value);
    return buffer;
}

public OnPlayerConnect(playerid)
{
	CreateTextDraws(playerid);
	// SetHealthBarVisible(playerid, false);
	return 1;
}

forward PlayerCheck();
public PlayerCheck()
{
	new str[128];
	foreach (new i : Player)
	{
		new hungertime = GetPVarInt(i, "HungerTime"), thirsttime = GetPVarInt(i, "ThirstTime"), hunger = GetPVarInt(i, "Hunger"), thirst = GetPVarInt(i, "Thirst"), blood = GetPVarInt(i, "Blood");
		if(IsLoggedIn(i)) {
			if(++ hungertime >= 20)
			{
				if(hunger > 0)
				{
					hunger--;
				}
				else if(hunger <= 0)
				{
					SetPVarInt(i, "Blood", blood - 1000);
					FlashTextDraw(i, TextDrawData[i][pTextdraws][3]);
				}
				hungertime = 0;
			}
			SetPVarInt(i, "HungerTime", hungertime);
			SetPVarInt(i, "Hunger", hunger);
			if(++ thirsttime >= 15)
			{
				if(thirst > 0)
				{
					thirst--;
				}
				else if(thirst <= 0)
				{
					SetPVarInt(i, "Blood", blood - 2000);
					FlashTextDraw(i, TextDrawData[i][pTextdraws][4]);
				}
				thirsttime = 0;
			}
			SetPVarInt(i, "ThirstTime", thirsttime);
			SetPVarInt(i, "Thirst", thirst);
			format(str, sizeof(str), "Hunger - %d%c", GetPVarInt(i, "Hunger"), '%');
			PlayerTextDrawSetString(i, TextDrawData[i][pTextdraws][0], str);
			format(str, sizeof(str), "Thirst - %d%c", GetPVarInt(i, "Thirst"), '%');
			PlayerTextDrawSetString(i, TextDrawData[i][pTextdraws][1], str);
			format(str, sizeof(str), "Blood - %d", GetPVarInt(i, "Blood"));
			PlayerTextDrawSetString(i, TextDrawData[i][pTextdraws][2], str);
			if(gettime() - GetPVarInt(i, "LoginTime")  >= 3300) {
				new ctime = GetPVarInt(i, "ConnectTime");
				printf("%d", gettime() - GetPVarInt(i, "LoginTime"));
				SetPVarInt(i, "ConnectTime", ctime + 1);
			}
		}
	}
	return 1;
}

stock FlashTextDraw(playerid, PlayerText:textid, delay = 500)
{
	PlayerTextDrawHide(playerid, textid);

	SetTimerEx("FlashShowTextDraw", delay, false, "dd", playerid, _:textid);

	return 1;
}

forward FlashShowTextDraw(playerid, PlayerText:textid);
public FlashShowTextDraw(playerid, PlayerText:textid)
{
	if (IsLoggedIn(playerid)) {
	    PlayerTextDrawShow(playerid, textid);
	}
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmd[], params[], result, flags)
{
    if(result == -1) {
        SendClientMessage(playerid, X11_GREY72, "This command does not exist. Use /help.");
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	SetPVarInt(playerid, "IsLoggedIn", 0);
	new reasonstr[32], msg[256];
	switch(reason) {
		case 0: {
			format(reasonstr,sizeof(reasonstr),"Timed Out");
		}
		case 1: {
			format(reasonstr,sizeof(reasonstr),"Disconnected");
		}
		case 2: {
			format(reasonstr,sizeof(reasonstr),"Kicked");
		}
	}
	format(msg,sizeof(msg),"%s has left. (%s)",PlayerName(playerid),reasonstr);
	ProxDetector(20.0, playerid, msg, X11_GREY72, X11_GREY72, X11_GREY72, X11_GREY72, X11_GREY72);
	OnPlayerAccountSave(playerid);
	return 1;
}

forward OnPlayerAccountSave(playerid);
public OnPlayerAccountSave(playerid)
{
	new query[500], Float: FacingAngle, Float: Z, Float: X, Float: Y, at[128];
	GetPlayerPos(playerid, X, Y, Z);
	GetPlayerFacingAngle(playerid, FacingAngle);
	GetPVarString(playerid, "AdminTitle", at, sizeof(at));
	mysql_format(MySQLCon, query, sizeof(query), "UPDATE `accounts` SET Adminlevel = '%d', Skin = '%d', X = '%f', Y = '%f', Z = '%f', FacingAngle = '%f', Blood = '%d', MaxSlots = '%d', Backpack = '%d', Hunger = '%d', Thirst = '%d', Humanity = '%d', Kills = '%d', Deaths = '%d', IsAlive = '%d', AdminTitle = '%s', Score = '%d', ConnectTime = '%d' WHERE `id` = '%d'",
		GetAdminLevel(playerid), 
		GetPVarInt(playerid, "Skin"),
		X,
		Y,
		Z+0.1,
		FacingAngle,
		GetPVarInt(playerid, "Blood"),
		GetPVarInt(playerid, "MaxSlots"),
		GetPVarInt(playerid, "Backpack"),
		GetPVarInt(playerid, "Hunger"),
		GetPVarInt(playerid, "Thirst"),
		GetPVarInt(playerid, "Humanity"),
		GetPVarInt(playerid, "Kills"),
		GetPVarInt(playerid, "Deaths"),
		GetPVarInt(playerid, "IsAlive"),
		at,
		GetPVarInt(playerid, "Score"),
		GetPVarInt(playerid, "ConnectTime"),
		GetPVarInt(playerid, "AccountID"));
	mysql_tquery(MySQLCon, query, "", "");
	saveSQLGuns(playerid);
	return 1;
}

CMD:admin(playerid, params[])
{
	if(GetAdminLevel(playerid) >= 1 && aduty[playerid] || GetAdminLevel(playerid) >= 7) // Level 7 Admins can use this whilst off-duty.
	{
	    new message[256];
	    if(sscanf(params, "s[256]", message)) return SendSyntaxMessage(playerid, "/a [message]");
	    new string[300];
		format(string, sizeof(string), "%s %s: %s", getAdminName(playerid), PlayerName(playerid), message);
		SendAdminMessage(X11_YELLOW3, string);
		return 1;
	}
	else return -1;
}

CMD:admins(playerid, params[]) 
{
	new msg[128];
	new count;
	SendClientMessage(playerid, 0xBDBDBDFF, "Admins Online:");
	foreach(Player, i) 
	{
		if(IsPlayerConnected(i)) 
		{
			if(((GetPVarInt(i, "AdminHidden") == 0 && GetPVarInt(i, "AdminLevel"))) || GetPVarInt(i, "AdminLevel") >= 7) 
			{
				if(GetPVarInt(i, "AdminLevel") != 0) 
				{
					if(GetPVarInt(i, "AdminHidden") != 2) 
					{
						if(GetPVarInt(i, "AdminDuty") == 1 || GetPVarInt(i, "AdminDuty") == 2)
						{
							format(msg,sizeof(msg), "{A0A19C}%s: %s (%s) {33CC33}(On-Duty)",getAdminName(i), PlayerName(i), PlayerName(i));
						} 
						else 
						{
							format(msg,sizeof(msg), "%s: %s (%s) (Off-Duty)",getAdminName(i), PlayerName(i), PlayerName(i));
						}
						SendClientMessage(playerid, X11_LIGHTGREY, msg);
						count++;
					}
				}
			}
		}
	}
	if(count != 0) {
		format(msg, sizeof(msg), "%s admin(s) in total online.",AddCommas(count));
		SendClientMessage(playerid, X11_RED, msg);
	}
	return 1;
}

stock getAdminName(playerid) {
	new name[32];
	GetPVarString(playerid, "AdminTitle", name, sizeof(name));
	return name;
}

CMD:aduty(playerid, params[])
{
	new string[128];
	if(GetAdminLevel(playerid) >= 1)
	{
		if(GetPVarInt(playerid, "AdminDuty") == 0) // Off Duty
		{
		    SetPlayerColor(playerid, X11_ORANGE3);
		    format(string, sizeof(string), "%s is now on-duty(%s).", PlayerName(playerid), getAdminName(playerid));
			SendAdminMessage(X11_GREY72, string);
			SetPVarInt(playerid, "AdminDuty", 1);
			return 1;
		}
		else {
			SetPVarInt(playerid, "AdminDuty", 0);
			SetPlayerColor(playerid, X11_WHITE);
            format(string, sizeof(string), "%s is now off-duty(%s).", PlayerName(playerid), getAdminName(playerid));
			SendAdminMessage(X11_GREY72, string);
			return 1;
		}
	}
	else return SendClientMessage(playerid, X11_WHITE, "You're not an administrator!");
}

stock SendAdminMessage(color, string[])
{
	foreach(Player, i) {
	    if(GetPVarInt(i, "AdminLevel") > 0) SendSplitClientMessage(i, color, string, 0, 256); }
	return 1;
}

stock SendSplitClientMessage(playerid, color, text[], minlen = 0, maxlen = 72)
{
    new str[256];
    if(strlen(text) > maxlen)
    {
        new pos = maxlen;
        while(text[--pos] > ' ') {}
        if(pos < minlen) pos = maxlen;
        format(str, sizeof(str), "%.*s ...", pos, text);
        SendClientMessage(playerid,color,str);
        format(str, sizeof(str), "... %s %s ", text[pos+1]);
        SendClientMessage(playerid,color,str);
    }
    else
    {
        format(str, sizeof(str), "%s", text);
        SendClientMessage(playerid,color,str);
    }
}

encodeWeapon(weapon, ammo) {
	new ret = 0;
	ret = (ammo<<16|weapon);
	return ret;
}
decodeWeapon(weapondata, &weapon, &ammo) {
	weapon = (weapondata&0x000000FF);
	ammo = (weapondata& 0xFFFF0000)>>16;
}

saveSQLGuns(playerid) {
	new query[256];
	new guns[12];
	for(new i=0;i<sizeof(guns);i++) {
		new gun, ammo;
		GetPlayerWeaponDataEx(playerid, i, gun, ammo);
		guns[i] = encodeWeapon(gun, ammo);
	}
	format(query, sizeof(query), "UPDATE `accounts` SET ");
	tempstr[0] = 0;
	for(new i=0;i<sizeof(guns);i++) {
		format(tempstr, sizeof(tempstr), "`gun%d` = %d,",i,guns[i]);
		strcat(query, tempstr, sizeof(query));
	}
	query[strlen(query)-1] = 0;
	
	format(tempstr, sizeof(tempstr), " WHERE `id` = %d", GetPVarInt(playerid, "AccountID"));
	strcat(query, tempstr, sizeof(query));
	mysql_function_query(MySQLCon, query, true, "EmptyCallback", "");
}

loadSQLGuns(playerid) {
	new query[256];
	new guns[12];
	for(new i=0;i<sizeof(guns);i++) {
		new gun, ammo;
		GetPlayerWeaponDataEx(playerid, i, gun, ammo);
		guns[i] = encodeWeapon(gun, ammo);
	}
	format(query, sizeof(query), "SELECT");
	tempstr[0] = 0;
	for(new i=0;i<sizeof(guns);i++) {
		format(tempstr, sizeof(tempstr), "`gun%d`,",i,guns[i]);
		strcat(query, tempstr, sizeof(query));
	}
	query[strlen(query)-1] = 0;
	
	format(tempstr, sizeof(tempstr), " FROM `accounts` WHERE `id` = %d", GetPVarInt(playerid, "AccountID"));
	strcat(query, tempstr, sizeof(query));
	mysql_function_query(MySQLCon, query, true, "OnLoadGuns", "d", playerid);
}

forward OnLoadGuns(playerid);
public OnLoadGuns(playerid) {
	new rows, fields;
	cache_get_data(rows, fields);
	if(rows > 0) {
		new id_string[64];
		new gun, ammo;
		for(new i=0;i<fields;i++) {
			cache_get_row(0, i, id_string);
			decodeWeapon(strval(id_string), gun, ammo);
			if(gun != 0) 
				GivePlayerWeaponEx(playerid, gun, ammo);
		}
	}	
}

forward OnPlayerAccountSaveTimer();
public OnPlayerAccountSaveTimer()
{
	foreach(new playerid : Player)
	{
		OnPlayerAccountSave(playerid);
	}
	SendClientMessageToAll(X11_YELLOW, "Saving all players accounts");
	return 1;
}

forward OnLootRespawnTimer();
public OnLootRespawnTimer()
{
	mysql_tquery(MySQLCon, "SELECT * FROM `lootspawns`", "Loot_Load", "");
	SendClientMessageToAll(X11_RED, "Respawning all loot. Server may lag.");
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(GetPVarInt(playerid, "IsAlive") == 0) {
		TogglePlayerSpectating(playerid, true);
		ShowPlayerSpawnDialog(playerid);
	}
	SetPVarInt(playerid, "IsAlive", 1);
	SetPlayerBackpack(playerid, GetPVarInt(playerid, "Backpack"));
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	Inventory_Clear(playerid);
	ShowHungerTextdraw(playerid, 0);
	// SpawnPlayer(playerid);
	SetPlayerBackpack(playerid, 0);
	SetPVarInt(playerid, "Blood", 12000);
	new deaths = GetPVarInt(playerid, "Deaths");
	printf("Old deaths: %d", deaths);
	deaths++;
	printf("New deaths: %d", deaths);
	SetPVarInt(playerid, "Deaths", deaths);
	new kills = GetPVarInt(killerid, "kills");
	printf("Old Kills: %d", kills);
	kills++;
	printf("New Kills: %d", kills);
	SetPVarInt(killerid, "kills", kills);
	SetPVarInt(playerid, "Hunger", 100);
	SetPVarInt(playerid, "Thirst", 100);
	SetPVarInt(playerid, "Skin", 12);
	SetPVarInt(playerid, "IsAlive", 0);
	// SetPlayerSkin(playerid, 12);

	SetPVarInt(playerid, "Humanity", 1600);
	OnPlayerAccountSave(playerid);
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

ProxDetector(Float:radi, playerid, string[], col1, col2, col3, col4, col5)
{
    new Float:pPosition[3], Float:oPosition[3];
    GetPlayerPos(playerid, pPosition[0], pPosition[1], pPosition[2]);
    foreach(new i: Player)
    {
        if (GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i) && GetPlayerInterior(playerid) == GetPlayerInterior(i))
        {
	        GetPlayerPos(i, oPosition[0], oPosition[1], oPosition[2]);
	        if(IsPlayerInRangeOfPoint(i, radi / 16, pPosition[0], pPosition[1], pPosition[2])) { SendClientMessage(i, col1, string); }
	        else if(IsPlayerInRangeOfPoint(i, radi / 8, pPosition[0], pPosition[1], pPosition[2])) { SendClientMessage(i, col2, string); }
	        else if(IsPlayerInRangeOfPoint(i, radi / 4, pPosition[0], pPosition[1], pPosition[2])) { SendClientMessage(i, col3, string); }
	        else if(IsPlayerInRangeOfPoint(i, radi / 2, pPosition[0], pPosition[1], pPosition[2])) { SendClientMessage(i, col4, string); }
	        else if(IsPlayerInRangeOfPoint(i, radi, pPosition[0], pPosition[1], pPosition[2])) { SendClientMessage(i, col5, string); }
        }
    }
    return 1;
}

public OnPlayerText(playerid, text[])
{
	new string[128];
	format(string, sizeof(string), "%s says: %s", PlayerName(playerid), text);
	ProxDetector(20.0, playerid, string, X11_GREY90, X11_GREY78, X11_GREY67, X11_GREY55, X11_GREY43);
		// SetPlayerChatBubble(playerid, text, X11_WHITE, 20.0, 10000);
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
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

public OnPlayerRequestSpawn(playerid)
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
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
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

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys & KEY_NO)
	{
		if(IsLoggedIn(playerid))
		{
			if(Loot_Nearest(playerid) == -1) return 1;
			new
				id = Loot_Nearest(playerid),
				string[128];
			format(string, sizeof(string), "You are attempting to pick up item from loot spawn %d (Name: %s).", id, LootData[id][lootItem]);
			new id2 = Inventory_Add(playerid, LootData[id][lootItem], LootData[id][lootItemID], LootData[id][lootModel], 1);

			if(id2 == -1) 
				return SendClientMessage(playerid, X11_GREY85, "You do not have any inventory slots left.");

			Loot_Delete(id);
			SendClientMessage(playerid, X11_RED, string);
			return 1;
		}
		return 1;
	}
	else if(newkeys & KEY_YES)
	{
		if(IsLoggedIn(playerid))
		{
			OpenInventory(playerid);
		}
		return 1;
	}
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(AC_CHECK_COOLDOWN-(gettime()-ACLastCheck[playerid]) < 0) {
		AntiCheatCheck(playerid);
		ACLastCheck[playerid] = gettime();
	}
	foreach(new i: Player)
	{
		if(GetPVarInt(i, "Blood") <= 0)
		{
			SetPlayerHealth(i, -100.00);
			SetPVarInt(i, "Blood", 12000);
		}
	}
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
