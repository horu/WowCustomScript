
local cs = cs_common
local pal = cs.pal
local bn = pal.bn
local spn = pal.spn




---@class pal.Bless
pal.Bless = cs.create_class()

-- Bless can by anavailable, but buffed on the target.
function pal.Bless.try_build(bless_name, unit)
  if not cs.is_spell_available(bless_name) then
    return
  end

  local rebuff_timeout = 5 * 60 - 50
  if string.find(bless_name, "Greater") then
    rebuff_timeout = 15 * 60 - 50
  end

  local bless = pal.Bless:new()
  bless.buff = cs.Buff.build(bless_name, unit, rebuff_timeout)

  return bless
end

function pal.Bless:get_name()
  return self.buff:get_name()
end

function pal.Bless:rebuff()
  if cs.check_combat() and self.buff:check_exists() then
    return cs.Buff.exists
  end

  return self.buff:rebuff()
end


-- Created container all available for player bless
local avail_bless_dict = {}

pal.bless = {}
pal.bless.get_buff = function(spell_name)
  return avail_bless_dict[spell_name]
end

pal.bn.get_available = function()
  local list = cs.dict_keys_to_list(avail_bless_dict, "string")
  return list
end



pal.bless.init = function()
  -- self bless list
  -- TODO: rebuild when spell book changed
  for bless_name, spell_name in pairs(bn.dict_all) do
    local bless = pal.Bless.try_build(spell_name)
    -- pal.bless[bless_name] = bless
    if bless then
      -- cs.print(bless:get_name())
      avail_bless_dict[spell_name] = bless
    end
  end
end






















