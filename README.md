# SilverLibs
FFXI Windower v4 GearSwap library. Hooks into GearSwap to provide additional advanced functionality.

The SilverLibs.lua file contains functionality that is designed to be easily implemented into job files. To use any of these functions, follow the instructions below:

## Installing SilverLibs
1. The SilverLibs.lua file should be placed in the gearswap/libs folder. It will still work if you have it in the gearswap/data folder though.
2. Add the following line at the top of your gearswap file in which you wish to use the function. If you have a global file, you can put it at the top of that one instead.
```
silibs = include('SilverLibs')
```
3. Mote library is required for this to work. To enable Mote libs, add this to the top of your `get_sets` function:
```
mote_include_version = 2
include('Mote-Include.lua')
```

## Features

### Cancel WS use if out of range
**Description**

Cancels the WS command from being sent to the game if you are out of range. Normally, executing a WS when out of range results in losing your TP without actually performing the WS. This is a blocker that will prevent the action from going through and prevent gear swapping.

**Implementation**

In your job file, add the following code to the beginning of your `job_precasts` function:
```
silibs.cancel_outranged_ws(spell, eventArgs)
```

If you do not have a `job_precasts` function in your lua, you can just add that as follows:
```
function job_precast(spell, action, spellMap, eventArgs)
  silibs.cancel_outranged_ws(spell, eventArgs)
end
```

### Cancel action if blocked by status effect
**Description**

When you use a spell, item, ability, etc this will check to see if you have a status effect that blocks this action (for example, Silence status will block magic casting). If you have a blocking status effect, this function will cancel your attempted action and prevent gear swapping.

**Implementation**

In your job file, add the following code to the beginning of your `job_precasts` function:
```
silibs.cancel_on_blocking_status(spell, eventArgs)
```

If you do not have a `job_precasts` function in your lua, you can just add that as follows:
```
function job_precast(spell, action, spellMap, eventArgs)
  silibs.cancel_on_blocking_status(spell, eventArgs)
end
```

### Automatic weapon re-arming
**Descripton**

Whenever your weapons are removed, this function will re-equip whatever you previously had equipped. This covers 'main', 'sub', 'ranged', and 'ammo' slots.

**Implementation**

In your job file after `include`ing SilverLibs and Mote libs, add the following:
```
silibs.use_weapon_rearm = true
```
Recommend putting it in your job lua instead of globals.

**Usage**

Functionality can be temporarily disabled by adding a togglable weapon lock state:
```
state.WeaponLock = M(false, 'Weapon Lock')
```

And add a keybind to perform the actual toggling (WIN+W is used here but it can be anything you want):
```
send_command('bind @w gs c toggle WeaponLock')
```


**Known Issue**

The 'sub' slot sometimes does not re-equip properly. Possibly a race condition.
