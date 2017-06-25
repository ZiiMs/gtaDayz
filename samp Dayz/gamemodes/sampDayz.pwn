

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

new
    MySQLCon,
    LoginAttempt[MAX_PLAYERS];

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
	new rows,fields;
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
	
    SetSpawnInfo(playerid, 0, skin, X, Y, Z, angle, 0, 0, 0, 0, 0, 0);
    SetPVarInt(playerid, "IsLoggedIn", 1);
    printf("X: %f | Y: %f | Z: %f", X,Y,Z);
    SetPlayerColor(playerid, X11_WHITE);
    TogglePlayerSpectating(playerid, false);
    SpawnPlayer(playerid);
    return 1;
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

public OnPlayerText(playerid, text[])
{
	return 1;
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
