local cs = cs_common


cs.chat = {}
cs.chat.c_c_vs_s_m = "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES"
cs.chat.c_hp_m = "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES"

cs.damage = {}

---@class cs.damage.Any
cs.damage.a = {}
cs.damage.a.unknown = "UNKNOWN"

---@class cs.damage.Param
cs.damage.p = {}
cs.damage.p.source = "source"
cs.damage.p.action = "action"
cs.damage.p.target = "target"
cs.damage.p.value = "value"
cs.damage.p.school = "school"
cs.damage.p.datatype = "datatype"

---@class cs.damage.Unit
cs.damage.u = {}
cs.damage.u.player = "u.player"
cs.damage.u.party = "u.party"

---@class cs.damage.Target
cs.damage.t = {}
cs.damage.t.you = "you"

---@class cs.damage.DataType
cs.damage.dt = {}
cs.damage.dt.damage = "damage"
cs.damage.dt.heal = "heal"

---@class cs.damage.School
cs.damage.s = {}
cs.damage.s.Unknown = "Unknown"
cs.damage.s.Fire = "Fire"
cs.damage.s.Frost = "Frost"
cs.damage.s.Shadow = "Shadow"
-- TODO: add other

---@class cs.damage.SourceType
cs.damage.st = {}
cs.damage.st.Physical = "Physical"
cs.damage.st.Spell = "Spell"

---@class cs.damage.AbsorbType
cs.damage.at = {}
cs.damage.at.none = "none"
cs.damage.at.miss = "miss"
cs.damage.at.dodge = "dodge"
cs.damage.at.parry = "parry"
cs.damage.at.block = "block"
cs.damage.at.resist = "resist"


-- Copy grom ShaguDPS

-- sanitize, cache and convert patterns into gfind compatible ones
local sanitize_cache = {}
function sanitize(pattern)
  if not sanitize_cache[pattern] then
    local ret = pattern
    -- escape magic characters
    ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
    -- remove capture indexes
    ret = gsub(ret, "%d%$", "")
    -- catch all characters
    ret = gsub(ret, "(%%%a)", "%(%1+%)")
    -- convert all %s to .+
    ret = gsub(ret, "%%s%+", ".+")
    -- set priority to numbers over strings
    ret = gsub(ret, "%(.%+%)%(%%d%+%)", "%(.-%)%(%%d%+%)")
    -- cache it
    sanitize_cache[pattern] = ret
  end

  return sanitize_cache[pattern]
end

-- find, cache and return the indexes of a regex pattern
local capture_cache = {}
function captures(pat)
  local r = capture_cache
  if not r[pat] then
    -- set default to nil
    r[pat] = { nil, nil, nil, nil, nil }

    -- try to find custom capture indexes
    for a, b, c, d, e in string.gfind(gsub(pat, "%((.+)%)", "%1"), gsub(pat, "%d%$", "%%(.-)$")) do
      r[pat][1] = tonumber(a)
      r[pat][2] = tonumber(b)
      r[pat][3] = tonumber(c)
      r[pat][4] = tonumber(d)
      r[pat][5] = tonumber(e)
    end
  end

  return r[pat][1], r[pat][2], r[pat][3], r[pat][4], r[pat][5]
end

-- same as string.find but aware of up to 5 capture indexes
local ra, rb, rc, rd, re
function cfind(str, pat)
  -- read capture indexes
  local a, b, c, d, e = captures(pat)
  local match, num, va, vb, vc, vd, ve = string.find(str, sanitize(pat))

  -- put entries into the proper return values
  ra = e == 1 and ve or d == 1 and vd or c == 1 and vc or b == 1 and vb or va
  rb = e == 2 and ve or d == 2 and vd or c == 2 and vc or a == 2 and va or vb
  rc = e == 3 and ve or d == 3 and vd or a == 3 and va or b == 3 and vb or vc
  rd = e == 4 and ve or a == 4 and va or c == 4 and vc or b == 4 and vb or vd
  re = a == 5 and va or d == 5 and vd or c == 5 and vc or b == 5 and vb or ve

  return match, num, ra, rb, rc, rd, re
end

local combatlog_strings = {
  -- [[ DAMAGE ]] --

  --[[ me source me target ]]--
  { -- Your %s hits you for %d %s damage.
    SPELLLOGSCHOOLSELFSELF, function(d, attack, value, school)
    return d.source, attack, d.target, value, school, "damage", cs.damage.st.Spell
  end
  },
  { -- Your %s crits you for %d %s damage.
    SPELLLOGCRITSCHOOLSELFSELF, function(d, attack, value, school)
    return d.source, attack, d.target, value, school, "damage", cs.damage.st.Spell
  end
  },
  { -- Your %s hits you for %d.
    SPELLLOGSELFSELF, function(d, attack, value)
    return d.source, attack, d.target, value, d.school, "damage", cs.damage.st.Spell
  end
  },
  { -- Your %s crits you for %d.
    SPELLLOGCRITSELFSELF, function(d, attack, value)
    return d.source, attack, d.target, value, d.school, "damage", cs.damage.st.Spell
  end
  },


  { -- You suffer %d %s damage from your %s.
    PERIODICAURADAMAGESELFSELF, function(d, value, school, attack)
    return d.source, attack, d.target, value, school, "damage", cs.damage.st.Spell
  end
  },


  --[[ me source ]]--
  { -- Your %s hits %s for %d %s damage.
    SPELLLOGSCHOOLSELFOTHER, function(d, attack, target, value, school)
    return d.source, attack, target, value, school, "damage", cs.damage.st.Spell
  end
  },
  { -- Your %s crits %s for %d %s damage.
    SPELLLOGCRITSCHOOLSELFOTHER, function(d, attack, target, value, school)
    return d.source, attack, target, value, school, "damage", cs.damage.st.Spell
  end
  },
  { -- Your %s hits %s for %d.
    SPELLLOGSELFOTHER, function(d, attack, target, value)
    return d.source, attack, target, value, d.school, "damage", cs.damage.st.Spell
  end
  },
  { -- Your %s crits %s for %d.
    SPELLLOGCRITSELFOTHER, function(d, attack, target, value)
    return d.source, attack, target, value, d.school, "damage", cs.damage.st.Spell
  end
  },


  { -- %s suffers %d %s damage from your %s.
    PERIODICAURADAMAGESELFOTHER, function(d, target, value, school, attack)
    return d.source, attack, target, value, school, "damage", cs.damage.st.Spell
  end
  },


  { -- You hit %s for %d %s damage.
    COMBATHITSCHOOLSELFOTHER, function(d, target, value, school)
    return d.source, d.attack, target, value, school, "damage", cs.damage.st.Physical
  end
  },
  { -- You crit %s for %d %s damage.
    COMBATHITCRITSCHOOLSELFOTHER, function(d, target, value, school)
    return d.source, d.attack, target, value, school, "damage", cs.damage.st.Physical
  end
  },
  { -- You hit %s for %d.
    COMBATHITSELFOTHER, function(d, target, value)
    return d.source, d.attack, target, value, d.school, "damage", cs.damage.st.Physical
  end
  },
  { -- You crit %s for %d.
    COMBATHITCRITSELFOTHER, function(d, target, value)
    return d.source, d.attack, target, value, d.school, "damage", cs.damage.st.Physical
  end
  },


  { -- You reflect %d %s damage to %s.
    DAMAGESHIELDSELFOTHER, function(d, value, school, target)
    return d.source, "Reflect (" .. school .. ")", target, value, school, "damage", cs.damage.st.Spell
  end
  },


  --[[ me target ]]--
  { -- %s's %s hits you for %d %s damage.
    SPELLLOGSCHOOLOTHERSELF, function(d, source, attack, value, school)
    return source, attack, d.target, value, school, "damage", cs.damage.st.Spell
  end
  },
  { -- %s's %s crits you for %d %s damage.
    SPELLLOGCRITSCHOOLOTHERSELF, function(d, source, attack, value, school)
    return source, attack, d.target, value, school, "damage", cs.damage.st.Spell
  end
  },
  { -- %s's %s hits you for %d.
    SPELLLOGOTHERSELF, function(d, source, attack, value)
    return source, attack, d.target, value, d.school, "damage", cs.damage.st.Spell
  end
  },
  { -- %s's %s crits you for %d.
    SPELLLOGCRITOTHERSELF, function(d, source, attack, value)
    return source, attack, d.target, value, d.school, "damage", cs.damage.st.Spell
  end
  },


  { -- You suffer %d %s damage from %s's %s.
    PERIODICAURADAMAGEOTHERSELF, function(d, value, school, source, attack)
    return source, attack, d.target, value, school, "damage", cs.damage.st.Spell
  end
  },


  { -- %s hits you for %d %s damage.
    COMBATHITSCHOOLOTHERSELF, function(d, source, value, school)
    return source, d.attack, d.target, value, school, "damage", cs.damage.st.Physical
  end
  },
  { -- %s crits you for %d %s damage.
    COMBATHITCRITSCHOOLOTHERSELF, function(d, source, value, school)
    return source, d.attack, d.target, value, school, "damage", cs.damage.st.Physical
  end
  },

  { -- %s hits you for %d.
    COMBATHITOTHERSELF, function(d, source, value)
    return source, d.attack, d.target, value, d.school, "damage", cs.damage.st.Physical
  end
  },
  { -- %s crits you for %d.
    COMBATHITCRITOTHERSELF, function(d, source, value)
    return source, d.attack, d.target, value, d.school, "damage", cs.damage.st.Physical
  end
  },

  --[[ other ]]--
  { -- %s's %s hits %s for %d %s damage.
    SPELLLOGSCHOOLOTHEROTHER, function(d, source, attack, target, value, school)
    return source, attack, target, value, school, "damage", cs.damage.st.Spell
  end
  },
  { -- %s's %s crits %s for %d %s damage.
    SPELLLOGCRITSCHOOLOTHEROTHER, function(d, source, attack, target, value, school)
    return source, attack, target, value, school, "damage", cs.damage.st.Spell
  end
  },
  { -- %s's %s hits %s for %d.
    SPELLLOGOTHEROTHER, function(d, source, attack, target, value)
    return source, attack, target, value, d.school, "damage", cs.damage.st.Spell
  end
  },
  { -- %s's %s crits %s for %d.
    SPELLLOGCRITOTHEROTHER, function(d, source, attack, target, value, school)
    return source, attack, target, value, school, "damage", cs.damage.st.Spell
  end
  },


  { -- %s suffers %d %s damage from %s's %s.
    PERIODICAURADAMAGEOTHEROTHER, function(d, target, value, school, source, attack)
    return source, attack, target, value, school, "damage", cs.damage.st.Spell
  end
  },


  { -- %s hits %s for %d %s damage.
    COMBATHITSCHOOLOTHEROTHER, function(d, source, target, value, school)
    return source, d.attack, target, value, school, "damage", cs.damage.st.Physical
  end
  },
  { -- %s crits %s for %d %s damage.
    COMBATHITCRITSCHOOLOTHEROTHER, function(d, source, target, value, school)
    return source, d.attack, target, value, school, "damage", cs.damage.st.Physical
  end
  },
  { -- %s hits %s for %d.
    COMBATHITOTHEROTHER, function(d, source, target, value)
    return source, d.attack, target, value, d.school, "damage", cs.damage.st.Physical
  end
  },
  { -- %s crits %s for %d.
    COMBATHITCRITOTHEROTHER, function(d, source, target, value)
    return source, d.attack, target, value, d.school, "damage", cs.damage.st.Physical
  end
  },


  { -- %s reflects %d %s damage to %s.
    DAMAGESHIELDOTHEROTHER, function(d, source, value, school, target)
    return source, "Reflect (" .. school .. ")", target, value, school, "damage", cs.damage.st.Spell
  end
  },

  -- [[ HEAL ]] --
  --[[ me target ]]--
  { -- %s's %s critically heals you for %d.
    HEALEDCRITOTHERSELF, function(d, source, spell, value)
    return source, spell, d.target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
  { -- %s's %s heals you for %d.
    HEALEDOTHERSELF, function(d, source, spell, value)
    return source, spell, d.target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
  { -- You gain %d health from %s's %s.
    PERIODICAURAHEALOTHERSELF, function(d, value, source, spell)
    return source, spell, d.target, value, d.school, "heal", cs.damage.st.Spell
  end
  },

  --[[ me source me target ]]--
  { -- Your %s critically heals you for %d.
    HEALEDCRITSELFSELF, function(d, spell, value)
    return d.source, spell, d.target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
  { -- Your %s heals you for %d.
    HEALEDSELFSELF, function(d, spell, value)
    return d.source, spell, d.target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
  { -- You gain %d health from %s.
    PERIODICAURAHEALSELFSELF, function(d, value, spell)
    return d.source, spell, d.target, value, d.school, "heal", cs.damage.st.Spell
  end
  },

  --[[ me source ]]--
  { -- Your %s critically heals %s for %d.
    HEALEDCRITSELFOTHER, function(d, spell, target, value)
    return d.source, spell, target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
  { -- Your %s heals %s for %d.
    HEALEDSELFOTHER, function(d, spell, target, value)
    return d.source, spell, target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
  { -- %s gains %d health from your %s.
    PERIODICAURAHEALSELFOTHER, function(d, target, value, spell)
    return d.source, spell, target, value, d.school, "heal", cs.damage.st.Spell
  end
  },

  --[[ other ]]--
  { -- %s's %s critically heals %s for %d.
    HEALEDCRITOTHEROTHER, function(d, source, spell, target, value)
    return source, spell, target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
  { -- %s's %s heals %s for %d.
    HEALEDOTHEROTHER, function(d, source, spell, target, value)
    return source, spell, target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
  { -- %s gains %d health from %s's %s.
    PERIODICAURAHEALOTHEROTHER, function(d, target, value, source, spell)
    return source, spell, target, value, d.school, "heal", cs.damage.st.Spell
  end
  },
}

---@class cs.damage.Event
---@field public source
---@field public action
---@field public target
---@field public value
---@field public resisted
---@field public school
---@field public datatype
---@field public sourcetype
---@field public absorbtype
cs.damage.Event = cs.create_class()

function cs.damage.Event.build(...)
  local event = cs.damage.Event:new()

  event.source, event.action, event.target, event.value,
  event.school, event.datatype, event.sourcetype, event.resisted, event.absorbtype = unpack(arg)
  return event
end



---@class cs.damage.Parser
cs.damage.Parser = cs.class()

function cs.damage.Parser:build()

  local parser = cs.create_simple_frame()
  -- register to all damage combat log events
  parser:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
  parser:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS")
  parser:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_PARTY_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS")
  parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")

  -- misses
  parser:RegisterEvent(cs.chat.c_c_vs_s_m)
  parser:RegisterEvent(cs.chat.c_hp_m)

  -- register to all heal combat log events
  parser:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
  parser:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
  parser:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
  parser:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")

  parser.cs_damage_parser = self

  -- call all datasources on each event
  parser:SetScript("OnEvent", function()
    local cs_parser = this.cs_damage_parser
    cs_parser:handle_event(arg1, event)
  end)

  self.player_name = UnitName(cs.u.player)
  self.sub_list = {}
end

function cs.damage.Parser:handle_event(msg, msg_event)
  if not msg then
    return
  end
  local event = self:parse(msg, msg_event)

  if event then
    return self:_on_parsed(event)
  end
end

-- cache default table
local defaults = { }

---@return cs.damage.Event
function cs.damage.Parser:parse(msg, msg_event)
  defaults.source = UnitName("player")
  defaults.target = UnitName("player")
  defaults.school = cs.damage.s.Unknown
  defaults.attack = "Auto Hit"
  defaults.spell = cs.damage.a.unknown
  defaults.value = 0
  defaults.sourcetype = cs.damage.st.Physical
  defaults.resisted = 0
  defaults.absorbtype = cs.damage.at.none

  -- TODO: add parser for c_hp_m
  if msg_event == cs.chat.c_hp_m then
    cs_debug(msg)
  end

  if msg_event == cs.chat.c_c_vs_s_m or msg_event == cs.chat.c_hp_m then
    local absorbtype
    if string.find(msg, " attacks. You block.") then
      absorbtype = cs.damage.at.block
    elseif string.find(msg, " attacks. You parry.") then
      absorbtype = cs.damage.at.parry
    elseif string.find(msg, " attacks. You dodge.") then
      absorbtype = cs.damage.at.dodge
    elseif string.find(msg, " misses you.") then
      absorbtype = cs.damage.at.miss
    end

    if not absorbtype then
      return
    end

    return cs.damage.Event.build(
            cs.damage.a.unknown,
            defaults.attack,
            cs.damage.t.you,
            0,
            defaults.school,
            cs.damage.dt.damage,
            cs.damage.st.Physical,
            defaults.resisted,
            absorbtype
    )
  end

  -- detection on all damage sources
  for id, data in pairs(combatlog_strings) do
    local result, _, a1, a2, a3, a4, a5, a6 = cfind(msg, data[1])

    if result then
      local pack_event = { data[2](defaults, a1, a2, a3, a4, a5, a6) }
      table.insert(pack_event, defaults.resisted)
      table.insert(pack_event, defaults.absorbtype)

      local event = cs.damage.Event.build(unpack(pack_event))

      event.value = tonumber(event.value)

      local _, _, resisted_str = string.find(msg, "%((%d+) resisted%)")
      if resisted_str then
        event.resisted = tonumber(resisted_str)
        event.absorbtype = cs.damage.at.resist
      end

      local _, _, blocked_str = string.find(msg, "%((%d+) blocked%)")
      if blocked_str then
        event.resisted = tonumber(blocked_str)
        event.absorbtype = cs.damage.at.block
      end

      return event
    end
  end
end


function cs.damage.Parser:_check_value(param, value, event)
  if value == cs.damage.u.player then
    -- check "player"
    return event[param] == self.player_name or event[param] == cs.damage.t.you
  end

  if value == cs.damage.u.party then
    return cs.is_party_player_exists(event[param])
  end

  return event[param] == value
end

function cs.damage.Parser:_check_filter(param, value_list, event)
  value_list = type(value_list) == "table" and value_list or { value_list }
  for _, value in pairs(value_list) do
    if self:_check_value(param, value, event) then
      return true
    end
  end
end

function cs.damage.Parser:_check_filter_list(filters, event)

  for param, value_list in pairs(filters) do
    if not self:_check_filter(param, value_list, event) then
      return
    end
  end
  return true
end

---@param event cs.damage.Event
function cs.damage.Parser:_on_parsed(event)
  for _, sub in pairs(self.sub_list) do
    if self:_check_filter_list(sub.filters, event) then
      sub.func(sub.obj, event)
    end
  end
end

---@param func function(event)
function cs.damage.Parser:subscribe(filters, obj, func)
  table.insert(self.sub_list, { filters = filters, obj = obj, func = func })
end

---@type cs.damage.Parser
cs.damage.parser = nil



---@class cs.damage.StatCounter
cs.damage.StatCounter = cs.class()
--region cs.damage.StatCounter
function cs.damage.StatCounter:build(type)
  for name in pairs(type) do
    self[name] = 0
  end
  self.sum = 0
end

function cs.damage.StatCounter:add(name, value)
  self[name] = self[name] + value
  self.sum = self.sum + value
end

function cs.damage.StatCounter:get_rate(name)
  return self[name] / self.sum
end

function cs.damage.StatCounter:get_rate_str(name)
  local rate = self:get_rate(name) * 100
  if rate >= 100 then
    rate = 99
  end
  return string.format(".%02d", rate)
end

function cs.damage.StatCounter:get(name)
  return self[name]
end
--endregion cs.damage.StatCounter



---@class cs.damage.Stat
cs.damage.Stat = cs.class()
--region cs.damage.Stat
function cs.damage.Stat:build()
  self.absorb_counter = cs.damage.StatCounter:new(cs.damage.at)
  self.source_counter = cs.damage.StatCounter:new(cs.damage.st)
end
--endregion cs.damage.Stat



---@class cs.damage.Analyzer
cs.damage.Analyzer = cs.class()
--region cs.damage.Analyzer
function cs.damage.Analyzer:build()
  local filter = {}
  filter[cs.damage.p.target] = { cs.damage.u.player }
  filter[cs.damage.p.datatype] = cs.damage.dt.damage
  cs.damage.parser:subscribe(filter, self, self._on_damage)

  self.last_type_ts_list = {}

  ---@type cs.FixTable
  self.event_list = cs.FixTable:create(nil, 300) -- sec
  self.stat = self:_calculate_stat()
end

-- const
function cs.damage.Analyzer:get_last_ts(sourcetype)
  return self.last_type_ts_list[sourcetype] or 0
end

-- const
function cs.damage.Analyzer:get_stat()
  return self.stat
end

function cs.damage.Analyzer:reset_events()
  cs.print("RESET ANALYZER EVENTS")
  self.event_list:clear()
  self.stat = self:_calculate_stat()
end

---@param event cs.damage.Event
function cs.damage.Analyzer:_on_damage(event)
  self.last_type_ts_list[event.sourcetype] = GetTime()

  local last_ts = self.event_list:get_last_ts()
  self.event_list:add(event)

  if not cs.compare_time(0.2, last_ts) then
    -- to optimization
    self.stat = self:_calculate_stat()
  end
end

function cs.damage.Analyzer:_calculate_stat()
  local stat = cs.damage.Stat:create()
  self.event_list:iterate_list(function(event)
    stat.absorb_counter:add(event.absorbtype, 1)
    stat.source_counter:add(event.sourcetype, event.value)
  end)
  return stat
end
--endregion cs.damage.Analyzer


---@type cs.damage.Analyzer
cs.damage.analyzer = nil




cs.damage.init = function()
  cs.damage.parser = cs.damage.Parser:new()
  cs.damage.analyzer = cs.damage.Analyzer:new()
end

cs.damage.test = function()
  local dmg_24_fire = "Burning Ravager hits you for 24 Fire damage."

  -- smoke
  do
    local event = cs.damage.parser:parse(dmg_24_fire)
    assert(event.action == "Auto Hit")
    assert(event.source == "Burning Ravager")
    assert(event.value == 24)
    assert(event.school == cs.damage.s.Fire)
    assert(event.datatype == cs.damage.dt.damage)
    assert(event.target == UnitName(cs.u.player))
    assert(event.sourcetype == cs.damage.st.Physical)
    assert(event.resisted == 0)
  end

  -- miss
  do
    local event = cs.damage.parser:parse("Skeleton attacks. You block.", cs.chat.c_c_vs_s_m)
    assert(event.value == 0)
    assert(event.target == cs.damage.t.you)
    assert(event.sourcetype == cs.damage.st.Physical)
    assert(event.resisted == 0)
    assert(event.absorbtype == cs.damage.at.block)
  end

  do
    local event = cs.damage.parser:parse("Skeletona aa aa attacks. You parry.", cs.chat.c_c_vs_s_m)
    assert(event.absorbtype == cs.damage.at.parry)
  end

  do
    local event = cs.damage.parser:parse("Skeleton asd attacks. You dodge.", cs.chat.c_c_vs_s_m)
    assert(event.absorbtype == cs.damage.at.dodge)
  end

  do
    local event = cs.damage.parser:parse("Skeleton sda misses you.", cs.chat.c_c_vs_s_m)
    assert(event.absorbtype == cs.damage.at.miss)
  end

  do
    local event = cs.damage.parser:parse("Ofasdsd asd attacks. Ofasdsd asda parry.", cs.chat.c_c_vs_s_m)
    assert(not event)
  end

  -- blocked
  do
    local msg = "Burning Ravager hits you for 20 damage. 21 blocked (none blocked) (2 blocked)"
    local event = cs.damage.parser:parse(msg)
    assert(event.action == "Auto Hit")
    assert(event.source == "Burning Ravager")
    assert(event.value == 20)
    assert(event.school == cs.damage.s.Unknown)
    assert(event.datatype == cs.damage.dt.damage)
    assert(event.target == UnitName(cs.u.player))
    assert(event.sourcetype == cs.damage.st.Physical)
    assert(event.resisted == 2)
  end

  do
    local msg = "Burning Ravager's Frostbolt hits you for 14 Fire damage. 12 resisted (all resisted) (10 resisted)"
    local event = cs.damage.parser:parse(msg)
    assert(event.action == "Frostbolt", event.action)
    assert(event.source == "Burning Ravager")
    assert(event.value == 14, event.value)
    assert(event.school == cs.damage.s.Fire)
    assert(event.datatype == cs.damage.dt.damage)
    assert(event.target == UnitName(cs.u.player))
    assert(event.sourcetype == cs.damage.st.Spell)
    assert(event.resisted == 10)
  end

  -- analyzer
  do
    cs.damage.parser:handle_event(dmg_24_fire)

    local msg = "Burning Ravager hits you for 20 damage."
    cs.damage.parser:handle_event(msg)

    --local type = cs.damage.analyzer:get_sourcetype(cs.damage.st.Physical)
    --assert(type:get_sum() == 44)
  end
end

