//reimplementation of RegenThink to allow fine grained callbacks and control

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "23w02a"

public Plugin myinfo = {
	name = "[TF2] PlayerClassData Hooks",
	author = "reBane",
	description = "Library to manipulate default health, speed and ammo for classes",
	version = PLUGIN_VERSION,
	url = "N/A"
}

#define TF2_NUM_AMMO_TYPES 7

enum struct PlayerClassData {
	float maxSpeed;
	int maxHealth;
	int maxArmor;
	int maxAmmo[TF2_NUM_AMMO_TYPES];
}
PlayerClassData pcd_defaults[10];

Handle sc_GetPlayerClassData;
Handle sc_TF2PlayerSetSpeed;

int off_m_flMaxSpeed;
int off_m_nMaxHealth;
int off_m_nMaxArmor;
int off_m_nMaxAmmo;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("TF2_GetPlayerClassData", Native_GetPlayerClassData);
	CreateNative("TF2_SetPlayerClassData", Native_SetPlayerClassData);
	CreateNative("TF2_ResetPlayerClassData", Native_ResetPlayerClassData);
	CreateNative("TF2_UpdatePlayerClassDataChanged", Native_UpdatePlayer);
	
	RegPluginLibrary("tf2playerclassdatahook");
	return APLRes_Success;
}

public void OnPluginStart() {
	GameData data = new GameData("tf2pcdh.games");
	
	// allows us to use the engines scheduler to re-schedule the think function
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "GetPlayerClassData(int)");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); //class int
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); //returns class ptr
	if ((sc_GetPlayerClassData = EndPrepSDKCall()) == INVALID_HANDLE)
		SetFailState("Failed to prepare call to GetPlayerClassData(int)");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed()");
	if ((sc_TF2PlayerSetSpeed = EndPrepSDKCall()) == INVALID_HANDLE)
		SetFailState("Failed to prepare call to CTFPlayer::TeamFortress_SetSpeed()");
	
	//unmapped offsets
	off_m_flMaxSpeed = data.GetOffset("TFPlayerClassData_t::m_flMaxSpeed");
	off_m_nMaxHealth = data.GetOffset("TFPlayerClassData_t::m_nMaxHealth");
	off_m_nMaxArmor = data.GetOffset("TFPlayerClassData_t::m_nMaxArmor");
	off_m_nMaxAmmo = data.GetOffset("TFPlayerClassData_t::m_nMaxAmmo[]");
	
	delete data;
	
	ConVar version = CreateConVar("sm_tf2playerclassdatahook_version", PLUGIN_VERSION, "Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	version.SetString(PLUGIN_VERSION);
	version.AddChangeHook(OnVersionChanged);
	delete version;
	
	
	//load default value
	for (int class = 1; class <= 9; class += 1) {
		BackupPCD(view_as<TFClassType>(class));
	}
}
public void OnVersionChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (!StrEqual(newValue,PLUGIN_VERSION)) {
		convar.SetString(PLUGIN_VERSION);
	}
}

public void OnPluginEnd() {
	//restore class data
	for (int class = 1; class <= 9; class += 1) {
		RestorePCD(view_as<TFClassType>(class));
	}
}

Address GetPlayerClassData(int class) {
	Address result = SDKCall(sc_GetPlayerClassData, class);
	if (result == Address_Null) ThrowError("Could not read class data %i", class);
	return result;
}

void UpdatePlayer(int client) {
	PlayerClassData data;
	if (TF2_GetClientTeam(client)>TFTeam_Spectator && IsPlayerAlive(client)) {
		LoadPCD(TF2_GetPlayerClass(client), data);
		int res = GetPlayerResourceEntity();
		SetEntProp(res, Prop_Send, "m_iMaxHealth", data.maxHealth, .element=client);
		SDKCall(sc_TF2PlayerSetSpeed, client); //update max speed
	}
}

static void BackupPCD(TFClassType class) {
	int index = view_as<int>(class);
	LoadPCD(class, pcd_defaults[index]);
}
static void RestorePCD(TFClassType class) {
	int index = view_as<int>(class);
	StorePCD(class, pcd_defaults[index]);
}

static void LoadPCD(TFClassType class, PlayerClassData data) {
	if (class == TFClass_Unknown) return;
	Address structptr = GetPlayerClassData(view_as<int>(class));
	data.maxSpeed = LoadFromAddress(structptr + off_m_flMaxSpeed, NumberType_Int32);
	data.maxHealth = LoadFromAddress(structptr + off_m_nMaxHealth, NumberType_Int32);
	data.maxArmor = LoadFromAddress(structptr + off_m_nMaxArmor, NumberType_Int32);
	for (int type=0; type<TF2_NUM_AMMO_TYPES; type+=1) {
		data.maxAmmo[type] = LoadFromAddress(structptr + off_m_nMaxAmmo + 4 * type, NumberType_Int32);
	}
}
static void StorePCD(TFClassType class, PlayerClassData data) {
	if (class == TFClass_Unknown) return;
	Address structptr = GetPlayerClassData(view_as<int>(class));
	if (data.maxSpeed > 520.0) data.maxSpeed = 520.0; // bigger values are not possible
	StoreToAddress(structptr + off_m_flMaxSpeed, data.maxSpeed, NumberType_Int32, false);
	StoreToAddress(structptr + off_m_nMaxHealth, data.maxHealth, NumberType_Int32, false);
	StoreToAddress(structptr + off_m_nMaxArmor, data.maxArmor, NumberType_Int32, false);
	for (int type=0; type<TF2_NUM_AMMO_TYPES; type+=1) {
		StoreToAddress(structptr + off_m_nMaxAmmo + 4 * type, data.maxAmmo[type], NumberType_Int32, false);
	}
}

any Native_GetPlayerClassData(Handle plugin, int numArgs) {
	PlayerClassData data;
	TFClassType class = GetNativeCell(1);
	LoadPCD(class, data);
	int error;
	if ((error = SetNativeArray(2, data, sizeof(PlayerClassData))) != SP_ERROR_NONE)
		ThrowNativeError(error, "PlayerClassData array invalid or outdated");
	return 0;
}
any Native_SetPlayerClassData(Handle plugin, int numArgs) {
	PlayerClassData data;
	TFClassType class = GetNativeCell(1);
	int error;
	if ((error = GetNativeArray(2, data, sizeof(PlayerClassData))) != SP_ERROR_NONE)
		ThrowNativeError(error, "PlayerClassData array invalid or outdated");
	StorePCD(class, data);
	return 0;
}
any Native_ResetPlayerClassData(Handle plugin, int numArgs) {
	TFClassType class = GetNativeCell(1);
	RestorePCD(class);
	return 0;
}

any Native_UpdatePlayer(Handle plugin, int numArgs) {
	int client = GetNativeCell(1);
	
	if (0<client<=MaxClients) {
		//update single client
		if (!IsClientInGame(client))
			ThrowNativeError(SP_ERROR_INDEX, "Client not in-game");
		UpdatePlayer(client);
	} else if (client == 0) {
		//update all clients
		for (client = 1; client <= MaxClients; client+=1) {
			if (IsClientInGame(client))
				UpdatePlayer(client);
		}
	} else
		ThrowNativeError(SP_ERROR_INDEX, "Invalid client index");
	return 0;
}