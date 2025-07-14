# Changelog
This document describes all changes made to SilverLibs.

## 2025.JUL.13.0
* Add overrides to Mote and Selindrile action handlers which process the precast, midcast, etc lifecycle functions.
  * This was needed in order for SilverLibs to inject logic more specifically where it belongs in the lifecycle.
  * A nice side effect is that installation of SilverLibs is now greatly simplified, and the wiki will be updated to reflect the new install method. The short version is that you can remove all silverlibs hooks except for silibs.user_setup_hook.
  * This fixes the remaining bug related to the gear locking feature.
* Removed Kaustra from dynamic elemental belt equipping logic (Hachirin and Orpheus).
  * It was decided that when using Kaustra, a SCH will always control the weather to make Hachirin-no-Obi always the best choice. Will let them set this in their Kaustra set and not override it with SilverLibs logic.

## 2025.JUL.13.1
* Added silibs.last_midcast_set variable which stores the midcast set used in your most recent action.
  * If you are using my RDM and BLM luas you should remove any setters for the last_midcast_set variable from there and use the silibs.last_midcast_set variable instead.
  * This was necessary due to the change in the last patch for where and when SilverLibs action hooks are executed.
