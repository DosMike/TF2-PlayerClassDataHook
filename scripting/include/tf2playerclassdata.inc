/**
 * The define can be used to check compatibility / interface version, in case more data is added in the future.
 */

#if defined __tf2_player_class_data_included
#endinput
#endif
#define __tf2_player_class_data_included 20220110

#include <tf2>

enum struct TF2PlayerClassData {
	float maxSpeed;
	int maxHealth;
	int maxArmor;
	int maxAmmo[7];
	
	/**
	 * Read TFPlayerClassData_t for the specified class.
	 *
	 * @param class  class to read
	 */
	void Load(TFClassType class) {
		TF2_GetPlayerClassData(class, this);
	}
	/**
	 * Write to given TFPlayerClassData_t for specified class.
	 *
	 * @param class   class to write to
	 * @param update  if true, will update max speed and health for all players
	 */
	void Store(TFClassType class, bool update=false) {
		TF2_SetPlayerClassData(class, this);
		if (update) TF2_UpdatePlayerClassDataChanged();
	}
	
	/**
	 * Resets the TFPlayerClassData_t values for the specified class and loads
	 * the default values into this struct.
	 *
	 * @param class  the class to reset
	 * @param update  if true, will update max speed and health for all players
	 */
	void Reset(TFClassType class, bool update=false) {
		TF2_ResetPlayerClassData(class);
		TF2_GetPlayerClassData(class, this);
		if (update) TF2_UpdatePlayerClassDataChanged();
	}
}

/**
 * Read TFPlayerClassData_t for the specified class into the passed array.
 *
 * @param class  class to read
 * @param data   output buffer. Use TF2PlayerClassData
 */
native void TF2_GetPlayerClassData(TFClassType class, any data[sizeof(TF2PlayerClassData)]);

/**
 * Write to given TFPlayerClassData_t for specified class with passed data.
 *
 * @param class  class to write to
 * @param data   input buffer. Use TF2PlayerClassData
 */
native void TF2_SetPlayerClassData(TFClassType class, any data[sizeof(TF2PlayerClassData)]);

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