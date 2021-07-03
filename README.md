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

In your job file at the beginning of the `job_setup` function, add the following:
```
silibs.use_weapon_rearm = true
```
If you do not have a `job_setup` function, just go ahead and create one underneath `get_sets` like this:
```
function job_setup()
  silibs.use_weapon_rearm = true
end
```

**Usage**

Functionality can be temporarily disabled by adding a togglable `Rearming Lock` state (also in `job_setup`):
```
state.RearmingLock = M(false, 'Rearming Lock')
```

And add a keybind (also in `job_setup`) to perform the actual toggling (WIN+W is used here but it can be anything you want):
```
send_command('bind @w gs c toggle RearmingLock')
```

### Lockstyle Setting
**Description**

Sets your lockstyle on job or subjob change. Also reapplies your lockstyle when encumbrance changes (which normally breaks lockstyle).

**Implementation**

In your job lua, anywhere in the `user_setup()` function, add the following:
```
silibs.set_lockstyle(n)
```
Replace `n` with a number 1-100 indicating the lockstyle set number you wish to use for that job. You must create the lockstyle set using the in-game menus found in Main Menu -> Macros -> Edit Equip. Set.

### Waltz Refiner
**Description**

Using any Curing Waltz will be intercepted by SilverLibs and will automatically use smart logic to determine the appropriate tier of Waltz to use in order to save you TP while still accomplishing your goal!

**Implementation**

In your job lua, anywhere in the `user_setup()` function, add the following:
```
silibs.set_waltz_stats({
  ['base_chr'] = 104,
  ['base_vit'] = 97,
  ['bonus_chr'] = 128,
  ['bonus_vit'] = 96,
  ['waltz_potency'] = 50,
  ['waltz_self_potency'] = 17,
  ['est_non_party_target_hp'] = 2000,
})
```
Override the numbers based on your own stats while wearing your Curing Waltz gear set.

**Details on How It Works**

First, the available Curing Waltz tiers you have available is determined based on your DNC level (either main or sub job). The refiner will use some smart logic to estimate how much HP you can cure with the different tiers of Curing Waltz. Then it will detect how much HP your target is missing, and needs cured. It will select the best tier of Curing Waltz to heal your target to full without wasting too much TP. If the best match is on cooldown, it will go up in tiers to find an available ability. If none are available, it will check down the tiers instead.

**Caveats**

This function is 100% accurate when curing yourself. However, if you are curing another player, some assumptions must be made because the game does not provide all the necessary information about other players in this context. Mainly, the target's VIT affects the amount cured and that data is not sent to you. Also, if the player is not in your party/alliance, we cannot know the target's max HP, so a value is assumed. A non-party/alliance player's max HP is determined by the 'est_non_party_target_hp' stat which you can customize, or leave at default of 2000.
