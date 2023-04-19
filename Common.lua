
cs_common = {}
local cs = cs_common

local dps_frame = {
  target = {"nibsrsCSdps", "BOTTOMLEFT",1150, 94, "DPS", false, true},
  player = {"nibsrsCSdps", "BOTTOMLEFT",347, 94, "DPS", "RIGHT", true},
}

-- debug
function cs.ToString(value, depth, itlimit, short)
  return pfUI.api.ToString(value, depth, itlimit, short)
end

function cs.debug(msg, depth)
  local line = debugstack(2, 1, 1)
  local line_end = string.find(line, "in function")
  line = string.sub(line, 32, line_end-1)
  if type(msg) ~= "string" or msg == nil then
    msg = cs.ToString(msg, depth, 20, true)
  end
  print(line..msg)
end




-- common
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



---@class cs.Class
cs.Class = {}

cs.create_class = function(class_tab)
  local class = class_tab or {}
  function class:new(tab)
    local obj = setmetatable(tab or {}, {__index = self})
    return obj
  end
  return class
end

cs.is_table = function(value)
  return type(value) == "table"
end

function cs.to_table(value)
  if type(value) ~= "table" then
    return { value }
  end
  return value
end

cs.to_dict = function(list)
  local dict = {}
  list = not cs.is_table(list) and { list } or list
  for i, v in pairs(list) do
    dict[v] = i
  end
  return dict
end


function cs.fmod(v, d)
  while v >= d do
    v = v - d
  end
  return v
end

cs.max_number_32 = math.pow(2, 32)

function cs.time_to_str(t)
  if not t then return end
  local h = cs.fmod(math.floor(t / 3600), 24)
  local m = cs.fmod(math.floor(t / 60), 60)
  local s = cs.fmod(math.floor(t), 60)
  return string.format("%02d:%02d:%02d", h, m, s)
end


cs.get_time_diff = function(past, now)
  if not past then return end

  now = now or GetTime()
  return now - past
end

cs.compare_time = function(limit, past, now)
  local diff = cs.get_time_diff(past, now)
  if not diff then return end

  return diff <= limit
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





---@class Looper
local Looper = cs.create_class()

---@type Looper
local looper = Looper:new({
  timer = nil,
  global_period = 0.1,
  list = {},
})

looper.delay_q = function(a1,a2,a3,a4,a5,a6,a7,a8,a9)
  if not looper.timer then
    local timer = CreateFrame("Frame")
    timer.queue = {}
    timer.interval = looper.global_period
    timer.DeQueue = function()
      local item = table.remove(timer.queue,1)
      if item then
        item[1](item[2],item[3],item[4],item[5],item[6],item[7],item[8],item[9])
      end
      if table.getn(timer.queue) == 0 then
        timer:Hide() -- no need to run the OnUpdate when the queue is empty
      end
    end
    timer:SetScript("OnUpdate",function()
      this.sinceLast = (this.sinceLast or 0) + arg1
      while (this.sinceLast > this.interval) do
        this.DeQueue()
        this.sinceLast = this.sinceLast - this.interval
      end
    end)
    looper.timer = timer
  end
  table.insert(looper.timer.queue,{a1,a2,a3,a4,a5,a6,a7,a8,a9})
  looper.timer:Show() -- start the OnUpdate
end

function Looper:iterate_event(event)
  event.cur_period = event.cur_period - self.global_period
  if event.cur_period <= 0 then
    event.func(event.obj)
    event.cur_period = event.period
  end
  return event.period == 0
end

function Looper:main_loop()
  local count = 0
  for name, event in pairs(self.list) do
    local break_event = self:iterate_event(event)
    if break_event then
      self.list[name] = nil
    end
    count = count + 1
  end
  if count > 0 then
    looper.delay_q(self.main_loop, self)
  end
end

cs.add_loop_event = function(name, period, obj, func)
  local event = {}
  event.func = func
  event.obj = obj
  event.period = period
  event.cur_period = 0
  looper.list[name] = event

  if not looper.timer then
    looper.delay_q(looper.main_loop, looper)
  end
end



cs.make_color = function(rgb)
  return "|cff"..rgb
end

cs.color_red = cs.make_color("ff2020")
cs.color_red_1 = cs.make_color("ff0000")
cs.color_orange = cs.make_color("FF8000")
cs.color_orange_1 = cs.make_color("FFB266")
cs.color_yellow = cs.make_color("FFFF66")
cs.color_blue = cs.make_color("20a0FF")
cs.color_purple = cs.make_color("C086F9")
cs.color_green = cs.make_color("00ff00")
cs.color_white = cs.make_color("ffffFF")
cs.color_grey = cs.make_color("A0A0A0")

-- Frame
function cs.create_simple_frame(name)
  local f = CreateFrame("Frame", name, UIParent)
  return f
end

function cs.create_simple_text_frame(name, to, x, y, text, text_to, mono, font_size,background)
  local f = cs.create_simple_frame(name)
  f:SetHeight(10)
  f:SetWidth(20)
  f:SetPoint(to, x, y)

  local font = "Fonts\\FRIZQT__.TTF"
  if mono then
    font = "Interface\\AddOns\\CustomScripts\\fonts\\UbuntuMono-R.ttf"
    font_size = font_size or 14
  else
    font_size = font_size or 12
  end

  f.cs_text = f:CreateFontString("Status", nil, "GameFontHighlightSmallOutline")
  f.cs_text:SetFont(font, font_size, "OUTLINE")
  f.cs_text:SetPoint(text_to or "BOTTOMLEFT", 0, 0)
  f.cs_text:SetJustifyH("LEFT")
  f.cs_text:SetText(text)

  if background then
    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetTexture(unpack(background))
  end

  function f:CS_SetText(text)
    self.cs_text:SetText(text)
    if self.texture then
      self.texture:SetHeight(self.cs_text:GetHeight()+2)
      self.texture:SetWidth(self.cs_text:GetWidth()+2)
      self.texture:ClearAllPoints()
      self.texture:SetPoint("CENTER", self.cs_text, "CENTER", 0, -1)
    end
  end

  return f
end





---@class cs.ActionBarProxy
cs.ActionBarProxy = cs.create_class()

cs.ActionBarProxy.key_state_up = "up"
cs.ActionBarProxy.key_state_down = "down"

function cs.ActionBarProxy.add_proxy(bar, button, callback, obj)
  local native_b = pfUI.bars[bar][button]
  native_b.cs_native_script = native_b:GetScript("OnClick")
  native_b.cs_callback = { callback = callback, obj = obj, bar = bar, button = button }
  native_b:SetScript("OnClick", function()
    this.cs_callback.callback(this.cs_callback.obj, this.cs_callback.bar, this.cs_callback.button)
    this.cs_native_script()
  end)
end





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
function cs.check_target(c1, c2, c3)
  local check_list = { c1, c2, c3 }

  for _, check in pairs(check_list) do

    if check == cs.t_close then
      if CheckInteractDistance("target", 2) then return true end
    elseif check == cs.t_close_30 then
      if CheckInteractDistance("target", 4) then return true end
    elseif check == cs.t_fr_player then
      return cs.check_target(cs.t_friend) and cs.check_target(cs.t_player)
    elseif check == cs.t_en_player then
      return cs.check_target(cs.t_enemy) and cs.check_target(cs.t_player)
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

-- aggro + combat
function cs.get_fight_info()
  local combat = st_combat_checker.combat
  local aggro = st_combat_checker.aggro
  local info = {}
  info.status = combat.status or aggro.status
  if combat.ts_leave and combat.ts_leave < aggro.ts_enter  then
    combat = {  }
  elseif aggro.ts_leave and aggro.ts_leave < combat.ts_enter then
    aggro = {  }
  end
  info.ts_enter = math.min(combat.ts_enter or cs.max_number_32, aggro.ts_enter or cs.max_number_32)
  info.ts_leave = math.max(combat.ts_leave or 0, aggro.ts_leave or 0)
  return info
end

-- aggro+combat
function cs.in_fight(second_after)
  local info = cs.get_fight_info()
  if second_after and info.ts_leave and cs.compare_time(second_after, info.ts_leave) then
    return true
  end
  return info.status
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


  for _, check in pairs(to_check) do
    local info = check()
    if info.status or cs.compare_time(time_after, info.ts_leave) then
      return true
    end
  end
end




function cs.get_hp_level() -- 0-1
  return UnitHealth("player")/UnitHealthMax("player")
end

function cs.is_in_party()
  return GetNumPartyMembers() ~= 0
end

function cs.auto_attack()
  if not cs.check_target(cs.t_exists) then
    TargetNearestEnemy()
  end
  if not cs.check_combat(cs.c_normal) then

    if cs.check_target(cs.t_enemy) and cs.check_target(cs.t_player) then
      -- prevent random pvp attack
      return
    end

    if not cs.check_target(cs.t_close) then
      return
    end

    AttackTarget()
  elseif cs.check_target(cs.t_friend) then
    AssistUnit("target")
  end
end



-- slot

---@class cs.Slot
cs.Slot = cs.create_class()

---@return cs.Slot
function cs.Slot.build(slot_n)
  return cs.Slot:new({slot_n = slot_n, last_ts = GetTime()})
end

function cs.Slot:is_equipped()
  return IsEquippedAction(self.slot_n)
end

function cs.Slot:use()
  UseAction(self.slot_n)
end

function cs.Slot:try_use()
  local ts = GetTime()
  if ts - self.last_ts <= 1 then
    -- frequent using has bugs
    return
  end
  self.last_ts = ts

  if not self:is_equipped() then
    self:use()
  end
end

---@class cs.MultiSlot
cs.MultiSlot = cs.Slot:new({last_ts = GetTime()})

---@return cs.MultiSlot
function cs.MultiSlot.build(slot_list_numbers)
  local slot_list = {}
  for _, slot in pairs(slot_list_numbers) do
    table.insert(slot_list, cs.Slot.build(slot))
  end
  return cs.MultiSlot:new({slot_list = slot_list})
end

function cs.MultiSlot:is_equipped()
  for _, slot in pairs(self.slot_list) do
    if not slot:is_equipped() then return end
  end
  return true
end

function cs.MultiSlot:use()
  for _, slot in pairs(self.slot_list) do
    slot:use()
  end
end





-- cas

cs.cast = function(a1,a2,a3,a4,a5,a6,a7)
  local cast_list
  if type(a1) == "table" then
    cast_list = a1
  else
    cast_list = { a1,a2,a3,a4,a5,a6,a7 }
  end

  if table.getn(cast_list) == 1 then
    cast(cast_list[1])
  else
    DoOrder(unpack(cast_list))
  end
  return true
end

cs.get_spell_cd = function(spell)
  local i,a=0
  while a~=spell do
    i=i+1
    a=GetSpellName(i,"spell")
  end
  local ts_start, duration = GetSpellCooldown(i,"spell")
  if ts_start == 0 then
    -- no cd
    return nil
  end

  local ts = GetTime()
  return duration - ts + ts_start, ts_start, duration
end

function cs.find_buff(check_list, unit)
  for i, check in pairs(cs.to_table(check_list)) do
    if FindBuff(check, unit) then
      return check, i
    end
  end
end

-- return nil if rebuff no need
function cs.rebuff(buff, custom_buff_check_list)
  if cs.find_buff(custom_buff_check_list or buff) then
    return
  end

  if cs.check_target(cs.t_friend) and not cs.check_target(cs.t_self) then
    return true
  end

  cs.cast(buff)
  return true
end

function cs.rebuff_unit(buff, check, unit)
  if cs.find_buff(check or buff, unit) then
    return
  end

  if not UnitExists(unit) or
          not UnitIsConnected(unit) or
          UnitIsDead(unit) or
          not CheckInteractDistance(unit, 4) or
          not UnitIsVisible(unit) then
    return 2
  end

  TargetUnit(unit)

  if UnitIsUnit(unit, "target") then
    -- SpellTargetUnit
    cs.cast(buff)
  end

  TargetLastTarget()
  cs.auto_attack()
  return 1
end

function cs.has_buffs(unit, buff_str, b_fun)
  if not unit then unit = "player" end
  if not buff_str then buff_str = "" end
  if not b_fun then b_fun = UnitBuff end

  for i=1, 100 do
    local buff = b_fun(unit, i)
    if not buff then break end

    --print(buff)
    if string.find(buff, buff_str) then
      return true
    end
  end
end

function cs.has_debuffs(unit, debuff_str)
  return cs.has_buffs(unit, debuff_str, UnitDebuff)
end


cs.spell_base_Shadow = "Shadow"
cs.spell_base_Frost = "Frost"
cs.spell_base_Fire = "Fire"

cs.get_spell_base = function(spell_icon)
  if string.find(spell_icon, cs.spell_base_Shadow) then
    return cs.spell_base_Shadow
  elseif string.find(spell_icon, cs.spell_base_Frost) then
    return cs.spell_base_Frost
  elseif string.find(spell_icon, cs.spell_base_Fire) then
    return cs.spell_base_Fire
  end
end

cs.get_cast_info = function(unit)
  local cast_db = pfUI.api.libcast.db

  for name, data in pairs(cast_db) do
    if UnitName(unit) == name and data.icon then
      return { data = data, spell_base = cs.get_spell_base(data.icon) }
    end
  end
end





---@class cs.Dps
cs.Dps = { new = function(self) return setmetatable({}, {__index = self}) end }


---@class cs.Dps.Session
cs.Dps.Session = { new = function(self) return setmetatable({}, {__index = self}) end }

function cs.Dps.Session.build()
  ---@type cs.Dps.Session
  local session = cs.Dps.Session:new()
  session.damage_sum = 0
  session.ts_sum = 0
  session.first_ts = cs.max_number_32
  session.last_ts = 0
  return session
end

-- const
function cs.Dps.Session:get_avg()
  if self.ts_sum <= 0 then
    return 0
  end
  return self.damage_sum / self.ts_sum
end

function cs.Dps.Session:update(damage, last_ts, cur_ts)
  self.damage_sum = self.damage_sum + damage
  self.ts_sum = self.ts_sum + cur_ts - last_ts
  self.first_ts = math.min(self.first_ts, last_ts)
  self.last_ts = math.max(self.last_ts, cur_ts)
end

function cs.Dps.Session:is_expired(ts)
  return not cs.compare_time(10, self.last_ts, ts)
end


---@class cs.Dps.Data
cs.Dps.Data = { new = function(self) return setmetatable({}, {__index = self}) end }

function cs.Dps.Data.build()
  ---@type cs.Dps.Data
  local data = cs.Dps.Data:new()
  data.sessions = {}
  data.start_ts = nil
  data.last_ts = nil

  return data
end

function cs.Dps.Data:get_all(after_ts)
  if not after_ts then after_ts = 0 end

  ---@type cs.Dps.Session
  local session = cs.Dps.Session.build()
  for start_ts, it in pairs(self.sessions) do
    local session_time = it.last_ts
    if session_time >= after_ts then
      session:update(it.damage_sum, start_ts, start_ts + it.ts_sum)
    end
  end
  return session
end

function cs.Dps.build(unit, frame_config)
  ---@type cs.Dps
  local dps = cs.Dps:new()
  dps.unit = unit
  dps.data = cs.Dps.Data.build()
  dps:init(frame_config)
  dps:handler("", unit, 0)
  return dps
end

function cs.Dps:handler(event, target, damage)
  ---@type cs.Dps.Data
  local data = self.data
  local ts = GetTime()

  if data.start_ts then
    local cur_session = data.sessions[data.start_ts]
    if      event == "PLAYER_LEAVE_COMBAT" or
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

    data.sessions[ts] = data.sessions[ts] or cs.Dps.Session.build()

    data.start_ts = ts
    data.last_ts = ts
  end

  ---@type cs.Dps.Session
  local cur_session = data.sessions[data.start_ts]

  cur_session:update(damage, data.last_ts, ts)

  data.last_ts = ts
  self:_update_output()
end

function cs.Dps:init(dps_frame_config)
  local f = cs.create_simple_text_frame(unpack(dps_frame_config))
  f:RegisterEvent("UNIT_COMBAT")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  -- f:RegisterEvent("PLAYER_ENTER_COMBAT")
  f:RegisterEvent("PLAYER_LEAVE_COMBAT")
  f:RegisterEvent("SPELLCAST_START")
  f:SetScript("OnEvent", function()
    if arg2 and arg2 == "HEAL" then return end
    this.cs_dps:handler(event, arg1, arg4)
  end)

  self.frame = f
  f.cs_dps = self

  --cs.add_loop_event("cs.Dps", 0.1, self, cs.Dps._loop)
end

function cs.Dps:_update_output()
  ---@type cs.Dps.Data
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

--function cs.Dps:_loop()
--  if cs.is_free() then
--    return
--  end
--  self:_update_output()
--end

---@type cs.Dps
local st_dps_target = cs.Dps.build("target", dps_frame.target)
local st_dps_player = cs.Dps.build("player", dps_frame.player)






-- mana check
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







--speed check
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









local main = function()

  --PVP
  local pvp = nil
  if not UnitIsPVP("player") and pvp then
    TogglePVP()
    print("ENABLE PVP")
  end
end

main()