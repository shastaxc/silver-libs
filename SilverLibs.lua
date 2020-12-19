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

-------------------------------------------------------------------------------
-- Instatiated variables for storing values and states
-------------------------------------------------------------------------------
-- Most recent weapons (used for re-arming)
silibs.most_recent_weapons = {main="empty",sub="empty",ranged="empty",ammo="empty"}


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


-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

function silibs.init_settings()
  silibs.most_recent_weapons = {main="",sub="",ranged="",ammo=""}
  silibs.use_weapon_rearm = false
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
-- Can be temporarily disabled by adding a toggled rearming lock state:
--    state.RearmingLock = M(false, 'Rearming Lock')
-- Which can be turned off or off with a keybind
--    send_command('bind @w gs c toggle RearmingLock')
function silibs.update_and_rearm_weapons()
  -- Save state of any equipped weapons
  if player.equipment.main ~= "empty" and player.equipment.main ~= nil then
    if not is_encumbered('main') then
      silibs.most_recent_weapons.main = player.equipment.main
    end
    if not is_encumbered('sub') then
      silibs.most_recent_weapons.sub = player.equipment.sub
    end
  end
  if player.equipment.ammo == "empty" or player.equipment.ammo == nil then
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
  -- If ammo is an ammunition (like bullet), update ranged if not empty
  elseif res.items:with('en', player.equipment.ammo).skill > 0 then
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
  -- If ammo is a stat item (like Aurgelmir Orb), update ranged even if empty
  else
    if not is_encumbered('ranged') then
      silibs.most_recent_weapons.ranged = player.equipment.ranged
    end
    if not is_encumbered('ammo') then
      silibs.most_recent_weapons.ammo = player.equipment.ammo
    end
  end

  -- Disarm Handling
  -- Table fills the string "empty" for empty slot. It won't return nil
  -- Must check if sub is also empty (and weapon) because if main hand is removed while dual wielding, the sub stays on for
  -- 1 cycle longer which will result in the main hand re-equipping but not the sub
  -- Also, if the sub is a shield, it will stay on even if main hand is removed.
  local is_sub_armor
  if player.equipment.sub and player.equipment.sub ~= 'empty' then
    is_sub_armor = res.items:with('en', player.equipment.sub).category == 'Armor'
  else
    is_sub_armor = false
  end
  if ((player.equipment.main == "empty" and silibs.most_recent_weapons.main ~= "empty" and player.equipment.sub == "empty")
      or (player.equipment.main == "empty" and silibs.most_recent_weapons.main ~= "empty" and is_sub_armor)
      or (player.equipment.ranged == "empty" and silibs.most_recent_weapons.ranged ~= "empty"))
      and (state.RearmingLock == nil or state.RearmingLock.value == false) then
    equip(silibs.most_recent_weapons)
  end
end


-------------------------------------------------------------------------------
-- Event hooks
-------------------------------------------------------------------------------
-- Executes on every frame. This is just a way to create a perpetual loop.
frame_count=0
windower.register_event('prerender',function()
  -- Use frame count to limit execution rate (roughly 0.16-0.33 seconds depending on FPS)
  if frame_count%10 == 0 and windower.ffxi.get_info().logged_in and windower.ffxi.get_player() then
    if silibs.use_weapon_rearm then
      silibs.update_and_rearm_weapons()
      frame_count = 0
    end
  else
    frame_count = frame_count + 1
  end
end)

-- Hook into job/subjob change event (happens BEFORE job starts changing)
windower.register_event('outgoing chunk', function(id, data, modified, injected, blocked)
  if id == 0x100 then -- Sending job change command to server
    silibs.init_settings()
  end
end)


return silibs