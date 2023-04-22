

local cs = cs_common
local pal = cs.pal
local cast = pal.cast

pal.heal = {}


cast.DivineShield = "Divine Shield"
cast.DivineProtection = "Divine Protection"
cast.BlessingProtection = "Blessing of Protection"
cast.LayOnHands = "Lay on Hands"
cast.shield_list = {cast.DivineShield, cast.BlessingProtection}





local EmegryCaster = cs.create_class()

EmegryCaster.build = function()
  local caster = EmegryCaster:new()
  caster.shield_ts = 0
  caster.spell_order = cs.SpellOrder.build(unpack(cast.shield_list))
  caster.lay_spell = cs.Spell.build(cast.LayOnHands)
  return caster
end

function EmegryCaster:has_debuff_protection()
  return cs.has_debuffs(cs.u_player, "Spell_Holy_RemoveCurse")
end

function EmegryCaster:em_buff(lay)
  local casted_shield = self:has_debuff_protection()
  if not casted_shield then
    local spell = self.spell_order:cast(cs.u_player)
    if spell then
      self.shield_ts = spell.cast_ts
      return cs.Buff.success
    end
  end

  if cs.compare_time(8, self.shield_ts) or cs.find_buff(cast.shield_list) then
    return cs.Buff.exists
  end

  if cs.get_spell_cd(cast.LayOnHands) then
    return cs.Buff.exists
  end

  if not lay then
    return cs.Buff.exists
  end

  cs.print(cs.color_red.."CAST Lay on Hands")
  self.lay_spell:cast_to_unit(cs.u_player)
  return cs.Buff.success
end



pal.heal.check_hp = function()
  local hp_level = cs.get_hp_level()
  if hp_level > 0.2 then
    return true
  end

  if pal.st_em_caster:em_buff(hp_level <= 0.1) == cs.Buff.exists then
    return true
  end
end


pal.heal.init = function()
  pal.st_em_caster = EmegryCaster.build()
end



-- PUBLIC
function cs_emegrancy()
  pal.st_em_caster:em_buff(true)
end