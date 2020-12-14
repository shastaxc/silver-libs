-- Copyright © 2020, Silvermutt (Asura)
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--     * Neither the name of SilverLibs nor the
--       names of its contributors may be used to endorse or promote products
--       derived from this software without specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


--=============================================================================
--=============================================================================
--====================             DO NOT              ========================
--====================             MODIFY              ========================
--====================            ANYTHING             ========================
--=============================================================================
--=============================================================================

silibs = {} -- Initialize library namespace

-------------------------------------------------------------------------------
-- Includes/imports
-------------------------------------------------------------------------------
res = include('resources')

-------------------------------------------------------------------------------
-- Flags to enable/disable features and store user settings
-------------------------------------------------------------------------------
silibs.use_weapon_rearm = false
silibs.use_dynamic_ws_keybinds = false
silibs.main_ws_target_mode = 't'
silibs.ranged_ws_target_mode = 't'

-------------------------------------------------------------------------------
-- Instatiated variables for storing values and states
-------------------------------------------------------------------------------
-- Most recent weapons (used for re-arming)
silibs.most_recent_weapons = {main="",sub="",ranged="",ammo=""}
silibs.current_weapon_type = nil
silibs.current_ranged_weapon_type = nil
silibs.latest_ws_binds = {}


-------------------------------------------------------------------------------
-- Constants and maps
-------------------------------------------------------------------------------
silibs.range_mult = {
  [2] = 1.55,
  [3] = 1.490909,
  [4] = 1.44,
  [5] = 1.377778,
  [6] = 1.30,
  [7] = 1.15,
  [8] = 1.25,
  [9] = 1.377778,
  [10] = 1.45,
  [11] = 1.454545454545455,
  [12] = 1.666666666666667,
}

silibs.action_type_blockers = {
  ['Magic'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'silence', 'mute', 'Omerta'},
  ['Ranged Attack'] = {'terror', 'petrification', 'stun', 'sleep', 'charm'},
  ['Ability'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'amnesia', 'impairment'},
  ['Item'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'muddle'},
  ['Monster Move'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'amnesia'},
}

-- DO NOT OVERWRITE THESE. You can use your own custom keybinds by copying this table
--   to your globals file and changing the bindings there.
-- To overwrite, create table with the same format, but named user_ws_bindings.
-- Your bindings will be used instead of the default for the entire weapon type table.
--   For example, if you have a 'Hand-to-Hand' table defined, none of the default 'Hand-to-Hand'
--   keybinds will be used.
-- Bindings will be set from top to bottom within a weapon type category. Ex. In Dagger
--   category, if 'Default' table is first, those will be set. If you then have 'MNK' table
--   and you are main job MNK, those bindings will overwrite default. If you have a '/WAR'
--   table after that, then those keybinds will overwrite the previous ones if you are sub
--   job WAR.
silibs.ws_binds = {
  ['Hand-to-Hand'] = {
    ['Default'] = {
      ['^numpad7'] = "Victory Smite", --empyrean
      ['^numpad8'] = "", --mythic
      ['^numpad9'] = "Final Heaven", --relic
      ['^numpad4'] = "Asuran Fists", --ambuscade
      ['^numpad5'] = "Shijin Spiral", --aeonic
      ['^numpad6'] = "Shoulder Tackle",
      ['^numpad1'] = "Spinning Attack", --aoe
      ['^numpad2'] = "Raging Fists",
      ['^numpad3'] = "Howling Fist",
    },
    ['MNK'] = {
      ['^numpad8'] = "Ascetic's Fury", --mythic
    },
    ['PUP'] = {
      ['^numpad8'] = "Stringing Pummel", --mythic
    },
  },
  ['Dagger'] = {
    ['Default'] = {
      ['^numpad7'] = "Rudra's Storm", --empyrean
      ['^numpad8'] = "", --mythic
      ['^numpad9'] = "Mercy Stroke", --relic
      ['^numpad4'] = "Evisceration", --ambuscade
      ['^numpad5'] = "Exenterator", --aeonic
      ['^numpad6'] = "Shark Bite",
      ['^numpad1'] = "Aeolian Edge", --aoe
      ['^numpad2'] = "Cyclone", --elemental
      ['^numpad3'] = "Energy Drain", --elemental
    },
    ['THF'] = {
      ['^numpad8'] = "Mandalic Stab", --mythic
    },
    ['DNC'] = {
      ['^numpad8'] = "Pyrrhic Kleos", --mythic
    },
    ['BRD'] = {
      ['^numpad8'] = "Mordant Rime", --mythic
    },
  },
  ['Sword'] = {
    ['Default'] = {
      ['^numpad7'] = "Chant du Cygne", --empyrean
      ['^numpad8'] = "", --mythic
      ['^numpad9'] = "Knights of Round", --relic
      ['^numpad4'] = "Savage Blade", --ambuscade
      ['^numpad5'] = "Requiescat", --aeonic
      ['^numpad6'] = "Sanguine Blade",
      ['^numpad1'] = "Circle Blade", --aoe
      ['^numpad2'] = "Red Lotus Blade", --elemental
      ['^numpad3'] = "Seraph Blade", --elemental
    },
    ['RDM'] = {
      ['^numpad8'] = "Death Blossom", --mythic
    },
    ['PLD'] = {
      ['^numpad8'] = "Atonement", --mythic
    },
    ['BLU'] = {
      ['^numpad8'] = "Expiacion", --mythic
    },
  },
  ['Great Sword'] = {
    ['Default'] = {
      ['^numpad7'] = "Torcleaver", --empyrean
      ['^numpad8'] = "Dimidiation", --mythic
      ['^numpad9'] = "Scourge", --relic
      ['^numpad4'] = "Ground Strike", --ambuscade
      ['^numpad5'] = "Resolution", --aeonic
      ['^numpad6'] = "Power Slash",
      ['^numpad1'] = "Shockwave", --aoe
      ['^numpad2'] = "Freezebite", --elemental
      ['^numpad3'] = "Herculean Slash",
    },
  },
  ['Axe'] = {
    ['Default'] = {
      ['^numpad7'] = "Cloudsplitter", --empyrean
      ['^numpad8'] = "Primal Rend", --mythic
      ['^numpad9'] = "Onslaught", --relic
      ['^numpad4'] = "Decimation", --ambuscade
      ['^numpad5'] = "Ruinator", --aeonic
      ['^numpad6'] = "Smash Axe",
      ['^numpad1'] = "Rampage",
      ['^numpad2'] = "Gale Axe", --elemental
      ['^numpad3'] = "Bora Axe",
    },
  },
  ['Great Axe'] = {
    ['Default'] = {
      ['^numpad7'] = "Ukko's Fury", --empyrean
      ['^numpad8'] = "King's Justice", --mythic
      ['^numpad9'] = "Metatron Torment", --relic
      ['^numpad4'] = "Steel Cyclone", --ambuscade
      ['^numpad5'] = "Upheaval", --aeonic
      ['^numpad6'] = "Weapon Break",
      ['^numpad1'] = "Fell Cleave", --aoe
      ['^numpad2'] = "Shield Break",
      ['^numpad3'] = "Armor Break",
    },
  },
  ['Scythe'] = {
    ['Default'] = {
      ['^numpad7'] = "Quietus", --empyrean
      ['^numpad8'] = "Insurgency", --mythic
      ['^numpad9'] = "Catastrophe", --relic
      ['^numpad4'] = "Spiral Hell", --ambuscade
      ['^numpad5'] = "Entropy", --aeonic
      ['^numpad6'] = "Cross Reaper",
      ['^numpad1'] = "Spinning Scythe", --aoe
      ['^numpad2'] = "Shadow of Death", --elemental
      ['^numpad3'] = "Nightmare Scythe",
    },
  },
  ['Polearm'] = {
    ['Default'] = {
      ['^numpad7'] = "Camlann's Torment", --empyrean
      ['^numpad8'] = "Drakesbane", --mythic
      ['^numpad9'] = "Geirskogul", --relic
      ['^numpad4'] = "Impulse Drive", --ambuscade
      ['^numpad5'] = "Stardiver", --aeonic
      ['^numpad6'] = "Leg Sweep",
      ['^numpad1'] = "Sonic Thrust", --aoe
      ['^numpad2'] = "Raiden Thrust", --elemental
      ['^numpad3'] = "Penta Thrust",
    },
  },
  ['Katana'] = {
    ['Default'] = {
      ['^numpad7'] = "Blade: Hi", --empyrean
      ['^numpad8'] = "Blade: Kamu", --mythic
      ['^numpad9'] = "Blade: Metsu", --relic
      ['^numpad4'] = "Blade: Ku", --ambuscade
      ['^numpad5'] = "Blade: Shun", --aeonic
      ['^numpad6'] = "Blade: Chi",
      ['^numpad1'] = "Blade: Yu",
      ['^numpad2'] = "Blade: Ei", --elemental
      ['^numpad3'] = "Blade: Ten",
    },
  },
  ['Great Katana'] = {
    ['Default'] = {
      ['^numpad7'] = "Tachi: Fudo", --empyrean
      ['^numpad8'] = "Tachi: Rana", --mythic
      ['^numpad9'] = "Tachi: Kaiten", --relic
      ['^numpad4'] = "Tachi: Kasha", --ambuscade
      ['^numpad5'] = "Tachi: Shoha", --aeonic
      ['^numpad6'] = "Tachi: Hobaku",
      ['^numpad1'] = "Tachi: Gekko",
      ['^numpad2'] = "Tachi: Jinpu", --elemental
      ['^numpad3'] = "Tachi: Koki", --elemental
    },
  },
  ['Club'] = {
    ['Default'] = {
      ['^numpad7'] = "Dagan", --empyrean
      ['^numpad8'] = "", --mythic
      ['^numpad9'] = "Randgrith", --relic
      ['^numpad4'] = "Black Halo", --ambuscade
      ['^numpad5'] = "Realmrazer", --aeonic
      ['^numpad6'] = "Brainshaker",
      ['^numpad1'] = "Hexa Strike",
      ['^numpad2'] = "Seraph Strike", --elemental
      ['^numpad3'] = "Skullbreaker",
    },
    ['WHM'] = {
      ['^numpad8'] = "Mystic Boon", --mythic
    },
    ['GEO'] = {
      ['^numpad8'] = "Exudation", --mythic
    },
  },
  ['Staff'] = {
    ['Default'] = {
      ['^numpad7'] = "Myrkr", --empyrean
      ['^numpad8'] = "", --mythic
      ['^numpad9'] = "Gate of Tartarus", --relic
      ['^numpad4'] = "Retribution", --ambuscade
      ['^numpad5'] = "Shattersoul", --aeonic
      ['^numpad6'] = "Shell Crusher",
      ['^numpad1'] = "Cataclysm", --aoe
      ['^numpad2'] = "Earth Crusher", --elemental
      ['^numpad3'] = "Sunburst", --elemental
    },
    ['BLM'] = {
      ['^numpad8'] = "Vidohunir", --mythic
    },
    ['SMN'] = {
      ['^numpad8'] = "Garland of Bliss", --mythic
    },
    ['SCH'] = {
      ['^numpad8'] = "Omniscience", --mythic
    },
  },
  -- =====================================================
  -- IMPORTANT: Ranged keybinds should be different than
  -- all of the other WS keybinds! Otherwise, you will
  -- only get either main WSs or ranged WSs, but not both!
  -- =====================================================
  ['Archery'] = {
    ['Default'] = {
      ['!numpad7'] = "Jishnu's Radiance", --empyrean
      ['!numpad8'] = "", --mythic
      ['!numpad9'] = "Namas Arrow", --relic
      ['!numpad4'] = "Empyreal Arrow", --ambuscade
      ['!numpad5'] = "Apex Arrow", --aeonic
      ['!numpad6'] = "Sidewinder",
      ['!numpad1'] = "Dulling Arrow",
      ['!numpad2'] = "Flaming Arrow", --elemental
      ['!numpad3'] = "Refulgent Arrow",
    },
    ['RNG'] = {
      ['!numpad9'] = "Namas Arrow", --relic
      ['!numpad5'] = "Apex Arrow", --aeonic
    },
    ['SAM'] = {
      ['!numpad9'] = "Namas Arrow", --relic
    },
  },
  ['Marksmanship'] = {
    ['Default'] = {
      ['!numpad7'] = "Wildfire", --empyrean
      ['!numpad8'] = "", --mythic
      ['!numpad9'] = "", --relic
      ['!numpad4'] = "Detonator",
      ['!numpad5'] = "", --aeonic
      ['!numpad6'] = "Slug Shot",
      ['!numpad1'] = "Sniper Shot",
      ['!numpad2'] = "Hot Shot", --elemental
      ['!numpad3'] = "Numbing Shot",
    },
    ['RNG'] = {
      ['!numpad8'] = "Trueflight", --mythic
      ['!numpad5'] = "Last Stand", --aeonic
      ['!numpad9'] = "Coronach", --relic
    },
    ['COR'] = {
      ['!numpad8'] = "Leaden Salute", --mythic
      ['!numpad5'] = "Last Stand", --aeonic
    },
  },
}

silibs.valid_keybind_modifiers = S{
  "^", 	-- Ctrl
  "!", 	-- Alt
  "@", 	-- Win
  "#", 	-- Apps
  "~", 	-- Shift
}
silibs.valid_keybind_states = S{
  "$", -- Keybind is valid while the game input line is active
  "%", -- Keybind is valid while the game input line is inactive
}
silibs.valid_keybinds = S{
  "`",
  "escape",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "0",
  "-",
  "=",
  "backspace",
  "tab",
  "q",
  "w",
  "e",
  "r",
  "t",
  "y",
  "u",
  "i",
  "o",
  "p",
  "[",
  "]",
  "enter",
  "return",
  "ctrl",
  "lctrl",
  "a",
  "s",
  "d",
  "f",
  "g",
  "h",
  "j",
  "k",
  "l",
  ";",
  "'",
  "shift",
  "lshift",
  "\\",
  "z",
  "x",
  "c",
  "v",
  "b",
  "n",
  "m",
  ",",
  ".",
  "/",
  "rshift",
  "numpad*",
  "alt",
  "lalt",
  "space",
  "capslock",
  "f1",
  "f2",
  "f3",
  "f4",
  "f5",
  "f6",
  "f7",
  "f8",
  "f9",
  "f10",
  "numlock",
  "numpad/",
  "scrolllock",
  "numpad7",
  "numpad8",
  "numpad9",
  "numpad-",
  "numpad4",
  "numpad5",
  "numpad6",
  "numpad+",
  "numpad1",
  "numpad2",
  "numpad3",
  "numpad0",
  "numpad.",
  "f11",
  "f12",
  "kana",
  "convert",
  "noconvert",
  "yen",
  "kanji",
  "numpadenter",
  "rctrl",
  "sysrq",
  "ralt",
  "pause",
  "home",
  "up",
  "pageup",
  "left",
  "right",
  "end",
  "down",
  "pagedown",
  "insert",
  "delete",
  "windows",
  "lwindows",
  "rwindows",
  "apps",
  "mail",
  "mmselect",
  "mmstop",
  "mute",
  "mycomputer",
  "mmnext",
  "mmnexttrack",
  "mmplaypause",
  "power",
  "mmprevtrack",
  "mmstop",
  "mmvolup",
  "mmvoldown",
  "webback",
  "webfav",
  "webforward",
  "webhome",
  "webrefresh",
  "websearch",
  "webstop",
}

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

function silibs.init_settings()
  silibs.most_recent_weapons = {main="",sub="",ranged="",ammo=""}
  silibs.use_weapon_rearm = false
  silibs.use_dynamic_ws_keybinds = false
  silibs.main_ws_target_mode = 't'
  silibs.ranged_ws_target_mode = 't'
end

-- 'ws_range' expected to be the range pulled from weapon_skills.lua
-- 's' is self player object
-- 't' is target object
function silibs.is_ws_out_of_range(ws_range, s, t)
  if ws_range == nil or s == nil or t == nil then
    print('Invalid params for is_ws_out_of_range.')
    return true
  end

  local distance = t.distance:sqrt()
  local is_out_of_range = distance > (t.model_size + ws_range * silibs.range_mult[ws_range] + s.model_size)

  if is_out_of_range then
    windower.add_to_chat(167, 'Target out of range.')
  end

  return is_out_of_range
end

-- 'spell' is the same as input parameter in job_precast function of Mote libs
-- 'eventArgs' is the same as input parameter in job_precast function of Mote libs
function silibs.cancel_outranged_ws(spell, eventArgs)
  -- Ensure spell is a weaponskill to proceed
  if spell.type ~= "WeaponSkill" then
    return
  end
  
  local player = windower.ffxi.get_mob_by_target('me')
  local target = windower.ffxi.get_mob_by_id(spell.target.id)

  if silibs.is_ws_out_of_range(spell.range, player, target) then
    cancel_spell() -- Blocks the outgoing action packet that would perform the WS
    eventArgs.cancel = true -- Ensures gear doesn't swap
  end
end

-- Don't swap gear if status forbids the action
-- 'spell' is the same as input parameter in job_precast function of Mote libs
-- 'eventArgs' is the same as input parameter in job_precast function of Mote libs
function silibs.cancel_on_blocking_status(spell, eventArgs)
  local forbidden_statuses = silibs.action_type_blockers[spell.action_type]
  for k,status in pairs(forbidden_statuses) do
    if buffactive[status] then
      windower.add_to_chat(167, 'Stopped due to status.')
      eventArgs.cancel = true -- Ensures gear doesn't swap
      return -- Ends function without finishing loop
    end
  end
end

function silibs.has_item(bag_name, item_name)
  local bag = res.bags:with('en', bag_name)
  local item = res.items:with('en', item_name)
  local items_in_bag = windower.ffxi.get_items(bag['id'])
  for k,v in pairs(items_in_bag) do
    if type(v)~='number' and type(v)~='boolean' and v['id'] == item['id'] then
      return true
    end
  end
  return false
end

-- Saves the state of your weapons
-- Re-arms your weapons when conditions are met
-- Can be temporarily disabled by adding a toggled weapon lock state:
--    state.WeaponLock = M(false, 'Weapon Lock')
--    send_command('bind @w gs c toggle WeaponLock')
-- If 'main', 'sub', or 'ranged' are in idle, engaged, or defense sets
-- it may conflict with this functionality
function silibs.update_and_rearm_weapons()
  -- Save state of any equipped weapons
  if player.equipment.main ~= "empty" then
    if not is_encumbered('main') then
      silibs.most_recent_weapons.main = player.equipment.main
    end
    if not is_encumbered('sub') then
      silibs.most_recent_weapons.sub = player.equipment.sub
    end
  end
  if player.equipment.ranged ~= "empty" and player.equipment.ranged ~= nil then
    -- Only save if ranged is a combat item
    local rangedItem = res.items:with('name', player.equipment.ranged)
    if res.skills[rangedItem.skill].category == 'Combat' then
      if not is_encumbered('ranged') then
        silibs.most_recent_weapons.ranged = player.equipment.ranged
      end
      if not is_encumbered('ammo') then
        silibs.most_recent_weapons.ammo = player.equipment.ammo
      end
    end
  end

  -- Disarm Handling
  -- Table fills the string "empty" for empty slot. It won't return nil
  if (player.equipment.main == "empty" and silibs.most_recent_weapons.main ~= "empty")
      or (player.equipment.ranged == "empty" and silibs.most_recent_weapons.ranged ~= "empty") then
    if state.WeaponLock == nil or state.WeaponLock.value == false then
      equip(silibs.most_recent_weapons)
    end
  end
end

function silibs.update_weaponskill_binds(has_job_changed)
  local has_main_weapon_changed = false
  local has_ranged_weapon_changed = false
  local main_weapon = nil
  local main_weapon_type = nil
  local ranged_weapon = nil
  local ranged_weapon_type = nil

  -- Get main weapon and type
  -- Handle barehanded case
  if player.equipment.main == nil or player.equipment.main == 0 or player.equipment.main == 'empty' then
    main_weapon_type = 'Hand-to-Hand'
  else -- Handle equipped weapons case
    main_weapon = res.items:with('name', player.equipment.main)
    main_weapon_type = res.skills[main_weapon.skill].en
  end

  -- Get ranged weapon and type
  if player.equipment.ranged ~= nil and player.equipment.ranged ~= 0 and player.equipment.ranged ~= 'empty' then
    ranged_weapon = res.items:with('name', player.equipment.ranged)
    ranged_weapon_type = res.skills[ranged_weapon.skill].en
  end

  has_main_weapon_changed = main_weapon_type ~= current_main_weapon_type
  has_ranged_weapon_changed = ranged_weapon_type ~= silibs.current_ranged_weapon_type
  
  -- Do not proceed to update keybinds if:
  -- Main weapon type has not changed, and
  -- Ranged weapon type has not changed, and
  -- Job has not changed
  if not has_main_weapon_changed and not has_ranged_weapon_changed and not has_job_changed then
    return
  end
  
  -- Update the main weapon type tracker and get new keybinds
  current_main_weapon_type = main_weapon_type
  -- Get new main hand bindings
  local new_main_ws_bindings = silibs.get_ws_bindings(main_weapon_type)

  -- Update the ranged weapon type tracker and get new keybinds
  silibs.current_ranged_weapon_type = ranged_weapon_type
  -- Get new ranged bindings
  local new_ranged_ws_bindings = silibs.get_ws_bindings(ranged_weapon_type)

  -- Merge main and ranged keybinds into same table
  local merged_main_ranged_bindings = new_main_ws_bindings
  for keybind,ws_name in pairs(new_ranged_ws_bindings) do
    -- If key is already in the table for main hand WS, warn user
    if merged_main_ranged_bindings[keybind] then
      print('Keybind Overwrite Warning: "'..ws_name..'" overwriting "'..
          merged_main_ranged_bindings[keybind]..'" keybind ('..keybind..').')
    end
    merged_main_ranged_bindings[keybind] = new_ranged_ws_bindings[keybind]
  end

  -- Unbind previous bindings if there is no overlap in new bindings. This
  -- is necessary because unbind commands appear to be asynchronous and
  -- would otherwise erase your new keybinds too.
  for old_keybind,old_ws_name in pairs(silibs.latest_ws_binds) do
    local is_same = false
    for new_keybind,new_ws_name in pairs(merged_main_ranged_bindings) do
      if old_keybind == new_keybind then
        is_same = true
        break
      end
    end
    if not is_same then
      send_command("unbind "..old_keybind)
    end
  end

  -- Set weaponskill bindings according to table
  for keybind,ws_name in pairs(merged_main_ranged_bindings) do
    local ws = res.weapon_skills:with('en', ws_name)
    local is_main_hand_keybind = ws.skill > 0 and ws.skill < 13 -- Skill ID 1-12 are main hand
    if is_main_hand_keybind then
      send_command("bind "..keybind.." input /ws \""..ws_name.."\" <"..silibs.main_ws_target_mode..">")
    else
      send_command("bind "..keybind.." input /ws \""..ws_name.."\" <"..silibs.ranged_ws_target_mode..">")
    end
  end

  silibs.latest_ws_binds = merged_main_ranged_bindings

  -- Notify user that keybinds have been updated
  local notify_msg = 'WS Keybinds: '..main_weapon_type
  if ranged_weapon_type ~= nil then
    notify_msg = notify_msg..'/'..ranged_weapon_type..''
  end
  notify_msg = notify_msg..' for '..silibs.get_current_job()
  windower.add_to_chat(8, notify_msg)
end

function silibs.get_ws_bindings(weapon_type)
  -- Null check
  if silibs.ws_binds == nil or weapon_type == nil then
    return {}
  end

  local player = windower.ffxi.get_player()
  local weapon_specific_bindings

  -- If user table exists for the weapon type, use those instead of defaults
  if user_ws_bindings and user_ws_bindings[weapon_type] then
    weapon_specific_bindings = user_ws_bindings[weapon_type]
  else
    weapon_specific_bindings = silibs.ws_binds[weapon_type]
  end

  -- Separate default bindings, main job bindings, and sub job bindings
  local default_bindings
  local main_job_bindings
  local sub_job_bindings
  local main_sub_combo_bindings
  
  for key,job_specific_table in pairs(weapon_specific_bindings) do
    local is_key_sub_job = key:sub(1, 1) == '/'
    local is_key_main_sub_combo = key:sub(4, 4) == '/' and string.len(key) == 7
    -- Get default bindings
    if key == 'Default' then
      default_bindings = job_specific_table
    -- Get sub job bindings
    elseif (is_key_sub_job and key:sub(2,string.len(key)):lower() == player.sub_job:lower()) then
      sub_job_bindings = job_specific_table
    -- Get main/sub bindings
    elseif (is_key_main_sub_combo and key:sub(1,3):lower() == player.main_job:lower()
        and key:sub(5,7):lower() == player.sub_job:lower()) then
      main_sub_combo_bindings = job_specific_table
    -- Get main job bindings
    elseif (not is_key_sub_job and not is_key_main_sub_combo and key:lower() == player.main_job:lower()) then
      main_job_bindings = job_specific_table
    end
  end

  -- Combine default, main job, and sub job bindings in that
  -- order to give priority to sub job bindings
  local merged_bindings = {}
  if default_bindings then
    for keybind,ws_name in pairs(default_bindings) do
      merged_bindings[keybind] = ws_name
    end
  end
  if main_job_bindings then
    for keybind,ws_name in pairs(main_job_bindings) do
      merged_bindings[keybind] = ws_name
    end
  end
  if sub_job_bindings then
    for keybind,ws_name in pairs(sub_job_bindings) do
      merged_bindings[keybind] = ws_name
    end
  end
  if main_sub_combo_bindings then
    for keybind,ws_name in pairs(main_sub_combo_bindings) do
      merged_bindings[keybind] = ws_name
    end
  end
  
  -- Purge invalid entries
  return silibs.purge_invalid_ws_bindings(merged_bindings)
end

function silibs.purge_invalid_ws_bindings(ws_bindings)
  local purged_table = {}
  for keybind,ws_name in pairs(ws_bindings) do

    -- Check if modifier or state is included
    local first_char = keybind:sub(1,1)
    local second_char = keybind:sub(2,2)
    local modifier
    local state
    local bind_btn
    if silibs.valid_keybind_states:contains(first_char) then
      state = first_char
      bind_btn = keybind:sub(2,string.len(keybind))
    elseif silibs.valid_keybind_modifiers:contains(first_char) then
      modifier = first_char
      if silibs.valid_keybind_states:contains(second_char) then
        state = second_char
        bind_btn = keybind:sub(3,string.len(keybind))
      else
        bind_btn = keybind:sub(2,string.len(keybind))
      end
    else
      bind_btn = keybind
    end

    local is_keybind_blank = bind_btn == ''
    local is_keybind_valid = silibs.valid_keybinds:contains(bind_btn)
    local is_ws_name_valid = res.weapon_skills:with('en', ws_name) ~= nil

    -- If keybind is valid and ws name is valid, add to purged table
    if not is_keybind_blank -- Ensure keybind is not blank
        and is_keybind_valid -- Ensure keybind is in list of valid keys
        and is_ws_name_valid then -- Ensure WS name is an actual WS name
      purged_table[keybind] = ws_name
    elseif is_keybind_blank then
      if ws_name ~= '' then
        print("WS Keybind Error: Keybind is blank for "..ws_name)
      else
        print("WS Keybind Error: Keybind is blank")
      end
    elseif not is_keybind_valid then
      print("WS Keybind Error: \""..keybind.."\" is not a valid keybind")
    elseif not is_ws_name_valid and ws_name ~= nil and ws_name ~= '' then
      print("WS Keybind Error: \""..ws_name.."\" is not a valid WS name")
    end
  end

  return purged_table
end

function silibs.get_current_job()
  local player = windower.ffxi.get_player()
  return player.main_job..'/'..player.sub_job
end

function silibs.unbind_all_ws()
  -- Iterate through all categories in silibs.ws_binds
  -- If there is a user override in user_ws_bindings, unbind that instead
  for weapon_category, weapon_specific_table in pairs(silibs.ws_binds) do
    if user_ws_bindings and user_ws_bindings[weapon_category] then
      weapon_specific_table = user_ws_bindings[weapon_category]
    end
    for job_category, job_specific_table in pairs(weapon_specific_table) do
      for keybind,ws_name in pairs(job_specific_table) do
        send_command("unbind "..keybind)
      end
    end
  end
end


-------------------------------------------------------------------------------
-- Event hooks
-------------------------------------------------------------------------------
-- Executes on every frame. This is just a way to create a perpetual loop.
windower.register_event('prerender',function()
  if silibs.use_weapon_rearm then
    silibs.update_and_rearm_weapons()
  end
  
  if silibs.use_dynamic_ws_keybinds then
    silibs.update_weaponskill_binds(false)
  end
end)

-- Hook into job/subjob change event (happens after job has finished changing)
windower.register_event('job change', function(main_job_id, main_job_level, sub_job_id, sub_job_level)
  -- For some reason, this event may fire twice. The first time, the game does not actually detect
  -- the player's new job. Enforce a check to ensure it has.
  if main_job_id == nil then return end

  silibs.init_settings()
  silibs.unbind_all_ws()
  if silibs.use_dynamic_ws_keybinds then
    coroutine.schedule(function()
      silibs.update_weaponskill_binds(true)
    end, 1)
  end
end)

return silibs