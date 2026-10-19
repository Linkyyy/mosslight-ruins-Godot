extends Node
## Small event bus. World code never depends on a specific HUD or menu node.
signal notice(text: String)
signal effect(at: Vector2, color: Color, count: int, force: float)
signal impact(at: Vector2, color: Color, strength: float)
signal damage_number(at: Vector2, amount: int, color: Color)
signal sound(cue: String)
signal item_used(id: String)
signal transition_requested(region_id: int, spawn: Vector2)
signal player_died
signal boss_health(current: int, maximum: int)
signal victory
