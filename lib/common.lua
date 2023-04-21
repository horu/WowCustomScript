
cs_common = cs_common or {}
local cs = cs_common

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
  local list = cs.to_table(unpack(arg))
  local short = list.short
  local stack_level = list.stack_level or 2
  list.short = nil
  list.stack_level = nil
  list.n = nil

  local line = debugstack(stack_level, 1, 1)
  local line_end = string.find(line, "in function")
  line_end = line_end and line_end -1
  line = string.sub(line, 32, line_end)


  local full_msg = ""
  for _, v in pairs(list) do
    local msg = ""
    for i=2,7 do
      msg = cs.ToString(v, i, 20, short)
      if strlen(msg) >= 120 then
        break
      end
    end
    full_msg = full_msg.."|"..msg
  end
  print(line..full_msg)
end


function cs.debug(...)
  local list = cs.to_table(arg)
  list.short = true
  list.stack_level = 3
  cs.ldebug(list)
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




