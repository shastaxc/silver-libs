-- Version 2021.JUL.05.001
-- Copyright © 2021, Shasta
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
packets = include('packets')


-------------------------------------------------------------------------------
-- One-off commands to execute on load
-------------------------------------------------------------------------------

-- Send request for player stats update
local packet = packets.new('outgoing', 0x061, {})
packets.inject(packet)


-------------------------------------------------------------------------------
-- Flags to enable/disable features and store user settings
-------------------------------------------------------------------------------
silibs.cancel_outranged_ws_enabled = false
silibs.cancel_on_blocking_status_enabled = false
silibs.weapon_rearm_enabled = false
silibs.auto_lockstyle_enabled = false
silibs.th_fix_enabled = false

-------------------------------------------------------------------------------
-- Instatiated variables for storing values and states
-------------------------------------------------------------------------------
-- Most recent weapons (used for re-arming)
silibs.most_recent_weapons = {main="empty",sub="empty",ranged="empty",ammo="empty"}
silibs.locked_style = false
silibs.lockstyle_set = 0
silibs.encumbrance = 0
silibs.waltz_stats = {
  ['base_chr'] = 100,
  ['base_vit'] = 100,
  ['bonus_chr'] = 100,
  ['bonus_vit'] = 100,
  ['waltz_potency'] = 25,
  ['waltz_self_potency'] = 15,
  ['est_non_party_target_hp'] = 2000,
}
silibs.playerStats = {}
silibs.playerStats.Base = {}
silibs.playerStats.Bonus = {}
silibs.prev_action_applied_TH = false
state.RearmingLock = M(false, 'Rearming Lock')


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

silibs.curing_waltz = T{
  [1] = {name='Curing Waltz',     tier=1, lv=15, tp=200, cure_slope=0.25, cure_base=60},
  [2] = {name='Curing Waltz II',  tier=2, lv=30, tp=350, cure_slope=0.5,  cure_base=130},
  [3] = {name='Curing Waltz III', tier=3, lv=45, tp=500, cure_slope=0.75, cure_base=270},
  [4] = {name='Curing Waltz IV',  tier=4, lv=70, tp=650, cure_slope=1,    cure_base=450},
  [5] = {name='Curing Waltz V',   tier=5, lv=87, tp=800, cure_slope=1.25, cure_base=600},
}


-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

function silibs.init_settings()
  silibs.cancel_outranged_ws_enabled = false
  silibs.cancel_on_blocking_status_enabled = false
  silibs.weapon_rearm_enabled = false
  silibs.auto_lockstyle_enabled = false
  silibs.th_fix_enabled = false

  silibs.most_recent_weapons = {main="",sub="",ranged="",ammo=""}
  silibs.lockstyle_set = 0
  silibs.locked_style = false
  silibs.encumbrance = 0
  silibs.waltz_stats = {
    ['base_chr'] = 100,
    ['base_vit'] = 100,
    ['bonus_chr'] = 100,
    ['bonus_vit'] = 100,
    ['waltz_potency'] = 25,
    ['waltz_self_potency'] = 15,
    ['est_non_party_target_hp'] = 2000,
  }
  silibs.prev_action_applied_TH = false
  
  state.RearmingLock = M(false, 'Rearming Lock')
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
  elseif res.items:with('en', player.equipment.ammo).skill ~= nil and
      res.items:with('en', player.equipment.ammo).skill > 0 then
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

function silibs.set_lockstyle()
  if not silibs.auto_lockstyle_enabled then
    return
  end
  -- Set lockstyle 2 seconds after changing job, trying immediately will error
  coroutine.schedule(function()
    if silibs.locked_style == false and silibs.lockstyle_set > 0 then
      send_command('input /lockstyleset '..silibs.lockstyle_set)
    end
  end, 2)
  -- In case lockstyle was on cooldown for first command, try again (lockstyle has 10s cd)
  coroutine.schedule(function()
    if silibs.locked_style == false and silibs.lockstyle_set > 0 then
      send_command('input /lockstyleset '..silibs.lockstyle_set)
    end
  end, 10)
end

function silibs.self_command(cmdParams, eventArgs)
  -- Make all cmdParams lowercase
  for i,j in ipairs(cmdParams) do
    cmdParams[i] = j:lower()
  end
  if cmdParams[1] == 'sneak' then
    silibs.use_sneak()
    eventArgs.handled = true
  elseif cmdParams[1] == 'invis' or cmdParams[1] == 'invisible' then
    silibs.use_invisible()
    eventArgs.handled = true
  elseif cmdParams[1] == 'usekey' or cmdParams[1] == 'noinvis' then
    send_command('cancel Invisible; cancel Hide; cancel Gestation; cancel Camouflage')
    if cmdParams[1] == 'usekey' then
      silibs.use_key()
    end
    eventArgs.handled = true
  elseif cmdParams[1] == 'faceaway' then
    windower.ffxi.turn(player.facing - math.pi);
    eventArgs.handled = true
  end
end

function silibs.use_sneak()
  local cmd
  -- If access to a spell or job ability (or multiples), attempt to use that (or those) first
  -- If JA not available, attempt to use spells that consume MP
  -- If those not available, attempt to use spells that consume items
  -- If those not available, attempt to use items
  if not cmd
    and silibs.can_access_ability("Spectral Jig")
    and silibs.can_recast_ability("Spectral Jig") then
    cmd = 'input /ja "Spectral Jig" <me>'
  end
  if not cmd
    and silibs.can_access_spell("Sneak") then
      cmd = 'input /ma "Sneak" <stpc>'
  end
  if not cmd
    and silibs.can_access_spell("Monomi: Ichi")
    and silibs.can_recast_spell("Monomi: Ichi", 5)
    and silibs.has_item('Inventory', 'Sanjaku-Tenugui') then
      cmd = 'input /ma "Monomi: Ichi" <me>'
  end
  if not cmd and silibs.has_item('Inventory','Silent Oil') then
    cmd = 'input /item "Silent Oil" <me>'
  end

  send_command(cmd)
end

function silibs.use_invisible()
  local cmd
  -- If access to a spell or job ability (or multiples), attempt to use that (or those) first
  -- If JA not available, attempt to use spells that consume MP
  -- If those not available, attempt to use spells that consume items
  -- If those not available, attempt to use items
  if not cmd
    and silibs.can_access_ability("Spectral Jig")
    and silibs.can_recast_ability("Spectral Jig") then
    cmd = 'input /ja "Spectral Jig" <me>'
  end
  if not cmd
    and silibs.can_access_spell("Invisible") then
      cmd = 'input /ma "Invisible" <stpc>'
  end
  if not cmd
    and silibs.can_access_spell("Tonko: Ni")
    and silibs.can_recast_spell("Tonko: Ni")
    and silibs.has_item('Inventory', 'Shinobi-Tabi') then
      cmd = 'input /ma "Tonko: Ni" <me>'
  end
  if not cmd
    and silibs.can_access_spell("Tonko: Ichi")
    and silibs.can_recast_spell("Tonko: Ichi")
    and silibs.has_item('Inventory', 'Shinobi-Tabi') then
      cmd = 'input /ma "Tonko: Ichi" <me>'
  end
  if not cmd and silibs.has_item('Inventory','Prism Powder') then
    cmd = 'input /item "Prism Powder" <me>'
  end

  send_command(cmd)
end

function silibs.use_key()
  if player.target.type ~= 'NONE' then
    if player.target.name == 'Sturdy Pyxis' then
      send_command('@input /item "Forbidden Key" <t>')
    elseif player.main_job == 'THF' then
      if silibs.has_item('Inventory','Skeleton Key') then
        send_command('@input /item "Skeleton Key" <t>')
      elseif silibs.has_item('Inventory','Living Key') then
        send_command('@input /item "Living Key" <t>')
      elseif silibs.has_item('Inventory','Thief\'s Tools') then
        send_command('@input /item "Thief\'s Tools" <t>')
      end
    end
  end
end

-- Utility function for automatically adjusting the waltz spell being used to match HP needs and TP limits.
-- If most appropriate Waltz is on cooldown, switch to next best match (higher tier if off cooldown and have the TP, otherwise lower)
function silibs.refine_waltz(spell, action, spellMap, eventArgs)
  -- In the case where this might be called from Selindrile lua, arguments are structured differently
  -- like so: refine_waltz(spell, spellMap, eventArgs)
  if not eventArgs then
    eventArgs = spellMap
    spellMap = action
  end
  if spell.type ~= 'Waltz' then
    return
  end

  -- Don't modify anything for Healing Waltz or Divine Waltzes
  if spell.english == "Healing Waltz" or spell.english == "Divine Waltz" or spell.english == "Divine Waltz II" then
    return
  end

  -- Trim waltz table to what's available for player's level
  local viable_waltzes = T{}
  
  for k,v in ipairs(silibs.curing_waltz) do
    if player.main_job == 'DNC' and player.main_job_level >= v.lv then
      viable_waltzes:append(v)
    elseif player.sub_job == 'DNC' and player.sub_job_level >= v.lv then
      viable_waltzes:append(v)
    end
  end

  -- If no viable waltzes, cancel operation
  if #viable_waltzes == 0 then
    add_to_chat(122,'Job requirement failed for '..spell.english'!')
    eventArgs.cancel = true
    return
  end

  local missingHP

  -- If curing ourself, get our exact missing HP
  if spell.target.type == "SELF" then
    missingHP = player.max_hp - player.hp
  -- If curing someone in our alliance, we can estimate their missing HP
  elseif spell.target.isallymember then
    local target = find_player_in_alliance(spell.target.name)
    local est_max_hp = target.hp / (target.hpp/100)
    missingHP = math.floor(est_max_hp - target.hp)
  else
    local est_max_hp = silibs.waltz_stats.est_non_party_target_hp
    missingHP = math.floor(est_max_hp - (est_max_hp * spell.target.hpp/100))
  end

  -- If missing HP cannot be calculated, or is too low, cancel operation
  -- Don't block when curing others to allow for waking them up.
  if not missingHP or (missingHP < 40 and spell.target.name == player.name) then
    add_to_chat(122,'Full HP!')
    eventArgs.cancel = true
    return
  end

  local waltz

  -- If we have an estimated missing HP value, we can adjust the preferred tier used.
  for k,v in ipairs(viable_waltzes) do
    if not waltz then
      if missingHP < silibs.waltz_cure_amount(k, spell.target) then
        if silibs.can_recast_ability(v.name) then
          waltz = v
        end
      end
    end
  end
  -- Default to highest tier if none selected yet (all higher than most appropriate are on cooldown)
  if not waltz then
    waltz = viable_waltzes:last()
  end

  -- Downgrade the spell to what we can afford that's not on cooldown
  if (player.tp < waltz.tp and not buffactive.trance) or not silibs.can_recast_ability(waltz.name) then
    local bad_tier = waltz.tier
    waltz = nil
    -- Loop down through viable waltzes starting at index for the current waltz tier
    for k,v in ipairs(viable_waltzes:reverse()) do
      if not waltz and v.tier < bad_tier and player.tp >= v.tp and silibs.can_recast_ability(v.name) then
        waltz = v
      end
    end
    -- If went through all viable waltzes and still don't have one selected, cancel operation
    if not waltz then
      add_to_chat(122, 'Insufficient TP ['..tostring(player.tp)..'] or all on cooldown. Cancelling.')
      eventArgs.cancel = true
      return
    end
  end

  if waltz.name ~= spell.english then
    send_command('@input /ja "'..waltz.name..'" '..tostring(spell.target.raw))
    eventArgs.cancel = true
    return
  end

  if missingHP and missingHP > 0 then
    add_to_chat(122,'Trying to cure '..tostring(missingHP)..' HP using '..waltz.name..'.')
  end
end

function silibs.set_waltz_stats(table)
  -- Write given values to settings table
  for k,v in pairs(table) do
    if rawget(silibs.waltz_stats,k) ~= nil then
      silibs.waltz_stats[k] = v
    else
      print('Silibs: Invalid waltz stat defined \''..tostring(k)..'\'')
    end
  end
end

function silibs.mark_th_tagged(target_type)
  -- Use TH set using offensive ability, if TH mode is on, and mob hasn't been hit yet
  if target_type == "MONSTER" and state.TreasureMode.value ~= 'None' and not info.tagged_mobs[target_id] then
    silibs.prev_action_applied_TH = true
  else
    silibs.prev_action_applied_TH = false
  end
end

-- Marks enemy as tagged with TH set if "true" is returned
function silibs.th_action_check(category, param)
  return silibs.prev_action_applied_TH
end


-------------------------------------------------------------------------------
-- Helpful/Supporting functions
-------------------------------------------------------------------------------
function silibs.find_ability(ability_name)
  return res.job_abilities:find(function(ability)
    return ability.en == ability_name
  end)
end

function silibs.find_spell(spell_name)
  return res.spells:find(function(s)
    return s.en == spell_name
  end)
end

function silibs.can_access_ability(ability_name)
  local ability_ids = S(windower.ffxi.get_abilities().job_abilities)
  return ability_ids:contains(silibs.find_ability(ability_name))
end

function silibs.can_access_spell(spell_name)
  local _, spell = silibs.find_spell(spell_name)
  local has_learned_spell = windower.ffxi.get_spells()[spell.id] ~= nil
	local spell_jobs = res.spells[spell.id].levels

	-- Filter for spells that you do not know. Exclude Impact, Honor March and Dispelga.
	if not has_learned_spell and not (spell.id == 503 or spell.id == 417 or spell.id == 360) then
		return false
	-- Filter for spells that you know, but do not currently have access to
	elseif (not spell_jobs[player.main_job_id]
      or not (spell_jobs[player.main_job_id] <= player.main_job_level
        or (spell_jobs[player.main_job_id] >= 100
          and silibs.number_of_jps(player.job_points[(res.jobs[player.main_job_id].ens):lower()]) >= spell_jobs[player.main_job_id]
        )
      )
    )
    and (not spell_jobs[player.sub_job_id] or not (spell_jobs[player.sub_job_id] <= player.sub_job_level)) then
		  return false
	elseif res.spells[spell.id].type == 'BlueMagic'
    and not (
      (player.main_job_id == 16
        and (data.spells.unbridled:contains(res.spells[spell.id].en)
         or table.contains(windower.ffxi.get_mjob_data().spells,spell.id)
        )
      )
      or (player.sub_job_id == 16 and table.contains(windower.ffxi.get_sjob_data().spells,spell.id))
    ) then	
		  return false
	else
		return true
	end
end

function silibs.can_recast_ability(ability_name, time)
  time = time or 1
  local _, ability = silibs.find_ability(ability_name)
  return windower.ffxi.get_ability_recasts()[ability.recast_id] <= time
end

function silibs.can_recast_spell(spell_name, time)
  time = time or 1
  local _, spell = silibs.find_spell(spell_name)
  return windower.ffxi.get_spell_recasts()[spell.recast_id] <= time
end

function silibs.number_of_jps(jp_tab)
    local count = 0
    for _,v in pairs(jp_tab) do
        count = count + v*(v+1)
    end
    return count/2
end

-- Cure 3 - 503

-- Values used for calculations can be customized in player's lua by setting silibs.waltz_stats
function silibs.waltz_cure_amount(tier, target)
  -- HP Cured = floor(
  --              floor(Slope×(User's CHR + Target's VIT) + Base + 2*(Waltz Job Point Tiers))
  --              × (Waltz Potency gear + Waltz Potency Received gear)
  --            )

  -- Determine slope (main vs sub DNC)
  -- The slope is halved when Dancer is subbed.
  local slope = silibs.curing_waltz[tier].cure_slope
  if player.main_job == 'DNC' then
    slope = slope
  elseif player.sub_job == 'DNC' then
    slope = 0.5 * slope
  else
    return
  end

  local cure_base = silibs.curing_waltz[tier].cure_base

  -- Get stats (these are not 100% up-to-date, has about 1-2 seconds lag)
  local base_chr = silibs.playerStats["Base"]["CHR"] or silibs.waltz_stats.base_chr
  local base_vit = silibs.playerStats["Base"]["VIT"] or silibs.waltz_stats.base_vit
  local bonus_chr = silibs.playerStats["Bonus"]["CHR"] or silibs.waltz_stats.bonus_chr
  local bonus_vit = silibs.playerStats["Bonus"]["VIT"] or silibs.waltz_stats.bonus_vit

  if not target then
    return
  end

  local isTargetingSelf = target.name == player.name
  local waltz_jp_count = 0
  if player.main_job == 'DNC' then
    waltz_jp_count = player.job_points.dnc.waltz_potency
  end

  -- Add waltz potency from gear.
  -- Enforce game's caps: waltz potency gear 50%; waltz potency received gear 30%
  local potency = math.min(silibs.waltz_stats.waltz_potency, 50)
  if isTargetingSelf then
    potency = potency + math.min(silibs.waltz_stats.waltz_self_potency, 30)
  end
  potency = potency / 100 -- convert to percentiles for mathing

  return math.floor(
    math.floor((slope * (base_chr + bonus_chr + base_vit + bonus_vit)) + cure_base + (2 * waltz_jp_count))
    * (1+potency)
  )
end

-------------------------------------------------------------------------------
-- Feature-enabling functions
-------------------------------------------------------------------------------
function silibs.enable_cancel_outranged_ws()
  silibs.cancel_outranged_ws_enabled = true
end

function silibs.enable_cancel_on_blocking_status()
  silibs.cancel_on_blocking_status_enabled = true
end

function silibs.enable_weapon_rearm()
  silibs.weapon_rearm_enabled = true
end

function silibs.enable_auto_lockstyle(set_number)
  if set_number then
    silibs.lockstyle_set = set_number
    silibs.auto_lockstyle_enabled = true
    silibs.set_lockstyle(set_number)
  end
end

function silibs.enable_waltz_refiner(table)
  if not table then table = {} end
  silibs.set_waltz_stats(table)
  -- Overwrite the global function refine_waltz with our own.
  refine_waltz = silibs.refine_waltz
end

function silibs.enable_th_fix()
  silibs.th_fix_enabled = true
  th_action_check = silibs.th_action_check
end


-------------------------------------------------------------------------------
-- Gearswap lifecycle hooks
-------------------------------------------------------------------------------
function silibs.precast_hook(spell, action, spellMap, eventArgs)
  if silibs.cancel_outranged_ws_enabled then
    silibs.cancel_outranged_ws(spell, eventArgs)
  end
  if silibs.cancel_on_blocking_status_enabled then
    silibs.cancel_on_blocking_status(spell, eventArgs)
  end
end

function silibs.post_precast_hook(spell, action, spellMap, eventArgs)
  if silibs.th_fix_enabled then
    -- Equip TH gear if appropriate
    if spell.target.type == "MONSTER" and state.TreasureMode.value ~= 'None' and not info.tagged_mobs[spell.target.id]then
      equip(sets.TreasureHunter)
    end

    -- Mark enemy as tagged
    silibs.mark_th_tagged(spell.target.type) -- Probably move this to aftercast
  end
end

function silibs.midcast_hook(spell, action, spellMap, eventArgs)
end

function silibs.post_midcast_hook(spell, action, spellMap, eventArgs)
  if silibs.th_fix_enabled then
    silibs.mark_th_tagged(spell.target.type)
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
    if silibs.weapon_rearm_enabled then
      silibs.update_and_rearm_weapons()
      frame_count = 0
    end
  else
    frame_count = frame_count + 1
  end
end)

-- Hook into job/subjob change event (happens BEFORE job starts changing)
windower.raw_register_event('outgoing chunk', function(id, data, modified, injected, blocked)
  if id == 0x100 then -- Sending job change command to server
    -- Re-init settings if changing main
    local newmain = data:byte(5)
    local newsub = data:byte(6)
    if res.jobs[newmain] and newmain ~= 0 and newmain ~= player.main_job_id then
      silibs.init_settings()
    elseif res.jobs[newsub] and newsub ~= 0 and newsub ~= player.sub_job_id then
      silibs.set_lockstyle()
    end
  elseif id == 0x053 then -- Send lockstyle command to server
    local type = data:unpack("I",0x05)
    if type == 0 then -- This is lockstyle 'disable' command
      silibs.locked_style = false
    else -- Various diff ways to set lockstyle
      silibs.locked_style = true
    end
  end
end)

-- Set lockstyle again when encumbrance value changes (which disables lockstyle as a side effect)
windower.raw_register_event('incoming chunk', function(id, data, modified, injected, blocked)
  if id == 0x01B then -- Contains info about player's encumbrance status
    local encumbrance = data:unpack('I',0x61)
    if encumbrance ~= silibs.encumbrance then
      silibs.locked_style = false
      silibs.encumbrance = encumbrance
      silibs.set_lockstyle()
    end
  elseif id == 0x061 then -- Contains info about player stats
    local p = packets.parse('incoming', data)
    local player = windower.ffxi.get_player()

    silibs.playerStats["Base"]["STR"] = p["Base STR"] -- Includes STR merits
    silibs.playerStats["Base"]["DEX"] = p["Base DEX"] -- Includes DEX merits
    silibs.playerStats["Base"]["VIT"] = p["Base VIT"] -- Includes VIT merits
    silibs.playerStats["Base"]["AGI"] = p["Base AGI"] -- Includes AGI merits
    silibs.playerStats["Base"]["INT"] = p["Base INT"] -- Includes INT merits
    silibs.playerStats["Base"]["MND"] = p["Base MND"] -- Includes MND merits
    silibs.playerStats["Base"]["CHR"] = p["Base CHR"] -- Includes CHR merits
    silibs.playerStats["Bonus"]["STR"] = p["Added STR"]
    silibs.playerStats["Bonus"]["DEX"] = p["Added DEX"]
    silibs.playerStats["Bonus"]["VIT"] = p["Added VIT"]
    silibs.playerStats["Bonus"]["AGI"] = p["Added AGI"]
    silibs.playerStats["Bonus"]["INT"] = p["Added INT"]
    silibs.playerStats["Bonus"]["MND"] = p["Added MND"]
    silibs.playerStats["Bonus"]["CHR"] = p["Added CHR"]
  end
end)

return silibs
