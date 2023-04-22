cs_common = cs_common or {}
local cs = cs_common

cs.game = {}



--units
cs.u = {}
cs.u.mouseover = "mouseover"
cs.u.target = "target"
cs.u.player = "player"


-- target
cs.t = {}
cs.t.friend = UnitIsFriend
cs.t.enemy = UnitIsEnemy
cs.t.exists = UnitExists
cs.t.dead = UnitIsDead
cs.t.player = UnitIsPlayer
cs.t.self = UnitIsUnit
cs.t.close_10 = "t_close_10"
cs.t.close_30 = "t_close_30"
cs.t.attackable = "t_attackable"
cs.t.fr_player = "t_fr_player"
cs.t.en_player = "t_en_player"


-- check condition by OR
function cs.check_unit(check, unit)
  if check == cs.t.close_10 then
    return CheckInteractDistance("target", 2)
  elseif check == cs.t.close_30 then
    return CheckInteractDistance("target", 4)
  elseif check == cs.t.fr_player then
    return cs.check_unit(cs.t.friend, unit) and cs.check_unit(cs.t.player, unit)
  elseif check == cs.t.en_player then
    return cs.check_unit(cs.t.enemy, unit) and cs.check_unit(cs.t.player, unit)
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








function cs.get_hp_level()
  -- 0-1
  return UnitHealth("player") / UnitHealthMax("player")
end

function cs.is_in_party()
  return GetNumPartyMembers() ~= 0
end

function cs.auto_attack()
  if not cs.check_target(cs.t.exists) then
    -- no auto check target
    return
  end

  if cs.check_target(cs.t.en_player) and cs.st_map_checker:get_zone_params().nopvp then
    ClearTarget()
    return
  end

  if not cs.check_combat(cs.c.normal) then
    AttackTarget()
  elseif cs.check_target(cs.t.friend) then
    AssistUnit("target")
  end
end







---@class cs.MapChecker
cs.MapChecker = cs.create_class()

cs.MapChecker.build = function()
  local map_checker = cs.MapChecker:new()

  map_checker.zone_text = ""
  map_checker.map_name = ""

  map_checker.zone_params = {}
  map_checker.zone_params["Booty Bay"] = { nopvp = true }

  local f = cs.create_simple_frame("cs.MapChecker.build")
  f.cs_map_checker = map_checker

  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  f:RegisterEvent("ZONE_CHANGED")
  f:SetScript("OnEvent", function()
    cs.once_event(2, this.cs_map_checker, cs.MapChecker._update)
  end)

  cs.once_event(2, map_checker, cs.MapChecker._update)

  return map_checker
end

-- const
function cs.MapChecker:get_zone_text()
  return self.zone_text
end

function cs.MapChecker:get_zone_params()
  local params = self.zone_params[self.zone_text]
  return params or {}
end

function cs.MapChecker:_update()
  self.zone_text = GetMinimapZoneText()
  self.map_name = GetMapInfo()
end

---@type cs.MapChecker
cs.st_map_checker = nil













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
  local x = 370
  local diff_x = 0

  checker.data = {}
  local data = checker.data

  data.aggro = {
    name = "aggro",
    color = cs.color.red,
    text = cs.create_simple_text_frame("", "BOTTOMLEFT", x - 2 * diff_x, y + 2 * diff_y, "0", "CENTER", false),
    ts_enter = GetTime(),
  }
  data.combat = {
    name = "combat",
    color = cs.color.orange,
    text = cs.create_simple_text_frame("", "BOTTOMLEFT", x - diff_x, y + diff_y, "0", "CENTER", false),
    ts_enter = GetTime(),
  }
  data.affect = {
    name = "affect",
    color = cs.color.yellow,
    text = cs.create_simple_text_frame("", "BOTTOMLEFT", x, y, "0", "CENTER", false),
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

      data.text.cs_text:SetText(data.color .. dur)
    else
      data.text.cs_text:SetText(" ")
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
cs.c.normal = cs.get_combat_info
cs.c.aggro = cs.get_aggro_info
cs.c.affect = cs.get_affect_info

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


cs.game.init = function()
  cs.st_map_checker = cs.MapChecker.build()
end
