local cs = cs_common
cs.dru = {}
local dru = cs.dru

dru.common = {}

dru.sn = {}

dru.sn.Rejuvenation = "Rejuvenation"
dru.sn.HealingTouch = "Healing Touch"

dru.buff = {}
dru.buff.create_mark = function()
  return cs.Buff:create("Mark of the Wild", 28 * 60)
end

-- SPell
dru.sp = {}

-- BuffSPell
dru.bsp = {}


dru.form = {}
dru.form.bear = "Bear Form"
dru.form.humanoid = "humanoid"
dru.form.Handler = cs.class()
function dru.form.Handler:build()
  self.forms = {}
  self.forms[dru.form.bear] = cs.Buff:create(dru.form.bear)
end

function dru.form.Handler:set(form)
  if form == dru.form.humanoid then
    for _, it in pairs(self.forms) do
      it:cancel()
    end
    return
  end

  self.forms[form]:rebuff()
end

dru.rebuff = function()
  if cs.check_combat(cs.c.affect) then
    return
  end

  dru.sp.MarkWild:rebuff()
  dru.sp.Thorns:rebuff()
end



function cs.party.Player:rebuff()
  if not self.data.dru_mark then
    self.data.dru_mark = dru.buff.create_mark()
  end

  if self.data.dru_mark:rebuff(self.unit) then
    dru.form.handler:set(dru.form.humanoid)
  end
end



dru.common.init = function()
  -- Human
  dru.sp.HT = cs.Spell:create(dru.sn.HealingTouch)
  dru.sp.Regrowth = cs.Spell:create("Regrowth")

  dru.sp.Wrath = cs.Spell:create("Wrath")
  dru.sp.Hibernate = cs.Spell:create("Hibernate")
  dru.sp.EntanglingRoots = cs.Spell:create("Entangling Roots")
  dru.sp.Moonfire = cs.Spell:create("Moonfire", function(spell)
    return not cs.has_debuffs(cs.u.target, "Spell_Nature_StarFall")
  end)
  dru.sp.FaerieFire = cs.Spell:create("Faerie Fire", function(spell)
    return not cs.has_debuffs(cs.u.target, "Spell_Nature_FaerieFire")
  end)

  dru.sp.RJ = cs.Buff:create(dru.sn.Rejuvenation)
  dru.sp.MarkWild = dru.buff.create_mark()
  dru.sp.Thorns = cs.Buff:create("Thorns", 9 * 60)

  -- Bear
  dru.sp.Maul = cs.Spell:create("Maul")
  dru.sp.Growl = cs.Spell:create("Growl")
  dru.sp.Enrage = cs.Spell:create("Enrage", function()
    return not cs.compare_unit_hp_rate(0.6) and not cs.check_target_hp(0.3 * cs.get_party_hp_sum())
  end)
  dru.sp.DemoralizingRoar = cs.Spell:create("Demoralizing Roar", function()
    return not cs.has_debuffs(cs.u.target, "Ability_Druid_DemoralizingRoar")
  end)
  dru.sp.Swipe = cs.Spell:create("Swipe")
  dru.sp.Bash = cs.Spell:create("Bash")

  dru.form.handler = dru.form.Handler:create()
end



-- PUBLIC

cs_dru_close_attack = function()
  cs.auto_attack()

  dru.form.handler:set(dru.form.bear)

  if not cs.check_target(cs.t.attackable) then
    return
  end

  if dru.sp.Enrage:cast() then return end

  dru.sp.Maul:cast()
end

cs_dru_bear_splash = function()
  cs.auto_attack()

  dru.form.handler:set(dru.form.bear)

  if dru.sp.DemoralizingRoar:cast() then return end
  dru.sp.Swipe:cast()
end

cs_dru_cast = function(form_str, name_str)
  local form = dru.form[form_str]
  if form == dru.form.bear then
    cs.auto_attack()
  end

  dru.form.handler:set(form)

  dru.sp[name_str]:cast()
end

cs_dru_range_attack =function()
  cs.auto_attack()

  dru.form.handler:set(dru.form.humanoid)

  if dru.sp.FaerieFire:cast() then return end
  if dru.sp.Moonfire:cast() then return end
  if dru.sp.Wrath:cast() then return end

  dru.rebuff()

  cs.party.rebuff()
end

cs_dru_RJ = function()
  dru.form.handler:set(dru.form.humanoid)

  if cs.check_target(cs.t.friend) then
    local buff = cs.Buff:create(dru.sn.Rejuvenation)
    buff:rebuff(cs.u.target)
    return
  end

  dru.sp.RJ:rebuff()
end

cs_dru_helpful = function(name)
  dru.form.handler:set(dru.form.humanoid)
  dru.sp[name]:cast_helpful()
end