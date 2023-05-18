local cs = cs_common
cs.dru = {}
local dru = cs.dru

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

dru.common = {}
dru.common.init = function()
  -- Human
  dru.sp.HT = cs.Spell:create(dru.sn.HealingTouch)
  dru.sp.Wrath = cs.Spell:create("Wrath")
  dru.sp.EntanglingRoots = cs.Spell:create("Entangling Roots")
  dru.sp.Moonfire = cs.Spell:create("Moonfire", function(spell)
    return not cs.has_debuffs(cs.u.target, "Spell_Nature_StarFall")
  end)

  dru.sp.RJ = cs.Buff:create(dru.sn.Rejuvenation)
  dru.sp.MarkWild = dru.buff.create_mark()
  dru.sp.Thorns = cs.Buff:create("Thorns", 9 * 60)

  -- Bear
  dru.sp.Maul = cs.Spell:create("Maul")
  dru.sp.Growl = cs.Spell:create("Growl")
end


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

dru.form.handler = dru.form.Handler:create()

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



-- PUBLIC

cs_dru_close_attack = function()
  cs.auto_attack()

  dru.form.handler:set(dru.form.bear)

  dru.sp.Maul:cast()
end

cs_dru_taunt = function()
  cs.auto_attack()

  dru.form.handler:set(dru.form.bear)

  dru.sp.Growl:cast()
end

cs_dru_range_attack =function()
  cs.auto_attack()

  dru.form.handler:set(dru.form.humanoid)

  if not dru.sp.Moonfire:cast() then
    dru.sp.Wrath:cast()
  end

  dru.rebuff()

  cs.party.rebuff()
end

cs_dru_root = function()
  dru.form.handler:set(dru.form.humanoid)

  dru.sp.EntanglingRoots:cast()
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

cs_dru_HT = function()
  dru.form.handler:set(dru.form.humanoid)

  dru.sp.HT:cast_helpful()
end