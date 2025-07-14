# Changelog
This document describes all changes made to SilverLibs.

## 2025.JUL.13.0
* Add overrides to Mote and Selindrile action handlers which process the precast, midcast, etc lifecycle functions.
  * This was needed in order for SilverLibs to inject logic more specifically where it belongs in the lifecycle.
  * A nice side effect is that installation of SilverLibs is now greatly simplified, and the wiki will be updated to reflect the new install method. The short version is that you can remove all silverlibs hooks except for silibs.user_setup_hook. You can (and should) safely remove from your job luas: silibs.precast_hook, silibs.post_precast_hook, silibs.midcast_hook, silibs.post_midcast_hook, silibs.aftercast_hook, silibs.post_aftercast_hook, silibs.customize_idle_set, silibs.customize_melee_set, silibs.customize_defense_set
  * This fixes the remaining bug related to the gear locking feature.
* Removed Kaustra from dynamic elemental belt equipping logic (Hachirin and Orpheus).
  * It was decided that when using Kaustra, a SCH will always control the weather to make Hachirin-no-Obi always the best choice. Will let them set this in their Kaustra set and not override it with SilverLibs logic.

## 2025.JUL.13.1
* Added silibs.last_midcast_set variable which stores the midcast set used in your most recent action.
  * If you are using my RDM and BLM luas you should remove any setters for the last_midcast_set variable from there and use the silibs.last_midcast_set variable instead.
  * This was necessary due to the change in the last patch for where and when SilverLibs action hooks are executed.

## 2025.JUL.13.2
* Added a custom self_command handler so users don't have to manually include it in their job luas during installation of SilverLibs.
  * You can (and should) remove the silibs.self_command function call from your job luas.
