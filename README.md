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

### Dynamic weaponskill keybinds
**Descripton**

Provides weaponskill keybinds that change dynamically based on your current weapon. This function has the
following benefits:
- Easily use multiple weapons on one job. For example, having a dagger equipped will allow you to
use 9 buttons for dagger weaponskills, and then changing your weapon to a sword will automatically unbind those
dagger WS keybinds and then set your sword keybinds.
- Use common keybinds for a specific weapon regardless of your job (but with the ability to customize it per job).
- Have all your keybinds defined in one place instead of in each individual job file.

Override functionality is included so that you can define your own keybinds in a global file without having
to modify this library lua.

**Implementation**

In your job file after `include`ing SilverLibs and Mote libs, add the following:
```
silibs.use_dynamic_ws_keybinds = true
```
Recommend putting it in your job lua instead of globals.

If you want to use `<stnpc>` targeting instead of the default `<t>` for your weaponskills you can set the
following line of code in the same place (you can use separate targeting mode for main hand WSs vs ranged WSs):
```
silibs.main_ws_target_mode = 'stnpc'
```
or
```
silibs.ranged_ws_target_mode = 'stnpc'
```

**Usage**

Think of the keybinds defined in this library as defaults and you can override for a specific weapon's keybinds.
To do so, create a global keybind file called `CharacterName-Globals.lua` and add a table called `user_ws_bindings`.
This table must have the same format as `default_ws_bindings` in the library lua. The syntax is as follows:
```
user_ws_bindings = {
  ['Weapon Category'] = {
    ['Default'] = {
      ['keybind1'] = "WS Name",
      ['keybind2'] = "WS2 Name",
    },
    ['JOB'] = {
      ['keybind1'] = "WS3 Name",
    },
    ['/SUB'] = {
      ['keybind1'] = "WS4 Name",
    },
    ['JOB/SUB'] = {
      ['keybind1'] = "WS4 Name",
    },
  },
}
```

The category's bindings will be merged in the following order: Default -> Main Job -> Sub Job -> Main Job/Sub Job Combo.
The player's current main job and sub job are used for matching and non-matching job definitions will be ignored. Default
bindings will apply for all jobs.

In other words, the most specific definitions will overwrite all the others. A Job/Sub combo is obviously the most specific.

The order in which they are defined in your table does not matter. Overwrites will always go in the order described above.

To use a sub job binding the key must begin with '/'. For example, '/NIN' will apply those bindings if your sub job is Ninja.

The 'Default' key is case-sensitive, you must use a capital 'D'. The job and sub job keys are not case sensitive.

**Known Issues**

If any of your job luas have an "Unbind" command that unbinds any of the ws keybinds you have defined, you may run into an
issue where switching jobs results in your WS keybinds not setting properly.