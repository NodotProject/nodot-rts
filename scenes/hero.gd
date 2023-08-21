extends NodotCharacter3D

@export var nav: NavigationAgent3D
@export var default_gravity: float = 15.0
@export var movement_speed: float = 5.0
@export var turn_rate: float = 1.0
## Maximum height for a ledge to allow stepping up.
@export var step_height: float = 0.5
## Constructs the step up movement vector.
@onready var step_vector: Vector3 = Vector3(0, step_height, 0)

func _physics_process(delta):
	if !is_on_floor():
		velocity.y -= default_gravity * delta
	
	var current_location = global_transform.origin
	var next_position = nav.get_next_path_position()
	var new_velocity = (next_position - current_location).normalized() * movement_speed
	
	nav.set_velocity(Vector3(new_velocity.x, 0.0, new_velocity.z))
	
	face_target(transform.origin + velocity, turn_rate * delta)
	
	move_and_slide()

func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, .25)
	
func selected():
	$SelectedIndicator.visible = true
	
func deselected():
	$SelectedIndicator.visible = false

func action(collision: Dictionary):
	nav.set_target_position(collision.position)
