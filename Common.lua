
cs_common = {}
local cs = cs_common



-- debug
function cs.ToString(value, depth, itlimit, short)
  return pfUI.api.ToString(value, depth, itlimit, short)
end

function cs.debug(msg)
  local line = debugstack(2, 1, 1)
  local line_end = string.find(line, '[\r\n]+')
  line = string.sub(line, 32, line_end-1)
  if type(msg) == "table" or msg == nil then
    msg = cs.ToString(msg)
  end
  print(line..": "..msg)
end


cs.error_disabler = {}
function cs.error_disabler.off(self)
  self.error = UIErrorsFrame.AddMessage
  UIErrorsFrame.AddMessage = function() end
end

function cs.error_disabler.on(self)
  if self.error then
    UIErrorsFrame.AddMessage = self.error
  end
end

function cs.to_table(value)
  if type(value) ~= "table" then
    return { value }
  end
  return value
end

function cs.fmod(v, d)

  while v >= d do
    v = v - d
  end
  return v
end


function cs.time_to_str(t)
  if not t then return end
  local h = cs.fmod(math.floor(t / 3600), 24)
  local m = cs.fmod(math.floor(t / 60), 60)
  local s = cs.fmod(math.floor(t), 60)
  return string.format("%02d:%02d:%02d", h, m, s)
end

function cs.create_fix_table(size)
  local fix_table = { size = size, list = {} }

  function fix_table.clear(self)
    self.list = {}
  end

  function fix_table.add(self, value)
    table.insert(self.list, 1, value)
    local size = table.getn(self.list)
    if size > self.size then
      table.remove(self.list, size)
    end
  end

  function fix_table.is_full(self)
    return table.getn(self.list) == self.size
  end

  function fix_table.get_max_diff(self)
    local min_v =  9999999
    local max_v = -9999999
    for _, v in self.list do
      min_v = min(min_v, v)
      max_v = max(max_v, v)
    end

    return max_v - min_v
  end

  function fix_table.get_sum(self, last_count)
    local sum = 0
    local cur_size = table.getn(self.list)
    local cur_count = math.min(last_count or cur_size, cur_size)
    for i=1, cur_count do
      sum = sum + self.list[i]
    end
    return sum
  end

  function fix_table.get_avg_value(self, last_count)
    local cur_size = table.getn(self.list)
    local cur_count = math.min(last_count or cur_size, cur_size)
    local sum = self:get_sum(cur_count)
    if cur_size > 0 then
      return sum / cur_count
    end
    return 0
  end
  return fix_table
end




-- target
cs.t_friend = UnitIsFriend
cs.t_enemy = UnitIsEnemy
cs.t_exists = UnitExists
cs.t_dead = UnitIsDead
cs.t_player = UnitIsPlayer
cs.t_close = "t_close"
cs.t_attackable = "t_attackable"

-- check condition by OR
function cs.check_target(c1, c2, c3)
  local check_list = { c1, c2, c3 }

  for _, check in pairs(check_list) do

    if check == cs.t_close then
      if CheckInteractDistance("target", 2) then return true end
    elseif check == cs.t_attackable then
      if cs.check_target(cs.t_exists) and
              not cs.check_target(cs.t_friend) and
              not cs.check_target(cs.t_dead) then
        return true
      end
    elseif check("target", "player") then
      return true
    end
  end
end





-- common
function cs.get_hp_level() -- 0-1
  return UnitHealth("player")/UnitHealthMax("player")
end

function cs.in_combat()
  return PlayerFrame.inCombat
end

function cs.in_aggro()
  return pfUI.api.UnitHasAggro("player") > 0
end

function cs.is_in_party()
  return GetNumPartyMembers() ~= 0
end

-- auto_attack
function cs.auto_attack()
  if not cs.check_target(cs.t_exists) then
    TargetNearestEnemy()
  end
  if not cs.in_combat() then
    AttackTarget()
  elseif cs.check_target(cs.t_friend) then
    AssistUnit("target")
  end
end




-- slot

cs.Slot = {}

function cs.Slot.new(slot_n)
  return setmetatable({slot_n = slot_n}, {__index = cs.Slot})
end

function cs.Slot.is_equipped(self)
  return IsEquippedAction(self.slot_n)
end

function cs.Slot.use(self)
  UseAction(self.slot_n)
end

function cs.Slot.try_use(self)
  if not self:is_equipped() then
    self:use()
  end
end

cs.MultiSlot = setmetatable({}, {__index = cs.Slot})

function cs.MultiSlot.new(slot_list)
  return setmetatable({slot_list = slot_list}, {__index = cs.MultiSlot})
end

function cs.MultiSlot.is_equipped(self)
  for _, slot in pairs(self.slot_list) do
    if not slot:is_equipped() then return end
  end
  return true
end

function cs.MultiSlot.use(self)
  for _, slot in pairs(self.slot_list) do
    slot:use()
  end
end


-- buffs
function cs.find_buff(check_list, unit)
  for i, check in pairs(cs.to_table(check_list)) do
    if FindBuff(check, unit) then
      return i, check
    end
  end
end

-- return nil if rebuff no need
function cs.rebuff(buff, custom_buff_check_list)
  if cs.find_buff(custom_buff_check_list or buff) then
    return
  end

  if not cs.check_target(cs.t_player) and cs.check_target(cs.t_friend) then
    return true
  end

  cast(buff)
  return true
end

function cs.rebuff_target(buff, check, unit)
  if cs.find_buff(check or buff, unit) then
    return
  end

  if not UnitExists(unit) or
          not UnitIsConnected(unit) or
          UnitIsDead(unit) or
          not CheckInteractDistance(unit, 4) or
          not UnitIsVisible(unit) then
    return true
  end

  TargetUnit(unit)

  if UnitIsUnit(unit, "target") then
    -- SpellTargetUnit
    print("BUFF: ".. buff .. " FOR ".. unit)
    cast(buff)
  end

  TargetLastTarget()
  cs.auto_attack()
  return true
end

-- create_buff_saver
function cs.create_buff_saver(list)
  local buff_saver = { list = {} }

  function buff_saver.add_list(self, list)
    for _, buff in pairs(list) do
      table.insert(self.list, buff)
    end
  end

  function buff_saver.get_buff(self, av_list)
    local i = cs.find_buff(self.list)
    if i and i ~= 1 then
      local last_buff = self.list[i]
      -- print(last_buff)
      table.remove(self.list, i)
      table.insert(self.list, 1, last_buff)
    end
    -- print(ToString(self.list))
    if not av_list then
      return self.list[1]
    end

    for _, buff in pairs(self.list) do
      for _, av_buff in pairs(av_list) do
        if buff == av_buff then
          return buff
        end
      end
    end
  end

  buff_saver:add_list(list)

  return buff_saver
end

function cs.has_buffs(unit, buff_str, b_fun)
  if not unit then unit = "player" end
  if not buff_str then buff_str = "" end
  if not b_fun then b_fun = UnitBuff end

  for i=1, 100 do
    local buff = b_fun(unit, i)
    if not buff then break end

    -- print(buff)
    if string.find(buff, buff_str) then
      return true
    end
  end
end

function cs.has_debuffs(unit, debuff_str)
  return cs.has_buffs(unit, debuff_str, UnitDebuff)
end




function cs.create_simple_frame(name)
  local f = CreateFrame("Frame", name, UIParent)
  return f
end



function cs.create_simple_text_frame(name, x, y, text)
  local f = cs.create_simple_frame(name)
  f:SetHeight(10)
  f:SetWidth(20)
  f:SetPoint("BOTTOM", x, y)

  f.cs_text = f:CreateFontString("Status", nil, "GameFontHighlightSmallOutline")
  f.cs_text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  f.cs_text:SetPoint("BOTTOMLEFT", 0, 0)
  f.cs_text:SetJustifyH("LEFT")
  f.cs_text:SetText(text)

  return f
end







function cs.create_dps_calculator()
  local f = cs.create_simple_text_frame("nibsrsCSdps", 15, 45, "DPS")
  f.cs_data = { storage = cs.create_fix_table(500), ts = GetTime() }

  f:RegisterEvent("UNIT_COMBAT")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  f:SetScript("OnEvent", function()
    local storage = this.cs_data.storage
    local ts = this.cs_data.ts
    if event == "PLAYER_TARGET_CHANGED" then
      storage:clear()
      this.cs_data.ts = GetTime()
      return
    end

    if arg1 ~= "target" then
      return
    end

    local damage = arg4

    storage:add(damage)

    local ts_diff = GetTime() - ts
    local sum = storage:get_sum()

    -- print(cs.ToString({sum, ts_diff}))
    this.cs_text:SetText("DPS: "..math.floor(sum / ts_diff))

  end)

  return f
end


local dps = cs.create_dps_calculator()














--- check
local pvp = nil
local mana = true

--PVP
if not UnitIsPVP("player") and pvp then
  TogglePVP()
  print("ENABLE PVP")
end

--COMMON
local function create_calc(start_value)
  local calc = { value = start_value, ts = GetTime() }
  function calc.get_avg_diff(self, value)
    local diff = value - self.value
    local ts = GetTime()
    local ts_diff =  ts - self.ts
    self.value = value
    self.ts = ts
    local r = diff/ts_diff
    return r
  end
  return calc
end

-- RUNNER
SM_single_runners = SM_single_runners or {}
local function create_single_runner(name, period_s, obj, fun)
  if not name then
    return
  end

  local old_runner = SM_single_runners[name]
  if old_runner then
    old_runner.run_loop = nil
  end

  local runner = {
    period = math.floor(period_s * 5),
    count_loop = math.floor(period_s * 5),
    run_loop = true,
    obj = obj,
    fun = fun,
  }
  function runner.loop(self)
    if not self.run_loop then
      return
    end

    self.count_loop = self.count_loop - 1
    if self.count_loop <= 0 then
      self.fun(self.obj)
      self.count_loop = self.period
    end

    pfUI.api.QueueFunction(self.loop, self)
  end
  SM_single_runners[name] = runner
  pfUI.api.QueueFunction(runner.loop, runner)
end

--MANA

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

local mana_checker = create_mana_checker(1, 300)
local function get_mana_regen()
  local ts = GetTime()
  if ts - mana_checker.ts >= mana_checker.period then
    local mana = UnitMana("player")
    local mana_reg = mana_checker.calc:get_avg_diff(mana)
    mana_checker.list:add(mana_reg)
    mana_checker.ts = ts
  end
  local v_0 = limit_value(mana_checker.list:get_avg_value(5), 99, -99)
  local v_1 = limit_value(mana_checker.list:get_avg_value(60), 99, -99)
  local v_5 = limit_value(mana_checker.list:get_avg_value(300), 99, -99)
  return string.format("%d/%d/%d", v_0, v_1, v_5)
end



local function get_speed_mod()
  if UnitIsDeadOrGhost("player") then
    return 1.25
  end

  -- tortle mount
  if cs.has_buffs("player", "inv_pet_speedy") then
    return 1.14
  end

  return 1
end


--SPEED
local speed_checker = {
  x=0, y=0, calc = create_calc(0), map = "" , k = 1,
  speed_table = cs.create_fix_table(15)
}

function speed_checker.get_k(self)
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

  avg = avg / get_speed_mod()
  if math.abs(avg - 1) < 0.005 then
    return k
  end

  -- set new k
  self.k = k/avg
  print(string.format("S: k:%.2f avg:%.2f", self.k, avg))

  return self.k
end


function speed_checker.get_speed(self)
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
  local k = self:get_k()
  local speed = self.calc:get_avg_diff(dist)*k/100
  self.calc.value = 0
  self.speed_table:add(speed)
  return string.format("%1.2f", speed)
end

function SM_get_panel()
  return speed_checker:get_speed().." "..get_mana_regen()
end







































local function unit_dump_scan(name)
  local units = pfUI.api.GetScanDb()
  local m = units["mobs"][name]
  local p = units["players"][name]
  local m_ut = time_to_str(m and m.updatetime or 0)
  local p_ut = time_to_str(p and p.updatetime or 0)
  print("    M("..m_ut.."):"..ToString(m, 2, 10, 1))
  print("    P("..p_ut.."):"..ToString(p, 2, 10, 1))
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
    return reaction.."_PLAYER"
  else
    return reaction.."_NPC"
  end
end

local function np_to_short(plate)
  local r, p = GetReactionAndPlayerType(plate)
  local cache_player = plate.cache and plate.cache.player
  return {
    CACHE=plate.cache,
    CACHE_P=cache_player,
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
      print("    NP: "..ToString(np_to_short(plate), 3, 20, nil))
    end
    count = count + 1
  end
  print("NP COUNT: "..count)
end

local function unit_dump(name)
  print("  "..name..":")
  unit_dump_scan(name)
  unit_dump_np(name)
end


local function all_dump()
  local units = pfUI.api.GetScanDb()
  -- print(pfUI.api.ToString(units, 2))
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
    print(type..": count:"..count)

  end
end

function ud(name)
  local cur_time = time_to_str(GetTime())
  print("----- "..cur_time)
  unit_dump(name)
end


function main_d()
  local cur_time = time_to_str(GetTime())
  print("----- "..cur_time)

  if UnitExists("target") then
    local name = UnitName("target")
    unit_dump(name)
  else
    all_dump()
  end

end
