
local cs = cs_common
local pal = cs.pal
local cast = pal.cast
local seal = pal.seal

-- ID
local state_RUSH = "RUSH"
local state_NORM = "NORM"
local state_DEF = "DEF"
local state_BASE = "BASE"
local state_HEAL = "HEAL"



-- ATTACKS

local judgement_any = function(...)
  for _, seal_spell in ipairs(arg) do
    if seal_spell:judgement_it() then
      return true
    end
  end
end

local build_cast_list = function(...)
  local cast_list = arg

  local target = UnitCreatureType("target")
  if target == "Demon" or target == "Undead" then
    table.insert(cast_list, 1, cast.Exorcism)
  end
  return unpack(cast_list)
end

---@param seal_list pal.Seal[]
local seal_action = function(state, seal_list)
  if not cs.check_target(cs.t_close_10) then
    -- the target is far away
    return
  end

  if not seal_list[1]:is_reseal_available() then
    -- seal can not be casted with current situation, just cast other spells
    cs.cast(cast.HolyStrike, cast.CrusaderStrike)
    return
  end

  if judgement_any(seal.Righteousness, seal_list[2], seal_list[3]) then
    -- wait another seal to judgement on the target
    return
  end

  for _, seal_spell in pairs(seal_list) do
    if not seal_spell:is_judgement_available() then
      -- it means the target already has other seal debuff. Reseal and cast other spells only
      if state.id == state_RUSH then
        cs.cast(cast.CrusaderStrike)
        return
      end

      seal_list[1]:reseal_and_cast(cast.HolyStrike, cast.CrusaderStrike)
      return
    end
  end

  -- the target has no other seal debuff. Lets reseal and judgement it.
  seal_list[1]:reseal_and_cast(cast.Judgement)
end


pal.actions = {}
pal.actions.right = function(state)
  if not cs.check_target(cs.t_close_30) then return end

  cs.cast(cast.HolyStrike)

  if state.id ~= state_RUSH then
    if judgement_any(seal.Light, seal.Wisdom, seal.Justice) then
      return
    end
  end

  seal.Righteousness:reseal_and_cast(build_cast_list(cast.Judgement, cast.CrusaderStrike ))
end

pal.actions.crusader = function(state)
  if not cs.check_target(cs.t_close_10) then return end

  if judgement_any(seal.Light, seal.Wisdom, seal.Justice, seal.Righteousness) then
    return
  end

  seal.Crusader:reseal_and_cast(cast.HolyStrike, cast.CrusaderStrike)
end

pal.actions.wisdom = function(state)
  seal_action(state, {seal.Wisdom, seal.Light, seal.Justice})
end

pal.actions.light = function(state)
  seal_action(state, {seal.Light, seal.Wisdom, seal.Justice})
end

pal.actions.justice = function(state)
  seal_action(state, {seal.Justice, seal.Light, seal.Wisdom})
end




