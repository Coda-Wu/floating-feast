extends Node
## Global signal hub — the decoupling surface for the whole game.
## Holds NO state and NO logic. Systems emit these; any system or UI may listen. (§7)

# --- Day cycle ---
signal day_started(day: int)
signal day_ended()

# --- Inventory ---
signal inventory_changed(item_id: String, new_count: int)
signal coins_changed(amount: int)
signal phase_changed(phase: int)
signal hotbar_item_selected(item_id: String)
signal fridge_changed()
signal tool_selected(tool_id: StringName) # &"" = cleared; else watering_can / shovel (GARDEN.md)

# --- Ocean Map / islands ---
signal island_entered(island_instance) ## runtime island object
signal island_exited()
signal node_started(node_def) ## NodeDefinition
signal node_resolved(node_def, rewards) ## rewards: {item_id: count}
signal run_buff_applied(buff: Dictionary) # run-scoped synergy buff set or cleared (empty = cleared)

# --- Spirits ---
signal spirit_encountered(spirit_data) ## SpiritData
signal spirit_tamed(spirit_data)
signal spirit_fled(spirit_data, drops)

# --- Meta ---
signal quest_phase_changed(phase: int)
signal rank_changed(rank: int) # Fair rank changed
signal tutorial_triggered(mechanic_id: String)
signal request_screen_change(screen_id: String)

# --- Cooking & Recipes ---
signal dish_cooked(recipe_id: String, tier: int)
signal dish_inventory_changed()
signal recipe_discovered(recipe_id: String)
signal station_ui_opened()
signal station_ui_closed()


# --- Commissions & Fair ---
signal commission_activated(commission_id: String)
signal commission_completed(commission_id: String)


# --- Exploration resources ---
signal fuel_changed(current: int, maximum: int)
signal time_changed(minutes: int)
signal day_auto_returned(reason: StringName) # the run ended itself: &"fuel" or &"curfew"


signal inventory_slots_changed() # any slot mutation (add/remove/move/sort) — drives hotbar + backpack grid