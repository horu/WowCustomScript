
local cs = cs_common



-- return spell_id, book
local find_spell = function(name)
  local id = 0
  local it_name = ""
  while it_name ~= name do
    id = id+1
    it_name = GetSpellName(id, "spell")
    if not it_name then
      return
    end
  end
  return id, "spell"
end



-- spells
---@class cs.Spell
cs.Spell = cs.create_class()

---@return cs.Spell
cs.Spell.build = function(name, custom_ready_check)
  ---@type cs.Spell
  local spell = cs.Spell:new()

  spell.id, spell.book = find_spell(name)
  spell.name = name
  --spell.id = id_name
  --spell.book = book
  --spell.name = GetSpellName(id_name, book)
  assert(spell.id, string.format("spell not found: '%s'", (name or "nil")))
  spell.cast_ts = 0
  spell.custom_ready_check = custom_ready_check

  return spell
end

-- const
function cs.Spell:get_cd()
  -- Global CD is returned as well
  local ts_start, duration = GetSpellCooldown(self.id, self.book)
  if ts_start == 0 then
    -- no cd
    return nil
  end

  local ts = GetTime()
  return duration - ts + ts_start, ts_start, duration
end

function cs.Spell:cast(to_self)
  if self:is_ready() then
    CastSpellByName(self.name, to_self)
    self.cast_ts = GetTime()
    return true
  end
end

function cs.Spell:cast_to_unit(unit)
  if self:cast(unit == cs.u.player) then
    if (SpellIsTargeting()) then
      SpellTargetUnit(unit)
    end
    return true
  end
end

function cs.Spell:cast_helpful()
  local unit = cs.u.player
  if cs.check_target(cs.t.friend) then
    unit = cs.u.target
  --elseif cs.check_mouse(cs.t.exists) and cs.check_mouse(cs.t.friend) then
  --  unit = cs.u.mouseover
  end

  return self:cast_to_unit(unit)
end

function cs.Spell:is_ready()
  return not self:get_cd() and (not self.custom_ready_check or self.custom_ready_check(self))
end



---@class cs.SpellOrder
cs.SpellOrder = cs.create_class()

---@return cs.SpellOrder
cs.SpellOrder.build = function(...)
  ---@type cs.SpellOrder
  local order = cs.SpellOrder:new()

  order.spell_list = {}
  for _, name in ipairs(arg) do
    local spell
    if type(name) == "string" then
      spell = cs.Spell.build(name)
    else
      spell = name
    end
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







cs.cast = function(...)
  local order = cs.SpellOrder.build(unpack(arg))
  return order:cast()
end

cs.get_spell_cd = function(spell_name)
  return cs.Spell.build(spell_name):get_cd()
end

-- default to player
-- For heals/recovery
cs.cast_helpful = function(name)
  local spell = cs.Spell.build(name)
  return spell:cast_helpful()
end

cs.is_spell_available = function(name)
  return find_spell(name)
end







-- BUFFS
-- find by spell name
function cs.find_buff(check_list, unit)
  check_list = cs.is_table(check_list) and check_list or {check_list}
  for i, check in pairs(check_list) do
    if FindBuff(check, unit) then
      return check, i
    end
  end
end


cs.spell = {}

-- find buff/debuff by icon name
---@class cs.spell.UnitBuff @buff on the unit
---@field public icon string
---@field public count number
---@field public type string
---@field public duration number
cs.spell.UnitBuff = cs.create_class()

cs.spell.UnitBuff.build = function(...)
  local unit_buff = cs.spell.UnitBuff:new()
  unit_buff.icon = arg[1]
  unit_buff.count = arg[2]
  unit_buff.type = arg[3] -- Magic
  unit_buff.duration = arg[4] -- CUSTOM FIELD. UnitBuff does not return it.

  if not unit_buff.icon then
    return
  end

  return unit_buff
end

---@return cs.spell.UnitBuff[]
cs.get_buff_list = function(unit, b_fun)
  if not unit then unit = cs.u.player end
  if not b_fun then b_fun = UnitBuff end

  local buff_list = {}
  for i=1, 100 do
    local buff = cs.spell.UnitBuff.build(b_fun(unit, i))
    if not buff then break end

    table.insert(buff_list, buff)
  end
  return buff_list
end

cs.has_buffs = function(unit, buff_icon_str, min_count, b_fun)
  if not buff_icon_str then buff_icon_str = "" end

  local buff_list = cs.get_buff_list(unit, b_fun)
  for _, buff in pairs(buff_list) do
    if string.find(buff.icon, buff_icon_str) and (not min_count or buff.count >= min_count) then
      return buff
    end
  end
end

cs.get_debuff_list = function(...)
  table.insert(arg, 2, UnitDebuff)
  return cs.get_buff_list(unpack(arg))
end

cs.has_debuffs = function(...)
  table.insert(arg, 4, UnitDebuff)
  return cs.has_buffs(unpack(arg))
end





---@class cs.Buff
cs.Buff = cs.create_class()

cs.Buff.exists = nil
cs.Buff.success = 1
cs.Buff.failed = 2

--region
cs.Buff.build = function(name, unit, rebuff_timeout)
  local buff = cs.Buff:new()

  buff.name = name
  buff.unit = unit or cs.u.player
  buff.spell = cs.Spell.build(name)
  buff.cast_ts = 0
  buff.rebuff_timeout = rebuff_timeout

  return buff
end

-- const
function cs.Buff:get_name()
  return self.name
end

-- const
function cs.Buff:check_target_range()
  local unit = self.unit
  if unit == cs.u.player then
    return true
  end
  return UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDead(unit) and
          CheckInteractDistance(unit, 4) and UnitIsVisible(unit)
end

-- const
function cs.Buff:check_exists()
  return cs.find_buff(self.name, self.unit)
end

-- const
function cs.Buff:is_expired()
  if not self.rebuff_timeout then
    return
  end

  return not cs.compare_time(self.rebuff_timeout, self.cast_ts)
end

function cs.Buff:rebuff()
  if not self:check_target_range() then
    return cs.Buff.failed
  end

  if self:check_exists() and not self:is_expired() then
    return cs.Buff.exists
  end

  if self.spell:cast_to_unit(self.unit) then
    self.cast_ts = GetTime()
    return cs.Buff.success
  end

  return cs.Buff.failed
end

--endregion






-- SpellSchool data of some caster in ritgh now
cs.ss = {}
cs.ss.Fire = cs.damage.s.Fire
cs.ss.Frost = cs.damage.s.Frost
cs.ss.Shadow = cs.damage.s.Shadow

cs.ss.to_print = function(school)
  if school == cs.ss.Shadow then
    school = cs.color.purple..school.."|r"
  elseif school == cs.ss.Frost then
    school = cs.color.blue..school.."|r"
  elseif school == cs.ss.Fire then
    school = cs.color.orange..school.."|r"
  end
  return school
end



---@class cs.spell.UnitCast
cs.spell.UnitCast = cs.create_class()

cs.spell.UnitCast.build = function(pfui_spell)
  if not pfui_spell.icon then
    return
  end

  local data = cs.spell.UnitCast:new()
  data.pfui_spell = pfui_spell
  data.ts_sec = math.floor(GetTime())
  return data
end

function cs.spell.UnitCast:find_icon_name(name)
  return string.find(self.pfui_spell.icon, name)
end

function cs.spell.UnitCast:get_school()
  local spell_icon = self.pfui_spell.icon

  if string.find(spell_icon, cs.ss.Shadow) then
    return cs.ss.Shadow
  elseif string.find(spell_icon, cs.ss.Frost) then
    return cs.ss.Frost
  elseif string.find(spell_icon, cs.ss.Fire) then
    return cs.ss.Fire
  end
end

function cs.spell.UnitCast:eq(other)
  if not other then
    return
  end
  return self.pfui_spell.cast == other.pfui_spell.cast and self.ts_sec == other.ts_sec
end

---@return cs.spell.UnitCast
cs.get_cast_info = function(unit)
  local cast_db = pfUI.api.libcast.db

  for name, pfui_spell in pairs(cast_db) do
    if UnitName(unit) == name then
      local unit_cast = cs.spell.UnitCast.build(pfui_spell)
      if unit_cast then
        return unit_cast
      end
    end
  end
end



-- detect cast spells from target
---@class cs.spell.UnitCastDetector
cs.spell.UnitCastDetector = cs.class()

function cs.spell.UnitCastDetector:build(unit)
  self.unit = unit
  self.sub_list = {}
  self.last_unit_cast = nil
end

-- func = function(obj, cs.spell.UnitCast)
function cs.spell.UnitCastDetector:subscribe(obj, func)
  -- TODO: test it
  cs.event.try_loop(0.2, self, self._check_loop)
  self.sub_list[obj] = func
end

function cs.spell.UnitCastDetector:_check_loop()
  local unit_cast = cs.get_cast_info(self.unit)
  if not unit_cast then
    return
  end

  if unit_cast:eq(self.last_unit_cast) then
    return
  end

  self.last_unit_cast = unit_cast
  for obj, func in pairs(self.sub_list)
    do func(obj, unit_cast)
  end
end

---@type cs.spell.UnitCastDetector
cs.st_target_cast_detector = cs.spell.UnitCastDetector:new(cs.u.target)
---@type cs.spell.UnitCastDetector
cs.st_player_cast_detector = cs.spell.UnitCastDetector:new(cs.u.player)





cs.spell.test = function()
  cs.has_buffs()
  cs.has_buffs(cs.u.target, "Holly", 3)
  cs.has_debuffs()
  cs.has_debuffs(cs.u.target, "Holly", 2)

  local spell = cs.Spell.build("Attack", function() return 1  end)
  spell:cast()
end



-- PUBLIC
function cs_cast_helpful(heal_cast)
  cs.cast_helpful(heal_cast)
end
