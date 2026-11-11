class_name PlanetWorld3D
extends Node3D

## Playable 3D third-person planetary surface view (Phase 1 -> Phase 2 bridge).
## Renders the planetary ground, third-person chemist avatar, over-the-shoulder
## camera rig, resource deposit crystals, dormant alien hubs, and deployed machines
## using procedural primitive meshes — 100% self-contained and headless-testable.

signal interaction_performed(result: Dictionary)

const MOVE_SPEED: float = 10.0
const TURN_SPEED_RAD: float = 2.2

var game_state: GameState
var camera_yaw: float = 0.0

var ground_body: StaticBody3D
var player_root: Node3D
var player_Visual: Node3D
var camera_pivot: Node3D
var camera_3d: Camera3D
var deposits_root: Node3D
var hubs_root: Node3D
var machines_root: Node3D

var _deposit_nodes: Dictionary = {}  # { deposit_id: Node3D }
var _hub_nodes: Dictionary = {}      # { hub_id: Node3D }
var _machine_nodes: Dictionary = {}  # { machine_id: Node3D }

func _ready() -> void:
	_build_environment()
	_build_player_and_camera()
	deposits_root = Node3D.new()
	deposits_root.name = "DepositsRoot"
	add_child(deposits_root)
	hubs_root = Node3D.new()
	hubs_root.name = "HubsRoot"
	add_child(hubs_root)
	machines_root = Node3D.new()
	machines_root.name = "MachinesRoot"
	add_child(machines_root)

func bind_state(state: GameState) -> void:
	game_state = state
	game_state.planet.player_moved.connect(_on_player_moved)
	game_state.planet.hub_activated.connect(_on_hub_activated)
	game_state.machine_added.connect(_on_machine_added)
	game_state.machine_removed.connect(_on_machine_removed)
	rebuild_from_state()

func rebuild_from_state() -> void:
	if game_state == null:
		return
	_clear_children(deposits_root)
	_clear_children(hubs_root)
	_clear_children(machines_root)
	_deposit_nodes.clear()
	_hub_nodes.clear()
	_machine_nodes.clear()

	for dep in game_state.planet.deposits:
		_spawn_deposit_node(dep)
	for hub_id in game_state.planet.hubs.keys():
		_spawn_hub_node(game_state.planet.hubs[hub_id])
	for m in game_state.machines:
		_spawn_machine_node(m)

	_sync_player_transform()

func _process(delta: float) -> void:
	if game_state == null:
		return
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	if Input.is_key_pressed(KEY_Q):
		rotate_camera_yaw(TURN_SPEED_RAD * delta)
	if Input.is_key_pressed(KEY_E):
		rotate_camera_yaw(-TURN_SPEED_RAD * delta)

	if input_dir.length_squared() > 0.001:
		move_in_view_direction(input_dir.normalized(), delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if game_state == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var ke := event as InputEventKey
		if ke.keycode == KEY_F or ke.keycode == KEY_SPACE:
			interact_at_player()

## Moves the player on the XZ plane relative to the current third-person camera yaw.
func move_in_view_direction(input_dir: Vector2, delta: float) -> void:
	if game_state == null:
		return
	var forward := Vector3(sin(camera_yaw), 0.0, cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	var world_dir: Vector3 = (right * input_dir.x + forward * input_dir.y).normalized()
	game_state.planet.move_player(world_dir * MOVE_SPEED * delta)
	if player_Visual and world_dir.length_squared() > 0.001:
		player_Visual.rotation.y = atan2(-world_dir.x, -world_dir.z)

func rotate_camera_yaw(delta_rad: float) -> void:
	camera_yaw += delta_rad
	if camera_pivot:
		camera_pivot.rotation.y = camera_yaw

## Performs context-sensitive 3D interaction at the player's position:
## 1. If a dormant Alien Hub is in range and can be activated, ignites it.
## 2. Otherwise, mines the nearest elemental deposit in range.
func interact_at_player() -> Dictionary:
	if game_state == null:
		return { "ok": false, "reason": "no_state" }
	var pos: Vector3 = game_state.planet.player_position
	var near_hub: Dictionary = game_state.planet.get_nearest_hub(pos)
	if not near_hub.is_empty() and not bool(near_hub.get("activated", false)):
		var hub_id: String = str(near_hub["id"])
		if game_state.planet.activate_hub(hub_id, game_state, true):
			var res: Dictionary = {
				"ok": true,
				"type": "hub_activated",
				"hub_id": hub_id,
				"hub_name": near_hub["name"]
			}
			interaction_performed.emit(res)
			return res

	var mine_res: Dictionary = game_state.planet.mine_nearest_deposit(game_state, 2.0)
	mine_res["type"] = "mine"
	interaction_performed.emit(mine_res)
	return mine_res

## Returns a short HUD string describing the player's 3D coordinates and nearest target.
func get_proximity_prompt() -> String:
	if game_state == null:
		return ""
	var pos: Vector3 = game_state.planet.player_position
	var coord_str: String = "Pos (%.1f, %.1f)" % [pos.x, pos.z]
	var dep: Dictionary = game_state.planet.get_nearest_deposit(pos)
	if not dep.is_empty():
		return "%s | Near: %s (%s x%.1f) [Press F to Mine]" % [
			coord_str, dep["name"], dep["element"], float(dep["richness"])
		]
	var hub: Dictionary = game_state.planet.get_nearest_hub(pos)
	if not hub.is_empty():
		var state_txt: String = "ONLINE" if bool(hub.get("activated", false)) else "Press F to Ignite"
		return "%s | Near Hub: %s [%s]" % [coord_str, hub["name"], state_txt]
	return "%s | Roaming Planet Surface (WASD move, Q/E rotate, F interact)" % coord_str

# --- 3D SCENE CONSTRUCTION ---

func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "DirectionalSun"
	sun.rotation_degrees = Vector3(-48.0, 35.0, 0.0)
	sun.light_energy = 1.25
	add_child(sun)

	ground_body = StaticBody3D.new()
	ground_body.name = "PlanetGround"
	var ground_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(PlanetGrid.WORLD_HALF_EXTENT * 2.4, 1.0, PlanetGrid.WORLD_HALF_EXTENT * 2.4)
	ground_mesh.mesh = box
	ground_mesh.position = Vector3(0.0, -0.5, 0.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.14, 0.16, 0.21)
	ground_mat.roughness = 0.9
	ground_mesh.material_override = ground_mat
	ground_body.add_child(ground_mesh)
	add_child(ground_body)

func _build_player_and_camera() -> void:
	player_root = Node3D.new()
	player_root.name = "PlayerRoot"
	add_child(player_root)

	player_Visual = Node3D.new()
	player_Visual.name = "PlayerVisual"
	player_root.add_child(player_Visual)

	# Chemist suit body
	var suit := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.45
	cap.height = 1.8
	suit.mesh = cap
	suit.position = Vector3(0.0, 0.9, 0.0)
	var suit_mat := StandardMaterial3D.new()
	suit_mat.albedo_color = Color(0.9, 0.92, 0.96)
	suit.material_override = suit_mat
	player_Visual.add_child(suit)

	# Glowing visor (indicates facing direction -Z)
	var visor := MeshInstance3D.new()
	var v_box := BoxMesh.new()
	v_box.size = Vector3(0.55, 0.25, 0.3)
	visor.mesh = v_box
	visor.position = Vector3(0.0, 1.35, -0.35)
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.2, 0.9, 1.0)
	visor_mat.emission_enabled = true
	visor_mat.emission = Color(0.2, 0.9, 1.0)
	visor.material_override = visor_mat
	player_Visual.add_child(visor)

	# Over-the-shoulder Third-Person Camera Rig
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	player_root.add_child(camera_pivot)

	camera_3d = Camera3D.new()
	camera_3d.name = "ThirdPersonCamera"
	camera_3d.position = Vector3(0.0, 4.5, 7.5)
	camera_3d.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
	camera_3d.current = true
	camera_pivot.add_child(camera_3d)

func _spawn_deposit_node(dep: Dictionary) -> void:
	var root := Node3D.new()
	root.name = str(dep["id"])
	root.position = dep["position"]

	var crystal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.9
	cyl.height = 2.0
	crystal.mesh = cyl
	crystal.position = Vector3(0.0, 1.0, 0.0)
	var mat := StandardMaterial3D.new()
	var col: Color = _element_color(str(dep["element"]))
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col * 0.5
	crystal.material_override = mat
	root.add_child(crystal)

	var lbl := Label3D.new()
	lbl.text = "%s [%s x%.1f]" % [dep["name"], dep["element"], float(dep["richness"])]
	lbl.position = Vector3(0.0, 2.6, 0.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 42
	lbl.modulate = col.lightened(0.35)
	root.add_child(lbl)

	deposits_root.add_child(root)
	_deposit_nodes[str(dep["id"])] = root

func _spawn_hub_node(hub: Dictionary) -> void:
	var hub_id: String = str(hub["id"])
	var root := Node3D.new()
	root.name = hub_id
	root.position = hub["position"]

	var pylon := MeshInstance3D.new()
	pylon.name = "PylonMesh"
	var box := BoxMesh.new()
	var is_core: bool = bool(hub.get("is_core", false))
	box.size = Vector3(2.8, 6.5, 2.8) if is_core else Vector3(1.8, 4.2, 1.8)
	pylon.mesh = box
	pylon.position = Vector3(0.0, box.size.y * 0.5, 0.0)
	root.add_child(pylon)

	var lbl := Label3D.new()
	lbl.name = "HubLabel"
	lbl.position = Vector3(0.0, box.size.y + 1.0, 0.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 48
	root.add_child(lbl)

	hubs_root.add_child(root)
	_hub_nodes[hub_id] = root
	_refresh_hub_visual(hub_id)

func _refresh_hub_visual(hub_id: String) -> void:
	if not _hub_nodes.has(hub_id) or game_state == null:
		return
	var root: Node3D = _hub_nodes[hub_id]
	var hub: Dictionary = game_state.planet.hubs[hub_id]
	var active: bool = bool(hub.get("activated", false))
	var pylon: MeshInstance3D = root.get_node("PylonMesh") as MeshInstance3D
	var lbl: Label3D = root.get_node("HubLabel") as Label3D

	var mat := StandardMaterial3D.new()
	if active:
		var glow := Color(1.0, 0.85, 0.25) if bool(hub.get("is_core", false)) else Color(0.2, 0.95, 1.0)
		mat.albedo_color = glow
		mat.emission_enabled = true
		mat.emission = glow * 0.8
		lbl.text = "%s [ONLINE +%s]" % [hub["name"], EnergySystem.format_watts(float(hub["passive_power_watts"]))]
		lbl.modulate = glow
	else:
		mat.albedo_color = Color(0.32, 0.34, 0.4)
		lbl.text = "%s [DORMANT]" % hub["name"]
		lbl.modulate = Color(0.85, 0.5, 0.4)
	pylon.material_override = mat

func _spawn_machine_node(machine: Machine) -> void:
	if machine.world_position == Vector3.ZERO and game_state != null:
		# Place around the player's current position in a ring
		var idx: int = max(0, machine.id - 1)
		var angle: float = float(idx) * 1.15
		var radius: float = 2.6 + float(idx / 6) * 1.5
		var p: Vector3 = game_state.planet.player_position
		machine.world_position = Vector3(p.x + cos(angle) * radius, 0.0, p.z + sin(angle) * radius)

	var root := Node3D.new()
	root.name = "Machine_%d" % machine.id
	root.position = machine.world_position

	var mesh_inst := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	if machine is AutoExtractor:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.55
		cyl.height = 1.2
		mesh_inst.mesh = cyl
		mesh_inst.position = Vector3(0.0, 0.6, 0.0)
		mat.albedo_color = Color(0.3, 0.8, 0.95)
	else:
		var sph := SphereMesh.new()
		sph.radius = 0.7
		sph.height = 1.4
		mesh_inst.mesh = sph
		mesh_inst.position = Vector3(0.0, 0.7, 0.0)
		mat.albedo_color = Color(0.95, 0.55, 0.2)
	mesh_inst.material_override = mat
	root.add_child(mesh_inst)

	var lbl := Label3D.new()
	lbl.text = "#%d %s" % [machine.id, machine.display_name]
	lbl.position = Vector3(0.0, 1.7, 0.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 34
	root.add_child(lbl)

	machines_root.add_child(root)
	_machine_nodes[machine.id] = root

func _on_player_moved(_new_pos: Vector3) -> void:
	_sync_player_transform()

func _sync_player_transform() -> void:
	if player_root and game_state:
		player_root.position = game_state.planet.player_position

func _on_hub_activated(hub_id: String) -> void:
	_refresh_hub_visual(hub_id)

func _on_machine_added(machine: Machine) -> void:
	_spawn_machine_node(machine)

func _on_machine_removed(machine: Machine) -> void:
	if _machine_nodes.has(machine.id):
		var n: Node3D = _machine_nodes[machine.id]
		_machine_nodes.erase(machine.id)
		n.queue_free()

static func _element_color(elem_id: String) -> Color:
	match elem_id:
		"H": return Color(0.25, 0.9, 1.0)
		"O": return Color(0.2, 0.55, 1.0)
		"C": return Color(0.75, 0.75, 0.78)
		"U": return Color(0.35, 1.0, 0.25)
		"EX_119": return Color(0.9, 0.3, 1.0)
	return Color(0.9, 0.85, 0.5)

static func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for c in parent.get_children():
		parent.remove_child(c)
		c.free()
