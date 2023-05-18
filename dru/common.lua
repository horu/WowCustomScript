local cs = cs_common
cs.dru = {}
local dru = cs.dru

dru.sn = {}

dru.sn.Rejuvenation = "Rejuvenation"

-- SPell
dru.sp = {}

-- BuffSPell
dru.bsp = {}

dru.common = {}
dru.common.init = function()
  dru.sp.Wrath = cs.Spell:create("Wrath")
  dru.sp.Moonfire = cs.Spell:create("Moonfire", function(spell)
    return not cs.has_debuffs(cs.u.target, "Spell_Nature_StarFall")
  end)

  dru.sp.RJ = cs.Buff:create(dru.sn.Rejuvenation)
  dru.sp.MarkWild = cs.Buff:create("Mark of the Wild", 28 * 60)
  dru.sp.Thorns = cs.Buff:create("Thorns", 9 * 60)
end


-- PUBLIC

cs_dru_main_attack =function()
  cs.auto_attack()

  if not dru.sp.Moonfire:cast() then
    dru.sp.Wrath:cast()
  end

  if not cs.check_combat(cs.c.affect) then
    dru.sp.MarkWild:rebuff()
    dru.sp.Thorns:rebuff()
  end

end

cs_dru_rj = function()
  if cs.check_target(cs.t.friend) then
    local buff = cs.Buff:create(dru.sn.Rejuvenation)
    buff:rebuff(cs.u.target)
    return
  end

  dru.sp.RJ:rebuff()
end