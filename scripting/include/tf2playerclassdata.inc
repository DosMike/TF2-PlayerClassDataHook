/**
 * The define can be used to check compatibility / interface version, in case more data is added in the future.
 */

#if defined __tf2_player_class_data_included
#endinput
#endif
#define __tf2_player_class_data_included 20220117

#include <tf2>
#include <tf2_stocks>

/** supported StringMap keys are currently:
 * maxSpeed maxHealth maxArmor maxAmmo1..maxAmmo6 building1..building6
 */
methodmap TF2PlayerClassData < StringMap {
	
	/** Set this up. Does not load class data yet, in case you want to set paritally.
	 * If class is TFClass_Unknown, the last-used class will not be set.
	 */
	public TF2PlayerClassData(TFClassType class = TFClass_Unknown) {
		StringMap map = new StringMap();
		if (class != TFClass_Unknown) map.SetValue("__player_class__", class);
		return view_as<TF2PlayerClassData>(map);
	}
	
	/**
	 * Read TFPlayerClassData_t for the specified class.
	 * You might want to do that before reading values in case they were changed
	 * by another plugin. This data is not hard linked to also allow setting up
	 * multiple instances of player class data to be applied at will.
	 *
	 * @param class - the class to load, or TFClass_Unknown to use the last-used class.
	 */
	public void Load(TFClassType class = TFClass_Unknown) {
		if (class != TFClass_Unknown) this.SetValue("__player_class__", class);
		else if (!this.GetValue("__player_class__", class)) ThrowError("Last-used class not set");
		TF2_GetPlayerClassData(class, this);
	}
	
	/**
	 * Write to given TFPlayerClassData_t for specified class.
	 *
	 * @param update  if true, will update max speed and health for all players
	 * @param class - the class to load, or TFClass_Unknown to use the last-used class.
	 */
	public void Store(bool update=false, TFClassType class = TFClass_Unknown) {
		if (class != TFClass_Unknown) this.SetValue("__player_class__", class);
		else if (!this.GetValue("__player_class__", class)) ThrowError("Last-used class not set");
		TF2_SetPlayerClassData(class, this);
		if (update) TF2_UpdatePlayerClassDataChanged();
	}
	
	/**
	 * Resets the TFPlayerClassData_t values for the specified class and loads
	 * the default values, both in memory and on this object.
	 *
	 * @param update  if true, will update max speed and health for all players
	 * @param class - the class to load, or TFClass_Unknown to use the last-used class.
	 */
	public void Reset(bool update=false, TFClassType class = TFClass_Unknown) {
		if (class != TFClass_Unknown) this.SetValue("__player_class__", class);
		else if (!this.GetValue("__player_class__", class)) ThrowError("Last-used class not set");
		TF2_ResetPlayerClassData(class);
		TF2_GetPlayerClassData(class, this);
		if (update) TF2_UpdatePlayerClassDataChanged();
	}
	
	property float MaxSpeed {
		public get() { float value; if (!this.GetValue("maxSpeed", value)) ThrowError("maxSpeed not set"); return value; }
		public set(float value) { this.SetValue("maxSpeed", value); }
	}
	property int MaxHealth {
		public get() { int value; if (!this.GetValue("maxHealth", value)) ThrowError("maxHealth not set"); return value; }
		public set(int value) { this.SetValue("maxHealth", value); }
	}
	/**
	 * known ammo types 1:primary 2:secondary 3:metal 4:grenade1
	 *
	 * @param type - natural counting ammo type (1..6 inclusive)
	 */
	public int GetMaxAmmo(int type) {
		if (type < 1 || type > 6) ThrowError("Invalid ammo type %i", type);
		char tname[] = "maxAmmo0";
		tname[7] = ('0'+type);
		int value; if (!this.GetValue(tname, value)) ThrowError("%s not set", tname); return value;
	}
	/**
	 * known ammo types 1:primary 2:secondary 3:metal 4:grenade1
	 *
	 * @param type - natural counting ammo type (1..6 inclusive)
	 */
	public void SetMaxAmmo(int type, int amount) {
		if (type < 1 || type > 6) ThrowError("Invalid ammo type %i", type);
		char tname[] = "maxAmmo0";
		tname[7] = ('0'+type);
		this.SetValue(tname, amount);
	}
	/** 
	 * know values: 2,0,1,4,4,4 for engy, 3,4,4,4,4,4 for spy, all 4 for the rest
	 * @return TFObjectType or max(TFObjectType)+1 == 4 if none
	 *
	 * @param number - natural counting index (1..6 inclusive)
	 */
	public TFObjectType GetBuildable(int number) {
		if (number < 1 || number > 6) ThrowError("Invalid buildable object number %i", number);
		char tname[] = "buildable0";
		tname[9] = ('0'+number);
		int type; if (!this.GetValue(tname, type)) ThrowError("%s not set", tname); return view_as<TFObjectType>(type);
	}
	/** 
	 * know values: 2,0,1,4,4,4 for engy, 3,4,4,4,4,4 for spy, all 4 for the rest
	 * set TFObjectType or max(TFObjectType)+1 == 4 if none
	 *
	 * @param number - natural counting index (1..6 inclusive)
	 */
	public void SetBuildable(int number, TFObjectType type) {
		if (number < 1 || number > 6) ThrowError("Invalid buildable object number %i", number);
		if (number <= 0 || number > 4) ThrowError("Invalid buildable object number %i", number);
		char tname[] = "buildable0";
		tname[9] = ('0'+number);
		this.SetValue(tname, type);
	}
}

/**
 * Read TFPlayerClassData_t for the specified class into the passed array.
 *
 * @param class  class to read
 * @param data   output buffer. Use TF2PlayerClassData
 */
native void TF2_GetPlayerClassData(TFClassType class, StringMap data);

/**
 * Write to given TFPlayerClassData_t for specified class with passed data.
 *
 * @param class  class to write to
 * @param data   input buffer. Use TF2PlayerClassData
 */
native void TF2_SetPlayerClassData(TFClassType class, StringMap data);

/**
 * Revert the data for the given class back to their defaults.
 *
 * @param class  class to revert
 */
native void TF2_ResetPlayerClassData(TFClassType class);

/**
 * Update max health and max speed for the specified player or the whole server.
 * These values will also update when touching a supply locker or they are
 * queried through any other means by the game.
 *
 * @param client  the client to update, or 0 for the whole server
 * @error if client != 0 and not ingame
 */
native void TF2_UpdatePlayerClassDataChanged(int client=0);


public SharedPlugin __pl_tf2regenthinkhook = {
	name = "tf2playerclassdatahook",
	file = "tf2playerclassdata.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};


#if !defined REQUIRE_PLUGIN
public void __pl_tf2playerclassdatahook_SetNTVOptional() {
	MarkNativeAsOptional("TF2_GetPlayerClassData");
	MarkNativeAsOptional("TF2_SetPlayerClassData");
	MarkNativeAsOptional("TF2_ResetPlayerClassData");
	MarkNativeAsOptional("TF2_UpdatePlayerClassDataChanged");
}
#endif