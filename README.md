# SilverLibs
FFXI Windower v4 GearSwap library. Hooks into GearSwap to provide additional advanced functionality.

The SilverLibs.lua file contains functionality that is designed to be easily implemented into job files. To use any of these functions, follow the instructions below.

You may reference my personal GearSwap job files if using Mote's libraries for help implementing these features, you can find them at https://github.com/shastaxc/gearswap-data

There are no solid examples for implementing this with Selindrile's libraries but it should work as well.

## Installing SilverLibs

One of either Mote library or Selindrile library is required for SilverLibs to work. See below for implementation instructions for whichever library you choose.

### Using Mote's Library

If you choose to use Mote's library, you do not need to download anything because those files are included with GearSwap. To enable Mote features, your job lua must have a `get_sets` function at the top of your file, and you must import Mote's Include file there and set the version number. Here is an example::
```lua
function get_sets()
  -- Load and initialize Mote library
  mote_include_version = 2
  include('Mote-Include.lua') -- Executes job_setup, user_setup, init_gear_sets
end
```

With Mote library now set up, a few more steps must be completed to integrate SilverLibs into your job files:

1. The SilverLibs.lua file should be placed in the gearswap/libs folder.
2. Add the following line at the top of your gearswap lua file in which you wish to use the function. If you have a global file, you can put it at the top of that one instead.
```lua
silibs = include('SilverLibs')
```
3. Add a few lines of code into all your job luas so that when you enable features, they have the ability to pull info from your lua where needed. Please add the following (and if the functions specified don't exist, they will need to be created):
* Inside your function `job_precast`, at the top of the function add:
```lua
  silibs.precast_hook(spell, action, spellMap, eventArgs)
```
* Inside your function `job_post_precast`, at the bottom of the function just before the `end` that closes it, add:
```lua
  silibs.post_precast_hook(spell, action, spellMap, eventArgs)
```
* Inside your function `job_midcast`, at the top of the function add:
```lua
  silibs.midcast_hook(spell, action, spellMap, eventArgs)
```
* Inside your function `job_post_midcast`, at the bottom of the function just before the `end` that closes it, add:
```lua
  silibs.post_midcast_hook(spell, action, spellMap, eventArgs)
```

### Using Selindrile's Libraries
Setting up Selindrile's library take a little more effort than Mote's so you should reference his documentation directly at https://github.com/Selindrile/GearSwap

With Selindrile library now set up, a few more steps must be completed to integrate SilverLibs into your job files:

1. The SilverLibs.lua file should be placed in the gearswap/libs folder.
2. Add the following line at the top of your gearswap Charname_Job_Gear.lua file in which you wish to use the function. If you have a global file, you can put it at the top of that one instead.
```lua
silibs = include('SilverLibs')
```
3. Add a few lines of code into all your job luas so that when you enable features, they have the ability to pull info from your lua where needed. Please add the following (and if the functions specified don't exist, they will need to be created):
* Inside your function `user_job_precast`, at the top of the function add:
```lua
  silibs.precast_hook(spell, nil, spellMap, eventArgs)
```
* Inside your function `extra_user_post_precast`, at the bottom of the function just before the `end` that closes it, add:
```lua
  silibs.post_precast_hook(spell, nil, spellMap, eventArgs)
```
* Inside your function `user_job_midcast`, at the top of the function add:
```lua
  silibs.midcast_hook(spell, nil, spellMap, eventArgs)
```
* Inside your function `extra_user_post_midcast`, at the bottom of the function just before the `end` that closes it, add:
```lua
  silibs.post_midcast_hook(spell, nil, spellMap, eventArgs)
```

## Features

### Cancel WS use if out of range
**Description**

Cancels the WS command from being sent to the game if you are out of range. Normally, executing a WS when out of range results in losing your TP without actually performing the WS. This is a blocker that will prevent the action from going through and prevent gear swapping.

**Implementation**

__If Using Mote Libs__

Ensure you have the silibs precast hook in your job lua. See the "Installing SilverLibs" section above for more details.

In your job file at the beginning of the `job_setup` function, add the following:
```lua
silibs.enable_cancel_outranged_ws()
```
If you do not have a `job_setup` function, just go ahead and create one underneath (not inside of) `get_sets`.
```lua
function job_setup()
  silibs.enable_cancel_outranged_ws()
end
```

__If Using Selindrile Libs__

Ensure you have the silibs precast hook in your job lua. See the "Installing SilverLibs" section above for more details.

In your char_job_gear.lua file at the beginning of the `user_job_setup` function, add the following:
```lua
silibs.enable_cancel_outranged_ws()
```
If you do not have a `user_job_setup` function, just go ahead and create one.
```lua
function user_job_setup()
  silibs.enable_cancel_outranged_ws()
end
```


### Cancel action if blocked by status effect
**Description**

When you use a spell, item, ability, etc this will check to see if you have a status effect that blocks this action (for example, Silence status will block magic casting). If you have a blocking status effect, this function will cancel your attempted action and prevent gear swapping.

**Implementation**

__If Using Mote Libs__

In your job file at the beginning of the `job_setup` function, add the following:
```lua
silibs.enable_cancel_on_blocking_status()
```
If you do not have a `job_setup` function, just go ahead and create one underneath (not inside of) `get_sets` like this:
```lua
function job_setup()
  silibs.enable_cancel_on_blocking_status()
end
```

__If Using Selindrile Libs__

Ensure you have the silibs precast hook in your job lua. See the "Installing SilverLibs" section above for more details.

In your char_job_gear.lua file at the beginning of the `user_job_setup` function, add the following:
```lua
  silibs.enable_cancel_on_blocking_status()
```
If you do not have a `user_job_setup` function, just go ahead and create one.
```lua
function user_job_setup()
  silibs.enable_cancel_on_blocking_status()
end
```


### Automatic weapon re-arming
**Descripton**

Whenever your weapons are removed, this function will re-equip whatever you previously had equipped. This covers 'main', 'sub', 'ranged', and 'ammo' slots.

**Implementation**

__If Using Mote Libs__

In your job file at the beginning of the `job_setup` function, add the following:
```lua
silibs.enable_weapon_rearm()
```
If you do not have a `job_setup` function, just go ahead and create one underneath `get_sets` like this:
```lua
function job_setup()
  silibs.enable_weapon_rearm()
end
```

__If Using Selindrile Libs__

Ensure you have the silibs precast hook in your job lua. See the "Installing SilverLibs" section above for more details.

In your char_job_gear.lua file at the beginning of the `user_job_setup` function, add the following:
```lua
  silibs.enable_weapon_rearm()
```
If you do not have a `user_job_setup` function, just go ahead and create one.
```lua
function user_job_setup()
  silibs.enable_weapon_rearm()
end
```

**Usage**

Simply including the "enable" line from the Implementation section above will allow the re-arming to work. However, if you want more control to turn this function on and off, you can do so with the following command: `gs c toggle RearmingLock`

You can tie this command to a keybind by adding the following line to your `job_setup` function (WIN+W is used here but it can be anything you want):
```lua
send_command('bind @w gs c toggle RearmingLock')
```


### Lockstyle Setting
**Description**

Sets your lockstyle on job or subjob change. Also reapplies your lockstyle when encumbrance changes (which normally breaks lockstyle).

**Implementation**

__If Using Mote Libs__

In your job lua, anywhere in the `user_setup` function, add the following:
```lua
  silibs.set_lockstyle(n)
```
If you do not have a `user_setup` function, just go ahead and create one like this:
```lua
function user_setup()
  silibs.set_lockstyle(n)
end
```
Replace `n` with a number 1-100 indicating the lockstyle set number you wish to use for that job. You must create the lockstyle set using the in-game menus found in Main Menu -> Macros -> Edit Equip. Set.

__If Using Selindrile Libs__

TODO


### Waltz Refiner
**Description**

Using any Curing Waltz will be intercepted by SilverLibs and will automatically use smart logic to determine the appropriate tier of Waltz to use in order to save you TP while still accomplishing your goal!

**Implementation**

__If Using Mote Libs__

In your job lua, anywhere in the `job_setup` function, add the following:
```lua
silibs.enable_waltz_refiner({
  ['base_chr'] = 100,
  ['base_vit'] = 100,
  ['bonus_chr'] = 100,
  ['bonus_vit'] = 100,
  ['waltz_potency'] = 25,
  ['waltz_self_potency'] = 15,
  ['est_non_party_target_hp'] = 2000,
})
```
If you do not have a `job_setup` function, just go ahead and create one like this:
```lua
function job_setup()
  -- Job initialization stuff goes here
end
```
Override the numbers based on your own stats while wearing your Curing Waltz gear set. Any of these settings that are omitted will cause the refiner to use defaults (which are the numbers listed in the code snippet above).

`base_chr` and `base_vit` are your character's CHR and VIT without gear on whatever job you choose to implement this function. `bonus_chr`, `bonus_vit`, `waltz_potency`, and `waltz_self_potency` are the bonuses from gear in your Curing Waltz set.

__If Using Selindrile Libs__

Ensure you have the silibs precast hook in your job lua. See the "Installing SilverLibs" section above for more details.

In your char_job_gear.lua file at the beginning of the `user_job_setup` function, add the following:
```lua
silibs.enable_waltz_refiner({
  ['base_chr'] = 100,
  ['base_vit'] = 100,
  ['bonus_chr'] = 100,
  ['bonus_vit'] = 100,
  ['waltz_potency'] = 25,
  ['waltz_self_potency'] = 15,
  ['est_non_party_target_hp'] = 2000,
})
```
If you do not have a `user_job_setup` function, just go ahead and create one like this:
```lua
function user_job_setup()
  -- Job initialization stuff goes here
end
```

**Details on How It Works**

First, the available Curing Waltz tiers you have available is determined based on your DNC level (either main or sub job). The refiner will use some smart logic to estimate how much HP you can cure with the different tiers of Curing Waltz. Then it will detect how much HP your target is missing, and needs cured. It will select the best tier of Curing Waltz to heal your target to full without wasting too much TP. If the best match is on cooldown, it will go up in tiers to find an available ability. If none are available, it will check down the tiers instead.

**Caveats**

This function is 100% accurate when curing yourself. However, if you are curing another player, some assumptions must be made because the game does not provide all the necessary information about other players in this context. Mainly, the target's VIT affects the amount cured and that data is not sent to you. Also, if the player is not in your party/alliance, we cannot know the target's max HP, so a value is assumed. A non-party/alliance player's max HP is determined by the 'est_non_party_target_hp' stat which you can customize, or leave at default of 2000.

### Self Commands
**Description**

Every GearSwap file has the ability to create custom commands in its job.lua file using the `job_self_command` function. SilverLibs has a few pre-built commands you can utilize so you don't have to write everything yourself.

**Implemenetation**

__If Using Mote Libs__

In your job lua, find the function called `job_self_command`. If it does not exist, create it. In the first line inside this function add the `silibs.self_command` function call like so:
```lua
function job_self_command(cmdParams, eventArgs)
  silibs.self_command(cmdParams, eventArgs)
end
```
If you have other content in this function, put it below the silibs.self_command function call. **Be aware** that this function changes all cmdParams to lowercase, so if you have other content in `job_self_command` that attempts to match params with capitalization, you should change those to match lowercase params.

__If Using Selindrile Libs__

In your job lua, find the function called `user_job_self_command`. If it does not exist, create it. In the first line inside this function add the `silibs.self_command` function call like so:
```lua
function user_job_self_command(cmdParams, eventArgs)
  silibs.self_command(cmdParams, eventArgs)
end
```
If you have other content in this function, put it below the silibs.self_command function call. **Be aware** that this function changes all cmdParams to lowercase, so if you have other content in `user_job_self_command` that attempts to match params with capitalization, you should change those to match lowercase params.

**Usage**

There are a few pre-built commands available to you in SilverLibs. Keep in mind that all gearswap commands can be added to in-game macros with the following pattern: `/con c gs c NameOfCommand`. These commands can be added to keybinds as well using the following pattern (usually placed in job_setup function): `send_command('bind !s gs c faceaway')`. The list below explains what they do.

* sneak: Use Sneak. Goes through a list of possible Sneak options that you might have available, prioritizing free/cheap options. First will check if you have a JA that can Sneak you, then spells, then consumable items.
* invisible: Use Invisible. Goes through a list of possible Invisible options that you might have available, prioritizing free/cheap options. First will check if you have a JA that can Invisible you, then spells, then consumable items.
* noinvis: Cancels Invisible effects on you. This includes buffs with similar effect as Invisible such as Camouflage and Hide.
* usekey: Attempts to use a key on a chest you have targeted. If you are in Abyssea targeting a Sturdy Pyxis, it will attempt to use Forbidden Key. If you are targeting any other chest and you are a THF, it will attempt to use (in this order) Skeleton Key, Living Key, and Thief's Tools. Also cancels Invisible effects on you because you cannot interact with chests while invisible.
* faceaway: Turns your character 180 degrees in-place.

### Treasure Hunter Fix
**Description**

Intended to work with `Mote-TreasureHunter` or `Sel-TreasureHunter`. This feature enhances the way TH is used by the Mote and Selindrile's libraries. Specifically, this adds the functionality for Treasure Hunter set to be used when attacking an enemy without engaging.

**How is this different from Mote-TreasureHunter or Sel-TreasureHunter?**

The base functionality of the Mote/Selindrile library has a problem in that it will only equip your TH set if you have engaged the enemy first (by drawing your weapon), but it will still erroneously mark it as tagged with TH if you hit the enemy without engaging. This means that if you tag it with something (like Flash) without engaging, and then engage it, it won't use your TH set either on the Flash nor any time afterward because it thinks you applied TH already (which you didn't). SilverLibs's TH Fix feature corrects this behavior.

**Implementation**

Ensure you have the silibs post_precast and post_midcast hooks in your job lua. See the "Installing SilverLibs" section above for more details.

Must have a set named `sets.TreasureHunter`. This does not need to be a complete set, as it will be overlayed on top of your normal sets for whatever action you use against an enemy (only if you have TH mode turned on).

Set up a keybind for turning TH mode on and off. This can be done with a command such as:
```lua
  send_command('bind ^` gs c cycle treasuremode')
```

__If Using Mote Libs__

Enable TH Fix by adding the following anywhere in your `job_setup` function: `silibs.enable_th_fix()`

Make sure the `Mote-TreasureHunter` library is imported somewhere in your job lua. This can be done with the following line of code, usually in your `job_setup` function: `include('Mote-TreasureHunter')`.

Must remove the function `th_action_check` from your job file if it is there. Optionally, you can remove any references of `info.default_ja_ids` and `info.default_u_ja_ids` from your job file since they will do nothing now.

__If Using Selindrile Libs__

Enable TH Fix by adding the following anywhere in your `user_job_setup` function: `silibs.enable_th_fix()`

Optionally, you can remove any references of `info.th_ma_ids`, `info.th_ws_ids`, `info.th_ja_ids`, and `info.th_u_ja_ids` from your job file since they will do nothing now.
