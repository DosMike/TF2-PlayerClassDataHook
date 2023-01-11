# TF2 PlayerClassData

Replace some TFPlayerClassData_t values using plugins.

This includes the default values, per class, for:
* max speed
* max health
* max armor (unused in TF2)
* max ammo (per type; primary, secondary, metal, idk what 4-7 do)

## Why is this interesting?

The default approach is to manipulate value on the client after spawning using EntProps or attributes.
This can mess with attributes on items, making certain manipulations rather inconvenient.

If you want to rebalance the game, you can now do so using the base values, keeping maximum compatibility
with any items or other plugins that apply attributes to the player without things breaking.

If you want to set the maximum speed above 520 you will need another plugin that removes that specific
hardcoded limit: [TF2 Move Speed Unlocker](https://forums.alliedmods.net/showthread.php?p=2659562)

## Installing

Drop plugin and gamedata file on your server. By default the plugin does nothing.

## Module

You can use TF2ClassDataConfig to change the Player Class Data Values using a config.

Put the config at `cfg/sourcemod/playerclassdata.cfg`

You can reload the config by reloading the plugin or using `sm_playerclassdata_reloadconfig`.
The command by default has ADMFLAG_CONFIG.

Yes, the first ammo type is 0. That's just where software likes to start counting.

You can just remove class sections or entries that you want to keep on default values.

```
"PlayerClassDataConfig"
{
	//"#default" {
	// you can use a defaul section to apply values to all classes before class specific overrides
	//}
	
	// if you create a section with a name not matching a class name, you can will it with template values
	// and copy the values into a class section using the entry like this:
	//    scout {
	//        "copy" "example"
	//    }
	
	// supported keys: speed_max, health_max, armor_max, ammo_max_0, ... ammo_max_6
	
	scout {
		speed_max 400
		health_max 125
		ammo_max_0 32
		ammo_max_1 36
		ammo_max_2 100
	}
	sniper {
		speed_max 300
		health_max 125
		ammo_max_0 25
		ammo_max_1 75
		ammo_max_2 100
	}
	soldier {
		speed_max 240
		health_max 200
		ammo_max_0 20
		ammo_max_1 32
		ammo_max_2 100
	}
	demoman {
		speed_max 280
		health_max 175
		ammo_max_0 16
		ammo_max_1 24
		ammo_max_2 100
	}
	medic {
		speed_max 320
		health_max 150
		ammo_max_0 150
		ammo_max_1 150
		ammo_max_2 100
	}
	heavy {
		speed_max 230
		health_max 300
		ammo_max_0 200
		ammo_max_1 32
		ammo_max_2 100
	}
	pyro {
		speed_max 300
		health_max 175
		ammo_max_0 200
		ammo_max_1 32
		ammo_max_2 100
	}
	spy {
		speed_max 320
		health_max 125
		ammo_max_0 20
		ammo_max_1 24
		ammo_max_2 100
	}
	engineer {
		speed_max 300
		health_max 125
		ammo_max_0 32
		ammo_max_1 200
		ammo_max_2 200
	}
}
```
