class_name RTSMouseInput extends Nodot3D

@export var enabled: bool = true
## The ColorRect to use as a selection box
@export var selection_box: ColorRect = ColorRect.new()
## The associated camera (usually an IsometricCamera3D)
@export var camera: Camera3D
## Maximum projection distance (the distance from camera to the ground)
@export var max_projection_distance: float = 500.0

@export_category("Input Actions")
@export var select_action: String = "isometric_camera_select"
@export var action_action: String = "isometric_camera_action"

signal selected(node: Node)
signal selected_multiple(nodes: Array[Node])
signal action_requested(collision: Dictionary)

var mouse_position: Vector2 = Vector2.ZERO
var select_down_position: Vector2 = Vector2.ZERO

func _init():
	register_mouse_actions()

func _ready():
	selection_box.visible = false
	if !selection_box.is_inside_tree():
		add_child(selection_box)

func _input(event):
	if !enabled: return
	
	if event is InputEventMouseMotion:
		mouse_position = event.position
		if selection_box.visible == true:
			selection_box.set_size(mouse_position - select_down_position)
	elif event.is_action_pressed(select_action):
		select_down_position = mouse_position
		selection_box.visible = true
		selection_box.position = select_down_position
		selection_box.set_size(Vector2.ZERO)
	elif event.is_action_released(select_action):
		select()
		selection_box.visible = false
	elif event.is_action_pressed(action_action):
		action()

func get_3d_position(position_2d: Vector2):
	return camera.project_position(position_2d, max_projection_distance)

func select():
	var drag_distance = abs(select_down_position - mouse_position)
	if drag_distance < Vector2(10, 10):
		get_selectable()
	else:
		get_selectables()
		
func get_selectable():
	var collision = get_collision()
	if collision and collision.collider:
		emit_signal("selected", collision.collider)
	
func get_selectables():
	var selection_box_positions = [get_3d_position(select_down_position), get_3d_position(mouse_position)]
	selection_box_positions.sort()
	var start_position = selection_box_positions[0]
	var selection_box_size = selection_box_positions[1] - start_position
	var selection_box: Rect2 = Rect2(start_position.x, start_position.z, selection_box_size.x, selection_box_size.z)
	var selected_nodes: Array[Node] = []
	for selectable in get_tree().get_nodes_in_group("rts_selectable"):
		var selectable_position = selectable.global_position
		var selectable_position_box: Rect2 = Rect2(selectable_position.x, selectable_position.z, 0.1, 0.1)
		if selection_box.intersects(selectable_position_box):
			selected_nodes.append(selected_nodes)
	emit_signal("selected_multiple", selected_nodes)
	
func get_collision():
	var projected_position = get_3d_position(mouse_position)
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = global_position
	params.to = projected_position

	var result = space_state.intersect_ray(params)
	return result

func action():
	var collision = get_collision()
	if collision and collision.collider:
		emit_signal("action_requested", collision)

func register_mouse_actions():
	var action_names = [select_action, action_action]
	var default_keys = [
		MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT
	]
	for i in action_names.size():
		var action_name = action_names[i]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			InputManager.add_action_event_mouse(action_name, default_keys[i])
