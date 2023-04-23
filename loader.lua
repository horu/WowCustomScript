local cs = cs_common

local main_load = function()
  cs.damage.init()
  cs.game.init()
  cs.services.init()
  cs.dps.init()

  cs.pal.heal.init()
  cs.pal.seal.init()
  cs.pal.actions.init()
  cs.pal.states.init()
end

local main_frame = cs.create_simple_frame("cs_main_frame")
main_frame:RegisterEvent("VARIABLES_LOADED")
main_frame:SetScript("OnEvent", function()
  if event ~= "VARIABLES_LOADED" then
    return
  end

  cs.once_event(0.2, main_load)
end)