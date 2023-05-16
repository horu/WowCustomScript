local cs = cs_common
local damage = cs.damage

cs.services = {}

local spd_checker_frame = { x=10, y=92, mono=true }



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









-- mana check
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






-- Calcualte and show current player speed
---@class cs.SpeedChecker
cs.SpeedChecker = cs.create_class()

cs.SpeedChecker.build = function()
  ---@type cs.SpeedChecker
  local speed_checker = cs.SpeedChecker:new()
  local period = 0.2

  speed_checker.x = 0
  speed_checker.y = 0
  speed_checker.calc = create_calc(0)
  speed_checker.speed_table = cs.create_fix_table(3/period)
  --
  ---- UI text
  --speed_checker.text = cs.ui.Text:build_from_config(spd_checker_frame)

  -- Deffered start
  cs.event.once(5, function()
    cs.event.loop(period, speed_checker, speed_checker._loop)
  end)

  -- To save calculated map size ratio to config
  speed_checker.map_params = cs.map.checker:get_map_params()
  cs.map.checker:subscribe(speed_checker, speed_checker._on_zone_changed)
  --
  ---- Reset saved map size ratio
  --local button_point = cs.ui.Point.build(0, 0, cs.ui.r.BOTTOMLEFT, speed_checker.text.frame, cs.ui.r.BOTTOMLEFT)
  --speed_checker.button = cs.create_simple_button(nil, nil, button_point, function()
  --  local map_params = this.cs_speed_checker.map_params
  --  cs.print("RESET SPEED FOR: " .. map_params.name)
  --  map_params.size_ratio = nil
  --end)

  speed_checker.current_speed = nil

  return speed_checker
end

--region

---@return @player speed - 1.0 - normal (100%), 1.6 - mounted, ...
function cs.SpeedChecker:get_speed()
  return self.current_speed
end

function cs.SpeedChecker:is_moving()
  return self:get_speed() ~= 0
end

function cs.SpeedChecker:reset_speed()
  local map_params = self.map_params
  cs.print("RESET SPEED FOR: " .. map_params.name)
  map_params.size_ratio = nil
end

function cs.SpeedChecker:_on_zone_changed()
  self.map_params = cs.map.checker:get_map_params()
end

-- speed modificator on mount/buffs/talents/ghost
function cs.SpeedChecker:_get_speed_mod()
  if UnitIsDeadOrGhost("player") then
    return 1.25
  end

  local speed = 1
  local _, class = UnitClass(cs.u.player)
  if class == "PALADIN" then
    local rank = cs.get_talent_rank("Pursuit of Justice")
    speed = speed + rank * 0.04
  end

  local is_mounted = cs.has_buffs(cs.u.player, "inv_pet_speedy") or
                     cs.has_buffs(cs.u.player, "Spell_Nature_Swiftness") or
                     cs.has_buffs(cs.u.player, "Ability_Mount_Charger")
  if is_mounted then
    local riding_rank = cs.skill.get_rank("Riding")
    if not riding_rank or riding_rank < 75 then
      speed = 1.14 * speed * speed -- ????
    elseif riding_rank < 150 then
      speed = 1.6 * speed
    else
      speed = 2 * speed
    end
  else
    if cs.has_buffs(cs.u.player, "Ability_Creature_Poison_05") then
      speed = 1.1
    end
  end

  return speed
end

-- all maps have different size. this function calculate size ratio
function cs.SpeedChecker:_calculate_size_ratio()
  local k = 1
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
  --if math.abs(avg - 1) < 0.005 then
  --  return k
  --end

  -- set new k
  self.map_params.size_ratio = k / avg

  cs.print(string.format("SAVE FOR %s: ratio:%.2f avg:%.2f",
          self.map_params.name, self.map_params.size_ratio, avg))

  return self.map_params.size_ratio
end

function cs.SpeedChecker:_get_map_size_ratio()
  if self.map_params.size_ratio then
    return self.map_params.size_ratio
  end

  return self:_calculate_size_ratio()
end

-- distance the player runs between calculations
function cs.SpeedChecker:_calculate_distance()
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
  return dist
end

function cs.SpeedChecker:_loop()
  local dist = self:_calculate_distance()
  local map_ratio = self:_get_map_size_ratio()
  local speed = self.calc:get_avg_diff(dist) * map_ratio / 100
  self.calc.value = 0
  self.speed_table:add(speed)
  if self.map_params.size_ratio or speed == 0 then
    self.current_speed = speed
  else
    self.current_speed = nil
  end
end

--endregion






cs.services.init = function()
  cs.services.speed_checker = cs.SpeedChecker.build()
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


