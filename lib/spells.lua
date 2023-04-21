
cs_common = cs_common or {}
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
  for _, name in ipairs(arg) do
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







cs.cast = function(...)
  local order = cs.SpellOrder.build(unpack(arg))
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






-- BUFFS
function cs.find_buff(check_list, unit)
  for i, check in pairs(cs.to_table(check_list)) do
    if FindBuff(check, unit) then
      return check, i
    end
  end
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

cs.has_buffs = function(unit, buff_str, b_fun)
  if not buff_str then buff_str = "" end

  local buff_list = cs.get_buff_list(unit, b_fun)
  for _, buff in pairs(buff_list) do
    if string.find(buff, buff_str) then
      return true
    end
  end
end

cs.get_debuff_list = function(unit)
  return cs.get_buff_list(unit, UnitDebuff)
end

cs.has_debuffs = function(unit, debuff_str)
  return cs.has_buffs(unit, debuff_str, UnitDebuff)
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
function cs.Buff:get_name()
  return self.name
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











-- detect cast spells from target
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
cs.st_cast_checker = cs.CastChecker.build()







-- PUBLIC
function cs_cast_helpful(heal_cast)
  cs.cast_helpful(heal_cast)
end
