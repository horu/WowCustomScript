local cs = cs_common

cs.services = {}

local dps_frame = {
  target = { "nibsrsCSdps", "BOTTOMLEFT", 1150, 94, "DPS", false, true },
  player = { "nibsrsCSdps", "BOTTOMLEFT", 347, 94, "DPS", "RIGHT", true },
}
local spd_checker_frame = { "speed_checker", "BOTTOMLEFT", 10, 94, "0", false, true }



-- To templorary change target, save combat mode and return to previous target
---@class cs.Targeter
cs.Targeter = cs.create_class()

function cs.Targeter.build()
  local targeter = cs.Targeter:new()

  return targeter
end

function cs.Targeter:set_target_mouse()
  if self.in_progress then
    return
  end
  self.in_progress = 1

  self.prev_target = cs.check_target(cs.t.exists)
  self.prev_combat = cs.check_combat(cs.c.normal)

  if UnitExists(cs.u.mouseover) then
    self.cur_target = cs.u.mouseover
    TargetUnit(cs.u.mouseover)
  else
    self.in_progress = 3
    self:completion()
  end
end

function cs.Targeter:set_last_target()
  if self.in_progress ~= 1 then
    return
  end
  self.in_progress = 2

  if self.prev_target then
    TargetLastTarget()
  else
    ClearTarget()
  end

  if self.prev_combat then
    cs.add_loop_event("Targeter2", 0.4, self, cs.Targeter.deffered_set_combat_mode, 1)
  else
    self.in_progress = 3
    self:completion()
  end
end

function cs.Targeter:deffered_set_combat_mode()
  --cs.debug(self)
  if self.in_progress ~= 2 then
    return
  end

  self.in_progress = 3

  if self.prev_combat then
    if not cs.check_combat(cs.c.normal) then
      AttackTarget()
    end
  end

  cs.add_loop_event("Targeter3", 0.4, self, cs.Targeter.completion, 1)
end

function cs.Targeter:completion()
  --cs.debug(self)
  if self.in_progress ~= 3 then
    return
  end

  self.in_progress = 4

  self.cur_target = nil
  self.in_progress = nil
  self.prev_combat = nil
  self.prev_target = nil
end

local st_targeter = cs.Targeter.build()












---@class cs.DpsSession
cs.DpsSession = cs.create_class_(function()
  ---@type cs.DpsSession
  local session = cs.DpsSession:new()
  session.damage_sum = 0
  session.ts_sum = 0
  session.first_ts = cs.max_number_32
  session.last_ts = 0
  return session
end)
--region

-- const
function cs.DpsSession:get_avg()
  if self.ts_sum <= 0 then
    return 0
  end
  return self.damage_sum / self.ts_sum
end

function cs.DpsSession:update(damage, last_ts, cur_ts)
  self.damage_sum = self.damage_sum + damage
  self.ts_sum = self.ts_sum + cur_ts - last_ts
  self.first_ts = math.min(self.first_ts, last_ts)
  self.last_ts = math.max(self.last_ts, cur_ts)
end

function cs.DpsSession:is_expired(ts)
  return not cs.compare_time(10, self.last_ts, ts)
end
--endregion


cs_dps_sessions = { target = {}, player = {} }

---@class cs.DpsData
cs.DpsData = cs.create_class_(function(unit)
  ---@type cs.DpsData
  local data = cs.DpsData:new()
  data.sessions = cs_dps_sessions[unit]
  local ts = GetTime()
  -- remove expired sessions from saves
  for it in pairs(data.sessions) do
    if not cs.compare_time(cs.Dps.session_store_limit_ts, it, ts) or it >= ts then
      data.sessions[it] = nil
    end
  end

  data.start_ts = nil
  data.last_ts = nil

  return data
end)
--region

function cs.DpsData:get_all(after_ts)
  if not after_ts then
    after_ts = 0
  end

  ---@type cs.DpsSession
  local session = cs.DpsSession.build()
  for start_ts, it in pairs(self.sessions) do
    local session_time = it.last_ts
    if session_time >= after_ts then
      session:update(it.damage_sum, start_ts, start_ts + it.ts_sum)
    end
  end
  return session
end
--endregion

---@class cs.Dps
cs.Dps = cs.create_class_(function(unit, frame_config)
  ---@type cs.Dps
  local dps = cs.Dps:new()
  dps.unit = unit
  dps.data = cs.DpsData.build(unit)
  dps:_init(frame_config)
  dps:_handler("", unit, 0)
  return dps
end)
--region

cs.Dps.session_store_limit_ts = 3600 * 2

function cs.Dps:get_dps()
  local session = self.data:get_all()
  return session:get_avg()
end

function cs.Dps:_handler(event, target, damage)
  ---@type cs.DpsData
  local data = self.data
  local ts = GetTime()

  if data.start_ts then
    local cur_session = data.sessions[data.start_ts]
    if event == "PLAYER_LEAVE_COMBAT" or
            event == "SPELLCAST_START" or
            event == "PLAYER_TARGET_CHANGED" or
            cur_session:is_expired(ts)
    then
      -- close session
      data.start_ts = nil
      data.last_ts = nil
      return
    end
  end

  if target ~= self.unit then
    return
  end

  if not data.start_ts then
    -- combat first damage. create session

    data.sessions[ts] = data.sessions[ts] or cs.DpsSession.build()

    data.start_ts = ts
    data.last_ts = ts
  end

  ---@type cs.DpsSession
  local cur_session = data.sessions[data.start_ts]

  cur_session:update(damage, data.last_ts, ts)

  data.last_ts = ts
  self:_update_output()
end

function cs.Dps:_init(dps_frame_config)
  local f = cs.create_simple_text_frame(unpack(dps_frame_config))
  f:RegisterEvent("UNIT_COMBAT")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  -- f:RegisterEvent("PLAYER_ENTER_COMBAT")
  f:RegisterEvent("PLAYER_LEAVE_COMBAT")
  f:RegisterEvent("SPELLCAST_START")
  f:SetScript("OnEvent", function()
    if arg2 and arg2 == "HEAL" then
      return
    end
    this.cs_dps:_handler(event, arg1, arg4)
  end)

  self.frame = f
  f.cs_dps = self

  --cs.add_loop_event("cs.Dps", 0.1, self, cs.Dps._loop)
end

function cs.Dps:_update_output()
  ---@type cs.DpsData
  local data = self.data
  local ts = GetTime()

  local combat_enter_ts = cs.get_affect_info().ts_enter
  local cur_dps = data:get_all(combat_enter_ts)
  local dps_4 = data:get_all(ts - 60 * 4)
  local dps_16 = data:get_all(ts - 60 * 16)
  local dps_64 = data:get_all(ts - 60 * 64)

  self.frame.cs_text:SetText(string.format(
          "DPS %3d [%3d%5d] / %3d / %3d / %3d",
          cur_dps:get_avg(), cur_dps.ts_sum, cur_dps.damage_sum, dps_4:get_avg(), dps_16:get_avg(), dps_64:get_avg()))
end
--endregion

--function cs.Dps:_loop()
--  if cs.is_free() then
--    return
--  end
--  self:_update_output()
--end

---@type cs.Dps
local st_dps_target -- target received damage
---@type cs.Dps
local st_dps_player -- player received damage










-- mana check
local function create_calc(start_value)
  local calc = { value = start_value, ts = GetTime() }
  function calc.get_avg_diff(self, value)
    local diff = value - self.value
    local ts = GetTime()
    local ts_diff = ts - self.ts
    self.value = value
    self.ts = ts
    local r = diff / ts_diff
    return r
  end
  return calc
end

local function create_mana_checker(period, size)
  local mana_checker = {
    calc = create_calc(UnitMana("player")),
    ts = GetTime(),
    period = period,
    list = cs.create_fix_table(size),
  }

  return mana_checker
end

local function limit_value(v, limit, m_limit)
  v = v > limit and limit or (v < m_limit and m_limit or v)
  return v
end

local st_mana_checker = create_mana_checker(1, 300)
local function get_mana_regen()
  local ts = GetTime()
  if ts - st_mana_checker.ts >= st_mana_checker.period then
    local mana = UnitMana("player")
    local mana_reg = st_mana_checker.calc:get_avg_diff(mana)
    st_mana_checker.list:add(mana_reg)
    st_mana_checker.ts = ts
  end
  local v_0 = limit_value(st_mana_checker.list:get_avg_value(5), 99, -99)
  local v_1 = limit_value(st_mana_checker.list:get_avg_value(60), 99, -99)
  local v_5 = limit_value(st_mana_checker.list:get_avg_value(300), 99, -99)
  return string.format("%d/%d/%d", v_0, v_1, v_5)
end







---@class cs.SpeedChecker
cs.SpeedChecker = cs.create_class_(function()
  ---@type cs.SpeedChecker
  local speed_checker = cs.SpeedChecker:new()
  local period = 0.2

  cs.debug(1)
  speed_checker.x = 0
  speed_checker.y = 0
  speed_checker.calc = create_calc(0)
  speed_checker.map = ""
  speed_checker.k = 1
  speed_checker.speed_table = cs.create_fix_table(3/period)

  speed_checker.text = cs.create_simple_text_frame(unpack(spd_checker_frame))

  cs.once_event(5, function()
    cs.loop_event(period, speed_checker, speed_checker._loop)
  end)

  return speed_checker
end)

--region

function cs.SpeedChecker:_get_speed_mod()
  if UnitIsDeadOrGhost("player") then
    return 1.25
  end

  local speed = 1
  local _, class = UnitClass(cs.u.player)
  if class == "PALADIN" then
    local _, _, _, _, current_rank = GetTalentInfo(3, 9)
    speed = speed + current_rank * 0.04
  end

  local is_mounted = cs.has_buffs(cs.u.player, "inv_pet_speedy") or
          cs.has_buffs(cs.u.player, "Spell_Nature_Swiftness")
  if is_mounted then
    local lvl = UnitLevel(cs.u.player)
    if lvl < 40 then
      speed = 1.14 * speed * speed -- ????
    elseif lvl < 60 then
      speed = 1.6 * speed
    else
      speed = 2 * speed
    end
  end

  return speed
end

function cs.SpeedChecker:_get_k()
  local k = self.k
  local is_ghost = UnitIsDeadOrGhost("player")
  if cs.has_debuffs() and not is_ghost then
    return k
  end

  if not self.speed_table:is_full() then
    return k
  end

  -- speed detected
  local avg = self.speed_table:get_avg_value()
  if avg <= 0.2 then
    return k
  end

  local diff = self.speed_table:get_max_diff()
  if diff == 0 then
    -- stay
    return k
  end

  if diff > 0.005 then
    return k
  end

  avg = avg / self:_get_speed_mod()
  if math.abs(avg - 1) < 0.005 then
    return k
  end

  -- set new k
  self.k = k / avg

  cs.print(string.format("S: k:%.2f avg:%.2f", self.k, avg))

  return self.k
end

function cs.SpeedChecker:get_speed()
  local x, y = GetPlayerMapPosition("player")
  local m = 82350
  local y_k = 1.5
  x = x * m
  y = y * m / y_k
  local diff_x = x - self.x
  local diff_y = y - self.y
  self.x = x
  self.y = y
  local dist = math.sqrt(math.pow(diff_x, 2) + math.pow(diff_y, 2))
  local k = self:_get_k()
  local speed = self.calc:get_avg_diff(dist) * k / 100
  self.calc.value = 0
  self.speed_table:add(speed)
  return string.format("%1.2f", speed)
end

function cs.SpeedChecker:_loop()
  local speed = self:get_speed()
  self.text.cs_text:SetText(speed)
end

local st_speed_checker

--endregion












local function unit_dump_scan(name)
  local units = pfUI.api.GetScanDb()
  local m = units["mobs"][name]
  local p = units["players"][name]
  local m_ut = cs.time_to_str(m and m.updatetime or 0)
  local p_ut = cs.time_to_str(p and p.updatetime or 0)
  cs.print("    M(" .. m_ut .. "):" .. ToString(m, 2, 10, 1))
  cs.print("    P(" .. p_ut .. "):" .. ToString(p, 2, 10, 1))
end








-- NAMEPLATES

PLAYER_UNIT_TYPE = "players"
NPC_UNIT_TYPE = "mobs"

local function GetReactionAndPlayerType(plate)
  local red, green, blue = plate.original.healthbar:GetStatusBarColor()

  if red > .9 and green < .2 and blue < .2 then
    return "ENEMY", nil
  elseif red > .9 and green > .9 and blue < .2 then
    return "NEUTRAL", "mobs"
  elseif red < .2 and green < .2 and blue > 0.9 then
    return "FRIENDLY", "players"
  elseif red < .2 and green > .9 and blue < .2 then
    return "FRIENDLY", "mobs"
  end
  return "ENEMY", nil
end

local function GetUnitType(reaction, player)
  if player == PLAYER_UNIT_TYPE then
    if reaction == "NEUTRAL" then
      return nil
    end
    return reaction .. "_PLAYER"
  else
    return reaction .. "_NPC"
  end
end

local function np_to_short(plate)
  local r, p = GetReactionAndPlayerType(plate)
  local cache_player = plate.cache and plate.cache.player
  return {
    CACHE = plate.cache,
    CACHE_P = cache_player,
  }
end

local function unit_dump_np(name)
  -- pfUI.api.GetNPList()

  local np_list = pfUI.api.GetNPList()
  local count = 0
  for frame in pairs(np_list) do
    local plate = frame.nameplate
    local np_name = plate.original.name:GetText()
    if np_name == name then
      cs.print("    NP: " .. ToString(np_to_short(plate), 3, 20, nil))
    end
    count = count + 1
  end
  cs.print("NP COUNT: " .. count)
end

local function unit_dump(name)
  cs.print("  " .. name .. ":")
  unit_dump_scan(name)
  unit_dump_np(name)
end

local function all_dump()
  local units = pfUI.api.GetScanDb()
  -- cs.print(pfUI.api.ToString(units, 2))
  for type, type_g in pairs(units) do

    local count = 0
    for name, u in pairs(type_g) do
      if type == "mobs" then
        local p = units["players"][name]
        if p then
          unit_dump(name)
        end
      end
      count = count + 1
    end
    cs.print(type .. ": count:" .. count)

  end
end






cs.services.init = function()
  st_dps_target = cs.Dps.build("target", dps_frame.target)
  st_dps_player = cs.Dps.build("player", dps_frame.player)

  st_speed_checker = cs.SpeedChecker.build()
end








-- PUBLIC

function SM_get_panel()
  return speed_checker:get_speed() .. " " .. get_mana_regen()
end

function cs_set_target_mouse()
  st_targeter:set_target_mouse()
end

function cs_set_target_last()
  st_targeter:set_last_target()
end

function cs_dump_unit()
  local cur_time = cs.time_to_str(GetTime())
  cs.print("----- " .. cur_time)

  if cs.check_target(cs.t.exists) then
    local buffs = cs.get_buff_list(cs.u.target)
    local debuffs = cs.get_debuff_list(cs.u.target)
    local casts = cs.get_cast_info(cs.u.target)
    for t, list in pairs({ buffs = buffs, debuffs = debuffs, casts = casts }) do
      cs.print(t .. ":")
      for _, buff in pairs(list) do
        cs.debug(buff)
      end
    end

    --local name = UnitName("target")
    --unit_dump(name)
  else
    all_dump()
  end

end
