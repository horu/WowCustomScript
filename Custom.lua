

--lib

-- error_disabler
local error_disabler = {}
function error_disabler.off(self)
  self.error = UIErrorsFrame.AddMessage
  UIErrorsFrame.AddMessage = function() end
end

function error_disabler.on(self)
  if self.error then
    UIErrorsFrame.AddMessage = self.error
  end
end

local function to_table(value)
  if type(value) ~= "table" then
    return { value }
  end
  return value
end

local function fmod(v, d)

  while v >= d do
    v = v - d
  end
  return v
end


local function time_to_str(t)
  if not t then return end
  local h = fmod(math.floor(t / 3600), 24)
  local m = fmod(math.floor(t / 60), 60)
  local s = fmod(math.floor(t), 60)
  return string.format("%02d:%02d:%02d", h, m, s)
end




-- target
local t_friend = UnitIsFriend
local t_enemy = UnitIsEnemy
local t_exists = UnitExists
local t_dead = UnitIsDead
local t_player = UnitIsPlayer
local t_close = "t_close"
local t_attackable = "t_attackable"

local function check_target(c1, c2, c3, c4, c5, c6)
  local check_list = { c1, c2, c3, c4, c5, c6 }

  if c1 == t_close then
    return CheckInteractDistance("target", 2);
  end

  if c1 == t_attackable then
    return check_target(t_exists) and not check_target(t_friend) and not check_target(t_dead)
  end

  for _, check in pairs(check_list) do
    if check("target", "player") then
      return true
    end
  end
end





-- common
local function get_hp_level() -- 0-1
  return UnitHealth("player")/UnitHealthMax("player")
end

local function in_combat()
  return PlayerFrame.inCombat
end

local function in_aggro()
  return pfUI.api.UnitHasAggro("player") > 0
end

local function is_in_party()
  return GetNumPartyMembers() ~= 0
end

-- auto_attack
local function auto_attack()
  if not check_target(t_exists) then
    TargetNearestEnemy()
  end
  if not in_combat() then
    AttackTarget()
  elseif check_target(t_friend) then
    AssistUnit("target")
  end
end







-- buffs
local c_BRF = "Righteous Fury"

local c_CA = "Concentration Aura"
local c_DA = "Devotion Aura"
local c_SA = "Sanctity Aura"
local c_RA = "Retribution Aura"
local c_SRA = "Shadow Resistance Aura"
local c_aura_list = { c_CA, c_SA, c_DA, c_RA, c_SRA }
local c_f_aura_list = { c_SA, c_DA, c_RA, c_SRA }
local c_d_aura_list = { c_DA, c_SRA }

local c_BW = "Blessing of Wisdom"
local c_BM = "Blessing of Might"
local c_bless_list = { c_BW, c_BM }


local function find_buff(check_list, unit)
  for i, check in pairs(to_table(check_list)) do
    if FindBuff(check, unit) then
      return i, check
    end
  end
end

local function rebuff(buff, check)
  if not check_target(t_player) and check_target(t_friend) then
    return
  end

  if find_buff(check or buff) then
    return
  end

  cast(buff)
  return true
end

local function rebuff_target(buff, check, unit)
  if not UnitExists(unit) or not UnitIsConnected(unit) or UnitIsDead(unit) or not CheckInteractDistance(unit, 4) then
    return
  end

  if find_buff(check or buff, unit) then
    return
  end

  TargetUnit(unit)

  if UnitIsUnit(unit, "target") then
    -- SpellTargetUnit
    print("BUFF: ".. buff .. " FOR ".. unit)
    cast(buff)
  end

  TargetLastTarget()
  auto_attack()
  return true
end

-- create_buff_saver
local function create_buff_saver(list)
  local buff_saver = { list = {} }

  function buff_saver.add_list(self, list)
    for _, buff in pairs(list) do
      table.insert(self.list, buff)
    end
  end

  function buff_saver.get_buff(self, av_list)
    local i = find_buff(self.list)
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

function has_buffs(unit, buff_str, b_fun)
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

function has_debuffs(unit, debuff_str)
  return has_buffs(unit, debuff_str, UnitDebuff)
end

local function ToString(value, depth, itlimit, short)
  return pfUI.api.ToString(value, depth, itlimit, short)
end








-- party

local function rebuff_party_member(unit)
  local buffs = {
    WARRIOR = c_BM,
    PALADIN = c_BM,
    HUNTER = c_BM,
    ROGUE = c_BM,

    DRUID = c_BW,
    PRIEST = c_BW,
    MAGE = c_BW,
    WARLOCK = c_BW,
  }

  local _, class = UnitClass(unit)

  local buff = buffs[class]
  if not buff then
    print("BUFF NOT FOUND FOR "..class)
    buff = c_BM
  end
  rebuff_target(buff, nil, unit)
end

local function buff_party()
  if in_combat() then return end

  local size = GetNumPartyMembers()
  for i=1, size do
    local unit = "party"..i
    rebuff_party_member(unit)
  end
end








--main


-- rebuff_fight
local aura_saver = create_buff_saver(c_aura_list)
local bless_saver = create_buff_saver(c_bless_list)
local function rebuff_fight(aura_list)
  -- rebuff last bless/aura
  rebuff(aura_saver:get_buff(aura_list))
  rebuff(bless_saver:get_buff())
  if is_in_party() then
    rebuff(c_BRF)
    buff_party()
  end
end

-- rebuff_heal
local function rebuff_heal()
  if in_aggro() or in_combat() then
    rebuff(c_CA)
  end
end







-- SEAL

local c_SR = "Seal of Righteousness"
local c_SC = "Seal of the Crusader"
local c_SJ = "Seal of Justice"
local c_SL = "Seal of Light"
local c_seal_list = { c_SR, c_SC, c_SJ, c_SL }

local function buff_seal(buff, check)
  if check_target(t_attackable) then
    return rebuff(buff, check)
  end
end

local function seal_and_cast(buff, cast_list, buff_check)
  if buff_seal(buff, buff_check) then
    return
  end

  if type(cast_list) ~= "table" then
    cast(cast_list)
  else
    DoOrder(unpack(cast_list))
  end
end


-- CAST

local c_CCS = "Crusader Strike"
local c_CJ = "Judgement"
local c_CHS = "Holy Strike"
local c_CE = "Exorcism"

local function get_cast_list(cast_list)
  cast_list = to_table(cast_list)

  local target = UnitCreatureType("target")
  if target == "Demon" or target == "Undead" then
    table.insert(cast_list, 1, c_CE)
  end
  return cast_list
end


-- attack_wr
local function attack_wr(inside)
  error_disabler:off()
  auto_attack()
  inside()
  error_disabler:on()
end





-- PUBLIC
function attack_4()
  attack_wr(function()
    local req_aura = { c_SA }
    rebuff_fight(req_aura)
    if not find_buff(req_aura) then
      return
    end

    seal_and_cast(c_SR, c_CHS)
    seal_and_cast(c_SR, get_cast_list({ c_CJ, c_CCS }))
  end)
end



function attack_3()
  attack_wr(function()
    rebuff_fight(c_f_aura_list)

    if find_buff(c_SL) then
      cast(c_CJ)
      return
    end

    --if not has_debuffs("target", "Spell_Holy_HealingAura") then
      --if find_buff(c_SR) then
     --   cast(c_CJ)
      --  return
    --  end

      --seal_and_cast(c_SL, c_CJ)
      --return
    --end

    seal_and_cast(c_SR, c_CHS)
    seal_and_cast(c_SR, get_cast_list({ c_CCS }))
  end)
end



function attack_2()
  attack_wr(function()
    rebuff_fight(c_f_aura_list)
    if not check_target(t_close) then
      return
    end

    seal_and_cast(c_SC, cc_CCS, {c_SC, c_SR})
  end)
end


function attack_heal()
  attack_wr(function()
    rebuff_fight(c_d_aura_list)
    if not check_target(t_close) then
      return
    end

    if find_buff(c_SR) then
      cast(c_CJ)
      return
    end

    if not has_debuffs("target", "Spell_Holy_HealingAura") then
      seal_and_cast(c_SL, c_CJ)
      return
    end

    seal_and_cast(c_SL, c_CHS)
    -- seal_and_cast(c_SL, get_cast_list({ }))
  end)
end


function attack_1()
  attack_wr(function()
    rebuff_fight(c_f_aura_list)
  end)
end

function cast_heal(cast1)
  rebuff_heal()
  cast(cast1)
end




































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

-- create_fix_table
local function create_fix_table(size)
  local fix_table = { size = size, list = {} }

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

  function fix_table.get_avg_value(self, last_count)
    local sum = 0
    local cur_size = table.getn(self.list)
    local cur_count = math.min(last_count or cur_size, cur_size)
    if cur_size > 0 then
      for i=1, cur_count do
        sum = sum + self.list[i]
      end
      return sum / cur_count
    end
    return 0
  end
  return fix_table
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
    list = create_fix_table(size),
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
  if has_buffs("player", "inv_pet_speedy") then
    return 1.14
  end

  return 1
end


--SPEED
local speed_checker = {
  x=0, y=0, calc = create_calc(0), map = "" , k = 1,
  speed_table = create_fix_table(15)
}

function speed_checker.get_k(self)
  local k = self.k
  local is_ghost = UnitIsDeadOrGhost("player")
  if has_debuffs() and not is_ghost then
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
