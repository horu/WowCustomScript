local cs = cs_common
local dru = cs.dru


dru.bear = {}

---@class dru.bear.Form
dru.bear.Form = cs.class()
dru.bear.Form.name = "Bear Form"
function dru.bear.Form:build()
  self.buff = cs.Buff:create(self.name)
end

function dru.bear.Form:set()
  self.buff:rebuff()
end

function dru.bear.Form:cancel()
  self.buff:cancel()
end

function dru.bear.Form:check_exists()
  return self.buff:check_exists()
end

function dru.bear.Form:attack()
  cs.auto_attack()

  if not cs.check_target(cs.t.attackable) then
    return
  end

  if dru.sp.Enrage:cast() then return end

  dru.sp.Maul:cast()
end

function dru.bear.Form:splash()
  if not cs.auto_attack() then return end

  if dru.sp.FaerieFire_Feral:cast() then return end
  if dru.sp.DemoralizingRoar:cast() then return end
  dru.sp.Swipe:cast()
end



dru.form = {}

dru.form.bear = "bear"
dru.form.cat = "cat"
dru.form.humanoid = "humanoid"

dru.form.Handler = cs.class()
function dru.form.Handler:build()
  self.forms = {}
  self.forms[dru.form.bear] = dru.bear.Form:create()
  self.forms[dru.form.cat] = dru.cat.Form:create()
end

function dru.form.Handler:set(form_name)
  if form_name == dru.form.humanoid then
    for _, it in pairs(self.forms) do
      it:cancel()
    end
    return
  end

  local form = self.forms[form_name]
  form:set()
  return form
end

function dru.form.Handler:get()
  for _, form in pairs(self.forms) do
    if form:check_exists() then
      return form
    end
  end
end


function cs.party.Player:rebuff()
  if not self.data.dru_mark then
    self.data.dru_mark = dru.buff.create_mark()
  end

  local result = self.data.dru_mark:rebuff(self.unit)
  if result then
    dru.form.handler:set(dru.form.humanoid)
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
    dru.form.handler:set(dru.form.humanoid)
    return true
  end

end



dru.form.init = function()
  dru.form.handler = dru.form.Handler:create()
end




-- PUBLIC

cs_dru_form_action = function(form_name, action_name)
  if dru.rebuff() then return end

  local form = dru.form.handler:set(form_name)
  local action = form[action_name]

  return action(form)
end

cs_dru_cast = function(form_name, spell_name)
  if form_name ~= dru.form.humanoid then
    cs.auto_attack()
  end

  dru.form.handler:set(form_name)

  dru.sp[spell_name]:cast()
end

cs_dru_buff = function(form_name, spell_name)
  dru.form.handler:set(form_name)

  dru.sp[spell_name]:rebuff()
end

cs_dru_range_attack =function()
  cs.auto_attack()

  dru.form.handler:set(dru.form.humanoid)

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
  dru.form.handler:set(dru.form.humanoid)

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
  dru.form.handler:set(dru.form.humanoid)

  if dru.form.handler:get() then
    return
  end

  if not dru.sp.RemoveCurse:is_failed(0.8) then
    if dru.sp.RemoveCurse:cast_helpful() then return end
  end

  dru.sp.Regrowth:cast_helpful()
end
