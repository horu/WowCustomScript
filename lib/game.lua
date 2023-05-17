
local cs = cs_common

--class
cs.cl = {}
cs.cl.WARRIOR = "WARRIOR"
cs.cl.PALADIN = "PALADIN"
cs.cl.HUNTER = "HUNTER"
cs.cl.ROGUE = "ROGUE"

cs.cl.SHAMAN = "SHAMAN"
cs.cl.DRUID = "DRUID"

cs.cl.PRIEST = "PRIEST"
cs.cl.MAGE = "MAGE"
cs.cl.WARLOCK = "WARLOCK"


--units
cs.u = {}
cs.u.mouseover = "mouseover"
cs.u.target = "target"
cs.u.player = "player"
cs.u.party = {}
for i=1,5 do table.insert(cs.u.party, i, "party"..i) end
cs.u.partypet = {}
for i=1,5 do table.insert(cs.u.partypet, i, "partypet"..i) end


-- target
cs.t = {}
cs.t.friend = UnitIsFriend
cs.t.enemy = UnitIsEnemy
cs.t.exists = UnitExists
cs.t.dead = UnitIsDead
cs.t.player = UnitIsPlayer
cs.t.self = UnitIsUnit
cs.t.close_9 = "t_close_9"
cs.t.close_10 = "t_close_10"
cs.t.close_30 = "t_close_30"
cs.t.attackable = "t_attackable"
cs.t.fr_player = "t_fr_player"
cs.t.en_player = "t_en_player"
cs.t.undead = "cs.t.undead"


-- check condition by OR
function cs.check_unit(check, unit)
  if check == cs.t.close_9 then
    return CheckInteractDistance(unit, 1)
  elseif check == cs.t.close_10 then
    return CheckInteractDistance(unit, 2)
  elseif check == cs.t.close_30 then
    return CheckInteractDistance(unit, 4)
  elseif check == cs.t.fr_player then
    return cs.check_unit(cs.t.friend, unit) and cs.check_unit(cs.t.player, unit)
  elseif check == cs.t.en_player then
    return cs.check_unit(cs.t.enemy, unit) and cs.check_unit(cs.t.player, unit)
  elseif check == cs.t.undead then
    local target = UnitCreatureType(cs.u.target)
    return target == "Demon" or target == "Undead"
  elseif check == cs.t.attackable then
    return cs.check_unit(cs.t.exists, unit) and
            not cs.check_unit(cs.t.friend, unit) and
            not cs.check_unit(cs.t.dead, unit)
  end

  return check(unit, cs.u.player)
end

function cs.check_target(check)
  return cs.check_unit(check, cs.u.target)
end

function cs.check_mouse(check)
  return cs.check_unit(check, cs.u.mouseover)
end

function cs.check_target_hp(limit)
  if not limit then
    return
  end

  local target_hp = UnitHealth(cs.u.target) or 0
  return target_hp <= limit
end

function cs.check_target_hp_perc(limit_perc)
  if not limit_perc then
    return
  end

  local target_hp_max_perc = UnitHealthMax(cs.u.target) or 0
  local limit_hp = limit_perc * target_hp_max_perc
  return cs.check_target_hp(limit_hp)
end


function cs.get_talent_rank(name)
  for page = 1,3 do
    for id = 1, 50 do
      local it_name, _, _, _, rank = GetTalentInfo(page, id)
      if not it_name then
        break
      end

      if it_name == name then
        return rank
      end
    end
  end
end


cs.get_party_max_hp_sum = function()
  -- TODO
end

cs.skill = {}
cs.skill.n = {}
cs.skill.n.riding = "Riding"

cs.skill.get_rank = function(skill_name)
  for i=1, GetNumSkillLines() do
    local name, _, _, rank = GetSkillLineInfo(i)
    if skill_name == name then
      return rank
    end
  end
end


function cs.get_mana_level()
  -- 0-1
  return UnitMana(cs.u.player) / UnitManaMax(cs.u.player)
end

function cs.is_low_mana()
  return cs.get_mana_level() <= 0.15
end


function cs.get_hp_level()
  -- 0-1
  return UnitHealth(cs.u.player) / UnitHealthMax(cs.u.player)
end

function cs.is_in_party()
  return GetNumPartyMembers() ~= 0
end

cs.iterate_party = function(func)
  local size = GetNumPartyMembers()
  for i=1, size do
    func(cs.u.party[i], i)
  end
end

cs.get_party_hp_sum = function()
  local sum = UnitHealthMax(cs.u.player)
  cs.iterate_party(function(unit)
    if not cs.check_unit(cs.t.close_30, unit) then
      return
    end
    sum = sum + UnitHealthMax(unit)
  end)
  return sum
end

function cs.auto_attack()
  if not cs.check_target(cs.t.exists) then
    -- no auto check target
    return
  end

  if cs.check_target(cs.t.en_player) and cs.map.checker:get_zone_params().nopvp then
    ClearTarget()
    return
  end

  if cs.check_target(cs.t.friend) then
    AssistUnit("target")
  elseif not cs.check_combat(cs.c.normal) then
    AttackTarget()
  end
  return true
end

cs.auto_attack_nearby = function()
  if cs.check_target(cs.t.close_9) then
    return
  end

  local has_target = cs.check_target(cs.t.exists)

  for i=1,10 do
    if cs.check_target(cs.t.close_9) then
      break
    end
    TargetNearestEnemy()
  end

  if cs.check_target(cs.t.close_9) then
    cs.event.once(0.2, cs.auto_attack)
    cs.event.once(0.6, cs.auto_attack)
  elseif not has_target then
    ClearTarget()
  end
end

cs.attack_target_max_hp = function()
  local has_target = cs.check_target(cs.t.exists)

  local max_hp = 0
  for i=1,10 do
    if cs.check_target(cs.t.close_9) then
      local hp = UnitHealth(cs.u.target)
      max_hp = math.max(max_hp, hp)
    end
    TargetNearestEnemy()
  end

  for i=1,10 do
    local hp = UnitHealth(cs.u.target)
    if hp + 100 >= max_hp then
      break
    end
    TargetNearestEnemy()
  end

  if cs.check_target(cs.t.close_9) then
    cs.event.once(0.2, cs.auto_attack)
    cs.event.once(0.6, cs.auto_attack)
  elseif not has_target then
    ClearTarget()
  end
end



cs_map_data = {}

---@class cs.MapChecker
cs.MapChecker = cs.class()

cs.MapChecker.zone_params = {}
cs.MapChecker.zone_params["Booty Bay"] = { nopvp = true }
cs.MapChecker.zone_params["Everlook"] = { nopvp = true }

cs.MapChecker.map_params = {}
cs.MapChecker.map_params["WarsongGulch"] = { pvp = true }
cs.MapChecker.map_params["ArathiBasin"] = { pvp = true }
--cs.MapChecker.map_params["AlteracValley"] = { pvp = true }

cs.MapChecker.map_params["EasternPlaguelands"] = { argent_dawn = true }
cs.MapChecker.map_params["WesternPlaguelands"] = { argent_dawn = true }
cs.MapChecker.map_params["Stratholme"] = { argent_dawn = true }
cs.MapChecker.map_params["Scholomance"] = { argent_dawn = true }
cs.MapChecker.map_params["Scholomance1f"] = { argent_dawn = true }
cs.MapChecker.map_params["Scholomance2f"] = { argent_dawn = true }
cs.MapChecker.map_params["Scholomance3f"] = { argent_dawn = true }
cs.MapChecker.map_params["Scholomance4f"] = { argent_dawn = true }

--region cs.MapChecker
function cs.MapChecker:build()
  self.subscribers = {}

  self.zone_text = ""
  self.map_name = ""

  local f = cs.create_simple_frame()
  f.cs_map_checker = self

  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  f:RegisterEvent("ZONE_CHANGED")
  f:RegisterEvent("MINIMAP_ZONE_CHANGED")
  f:RegisterEvent("WORLD_MAP_UPDATE")
  f:SetScript("OnEvent", function()
    cs.event.rep(3, 3, this.cs_map_checker, self._on_zone_changed)
  end)

  cs.event.once(2, self, self._on_zone_changed)
end

-- const
function cs.MapChecker:get_zone_text()
  return self.zone_text
end

-- const
-- from static zone_params/map_params
function cs.MapChecker:get_zone_params()
  local zone_params = self.zone_params[self.zone_text] or {}
  local map_params = self.map_params[self.map_name] or {}
  for name, value in pairs(map_params) do
    zone_params[name] = value
  end
  return zone_params
end

-- const
-- from cs_map_data
function cs.MapChecker:get_map_params()
  cs_map_data[self.map_name] = cs_map_data[self.map_name] or { name = self.map_name }
  return cs_map_data[self.map_name]
end

function cs.MapChecker:subscribe(obj, func)
  table.insert(self.subscribers, {obj = obj, func = func})
end

function cs.MapChecker:_on_zone_changed()
  self.zone_text = GetMinimapZoneText() or self.zone_text

  local new_map_name = GetMapInfo()
  if new_map_name and new_map_name ~= self.map_name then
    self.map_name = new_map_name
    for _, sub in self.subscribers do
      sub.func(sub.obj)
    end
  end
end
--endregion cs.MapChecker

cs.map = {}
---@type cs.MapChecker
cs.map.checker = nil



---@class cs.CombatChecker
cs.CombatChecker = cs.create_class()

function cs.CombatChecker.build()
  local combat_frame = cs.create_simple_frame()

  combat_frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
  combat_frame:RegisterEvent("PLAYER_ENTER_COMBAT")
  combat_frame:SetScript("OnEvent", function()
    local combat = this.cs_checker.data.combat

    if event == "PLAYER_ENTER_COMBAT" then
      combat.ts_enter = GetTime()
      combat.ts_leave = nil
      combat.status = true
    end

    if event == "PLAYER_LEAVE_COMBAT" then
      combat.ts_leave = GetTime()
      combat.status = false
    end
  end)

  ---@type cs.CombatChecker
  local checker = cs.CombatChecker:new()

  local y = 43
  local diff_y = 17
  local x = GetScreenWidth() / 2 - 10
  local diff_x = 0

  checker.data = {}
  local data = checker.data

  data.aggro = {
    name = "aggro",
    color = cs.color.red,
    text = cs.ui.Text:build_from_config({x=x - 2 * diff_x, y=y + 2 * diff_y, text_relative=cs.ui.r.CENTER}),
    ts_enter = GetTime(),
  }
  data.combat = {
    name = "combat",
    color = cs.color.orange,
    text = cs.ui.Text:build_from_config({x=x - diff_x, y=y + diff_y, text_relative=cs.ui.r.CENTER}),
    ts_enter = GetTime(),
  }
  data.affect = {
    name = "affect",
    color = cs.color.yellow,
    text = cs.ui.Text:build_from_config({x=x, y=y, text_relative=cs.ui.r.CENTER}),
    ts_enter = GetTime(),
  }

  combat_frame.cs_checker = checker

  cs.add_loop_event("st_combat_frame", 0.1, checker, checker._check_combat)
  cs.add_loop_event("st_combat_frame_report", 1, checker, checker._report_status)
  return checker
end

function cs.CombatChecker:_report_status()
  local ts = GetTime()
  for _, data in pairs(self.data) do
    if data.status then
      local dur = math.floor(ts - data.ts_enter)
      if dur >= 100 then
        dur = math.floor(dur / 60) .. "m"
      end

      data.text:set_text(data.color .. dur)
    else
      data.text:set_text(" ")
    end
  end
end

function cs.CombatChecker:_handle(data, status, time_gap)
  local ts = GetTime()
  data.status = status
  if data.status then
    -- in fight
    if data.ts_leave then
      -- first tick after end of fight
      if cs.compare_time(time_gap, data.ts_leave) then
        -- end of tigh happend recently. extend previus session.
      else
        -- begin a new session
        data.ts_enter = ts
      end
    end
    data.ts_leave = nil
  elseif not data.ts_leave then
    -- out of fight
    data.ts_leave = ts
  end
  return data
end

function cs.CombatChecker:_check_combat()
  local data = self.data
  data.aggro = self:_handle(data.aggro, pfUI.api.UnitHasAggro("player") > 0, 3)
  data.affect = self:_handle(data.affect, UnitAffectingCombat("player") or false, 0)
end

local st_combat_checker = cs.CombatChecker.build()

function cs.get_combat_info()
  return st_combat_checker.data.combat
end

function cs.get_aggro_info()
  return st_combat_checker.data.aggro
end

function cs.get_affect_info()
  return st_combat_checker.data.affect
end

-- combat
cs.c = {}
-- player attack with weapon
cs.c.normal = cs.get_combat_info
-- anybody attack player
cs.c.aggro = cs.get_aggro_info
-- common combat state, when mount is not available and other...
cs.c.affect = cs.get_affect_info

-- example: check_combat(2) - check normal + agro + 2 sec after
-- example: check_combat() - check normal + agro
-- example: check_combat(cs.c.affect) - check affect only
function cs.check_combat(m0or, m1or, m2or, m3or)
  local to_check
  local time_after
  if type(m0or) == "number" then
    to_check = { m1or, m2or, m3or }
    time_after = m0or
  else
    to_check = { m0or, m1or, m2or, m3or }
    time_after = 0
  end

  if not to_check[1] then
    -- default normal + agro
    to_check = { cs.c.normal, cs.c.aggro }
  end

  for _, check in pairs(to_check) do
    local info = check()
    if info.status or cs.compare_time(time_after, info.ts_leave) then
      return true
    end
  end
end



cs.is_party_player_exists = function(player_name)
  local size = GetNumPartyMembers()
  for i=1, size do
    local unit = "party"..i
    if UnitName(unit) == player_name then
      return true
    end
  end
end




cs.game = {}
cs.game.init = function()
  cs.map.checker = cs.MapChecker:new()
end

cs.game.test = function()
  cs.get_party_hp_sum()
end
