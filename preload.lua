local mod = game.mod_runtime[game.current_mod]

game.add_hook("on_mapgen_postprocess", function(params)
  if mod.on_mapgen_postprocess then return mod.on_mapgen_postprocess(params) end
end)

game.add_hook("on_npc_spawn", function(params)
  if mod.on_npc_spawn then return mod.on_npc_spawn(params) end
end)

game.add_hook("on_npc_loaded", function(params)
  if mod.on_npc_loaded then return mod.on_npc_loaded(params) end
end)

game.add_hook("on_monster_loaded", function(params)
  if mod.on_monster_loaded then return mod.on_monster_loaded(params) end
end)

gapi.add_on_every_x_hook(TimeDuration.from_turns(1), function()
  if mod.process_pending_cleanups then return mod.process_pending_cleanups() end
end)
