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
cs.slot.id.main_hand = 16
cs.slot.id.off_hand = 17

cs.slot.id.get_item_name = function(slot_id)
  return cs.slot.link_to_name(GetInventoryItemLink(cs.u.player, slot_id))
end

cs.slot.id.is_equipped = function(slot_id)
  return cs.slot.id.get_item_name(slot_id) ~= nil
end



---@class cs.slot.Set
cs.slot.Set = cs.class()

function cs.slot.Set:build(list)
  -- map slot_id: item_name
  self.list = {}
  for id, name in pairs(list) do
    if name == "" then
      -- Save current set by default
      self.list[id] = cs.slot.id.get_item_name(id)
    else
      self.list[id] = name
    end
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

function cs.slot.Set:use()
  for id, name in pairs(self.list) do
    if cs.slot.id.get_item_name(id) ~= name then
      cs.slot.use_by_name(name)
    end
  end
end


cs.slot.test = function()
  cs.debug(cs.slot.id.get_item_name(17))
end


