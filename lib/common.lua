
cs_common = cs_common or {}
local cs = cs_common

cs.type = {}
cs.type.number = "number"
cs.type.string = "string"
cs.type.table = "table"
cs.type.check = function(v, t)
  return type(v) == t
end

cs.deepcopy = function(tbl)
  if cs.type.check(tbl, cs.type.table) then
    local result = {}
    for key, value in pairs(tbl) do
      local copy_key = cs.deepcopy(key)
      local copy_value = cs.deepcopy(value)
      result[copy_key] = copy_value
    end
    return result
  end

  return tbl
end

cs_print = function(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffcccc33CS: |cffffff55" .. ( msg or "nil" ))
end


local get_stack_line = function(stack_level)
  local line = debugstack(stack_level, 1, 1)
  local to_output = ""
  if line then
    local file_info_begin = 32
    local file_info_end = string.find(line, " in function") or nil
    to_output = to_output..string.sub(line, file_info_begin, file_info_end)

    if file_info_end then
      local fun_info_begin = file_info_end + 13
      if fun_info_begin then
        local fun_info_end = string.find(line, "[\n]", fun_info_begin)
        --if not fun_info_end or string.find(line, "[<]", fun_info_begin) >= fun_info_end then
          to_output = to_output..string.sub(line, fun_info_begin, fun_info_end)
        --end
      end
    end
  end
  return string.sub(to_output, 1, strlen(to_output) - 1)
end

cs_stack = function(condition)
  if not condition then
    return
  end
  cs_print("STACK BEGIN")
  for i=1,10 do
    local line = get_stack_line(i)
    if line then
      cs_print(line)
    else
      break
    end
  end
  cs_print("STACK END")
end

cs_error = function(msg)
  cs_stack(true)
  cs_print("|cffcc3333ERROR: |cffff7777".. (msg or "nil" ))
end
seterrorhandler(cs_error)


cs.print = cs_print
cs.stack = cs_stack


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


function cs.to_string(value, depth, itlimit, short)
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
        local str_key = cs.to_string(ikey, depth - 1, itlimit, short)
        if short then
          str_key = cs.name_to_short(str_key)
        end
        str = str ..str_key..' = ' .. cs.to_string(ivalue, depth - 1, itlimit, short) .. ','
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

cs.to_string_best_d = function(...)
  local short = nil
  local full_msg = ""
  for _, v in ipairs(arg) do
    local msg = ""
    for i=2,7 do
      msg = cs.to_string(v, i, 20, short)
      if strlen(msg) >= 220 then
        break
      end
    end
    full_msg = full_msg..msg.." | "
  end
  return full_msg
end

function cs.print_table(...)
  local full_msg = cs.to_string_best_d(unpack(arg))
  cs.print(full_msg)
end

cs_debug = function(...)
  local stack_level = 3

  local line = get_stack_line(stack_level)

  local full_msg = cs.to_string_best_d(unpack(arg))
  cs.print(line..": "..full_msg)
end

cs.debug = cs_debug



-- regex

-- example: cs.regex("Fire damage. (10 resisted)", "%((%d+) resisted%)") == 10
cs.regex = function(str, pattern)
  local result = { string.find(str, pattern) }
  if table.getn(result) < 3 then
    return
  end

  for i=1,2 do
    table.remove(result, 1)
  end

  return unpack(result)
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
    local obj = setmetatable(tab or {}, self)
    self.__index = self
    return obj
  end
  function class:create(...)
    return self.build(unpack(arg))
  end
  return class
end

cs.class = function(base)
  local class = {}
  if base then
    setmetatable(class ,{__index = base})
    class._cs_base_build = base.build
    class.build = function()  end
  end

  function class:new(...)
    local obj = setmetatable({}, self)
    self.__index = self
    if self._cs_base_build then
      self._cs_base_build(obj, unpack(arg))
    end
    if self.build then
      self.build(obj, unpack(arg))
    end
    return obj
  end
  class.create = class.new

  return class
end



cs.is_table = function(value)
  return type(value) == "table"
end

cs.list_to_dict = function(list, value_type)
  assert(value_type)

  local dict = {}
  list = not cs.is_table(list) and { list } or list
  for i, v in pairs(list) do
    dict[v] = i
  end
  return dict
end

cs.filter_dict = function(dict, value_type)
  assert(value_type)

  local result = {}
  for name, value in pairs(dict) do
    if type(value) == value_type then
      result[name] = value
    end
  end
  return result
end

cs.dict_to_list = function(dict, value_type)
  assert(value_type)

  local list = {}
  for _, value in pairs(dict) do
    if type(value) == value_type then
      table.insert(list, value)
    end
  end
  return list
end

cs.dict_keys_to_list = function(dict, value_type)
  assert(value_type)

  local list = {}
  for key in pairs(dict) do
    if type(key) == value_type then
      table.insert(list, key)
    end
  end
  return list
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


---@class cs.FixTable
cs.FixTable = cs.class()
--region cs.FixTable
function cs.FixTable:build(timeout, size_limit)
  self.timeout = timeout
  self.size_limit = size_limit
  self.list = {}
end

-- const
function cs.FixTable:iterate_list(func)
  self:_remove_expired()
  for _, el in pairs(self.list) do
    func(el.value)
  end
end

-- const
function cs.FixTable:get_last_ts()
  self:_remove_expired()
  local size = self:get_size()
  if size > 0 then
    return self.list[1].ts
  end
  return 0
end

-- const
function cs.FixTable:get_size()
  self:_remove_expired()
  return table.getn(self.list)
end

-- const
function cs.FixTable:is_full()
  self:_remove_expired()
  return self.size_limit and self:get_size() == self.size_limit
end

-- const
function cs.FixTable:get_max_diff()
  self:_remove_expired()
  local min_v =  9999999
  local max_v = -9999999
  for _, el in self.list do
    min_v = min(min_v, el.value)
    max_v = max(max_v, el.value)
  end

  return max_v - min_v
end

-- const
function cs.FixTable:get_sum(last_count)
  self:_remove_expired()
  local sum = 0
  local cur_size = self:get_size()
  local cur_count = math.min(last_count or cur_size, cur_size)
  for i=1, cur_count do
    sum = sum + self.list[i].value
  end
  return sum
end

-- const
function cs.FixTable:get_avg_value(last_count)
  local cur_size = self:get_size()
  local cur_count = math.min(last_count or cur_size, cur_size)
  local sum = self:get_sum(cur_count)
  if cur_size > 0 then
    return sum / cur_count
  end
  return 0
end

function cs.FixTable:add(value)
  local ts = GetTime()
  table.insert(self.list, 1, { value = value, ts = ts })

  local size = table.getn(self.list)
  if self.size_limit and size > self.size_limit then
    table.remove(self.list, size)
  end
  self:_remove_expired(ts)
end

function cs.FixTable:clear()
  self.list = {}
end

function cs.FixTable:_remove_expired(ts)
  if not self.timeout then
    return
  end

  ts = ts or GetTime()
  local size = table.getn(self.list)
  for i=size, 1, -1 do
    if not cs.compare_time(self.timeout, self.list[i].ts, ts) then
      table.remove(self.list, i)
    else
      break
    end
  end
end
--endregion cs.FixTable

function cs.create_fix_table(size)
  return cs.FixTable:new(nil, size)
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
  for id, event in pairs(self.event_list) do
    local break_event = self:iterate_event(event)
    if break_event then
      self.event_list[id] = nil
    end
    count = count + 1
  end
  if count > 0 then
    looper.delay_q(self.main_loop, self)
  end
end

cs.add_loop_event = function(name, period, obj, func, count)
  if type(obj) == "function" then
    func = obj
    obj = nil
  end

  local event = {}
  event.func = func
  event.obj = obj
  event.period = period
  event.cur_period = period
  event.count = count

  table.insert(looper.event_list, event)

  if not looper.timer then
    looper.delay_q(looper.main_loop, looper)
  end
end

local looper_sub_list = {}

cs.event = {}
cs.event.loop = function(period, obj, func)
  cs.add_loop_event("", period, obj, func)
end

cs.event.try_loop = function(period, obj, func)
  if looper_sub_list[obj] then
    return
  end

  looper_sub_list[obj] = true

  cs.add_loop_event("", period, obj, func)
end

cs.event.rep = function(period, count, obj, func)
  cs.add_loop_event("", period, obj, func, count)
end

cs.event.once = function(delay, obj, func)
  cs.add_loop_event("", delay, obj, func, 1)
end



cs.common = {}
cs.common.test = function()
  do
    ---@type cs.FixTable`
    local fix = cs.FixTable:new(nil, 3)
    assert(fix:get_size() == 0)
    assert(not fix:is_full())
    assert(fix:get_last_ts() == 0)
    assert(fix:get_sum() == 0)
    assert(fix:get_avg_value() == 0)

    fix:add(10)
    assert(fix:get_size() == 1)
    assert(not fix:is_full())
    assert(fix:get_sum() == 10)
    assert(fix:get_avg_value() == 10)
    assert(fix:get_max_diff() == 0)

    fix:add(6)
    assert(fix:get_size() == 2)
    assert(not fix:is_full())
    assert(fix:get_sum() == 16)
    assert(fix:get_avg_value() == 8)
    assert(fix:get_max_diff() == 4)

    fix:add(104)
    assert(fix:get_size() == 3)
    assert(fix:is_full())
    assert(fix:get_sum() == 120)
    assert(fix:get_avg_value() == 40)
    assert(fix:get_max_diff() == 98)

    fix:add(-20)
    assert(fix:get_size() == 3)
    assert(fix:is_full())
    assert(fix:get_sum() == 90)
    assert(fix:get_avg_value() == 30)
    assert(fix:get_max_diff() == 124)
  end

  do
    local fix = cs.FixTable:new(1)
    assert(fix:get_size() == 0)
    assert(fix:get_last_ts() == 0)
    assert(fix:get_sum() == 0)
    assert(fix:get_avg_value() == 0)

    fix:add(10)
    assert(fix:get_size() == 1)
    assert(not fix:is_full())
    assert(fix:get_sum() == 10)
    assert(fix:get_avg_value() == 10)
    assert(fix:get_max_diff() == 0)
    --
    --cs.event.once(0.5, function()
    --  assert(fix:get_size() == 1)
    --  assert(not fix:is_full())
    --  assert(fix:get_sum() == 10)
    --  assert(fix:get_avg_value() == 10)
    --  assert(fix:get_max_diff() == 0)
    --end)

    cs.event.once(10, function()
      assert(fix:get_size() == 0)
      assert(fix:get_last_ts() == 0)
      assert(fix:get_sum() == 0)
      assert(fix:get_avg_value() == 0)
    end)
  end
end
