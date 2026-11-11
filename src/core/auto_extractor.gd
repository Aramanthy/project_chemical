class_name AutoExtractor
extends Machine

## Continuously extracts one raw element into storage at a fixed rate,
## consuming power while running. Stalls (without drawing power) when storage is full.

var element_id: String = ""
var rate_per_sec: float = 1.0

func step(dt: float, state: GameState) -> void:
	if not enabled:
		status = Status.DISABLED
		return

	var inv: PlayerInventory = state.inventory
	if PlayerInventory.is_capacity_limited(element_id) \
			and inv.get_capacity_usage() >= inv.max_capacity - PlayerInventory.EPSILON:
		status = Status.OUTPUT_BLOCKED
		return

	if not _draw_power(dt, state):
		return

	inv.add_element(element_id, rate_per_sec * dt)
	status = Status.RUNNING
