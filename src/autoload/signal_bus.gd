extends Node
## Global signal hub — the decoupling surface for the whole game.
## Holds NO state and NO logic. Systems emit these; any system or UI may listen. (§7)

# --- Day cycle ---
signal day_started(day: int)
signal day_ended()
signal budget_changed(current: int, max: int)
signal budget_depleted()

# --- Inventory ---
signal inventory_changed(item_id: String, new_count: int)
signal coins_changed(amount: int)

# --- Ocean Map / islands ---
signal island_entered(island_instance) ## runtime island object
signal island_exited()
signal node_started(node_def) ## NodeDefinition
signal node_resolved(node_def, rewards) ## rewards: {item_id: count}

# --- Spirits ---
signal spirit_encountered(spirit_data) ## SpiritData
signal spirit_tamed(spirit_data)
signal spirit_fled(spirit_data, drops)

# --- Meta ---
signal quest_phase_changed(phase: int)
signal tutorial_triggered(mechanic_id: String)
signal request_screen_change(screen_id: String)