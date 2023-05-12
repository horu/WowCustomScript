
local cs = cs_common
local pal = cs.pal
local bn = pal.bn
local spn = pal.spn




---@class pal.Bless
pal.Bless = cs.create_class()

-- Bless can by anavailable, but buffed on the target.
function pal.Bless.try_build(bless_name)
  if not cs.is_spell_available(bless_name) then
    return
  end

  local rebuff_timeout = 5 * 60 - 50
  if string.find(bless_name, "Greater") then
    rebuff_timeout = 15 * 60 - 50
  end

  local bless = pal.Bless:new()
  bless.buff = cs.Buff.build(bless_name, rebuff_timeout)

  return bless
end

-- const
function pal.Bless:get_texture()
  return self.buff:get_texture()
end

function pal.Bless:get_name()
  return self.buff:get_name()
end

function pal.Bless:rebuff(unit)
  if cs.check_combat() and self.buff:check_exists(unit) then
    return cs.Buff.exists
  end

  return self.buff:rebuff(unit)
end


-- Created container all available for player bless
local avail_bless_dict = {}
local update_bless_list = function()
  avail_bless_dict = {}
  for bless_name, spell_name in pairs(bn.dict_all) do
    local bless = pal.Bless.try_build(spell_name)
    -- pal.bless[bless_name] = bless
    if bless then
      -- cs.print(bless:get_name())
      avail_bless_dict[spell_name] = bless
    end
  end
end
local bless_updater = cs.create_simple_frame()

pal.bless = {}
pal.bless.get_buff = function(spell_name)
  return avail_bless_dict[spell_name]
end

pal.bn.get_available = function()
  local list = cs.dict_keys_to_list(avail_bless_dict, "string")
  return list
end


pal.bless.init = function()
  bless_updater:RegisterEvent("SPELLS_CHANGED")
  bless_updater:SetScript("OnEvent", function()
    if cs.check_combat(cs.c.affect) then
      return
    end
    update_bless_list()
  end)
  update_bless_list()
end






















