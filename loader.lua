local cs = cs_common

local main_tests = function()
  cs.common.test()
  cs.damage.test()
  cs.game.test()
  cs.spell.test()
  cs.prof.test()
  cs.slot.test()

  cs.pal.resist.test()
  cs.pal.states.test()
end

local main_load = function()
  cs.damage.init()
  cs.game.init()
  cs.slot.init()
  cs.services.init()
  cs.dps.init()
  cs.stat.init()

  cs.pal.common.init()
  cs.pal.resist.init()
  cs.pal.bless.init()
  cs.pal.heal.init()
  cs.pal.seal.init()
  cs.pal.actions.init()
  cs.pal.config.init()
  cs.pal.states.init()

  main_tests()
  cs.print(cs.color.green.."+++++++++++++++++++++++++++ CS LOADED +++++++++++++++++++++++++++")
end

local main_frame = cs.create_simple_frame()
main_frame:RegisterEvent("VARIABLES_LOADED")
main_frame:SetScript("OnEvent", function()
  if event ~= "VARIABLES_LOADED" then
    return
  end

  cs.event.once(0.2, main_load)
end)