local cs = cs_common



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


cs.item = {}
cs.item.hearth_stone = "Hearthstone"


cs.slot = {}

-- SlotId

cs.slot.two_hand = { 13 }
cs.slot.one_hand_shield = { 14, 15 }
cs.slot.prof = 16
cs.slot.tinker = 17

-- from SM
cs.slot.use_by_name = UseItemByName
cs.slot.link_to_name = ItemLinkToName

cs.slot.id = {}

cs.slot.id.head = 1
cs.slot.id.neck = 2
cs.slot.id.shoulder = 3
cs.slot.id.shirt = 4
cs.slot.id.chest = 5
cs.slot.id.waist = 6
cs.slot.id.legs = 7
cs.slot.id.feet = 8
cs.slot.id.wrist = 9
cs.slot.id.hands = 10
cs.slot.id.finger1 = 11
cs.slot.id.finger2 = 12
cs.slot.id.trinket1 = 13
cs.slot.id.trinket2 = 14
cs.slot.id.back = 14
cs.slot.id.main_hand = 16
cs.slot.id.off_hand = 17

cs.slot.id.get_item_name = function(slot_id)
  return cs.slot.link_to_name(GetInventoryItemLink(cs.u.player, slot_id)) or ""
end

cs.slot.id.is_equipped = function(slot_id)
  return cs.slot.id.get_item_name(slot_id) ~= ""
end

cs.slot.try_equip_slot = function(id, item_name)
  if cs.slot.id.get_item_name(id) == item_name then
    return
  end

  cs.slot.use_by_name(item_name)
end


---@class cs.slot.Set
cs.slot.Set = cs.class()

function cs.slot.Set:build(list)
  -- map slot_id: item_name
  self.list = {}
  for id, name in pairs(list) do
    if cs.type.check(name, cs.type.number) then
      -- Save current set by default
      self.list[name] = cs.slot.id.get_item_name(name)
    else
      self.list[id] = name
    end
  end
end

function cs.slot.Set:reset()
  for id in pairs(self.list) do
    self.list[id] = cs.slot.id.get_item_name(id)
  end
end

function cs.slot.Set:is_equipped()
  for id, name in pairs(self.list) do
    if cs.slot.id.get_item_name(id) ~= name then
      return
    end
  end
  return true
end

function cs.slot.Set:equip()
  local main_hand = self.list[cs.slot.id.main_hand]
  if main_hand then
    -- main hand first
    cs.slot.try_equip_slot(cs.slot.id.main_hand, main_hand)
  end

  for id, name in pairs(self.list) do
    cs.slot.try_equip_slot(id, name)
  end
end

function cs.slot.Set:to_config()
  return self.list
end


cs.slot.Set.arm = "arm"
cs.slot.Set.weap = "weap"
cs.slot.Set.id = {}
cs.slot.Set.id.weap_1 = 5
cs.slot.Set.id.weap_2 = 6
cs.slot.Set.id.weap_3 = 7
cs.slot.Set.id.mining = 8

local bar = 12 * 4
local arm_set_list = {
  cs.slot.id.head,
  cs.slot.id.neck,
  cs.slot.id.shoulder,
  --cs.slot.id.shirt,
  cs.slot.id.chest,
  cs.slot.id.waist,
  cs.slot.id.legs,
  cs.slot.id.feet,
  cs.slot.id.wrist,
  cs.slot.id.hands,
  --cs.slot.id.finger1,
  --cs.slot.id.finger2,
  --cs.slot.id.trinket1,
  --cs.slot.id.trinket2,
  cs.slot.id.back,
}

local weap_set_list = {
  cs.slot.id.main_hand,
  cs.slot.id.off_hand,
}

-- TODO: fix it
local default_item_sets = {
  cs.slot.Set:new(arm_set_list):to_config(),
  cs.slot.Set:new(arm_set_list):to_config(),
  cs.slot.Set:new({}):to_config(),
  cs.slot.Set:new({}):to_config(),
  cs.slot.Set:new(weap_set_list):to_config(),
  cs.slot.Set:new(weap_set_list):to_config(),
  cs.slot.Set:new(weap_set_list):to_config(),
  cs.slot.Set:new(weap_set_list):to_config(),
}

cs_item_sets = cs.deepcopy(default_item_sets)

---@class cs.slot.SetHolder
cs.slot.SetHolder = cs.class()

function cs.slot.SetHolder:build()
  ---@type cs.slot.Set[]
  self.set_list = {}

  self.current_set = 0

  for id, list in pairs(cs_item_sets) do
    self.set_list[id] = cs.slot.Set:new(list)

    local longkey = bar + id
    cs.ui.down_checker:add_sub(longkey, self, self._on_manual_changed)
  end
end

function cs.slot.SetHolder:_on_manual_changed(longkey, duration)
  local id = longkey - bar

  if duration == cs.ui.down_checker.t.change then
    self:equip_set(id)
  elseif duration == cs.ui.down_checker.t.save then
    self:_reset_set(id)
  end
end

function cs.slot.SetHolder:equip_set(id)
  if self.current_set == id then
    return
  end
  cs_print("SET: "..id)
  self.current_set = id
  ---@type cs.slot.Set
  local set = self.set_list[id]
  set:equip()
end

function cs.slot.SetHolder:_reset_set(id)
  local set = cs.slot.Set:new(default_item_sets[id])

  set:reset()
  cs.debug(set:to_config())
  self.set_list[id] = set
  cs_item_sets[id] = set.list
end


cs.slot.init = function()
  cs.slot.set_holder = cs.slot.SetHolder:new()
end

cs.slot.test = function()
end
