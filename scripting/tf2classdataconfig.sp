#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2playerclassdata>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "23w01a"

public Plugin myinfo = {
	name = "[TF2] Player Class Data Configuration",
	author = "reBane",
	description = "Control max healh, speed and ammo limit for everyone",
	version = PLUGIN_VERSION,
	url = "N/A"
}

// config keys, allow user defined "defaults" for all-class
char tf2classnames[10][12] = { "#default", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer" };

public void OnPluginStart() {
	RegAdminCmd("sm_playerclassdata_reloadconfig", ConCmd_ReloadConfig, ADMFLAG_CONFIG, "Reload the config from disk");
	
	ConVar version = CreateConVar("sm_tf2playerclassdataconfig_version", PLUGIN_VERSION, "Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	version.SetString(PLUGIN_VERSION);
	version.AddChangeHook(OnVersionChanged);
	delete version;
}
public void OnVersionChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (!StrEqual(newValue,PLUGIN_VERSION)) {
		convar.SetString(PLUGIN_VERSION);
	}
}

public void OnAllPluginsLoaded() {
	if (!LibraryExists("tf2playerclassdatahook"))
		SetFailState("TF2 PlayerClassData Hook was not found");
}

public Action ConCmd_ReloadConfig(int client, int args) {
	LoadConfig(client);
	TF2_UpdatePlayerClassDataChanged();
	ReplyToCommand(client, "[TF2 PlayerClassData] Reloaded");
	return Plugin_Handled;
}

public void OnConfigsExecuted() {
	LoadConfig(0);
	TF2_UpdatePlayerClassDataChanged();
}

public void LoadConfig(int replyTo) {
	KeyValues regenConfig = new KeyValues("PlayerClassDataConfig");
	if (!regenConfig.ImportFromFile("cfg/sourcemod/playerclassdata.cfg")) {
		if (replyTo) ReplyToCommand(replyTo, "[TF2 PlayerClassData] Failed to load config from cfg/sourcemod/playerclassdata.cfg");
		else PrintToServer("[TF2 PlayerClassData] Failed to load config from cfg/sourcemod/playerclassdata.cfg");
		delete regenConfig;
		return;
	}
	
	TF2PlayerClassData data;
	for (TFClassType clz=TFClass_Unknown; clz <= TFClass_Engineer; clz++) {
		data.Reset(clz);
		if (regenConfig.JumpToKey(tf2classnames[clz])) {
			char tmp[64];
			regenConfig.GetString("copy", tmp, sizeof(tmp));
			if (tmp[0]!=0) {
				regenConfig.GoBack();
				if (!regenConfig.JumpToKey(tmp)) {
					if (replyTo) ReplyToCommand(replyTo, "[TF2 PlayerClassData] Failed to copy section \"%s\" into \"%s\", not found", tmp, tf2classnames[clz]);
					else PrintToServer("[TF2 PlayerClassData] Failed to copy section \"%s\" into \"%s\", not found", tmp, tf2classnames[clz]);
					continue;
				}
			}
			
			if (regenConfig.JumpToKey("speed_max"))
				data.maxSpeed = regenConfig.GetFloat(NULL_STRING);
			regenConfig.GoBack();
			if (regenConfig.JumpToKey("health_max"))
				data.maxHealth = regenConfig.GetNum(NULL_STRING);
			regenConfig.GoBack();
			if (regenConfig.JumpToKey("armor_max"))
				data.maxArmor = regenConfig.GetNum(NULL_STRING);
			regenConfig.GoBack();
			
			for (int ammotype=0; ammotype<7; ammotype+=1) {
				Format(tmp,sizeof(tmp),"ammo_max_%i", ammotype);
				if (regenConfig.JumpToKey(tmp))
					data.maxAmmo[ammotype] = regenConfig.GetNum(NULL_STRING);
				regenConfig.GoBack();
			}
			
			if (clz == TFClass_Unknown) {
				//for all classes
				for (TFClassType clzi = TFClass_Scout; clzi <= TFClass_Engineer; clzi += 1)
					data.Store(clzi);
			} else {
				//only for this class
				data.Store(clz);
			}
			
//			if (replyTo) ReplyToCommand(replyTo, "[TF2 PlayerClassData] %s : spd %.0f hp %i arm %i ammo [ %i %i %i %i %i %i %i ]", tf2classnames[clz], data.maxSpeed, data.maxHealth, data.maxArmor, data.maxAmmo[0], data.maxAmmo[1], data.maxAmmo[2], data.maxAmmo[3], data.maxAmmo[4], data.maxAmmo[5], data.maxAmmo[6]);
//			else PrintToServer("[TF2 PlayerClassData] %s : spd %.0f hp %i arm %i ammo [ %i %i %i %i %i %i %i ]", tf2classnames[clz], data.maxSpeed, data.maxHealth, data.maxArmor, data.maxAmmo[0], data.maxAmmo[1], data.maxAmmo[2], data.maxAmmo[3], data.maxAmmo[4], data.maxAmmo[5], data.maxAmmo[6]);
		}
	}
	delete regenConfig;
}