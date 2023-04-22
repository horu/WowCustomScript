
local cs = cs_common





cs.color = {}
cs.color.make = function(rgb)
    return "|cff"..rgb
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
cs.st_button_checker = cs.ButtonChecker.build()


