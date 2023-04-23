local cs = cs_common
local damage = cs.damage


local dps_frame = {
  target = { "nibsrsCSdps", "BOTTOMLEFT", 1150, 94, "DPS", false, true },
  player = { "nibsrsCSdps", "BOTTOMLEFT", 347, 94, "DPS", "RIGHT", true },
}







---@class cs.DpsSession
cs.DpsSession = cs.class()

--region
function cs.DpsSession:build()
  self.damage_sum = 0
  self.ts_sum = 0
  self.first_ts = cs.max_number_32
  self.last_ts = 0
end

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
cs.DpsData = cs.class()

--region
function cs.DpsData:build(unit)
  self.sessions = cs_dps_sessions[unit]
  local ts = GetTime()
  -- remove expired sessions from saves
  for it in pairs(self.sessions) do
    if not cs.compare_time(cs.Dps.session_store_limit_ts, it, ts) or it >= ts then
      self.sessions[it] = nil
    end
  end

  self.start_ts = nil
  self.last_ts = nil
end

function cs.DpsData:get_all(after_ts)
  if not after_ts then
    after_ts = 0
  end

  ---@type cs.DpsSession
  local session = cs.DpsSession:new()
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
cs.Dps = cs.class()

--region
function cs.Dps:build(unit, frame_config)
  ---@type cs.Dps
  self.unit = unit
  self.data = cs.DpsData:new(unit)
  self:_init(frame_config)
  self:_on_damage(0)

  local filter = {}
  if unit == cs.u.target then
    filter[damage.p.source] = damage.u.player
  else
    filter[damage.p.target] = damage.u.player
  end
  filter[damage.p.datatype] = damage.dt.damage
  damage.parser:subscribe(filter, self, self._on_damage_parser_event)
end

cs.Dps.session_store_limit_ts = 3600 * 2

function cs.Dps:get_dps()
  local session = self.data:get_all()
  return session:get_avg()
end

---@param event cs.damage.Event
function cs.Dps:_on_damage_parser_event(event)
  self:_on_damage(event.value)
end

function cs.Dps:_on_damage(damage_value)

  ---@type cs.DpsData
  local data = self.data
  local ts = GetTime()

  if data.start_ts then
    local cur_session = data.sessions[data.start_ts]
    if not damage_value or cur_session:is_expired(ts) then
      -- close session
      data.start_ts = nil
      data.last_ts = nil
      return
    end
  end

  if not data.start_ts then
    -- combat first damage. create session

    data.sessions[ts] = data.sessions[ts] or cs.DpsSession:new()

    data.start_ts = ts
    data.last_ts = ts
  end

  ---@type cs.DpsSession
  local cur_session = data.sessions[data.start_ts]

  cur_session:update(damage_value, data.last_ts, ts)

  data.last_ts = ts
  self:_update_output()
end



function cs.Dps:_init(dps_frame_config)
  local f = cs.create_simple_text_frame(unpack(dps_frame_config))
  --f:RegisterEvent("UNIT_COMBAT")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  -- f:RegisterEvent("PLAYER_ENTER_COMBAT")
  f:RegisterEvent("PLAYER_LEAVE_COMBAT")
  f:RegisterEvent("SPELLCAST_START")
  f:SetScript("OnEvent", function()
    if arg2 and arg2 == "HEAL" then
      return
    end

    if arg1 ~= this.cs_dps.unit then
      return
    end

    this.cs_dps:_on_damage(nil)
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
  local cur_dps = data:get_all(combat_enter_ts - 0.7) -- damage can be received before combat entering
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





cs.dps = {}
cs.dps.init = function()
  st_dps_target = cs.Dps:new("target", dps_frame.target)
  st_dps_player = cs.Dps:new("player", dps_frame.player)
end
