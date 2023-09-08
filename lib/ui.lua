local cs = cs_common

cs.color = {}
cs.color.make = function(rgb)
  return "|cff" .. rgb
end

cs.color.red = cs.color.make("ff2020")
cs.color.red_1 = cs.color.make("ff0000")
cs.color.orange = cs.color.make("FF8000")
cs.color.orange_1 = cs.color.make("FFB266")
cs.color.yellow = cs.color.make("FFFF66")
cs.color.blue = cs.color.make("20a0FF")
cs.color.purple = cs.color.make("C086F9")
cs.color.green = cs.color.make("00ff00")
cs.color.white = cs.color.make("ffffFF")
cs.color.grey = cs.color.make("A0A0A0")
cs.color.none = "|r"


cs.ui = {}

--- @class cs.ui.Point
cs.ui.Point = cs.class()

function cs.ui.Point:build(x, y, to_point, relative_frame, relative_point)
  if relative_frame then
    self.impl = {
      to_point or cs.ui.r.BOTTOMLEFT,
      relative_frame,
      relative_point or cs.ui.r.BOTTOMLEFT,
      x or 0,
      y or 0,
    }
  else
    self.impl = {
      to_point or cs.ui.r.BOTTOMLEFT,
      x or 0,
      y or 0,
    }
  end
end

function cs.ui.Point:unpack()
  return unpack(self.impl)
end



-- Frame
function cs.create_simple_frame()
  local f = CreateFrame("Frame", nil, UIParent)
  return f
end

function cs.create_escape_press_detector(native_parent, obj, func)
  local f = CreateFrame("EditBox", nil, native_parent)
  f.cs_obj = obj
  f.cs_func = func
  f:SetAutoFocus(true)
  f:SetWidth(1)
  f:SetHeight(1)
  f:SetScript("OnEscapePressed", function()
    this.cs_func(this.cs_obj)
  end)
  return f
end


-- relative
cs.ui.r = {}
cs.ui.r.BOTTOMLEFT = "BOTTOMLEFT"
cs.ui.r.LEFT = "LEFT"
cs.ui.r.RIGHT = "RIGHT"
cs.ui.r.CENTER = "CENTER"

---@class cs.ui.Text
cs.ui.Text = cs.create_class()

--region
function cs.ui.Text:build(x, y, frame_relative, text_relative, mono, font_size, background)

  local obj = self:new()

  local f = cs.create_simple_frame()
  f:SetHeight(10)
  f:SetWidth(20)
  f:SetPoint(frame_relative or cs.ui.r.BOTTOMLEFT, x, y)

  obj.frame = f

  local font = "Fonts\\FRIZQT__.TTF"
  if mono then
    font = "Interface\\AddOns\\CustomScripts\\fonts\\UbuntuMono-R.ttf"
    font_size = font_size or 14
  else
    font_size = font_size or 12
  end

  obj.font = font
  obj.font_size = font_size
  obj.text_relative = text_relative or cs.ui.r.BOTTOMLEFT

  obj.lines = {}

  obj:add_line(0)

  if background then
    obj.texture_frame = f:CreateTexture(nil, "BACKGROUND")
    obj.texture_frame:SetTexture(unpack(background))
  end

  return obj
end

function cs.ui.Text:build_from_config(c)
  return cs.ui.Text:build(c.x, c.y, c.frame_relative, c.text_relative, c.mono, c.font_size, c.background)
end

function cs.ui.Text:set_text(text, line_number)
  line_number = line_number or 0

  self.lines[line_number]:SetText(text)
  if self.texture_frame then
    -- TODO: fix for multi line
    self.texture_frame:SetHeight(self.cs_text:GetHeight() + 2)
    self.texture_frame:SetWidth(self.cs_text:GetWidth() + 2)
    self.texture_frame:ClearAllPoints()
    self.texture_frame:SetPoint("CENTER", self.cs_text, "CENTER", 0, -1)
  end
end

function cs.ui.Text:get_text(line_number)
  return self.lines[line_number]:GetText()
end

function cs.ui.Text:add_line(number)
  local text_frame = self.frame:CreateFontString("Status", nil, "GameFontHighlightSmallOutline")
  text_frame:SetFont(self.font, self.font_size, "OUTLINE")
  text_frame:SetPoint(self.text_relative or cs.ui.r.BOTTOMLEFT, 0, number * self.font_size)
  text_frame:SetJustifyH(cs.ui.r.LEFT)
  table.insert(self.lines, number, text_frame)
end

function cs.ui.Text:get_native()
  return self.lines[0]
end
--endregion



-- Button
---@class cs.ui.Button
cs.ui.Button = cs.class()

function cs.ui.Button:build(width, height, point, texture, on_click_obj, on_click_func)
  local b = CreateFrame("Button", nil, UIParent)
  b.cs_on_click_obj = on_click_obj
  b.cs_on_click_func = on_click_func
  b:SetHeight(height)
  b:SetWidth(width)
  b:SetScript("OnClick", function()
    this.cs_on_click_func(this.cs_on_click_obj)
  end)
  self.button = b

  if texture then
    local texture_frame = b:CreateTexture(nil, "BACKGROUND")
    texture_frame:SetHeight(height)
    texture_frame:SetWidth(width)
    texture_frame:SetTexture(cs.type.check(texture, cs.type.table) and unpack(texture) or texture)
    self.texture = texture_frame
  end

  self:move(point)
end

---@param point cs.ui.Point
function cs.ui.Button:move(point)
  self.button:ClearAllPoints()
  self.button:SetPoint(point:unpack())
  if self.texture then
    self.texture:ClearAllPoints()
    self.texture:SetPoint(cs.ui.r.LEFT, self.button, cs.ui.r.LEFT, 0, 0)
  end
end

function cs.ui.Button:get_native()
  return self.button
end

function cs.ui.Button:is_shown()
  return self.button:IsShown()
end

function cs.ui.Button:hide()
  self.button:Hide()
  if self.texture then
    self.texture:Hide()
  end
end

function cs.ui.Button:show()
  self.button:Show()
  if self.texture then
    self.texture:Show()
  end
end



---@class cs.ui.ButtonBar
cs.ui.ButtonBar = cs.class()

function cs.ui.ButtonBar:build(size, texture_list, obj, func)
  local point = cs.ui.Point:create(0, 0)

  ---@type cs.ui.Button[]
  self.button_list = {}

  for _, texture in pairs(texture_list) do
    local callback = { texture = texture, obj = obj, func = func }
    ---@type cs.ui.Button
    local button = cs.ui.Button:new(size, size, point, texture, callback, function(callback)
      callback.func(callback.obj, callback.texture)
    end)
    table.insert(self.button_list, button)
  end

  self:move(0, 0)
end

function cs.ui.ButtonBar:move(x, y)
  local point = cs.ui.Point:create(x, y)
  for _, button in pairs(self.button_list) do
    button:move(point)
    point = cs.ui.Point:create(0, 0, cs.ui.r.LEFT, button:get_native(), cs.ui.r.RIGHT)
  end
end

function cs.ui.ButtonBar:get_native()
  return self.button_list[1]:get_native()
end

function cs.ui.ButtonBar:is_shown()
  return self.button_list[1]:is_shown()
end

function cs.ui.ButtonBar:hide()
  for _, button in pairs(self.button_list) do
    button:hide()
  end
end

function cs.ui.ButtonBar:show()
  for _, button in pairs(self.button_list) do
    button:show()
  end
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

  cs.add_loop_event("cs.ButtonChecker", 0.2, holder, holder._check_loop)

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
  --cs_debug({bar, key, keystate})
  -- TODO: fix bag when move icon to other
  local longkey = bar * 12 + key - 12
  local ts = GetTime()
  local click_info = { longkey = longkey, keystate = keystate, ts = ts, handler = 0 }

  if click_info.keystate == cs.ActionBarProxy.key_state_up then
    self.down_list[longkey] = nil
    self.repeat_list[longkey] = self.repeat_list[longkey] or {}
    table.insert(self.repeat_list[longkey], click_info)
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
cs.st_button_checker = cs.ButtonChecker.build()



---@class cs.ui.DownChecker
cs.ui.DownChecker = cs.class()

-- timeout down
cs.ui.DownChecker.t = {}
cs.ui.DownChecker.t.change = 0.55
cs.ui.DownChecker.t.save = 3
cs.ui.DownChecker.t.reset = 6
cs.ui.DownChecker.t.full_reset = 10

-- click per sec
cs.ui.DownChecker.c = {}
cs.ui.DownChecker.c.save = 7

function cs.ui.DownChecker:build()
  self.sub_list = {}

  cs.st_button_checker:add_down_pattern(self.t.change, self, self._down_button_event)
  cs.st_button_checker:add_down_pattern(self.t.save, self, self._down_button_event)
  cs.st_button_checker:add_down_pattern(self.t.reset, self, self._down_button_event)
  cs.st_button_checker:add_down_pattern(self.t.full_reset, self, self._down_button_event)

  cs.st_button_checker:add_repeat_pattern(self.c.save, self, self._down_button_event)
end

function cs.ui.DownChecker:add_sub(longkey, obj, func)
  self.sub_list[longkey] = { obj = obj, func = func }

  cs.st_button_checker:add_button(longkey)
end

function cs.ui.DownChecker:_down_button_event(longkey, event)
  local sub = self.sub_list[longkey]

  sub.func(sub.obj, longkey, event)
end

cs.ui.down_checker = cs.ui.DownChecker:new()
