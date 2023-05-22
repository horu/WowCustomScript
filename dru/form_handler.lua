local cs = cs_common
local dru = cs.dru


dru.ff = {}

dru.ff.bear = "bear"
dru.ff.cat = "cat"
dru.ff.travel = "travel"
dru.ff.aquatic = "aquatic"
dru.ff.humanoid = "humanoid"

---@class dru.ff.Handler
dru.ff.Handler = cs.class()
--region dru.ff.Handler
function dru.ff.Handler:build()
  self.forms = {}
  self.forms[dru.ff.bear] = dru.bear.Form:create()
  self.forms[dru.ff.cat] = dru.cat.Form:create()
  self.forms[dru.ff.travel] = dru.travel.Form:create()
  self.forms[dru.ff.aquatic] = dru.aquatic.Form:create()
end

function dru.ff.Handler:set(form_name)
  if form_name == dru.ff.humanoid then
    for _, it in pairs(self.forms) do
      it:cancel()
    end
    return
  end

  local form = self.forms[form_name]
  form:set()
  return form
end

function dru.ff.Handler:get()
  for _, form in pairs(self.forms) do
    if form:check_exists() then
      return form
    end
  end
end
--regionend dru.ff.Handler



function cs.party.Player:rebuff()
  if not self.data.dru_mark then
    self.data.dru_mark = dru.buff.create_mark()
  end

  local result = self.data.dru_mark:rebuff(self.unit)
  if result then
    dru.ff.handler:set(dru.ff.humanoid)
    if result == cs.Buff.success then
      cs.print(string.format("BUFF: FOR %s [%s] %s", self.name, self.unit, cs.cl.get(self.unit)))
    end
    return true
  end
end



dru.rebuff = function()
  if not cs.party.can_rebuff() then
    return
  end

  if dru.sp.MarkWild:rebuff() or dru.sp.Thorns:rebuff() then
    dru.ff.handler:set(dru.ff.humanoid)
    return true
  end

end



dru.ff.init = function()
  dru.ff.handler = dru.ff.Handler:create()
end




-- PUBLIC

cs_dru_travel = function()
  if dru.ff.handler:get() == dru.ff.aquatic then
    return
  end

  if cs.is_swimming() then
    dru.ff.handler:set(dru.ff.aquatic)
    return
  end

  dru.ff.handler:set(dru.ff.travel)
end

cs_dru_form_action = function(form_name, action_name)
  if dru.rebuff() then return end

  local form = dru.ff.handler:set(form_name)
  local action = form[action_name]

  return action(form)
end

cs_dru_cast = function(form_name, spell_name)
  if form_name ~= dru.ff.humanoid then
    cs.auto_attack()
  end

  dru.ff.handler:set(form_name)

  dru.sp[spell_name]:cast()
end

cs_dru_buff = function(form_name, spell_name)
  dru.ff.handler:set(form_name)

  dru.sp[spell_name]:rebuff()
end

cs_dru_range_attack =function()
  cs.auto_attack()

  dru.ff.handler:set(dru.ff.humanoid)

  if cs.check_target(cs.t.attackable) then
    if dru.sp.FaerieFire:cast() then return end
    if dru.sp.InsectSwarm:cast() then return end
    if dru.sp.Wrath:cast() then return end
    if dru.sp.Moonfire:cast() then return end
  end

  dru.rebuff()
  return cs.party.rebuff()
end

cs_dru_RJ = function()
  dru.ff.handler:set(dru.ff.humanoid)

  if cs.check_target(cs.t.friend) then
    if cs.Buff:create(dru.sn.Rejuvenation):rebuff(cs.u.target) == cs.Buff.exists then
      cs.Buff:create(dru.sn.AbolishPoison):rebuff(cs.u.target)
    end
    return
  end

  if dru.sp.RJ:rebuff() == cs.Buff.exists then
    dru.sp.AbolishPoison:rebuff()
  end
end

cs_dru_heal = function()
  dru.ff.handler:set(dru.ff.humanoid)

  if dru.ff.handler:get() then
    return
  end

  if dru.sp.RemoveCurse:cast_helpful() then return end
  dru.sp.Regrowth:cast_helpful()
end
