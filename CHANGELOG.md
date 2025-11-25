# Changelog
This document describes all changes made to SilverLibs.

## 2025.NOV.24.0
* Small bug fix from previous update.

## 2025.NOV.22.1
* Added quivers and ammo pouches to no_swap_gear list.

## 2025.NOV.22.0
* Added "usable_item" auto-lock feature which checks the "silibs.no_swap_gear" list when gear is equipped and if it's on the list, keeps it equipped until it is manually removed or the player changes zones. This feature is enabled by default and cannot opt-out, but if you wish to override the list you can add to your globals file your own verison of `silibs.no_swap_gear` which must be a "Set" containing item IDs.
* Added a warning when using WS and a "usable_item" lock is active.
* Users can remove any existing gear locking logic from their job luas now. If you were using any adapted from my personal luas, you can leave them alone with no conflict in functionality but if you were interested in cleaning it up a bit, here's what I removed https://github.com/shastaxc/gearswap-data/commit/6302024520216574fdcf3877a2fe21c23cf2706c
* Updated some chat messages from using "Silibs:" prefix to "SilverLibs:".

## 2025.OCT.02.0
* Added all songs to spell_maps

## 2025.JUL.17.0
* Deprecated silibs.self_command function.
  * Just deprecating the name. Renamed to silibs.self_command_hook in order to prevent older implementations from calling it twice.

## 2025.JUL.13.3
* Added function getter for silibs.last_midcast_set called silibs.get_last_midcast_set(). This is done in order to remain consistent in how variables are exposed to users for general purpose use.

## 2025.JUL.13.2
* Added a custom self_command handler so users don't have to manually include it in their job luas during installation of SilverLibs.
  * You can (and should) remove the silibs.self_command function call from your job luas.

## 2025.JUL.13.1
* Added silibs.last_midcast_set variable which stores the midcast set used in your most recent action.
  * If you are using my RDM and BLM luas you should remove any setters for the last_midcast_set variable from there and use the silibs.get_last_midcast_set() function instead.
  * This was necessary due to the change in the last patch for where and when SilverLibs action hooks are executed.

## 2025.JUL.13.0
* Add overrides to Mote and Selindrile action handlers which process the precast, midcast, etc lifecycle functions.
  * This was needed in order for SilverLibs to inject logic more specifically where it belongs in the lifecycle.
  * A nice side effect is that installation of SilverLibs is now greatly simplified, and the wiki will be updated to reflect the new install method. The short version is that you can remove all silverlibs hooks except for silibs.user_setup_hook. You can (and should) safely remove from your job luas: silibs.precast_hook, silibs.post_precast_hook, silibs.midcast_hook, silibs.post_midcast_hook, silibs.aftercast_hook, silibs.post_aftercast_hook, silibs.customize_idle_set, silibs.customize_melee_set, silibs.customize_defense_set
  * This fixes the remaining bug related to the gear locking feature.
* Removed Kaustra from dynamic elemental belt equipping logic (Hachirin and Orpheus).
  * It was decided that when using Kaustra, a SCH will always control the weather to make Hachirin-no-Obi always the best choice. Will let them set this in their Kaustra set and not override it with SilverLibs logic.
