

#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <Pawn.CMD>
#include <easyDialog>
#include <foreach>
#include <sscanf2>
#include <YSI\y_colours>
#include <GarageBlock>

#define mysql_host "127.0.0.1"
#define mysql_user "AlexT"
#define mysql_password "AlexT"
#define mysql_database "GTADayz"

#define MAX_ADMIN_LEVEL 9
#define ADMINOVERRIDE_PASS "eec8eb13fb975d56389a08be866cb37bd2445b46"
#define MAX_ADMIN_OVERRIDE_ATTEMPTS 3
#define MAX_HACK_WARNS 2

#define INFINITE_AMMO 22767

new
    MySQLCon,
    GunSync[MAX_PLAYERS],
    LastAmmo[MAX_PLAYERS],
    HackWarns[MAX_PLAYERS],
    Text3D:bloodtext[MAX_PLAYERS],
    GunScan[MAX_PLAYERS][13][2],
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
	800, //spray can
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
	SetGameModeText("SA-DayZ 0.0.1");
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	MySQLCon = mysql_connect(mysql_host, mysql_user, mysql_database, mysql_password);
	if(mysql_errno(MySQLCon) != 0) print("Could not connect to database!");
	if(mysql_errno(MySQLCon) == 0) print("Successfully connected to MySQL database.");
	mysql_log(LOG_ERROR | LOG_WARNING, LOG_TYPE_HTML);
	BlockGarages(true, GARAGE_TYPE_ALL, "DISABLED");
	BlockGarages(true, GARAGE_TYPE_MODSHOP, "DISABLED");
	BlockGarages(true, GARAGE_TYPE_BOMB, "DISABLED");	
	BlockGarages(true, GARAGE_TYPE_PAINT, "DISABLED");
	ManualVehicleEngineAndLights();
	EnableStuntBonusForAll(0);
    DisableInteriorEnterExits();
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
    SendRconCommand("hostname [0.3.7] San Andreas DayZ [www.sa-dayz.com]");
	return 1;
}

public OnGameModeExit()
{
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
    if(IsPlayerNPC(playerid))
	{
	    new pIP[16];
	    GetPlayerIp(playerid, pIP, 16);
	    if(!strcmp(pIP, "127.0.0.1", true)) return true;
	    else return Kick(playerid);
	}
	new query[500], pName[64];
	GetPlayerName(playerid, pName, sizeof(pName));
	mysql_format(MySQLCon, query, sizeof(query), "SELECT id, username FROM `accounts` WHERE `username` = '%e' LIMIT 1", pName);
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
        new field_int[128], pName[64];
        cache_get_row(0,0, field_int);
        SetPVarInt(playerid, "AccountID", strval(field_int));
        cache_get_row(0,2, field_int);
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
		SetPVarString(playerid, "Password",inputtext);
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
    SetSpawnInfo(playerid, 0, 24, 1536.61, -1691.2, 13.3, 78.0541, 0, 0, 0, 0, 0, 0);
    SetPVarInt(playerid, "IsLoggedIn", 1);
    SetPlayerColor(playerid, X11_WHITE);
    TogglePlayerSpectating(playerid, false);
    SpawnPlayer(playerid);
    return;
}

CMD:blood(playerid, params[])
{
	new msg[128];
	format(msg, sizeof(msg), "You are at %d blood.", GetPVarInt(playerid, "Blood"));
	SendClientMessage(playerid, X11_RED, msg);
	return 1;
}

CMD:setskin(playerid, params[])
{
    if(GetPVarInt(playerid, "AdminLevel") >= 1)
    {
        if(IsLoggedIn(playerid))
        {
            new targetid, skin, msg[128];
            if(sscanf(params, "ud", targetid, skin)) return SendClientMessage(playerid, X11_GREY_85, "/setskin [playerid] [skin]");
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
	if(GetPVarInt(playerid, "AdminLevel") >= 1)
	{
	    new giveplayerid, string[129];
	    if(sscanf(params, "u", giveplayerid)) return SendClientMessage(playerid, X11_GREY85,"/freeze [playerid]");
	    
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
	    new wep,ammo;
		for (new w = 0; w < 12; w++)//For each weapon slot
		{
		    wep = 0;
		    ammo = 0;
			GetPlayerWeaponData(playerid, w, wep, ammo);//Get all his Weapon Data
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
					SendClientMessageToAll(X11_ORANGERED, msg);
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
						SendClientMessageToAll(X11_TOMATO_2,msg);
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

CMD:makeadmin(playerid, params[])
{
    if(GetPVarInt(playerid, "AdminLevel") >= 1)
    {
        if(IsLoggedIn(playerid))
        {
            new targetid, level, msg[128];
            if(sscanf(params, "ud", targetid, level)) return SendClientMessage(playerid, X11_GREY_85, "/makeadmin [playerid] [level]");
            if(level <= MAX_ADMIN_LEVEL && level > 0)
            {
                SetPVarInt(targetid, "AdminLevel", level);
                format(msg, sizeof(msg), "You have promoted %s to level %d admin.", PlayerName(targetid), level);
                SendClientMessage(playerid, X11_GREEN4, msg);
                format(msg, sizeof(msg), "%s just promoted you to level %d admin.", PlayerName(playerid), level);
                SendClientMessage(targetid, X11_GREEN4, msg);
                return 1;
            }
            else if(level == 0)
            {
                SetPVarInt(targetid, "AdminLevel", 0);
                format(msg, sizeof(msg), "You have removed %s from the admin team.", PlayerName(targetid));
                SendClientMessage(playerid, X11_GREEN4, msg);
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

CMD:adminoverride(playerid, params[]) {
//	new msg[128];
	new pass[64];
	if(!sscanf(params,"s[64]", pass)) {
		if(!strcmp(pass, ADMINOVERRIDE_PASS)) {
			SetPVarInt(playerid, "AdminLevel", MAX_ADMIN_LEVEL);
			/*format(msg,sizeof(msg),"%s(%s) has used Admin Override!",GetPlayerNameEx(playerid, ENameType_RPName_NoMask),GetPlayerNameEx(playerid,ENameType_AccountName));
			SendAdminMessage(X11_RED,msg);*/
			SendClientMessage(playerid, X11_WHITE, "Accepted!");
		} else {
			/*format(msg, sizeof(msg), "%s[%d] failed an admin override",GetPlayerNameEx(playerid, ENameType_RPName_NoMask), playerid);
			SendAdminMessage(X11_RED,msg);*/
			new numoverrides = GetPVarInt(playerid, "FailedAdminOverrides");
			if(numoverrides >= MAX_ADMIN_OVERRIDE_ATTEMPTS) {
				/*format(msg, sizeof(msg), "%s[%d] has been banned for failing Admin Override too many times",GetPlayerNameEx(playerid, ENameType_RPName_NoMask), playerid, pass);
				SendAdminMessage(X11_RED,msg);*/			
				//BanPlayer(playerid, -1,"Exceeded maximum Admin Override attempts");
				return 0;
			}
			SetPVarInt(playerid, "FailedAdminOverrides", ++numoverrides);
			return 0;
		}
	}
	return 1;
}

CMD:givegun(playerid, params[]) {
	new playa, gunid, ammo;
	new ignoreslot;
	new msg[128];
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
		SendClientMessage(playerid, X11_GREY85,"/givegun [playerid/name] [gunid] [ammo]");
		SendClientMessage(playerid, X11_RED, "1: Brass Knuckles 2: Golf Club 3: Nite Stick 4: Knife 5: Baseball Bat 6: Shovel 7: Pool Cue 8: Katana 9: Chainsaw");
		SendClientMessage(playerid, X11_RED, "10: Purple Dildo 11: Small White Vibrator 12: Large White Vibrator 13: Silver Vibrator 14: Flowers 15: Cane 16: Frag Grenade");
		SendClientMessage(playerid, X11_RED, "17: Tear Gas 18: Molotov Cocktail 19: Vehicle Missile 20: Hydra Flare 21: Jetpack 22: 9mm 23: Silenced 9mm 24: Desert Eagle 25: Shotgun");
		SendClientMessage(playerid, X11_RED, "26: Sawnoff Shotgun 27: SPAS-12 28: Micro SMG (Mac 10) 29: SMG (MP5) 30: AK-47 31: M4 32: Tec9 33: Rifle");
		SendClientMessage(playerid, X11_RED, "25: Shotgun 34: Sniper Rifle 35: Rocket Launcher 36: HS Rocket Launcher 37: Flamethrower 38: Minigun 39: Satchel Charge");
		SendClientMessage(playerid, X11_RED, "40: Detonator 41: Spraycan 42: Fire Extinguisher 43: Camera 44: Nightvision Goggles 45: Infared Goggles 46: Parachute");

	}
	return 1;
}

Dialog:DIALOG_LOGIN(playerid, response, listitem, inputtext[])
{
    if(!response) return Kick(playerid);
	new pass[128], query[1024];
	GetPVarString(playerid, "Password", pass, sizeof(pass));
	if(!strcmp(PasswordHash(inputtext), pass, false))
	{
	    print("Login1");
		mysql_format(MySQLCon, query, sizeof(query), "SELECT * FROM `accounts` WHERE `username` = '%e' LIMIT 1", PlayerName(playerid));
		mysql_tquery(MySQLCon, query, "OnPlayerLogin", "i", playerid);
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
	new rows,fields, msg[64];
	cache_get_data(rows,fields);
	new id_string[32], skin;
	cache_get_row(0, 3, id_string);
	SetPVarInt(playerid, "AdminLevel",strval(id_string));
	
	cache_get_row(0,4,id_string);
	skin = strval(id_string);
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
	
    SetSpawnInfo(playerid, 0, skin, X, Y, Z, angle, 0, 0, 0, 0, 0, 0);
    SetPVarInt(playerid, "IsLoggedIn", 1);
    printf("X: %f | Y: %f | Z: %f", X,Y,Z);
    SetPlayerColor(playerid, X11_WHITE);

	format(msg, sizeof(msg), "Blood: %d", GetPVarInt(playerid, "Blood"));
	bloodtext[playerid] = Create3DTextLabel(msg, X11_WHITE, 0, 0, 0, 500, 0, 1);
	Attach3DTextLabelToPlayer(bloodtext[playerid], playerid, 0, 0, 0.5);

    TogglePlayerSpectating(playerid, false);
    SpawnPlayer(playerid);
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

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	if(IsLoggedIn(playerid))
	{
		new bloodamount, oldblood, newblood, bloodexts[32];
		bloodamount = GetWeaponBloodDamage(weaponid);
		PlayerPlaySound(issuerid, 17802, 0, 0, 0);
		oldblood = GetPVarInt(playerid, "Blood");
		newblood = oldblood - bloodamount;
		printf("TotalBlood: %d || WeaponID: %d", newblood, weaponid);
		format(bloodexts, sizeof(bloodexts), "Blood: %d", newblood);
		Update3DTextLabelText(bloodtext[playerid], X11_WHITE, bloodexts);
		SetPVarInt(playerid, "Blood", newblood);
		SetPlayerHealth(playerid, 100);
		if(newblood <= 0)
		{
			SetPlayerHealth(playerid, -100);
			SetPVarInt(playerid, "Blood", 12000);
		}
		new string[128];
		format(string, sizeof(string), "You are at %d blood.", newblood);
		SendClientMessage(playerid, X11_GREY85, string);
		return 1;
	}
	else return 0;
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
	new buffer[129];
    WP_Hash(buffer,sizeof(buffer),value);
    return buffer;
}

public OnPlayerConnect(playerid)
{
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
	Delete3DTextLabel(bloodtext[playerid]);
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
	new query[500], Float: FacingAngle, Float: Z, Float: X, Float: Y;
	GetPlayerPos(playerid, X, Y, Z);
	GetPlayerFacingAngle(playerid, FacingAngle);
	printf("Check Blood: %d", GetPVarInt(playerid, "Blood"));
	mysql_format(MySQLCon, query, sizeof(query), "UPDATE `accounts` SET Adminlevel = '%d', Skin = '%d', X = '%f', Y = '%f', Z = '%f', FacingAngle = '%f', Blood = '%d' WHERE `id` = '%d'",
		GetPVarInt(playerid, "AdminLevel"), 
		GetPVarInt(playerid, "Skin"),
		X,
		Y,
		Z+0.1,
		FacingAngle,
		GetPVarInt(playerid, "Blood"),
		GetPVarInt(playerid, "AccountID"));
	mysql_tquery(MySQLCon, query, "", "");
	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
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
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
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
