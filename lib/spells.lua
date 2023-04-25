
local cs = cs_common





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

---@param limiting_debuff cs.spell.UnitBuff
cs.Spell.build = function(name, limiting_debuff)
  local spell = cs.Spell:new()

  spell.id, spell.book = find_spell(name)
  spell.name = name
  --spell.id = id_name
  --spell.book = book
  --spell.name = GetSpellName(id_name, book)
  assert(spell.id)
  spell.cast_ts = 0
  spell.limiting_debuff = limiting_debuff

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

function cs.Spell:_has_debuff()
  if not self.limiting_debuff then
    return
  end

  local debuff = self.limiting_debuff
  if cs.has_debuffs(cs.u.target, debuff.icon, debuff.count) then
    if debuff.duration then
      local duration_limit = debuff.duration * 0.7
      return cs.compare_time(duration_limit, self.cast_ts)
    end
    return true
  end
end

function cs.Spell:cast(to_self)
  if not self:get_cd() and not self:_has_debuff() then
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









---@class cs.SpellOrder
cs.SpellOrder = cs.create_class()

cs.SpellOrder.build = function(...)
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
cs.cast_helpful = function(name)
  local unit = cs.u.player
  if cs.check_target(cs.t.friend) then
    unit = cs.u.target
  elseif cs.check_mouse(cs.t.exists) and cs.check_mouse(cs.t.friend) then
    unit = cs.u.mouseover
  end

  local spell = cs.Spell.build(name)
  return spell:cast_to_unit(unit)
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
cs.ss.Shadow = "Shadow"
cs.ss.Frost = "Frost"
cs.ss.Fire = "Fire"

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
cs.spell.UnitCastDetector = cs.create_class()

cs.spell.UnitCastDetector.build = function(unit)
  local cast_detector = cs.spell.UnitCastDetector:new()

  cast_detector.unit = unit
  cast_detector.sub_list = {}
  cast_detector.last_unit_cast = nil
  cs.loop_event(0.2, cast_detector, cast_detector._check_loop)

  return cast_detector
end

-- func = function(obj, cs.spell.UnitCast)
function cs.spell.UnitCastDetector:subscribe(obj, func)
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
cs.st_target_cast_detector = cs.spell.UnitCastDetector.build(cs.u.target)
---@type cs.spell.UnitCastDetector
cs.st_player_cast_detector = cs.spell.UnitCastDetector.build(cs.u.player)





cs.spell.test = function()
  cs.has_buffs()
  cs.has_buffs(cs.u.target, "Holly", 3)
  cs.has_debuffs()
  cs.has_debuffs(cs.u.target, "Holly", 2)

  local spell = cs.Spell.build("Attack", cs.spell.UnitBuff.build("asdasd", 3))
  spell:cast()
end



-- PUBLIC
function cs_cast_helpful(heal_cast)
  cs.cast_helpful(heal_cast)
end
