
cs_common = {}
local cs = cs_common

local dps_frame = {
  target = {"nibsrsCSdps", "BOTTOMLEFT",1150, 94, "DPS", false, true},
  player = {"nibsrsCSdps", "BOTTOMLEFT",347, 94, "DPS", "RIGHT", true},
}

-- debug


cs.name_to_short = function(name)
  if string.find(name, "[0-9]") then
    return name
  end

  local i = 0
  local short = ""
  for k=1,10 do
    i = i + 1
    short = short..string.sub(name, i, i)
    i = string.find(name, "_", i)
    if not i then
      break
    end
  end
  return short
end


function cs.ToString(value, depth, itlimit, short)
  depth = depth or 3
  itlimit = itlimit or 50
  if type(value) == 'table' then
    local str = '{'
    if not short then
      str = str .. tostring(value) .. ': '
    end
    if depth > 1 then
      local count = 0
      for ikey, ivalue in pairs(value) do
        local str_key = cs.ToString(ikey, depth - 1, itlimit, short)
        if short then
          str_key = cs.name_to_short(str_key)
        end
        str = str ..str_key..' = ' .. cs.ToString(ivalue, depth - 1, itlimit, short) .. ','
        count = count + 1
        if count >= itlimit then
          str = str .. '... '
          break
        end
      end
      str = str .. '}'
      return str
    else
      local size = 0
      for _ in pairs(value) do
        size = size + 1
      end
      return str..size..'} '
    end
  elseif type(value) == 'string' then
    if short then
      return tostring(value)
    end
    return '"'..tostring(value)..'"'
  end
  return tostring(value)
end


function cs.ldebug(...)
  local line = debugstack(2, 1, 1)
  local line_end = string.find(line, "in function")
  line_end = line_end and line_end -1
  line = string.sub(line, 32, line_end)

  for i, v in pairs(cs.to_table(arg)) do
    if i ~= "n" then
      local msg = ""
      for i=2,7 do
        msg = cs.ToString(v, i, 20)
        if strlen(msg) >= 320 then
          break
        end
      end
      print(line..msg)
    end
  end
end


function cs.debug(...)
  local line = debugstack(2, 1, 1)
  local line_end = string.find(line, "in function")
  line_end = line_end and line_end -1
  line = string.sub(line, 32, line_end)

  local full_msg = ""
  for i, v in pairs(cs.to_table(arg)) do
    if i ~= "n" then
      local msg = ""
      for i=2,7 do
        msg = cs.ToString(v, i, 20, true)
        if strlen(msg) >= 120 then
          break
        end
      end
      full_msg = full_msg.."|"..msg
    end
  end
  print(line..full_msg)
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


cs.create_class = function(class_tab)
  local class = class_tab or {}
  function class:new(tab)
    local obj = setmetatable(tab or {}, {__index = self})
    return obj
  end
  return class
end

---@class cs.Class
cs.Class = cs.create_class()

cs.Class.build = function()
  local class = cs.Class:new()

  return class
end

---@type cs.Class
cs.st_class = nil



cs.is_table = function(value)
  return type(value) == "table"
end

function cs.to_table(...)
  local tbl = {}
  for i, v in pairs(arg) do
    if type(v) == "table" then
      return v
    end
    if type(i) == "number" then
      table.insert(tbl, v)
    end
  end
  return tbl
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
  event_list = {},
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
    if event.count then
      event.count = event.count - 1
      if event.count <= 0 then
        event.period = 0
      end
    end
  end
  return event.period == 0
end

function Looper:main_loop()
  local count = 0
  for name, event in pairs(self.event_list) do
    local break_event = self:iterate_event(event)
    if break_event then
      self.event_list[name] = nil
    end
    count = count + 1
  end
  if count > 0 then
    looper.delay_q(self.main_loop, self)
  end
end

cs.add_loop_event = function(name, period, obj, func, count)
  local event = {}
  event.func = func
  event.obj = obj
  event.period = period
  event.cur_period = period
  event.count = count

  looper.event_list[name] = event

  if not looper.timer then
    looper.delay_q(looper.main_loop, looper)
  end
end

cs.add_loop_event_once = function(name, delay, obj, func)
  cs.add_loop_event(name, delay, obj, func, 1)
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






---@class cs.ButtonChecker
cs.ButtonChecker = cs.create_class()

cs.ButtonChecker.build = function()
  ---@type cs.ButtonChecker
  local holder = cs.ButtonChecker:new()

  holder.down_list = {}
  holder.down_pattern_list = {}

  holder.repeat_list = {}
  holder.repeat_pattern_list = {}

  cs.add_loop_event("cs.ButtonChecker",0.2, holder, holder._check_loop)

  return holder
end

-- const
function cs.ButtonChecker:add_button(longkey)
  local bar = math.floor(longkey / 12 + 1)
  local key = cs.fmod(longkey, 12)
  cs.ActionBarProxy.add_proxy(bar, key, cs.ButtonChecker._button_callback, self)
end

-- callback_func = function(callback_obj, longkey, duration)
function cs.ButtonChecker:add_down_pattern(down_duration, callback_obj, callback_func)
  self.down_pattern_list[down_duration] = { obj = callback_obj, func = callback_func }
end

function cs.ButtonChecker:add_repeat_pattern(cps, callback_obj, callback_func)
  self.repeat_pattern_list[cps] = { obj = callback_obj, func = callback_func }
end


function cs.ButtonChecker:_button_callback(bar, key)
  --cs.debug({bar, key, keystate})
  local longkey = bar * 12 + key - 12
  local ts = GetTime()
  local click_info = {longkey = longkey, keystate = keystate, ts = ts, handler = 0}

  if click_info.keystate == cs.ActionBarProxy.key_state_up then
    self.down_list[longkey] = nil
    self.repeat_list[longkey] = self.repeat_list[longkey] or {}
    table.insert(self.repeat_list[longkey] , click_info)
    self:_check_repeat_patterns(longkey, self.repeat_list[longkey], ts)
  else
    self.down_list[longkey] = click_info
  end
end

function cs.ButtonChecker:_check_down_patterns(click_info, ts)
  for down_duration, callback in pairs(self.down_pattern_list) do
    if not cs.compare_time(down_duration, click_info.ts, ts) and click_info.handler < down_duration then
      click_info.handler = down_duration
      callback.func(callback.obj, click_info.longkey, down_duration)
    end
  end
end

function cs.ButtonChecker:_check_repeat_patterns(longkey, key_clicks, ts)
  local count = 0
  for i, click_info in pairs(key_clicks) do
    if cs.compare_time(1, click_info.ts, ts) then
      count = count + 1
    else
      key_clicks[i] = nil
    end
  end

  for cps, callback in pairs(self.repeat_pattern_list) do
    if count >= cps then
      callback.func(callback.obj, longkey, cps)
    end
  end
end

function cs.ButtonChecker:_check_loop()
  local ts = GetTime()

  for _, key_click in pairs(self.down_list) do
    self:_check_down_patterns(key_click, ts)
  end
end

---@type cs.ButtonChecker
cs.st_button_checker = nil





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

  self.prev_target = cs.check_target(cs.t_exists)
  self.prev_combat = cs.check_combat(cs.c_normal)

  if UnitExists(cs.u_mouseover) then
    self.cur_target = cs.u_mouseover
    TargetUnit(cs.u_mouseover)
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
    if not cs.check_combat(cs.c_normal) then
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





-- spells
---@class cs.Spell
cs.Spell = cs.create_class()

cs.Spell.build = function(id_name, book)
  local spell = cs.Spell:new()

  if type(id_name) == "string" then
    spell.id, spell.book = cs.Spell._find_spell(id_name)
    spell.name = id_name
  else
    spell.id = id_name
    spell.book = book
    spell.name = GetSpellName(id_name, book)
  end
  spell.cast_ts = nil

  return spell
end

-- const
function cs.Spell:get_cd()
  local ts_start, duration = GetSpellCooldown(self.id, self.book)
  if ts_start == 0 then
    -- no cd
    return nil
  end

  local ts = GetTime()
  return duration - ts + ts_start, ts_start, duration
end

function cs.Spell:cast(to_self)
  if not self:get_cd() then
    CastSpellByName(self.name, to_self);
    self.cast_ts = GetTime()
    return true
  end
end

function cs.Spell:cast_to_unit(unit)
  if self:cast(unit == cs.u_player) then
    if (SpellIsTargeting()) then
      SpellTargetUnit(unit)
    end
    return true
  end
end

-- return spell_id, book
cs.Spell._find_spell = function(name)
  local id = 0
  local it_name = ""
  while it_name ~= name do
    id = id+1
    it_name = GetSpellName(id, "spell")
  end
  return id, "spell"
end




---@class cs.SpellOrder
cs.SpellOrder = cs.create_class()

cs.SpellOrder.build = function(...)
  local order = cs.SpellOrder:new()

  order.spell_list = {}
  for _, name in pairs(cs.to_table(unpack(arg))) do
    local spell = cs.Spell.build(name)
    table.insert(order.spell_list, spell)
  end

  order.last_casted = 0

  return order
end

function cs.SpellOrder:cast(unit_to)
  for i, spell in pairs(self.spell_list) do
    local casted
    if unit_to then
      casted = spell:cast_to_unit(unit_to)
    else
      casted = spell:cast()
    end
    if casted then
      self.last_casted = i
      return spell
    end
  end
end





cs.cast = function(a1,a2,a3,a4,a5,a6,a7)
  local cast_list
  if type(a1) == "table" then
    cast_list = a1
  else
    cast_list = { a1,a2,a3,a4,a5,a6,a7 }
  end

  local order = cs.SpellOrder.build(cast_list)
  return order:cast()
end

cs.get_spell_cd = function(spell_name)
  return cs.Spell.build(spell_name):get_cd()
end


-- default to player
cs.cast_helpful = function(name)
  local unit = cs.u_player
  if cs.check_target(cs.t_friend) then
    unit = cs.u_target
  elseif cs.check_mouse(cs.t_exists) and cs.check_mouse(cs.t_friend) then
    unit = cs.u_mouseover
  end

  local spell = cs.Spell.build(name)
  return spell:cast_to_unit(unit)
end



function cs.find_buff(check_list, unit)
  for i, check in pairs(cs.to_table(check_list)) do
    if FindBuff(check, unit) then
      return check, i
    end
  end
end




---@class cs.Buff
cs.Buff = cs.create_class()

cs.Buff.exists = nil
cs.Buff.success = 1
cs.Buff.failed = 2

cs.Buff.build = function(name, unit)
  local buff = cs.Buff:new()

  buff.name = name
  buff.unit = unit or cs.u_player
  buff.spell = cs.Spell.build(name)

  return buff
end

-- const
function cs.Buff:check_target_range()
  local unit = self.unit
  if unit == cs.u_player then
    return true
  end
  return UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDead(unit) and
          CheckInteractDistance(unit, 4) and UnitIsVisible(unit)
end

-- const
function cs.Buff:check_exists()
  return cs.find_buff(self.name, self.unit)
end

function cs.Buff:rebuff()
  if not self:check_target_range() then
    return cs.Buff.failed
  end

  if self:check_exists() then
    return cs.Buff.exists
  end

  if self.spell:cast_to_unit(self.unit) then
    return cs.Buff.success
  end

  return cs.Buff.failed
end



-- default to player
function cs.rebuff(buff, custom_buff_check_list, unit)
  unit = unit or cs.u_player

  if unit ~= cs.u_player then
    if not UnitExists(unit) or
            not UnitIsConnected(unit) or
            UnitIsDead(unit) or
            not CheckInteractDistance(unit, 4) or
            not UnitIsVisible(unit) then
      return cs.Buff.failed
    end
  end

  if cs.find_buff(custom_buff_check_list or buff, unit) then
    return cs.Buff.exists
  end

  local spell = cs.Spell.build(buff)
  if spell:cast_to_unit(unit) then
    return cs.Buff.success
  end

  return cs.Buff.failed
end

cs.get_buff_list = function(unit, b_fun)
  if not unit then unit = cs.u_player end
  if not b_fun then b_fun = UnitBuff end

  local buff_list = {}
  for i=1, 100 do
    local buff = b_fun(unit, i)
    if not buff then break end

    table.insert(buff_list, buff)
  end
  return buff_list
end

cs.get_debuff_list = function(unit)
  return cs.get_buff_list(unit, UnitDebuff)
end

function cs.has_buffs(unit, buff_str, b_fun)
  if not buff_str then buff_str = "" end

  local buff_list = cs.get_buff_list(unit, b_fun)
  for _, buff in pairs(buff_list) do
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

---@class cs.SpellData
cs.SpellData = cs.create_class()

cs.SpellData.build = function(pfui_spell)
  local data = cs.SpellData:new()
  data.pfui_spell = pfui_spell
  data.ts_sec = math.floor(GetTime())
  return data
end

function cs.SpellData:get_base()
  local spell_icon = self.pfui_spell.icon

  if string.find(spell_icon, cs.spell_base_Shadow) then
    return cs.spell_base_Shadow
  elseif string.find(spell_icon, cs.spell_base_Frost) then
    return cs.spell_base_Frost
  elseif string.find(spell_icon, cs.spell_base_Fire) then
    return cs.spell_base_Fire
  end
end

function cs.SpellData:eq(other)
  if not other then
    return
  end
  return self.pfui_spell.cast == other.pfui_spell.cast and self.ts_sec == other.ts_sec
end

---@return cs.SpellData
cs.get_cast_info = function(unit)
  local cast_db = pfUI.api.libcast.db

  for name, pfui_spell in pairs(cast_db) do
    if UnitName(unit) == name and pfui_spell.icon then
      return cs.SpellData.build(pfui_spell)
    end
  end
end












---@class cs.CastChecker
cs.CastChecker = cs.create_class()

cs.CastChecker.build = function()
  local cast_checker = cs.CastChecker:new()

  cast_checker.callback_list = {}
  cast_checker.last_spell = nil
  cs.add_loop_event("cs.CastChecker",0.2, cast_checker, cast_checker._check_loop)

  return cast_checker
end

-- func = function(obj, cs.SpellData)
function cs.CastChecker:add_callback(obj, func)
  self.callback_list[obj] = func
end

function cs.CastChecker:_check_loop()
  if not cs.check_target(cs.t_attackable) then
    return
  end

  local data = cs.get_cast_info(cs.u_target)
  if not data then
    return
  end

  if data:eq(self.last_spell) then
    return
  end

  self.last_spell = data
  for obj, func in pairs(self.callback_list)
    do func(obj, data)
  end
end

---@type cs.CastChecker
cs.st_cast_checker = nil



---@class cs.Dps
cs.Dps = { new = function(self) return setmetatable({}, {__index = self}) end }
cs.Dps.session_store_limit_ts = 3600 * 2

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


cs_dps_sessions = { target = {}, player = {}}

---@class cs.Dps.Data
cs.Dps.Data = { new = function(self) return setmetatable({}, {__index = self}) end }

function cs.Dps.Data.build(unit)
  ---@type cs.Dps.Data
  local data = cs.Dps.Data:new()
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
  dps.data = cs.Dps.Data.build(unit)
  dps:_init(frame_config)
  dps:_handler("", unit, 0)
  return dps
end

function cs.Dps:get_dps()
  local session = self.data:get_all()
  return session:get_avg()
end

function cs.Dps:_handler(event, target, damage)
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

function cs.Dps:_init(dps_frame_config)
  local f = cs.create_simple_text_frame(unpack(dps_frame_config))
  f:RegisterEvent("UNIT_COMBAT")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  -- f:RegisterEvent("PLAYER_ENTER_COMBAT")
  f:RegisterEvent("PLAYER_LEAVE_COMBAT")
  f:RegisterEvent("SPELLCAST_START")
  f:SetScript("OnEvent", function()
    if arg2 and arg2 == "HEAL" then return end
    this.cs_dps:_handler(event, arg1, arg4)
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
local st_dps_target -- target received damage
---@type cs.Dps
local st_dps_player -- player received damage










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

  local class_speed = 1
  local _, class = UnitClass(cs.u_player)
  if class == "PALADIN" then
    local _, _, _, _, current_rank = GetTalentInfo(3, 9)
    class_speed = 1 + current_rank * 0.04
  end

  -- tortle mount
  if cs.has_buffs("player", "inv_pet_speedy") then
    return 1.14 * class_speed * class_speed
  end

  return 1 * class_speed
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
  local m_ut = cs.time_to_str(m and m.updatetime or 0)
  local p_ut = cs.time_to_str(p and p.updatetime or 0)
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






-- defer load
local main = function()

  local main_frame = cs.create_simple_frame("common_main_frame")
  main_frame:RegisterEvent("VARIABLES_LOADED")
  main_frame:SetScript("OnEvent", function()
    st_dps_target = cs.Dps.build("target", dps_frame.target)
    st_dps_player = cs.Dps.build("player", dps_frame.player)
  end)

  cs.st_button_checker = cs.ButtonChecker.build()
  cs.st_cast_checker = cs.CastChecker.build()
  cs.st_map_checker = cs.MapChecker.build()

  --PVP
  --local pvp = nil
  --if not UnitIsPVP("player") and pvp then
  --  TogglePVP()
  --  print("ENABLE PVP")
  --end
end

main()












-- public

function cs_set_target_mouse()
  st_targeter:set_target_mouse()
end

function cs_set_target_last()
  st_targeter:set_last_target()
end

function cs_cast_helpful(heal_cast)
  cs.cast_helpful(heal_cast)
end

function cs_dump_unit()
  local cur_time = cs.time_to_str(GetTime())
  print("----- "..cur_time)

  if cs.check_target(cs.t_exists) then
    local buffs = cs.get_buff_list(cs.u_target)
    local debuffs = cs.get_debuff_list(cs.u_target)
    for t, list in pairs({buffs = buffs, debuffs = debuffs}) do
      print(t)
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
