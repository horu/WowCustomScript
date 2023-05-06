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



cs.slot = {}

-- SlotId
cs.slot.id = {}
cs.slot.id.off_hand = 17
cs.slot.id.is_equipped = function(id)
  return GetInventoryItemTexture(cs.u.player, id) ~= nil
end

cs.slot.two_hand = cs.Slot.build(13)
cs.slot.one_hand_shield = cs.MultiSlot.build({ 14, 15 })
cs.slot.prof = cs.Slot.build(16)
cs.slot.tinker = cs.Slot.build(17)
cs.slot.list = cs.dict_to_list(cs.slot, "table")

cs.slot.get_equipped = function(available_list)
  available_list = available_list or cs.slot.list
  for _, slot in cs.slot.list do
    if slot:is_equipped() then
      return slot
    end
  end
end


