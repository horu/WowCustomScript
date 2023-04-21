
cs_common = cs_common or {}
local cs = cs_common





--units
cs.u_mouseover = "mouseover"
cs.u_target = "target"
cs.u_player = "player"

-- target
cs.t_friend = UnitIsFriend
cs.t_enemy = UnitIsEnemy
cs.t_exists = UnitExists
cs.t_dead = UnitIsDead
cs.t_player = UnitIsPlayer
cs.t_self = UnitIsUnit
cs.t_close = "t_close"
cs.t_close_30 = "t_close_30"
cs.t_attackable = "t_attackable"
cs.t_fr_player = "t_fr_player"
cs.t_en_player = "t_en_player"

-- check condition by OR
function cs.check_unit(check, unit)
  if check == cs.t_close then
    return CheckInteractDistance("target", 2)
  elseif check == cs.t_close_30 then
    return CheckInteractDistance("target", 4)
  elseif check == cs.t_fr_player then
    return cs.check_unit(cs.t_friend, unit) and cs.check_unit(cs.t_player, unit)
  elseif check == cs.t_en_player then
    return cs.check_unit(cs.t_enemy, unit) and cs.check_unit(cs.t_player, unit)
  elseif check == cs.t_attackable then
    return cs.check_unit(cs.t_exists, unit) and
            not cs.check_unit(cs.t_friend, unit) and
            not cs.check_unit(cs.t_dead, unit)
  end

  return check(unit, cs.u_player)
end

function cs.check_target(check)
  return cs.check_unit(check, cs.u_target)
end

function cs.check_mouse(check)
  return cs.check_unit(check, cs.u_mouseover)
end










function cs.get_hp_level() -- 0-1
  return UnitHealth("player")/UnitHealthMax("player")
end

function cs.is_in_party()
  return GetNumPartyMembers() ~= 0
end

function cs.auto_attack()
  local prev_target = cs.check_target(cs.t_exists)

  if not prev_target then
    TargetNearestEnemy()

    local i = 1
    while cs.check_target(cs.t_en_player) do
      if cs.st_map_checker:get_zone_params().nopvp or i > 5 then
        cs.debug("CLEARTARGET", cs.st_map_checker:get_zone_text())
        ClearTarget()
        return
      end

      TargetNearestEnemy()

      i = i + 1
    end
  end

  if not cs.check_combat(cs.c_normal) then

    if not cs.check_target(cs.t_close_30) then
      return
    end

    AttackTarget()
  elseif cs.check_target(cs.t_friend) then
    AssistUnit("target")
  end
end







---@class cs.MapChecker
cs.MapChecker = cs.create_class()

cs.MapChecker.build = function()
    local map_checker = cs.MapChecker:new()

    map_checker.zone_text = ""

    map_checker.f = cs.create_simple_frame("cs.MapChecker.build")
    map_checker.f.cs_parrent = map_checker

    map_checker.f:RegisterEvent("PLAYER_ENTERING_WORLD")
    map_checker.f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    map_checker.f:RegisterEvent("ZONE_CHANGED")
    map_checker.f:SetScript("OnEvent", function()
        cs.add_loop_event("map_checker.f:SetScript", 0.5, this.cs_parrent, cs.MapChecker.update_zone, 5)
    end)

    map_checker.params = {}
    map_checker.params["Booty Bay"] = { nopvp = true }

    return map_checker
end

-- const
function cs.MapChecker:get_zone_text()
    return self.zone_text
end

function cs.MapChecker:get_zone_params()
    local params = self.params[self.zone_text]
    return params or {}
end

function cs.MapChecker:update_zone()
    self.zone_text = GetMinimapZoneText()
end


---@type cs.MapChecker
cs.st_map_checker = cs.MapChecker.build()









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
        color = cs.color_red,
        text = cs.create_simple_text_frame("", "BOTTOMLEFT", x-2*diff_x, y+2*diff_y, "0", "CENTER", false),
        ts_enter = GetTime(),
    }
    data.combat = {
        name = "combat",
        color = cs.color_orange,
        text = cs.create_simple_text_frame("", "BOTTOMLEFT", x-diff_x, y+diff_y, "0", "CENTER", false),
        ts_enter = GetTime(),
    }
    data.affect = {
        name = "affect",
        color = cs.color_yellow,
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
                dur = math.floor(dur / 60).."m"
            end

            data.text.cs_text:SetText(data.color..dur)
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


cs.c_normal = cs.get_combat_info
cs.c_aggro = cs.get_aggro_info
cs.c_affect = cs.get_affect_info

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
        to_check = { cs.c_normal, cs.c_aggro }
    end

    for _, check in pairs(to_check) do
        local info = check()
        if info.status or cs.compare_time(time_after, info.ts_leave) then
            return true
        end
    end
end


