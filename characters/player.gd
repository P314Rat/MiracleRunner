extends CharacterBody3D
class_name Player


@export var move_speed: float = 4.0
@export var turn_speed: float = 8.0
@export var target_point: Point = null

@onready var camera: Camera3D = $Camera3D
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var target_position: Vector3 = Vector3.ZERO
var path_points: Array[Vector3] = []
var current_path_point_index: int = -1
var is_moving: bool = false


func _ready() -> void:
	call_deferred("navigation_setup")
	navigation_agent.path_changed.connect(on_change_path)

func navigation_setup():
	await get_tree().physics_frame
	var map = get_parent().get_navigation_map()
	print(NavigationServer3D.map_get_path(map, self.global_position, target_point.global_position, false))
	navigation_agent.set_target_position(target_point.global_position)
	navigation_agent.get_next_path_position()
	navigation_agent.simplify_epsilon = 0.2
	navigation_agent.simplify_path = true

func _process(delta: float) -> void:
	pass
	#if !is_moving:
		#navigation_agent.set_target_position(target_point.global_position)
	
	#if navigation_agent.is_target_reached():
		#is_moving = false

func _physics_process(delta: float) -> void:
	if is_moving:
		#var next_path_position = navigation_agent.get_next_path_position()
		var next_path_position = path_points[current_path_point_index]
		var direction = (next_path_position - global_position).normalized()
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, turn_speed * delta)
		global_position = global_position.move_toward(next_path_position, move_speed * delta)
		
		#if navigation_agent.is_target_reached():
			#is_moving = false
		
		if global_position.distance_to(next_path_position) < 0.01:
			global_position = next_path_position
			current_path_point_index += 1
			
			if current_path_point_index == len(path_points):
				current_path_point_index = -1
				is_moving = false

func on_change_path() -> void:
	#var raw_points = NavigationServer3D.map_get_path(get_parent().get_navigation_map(), self.global_position, target_point.global_position, true)
	var raw_points = navigation_agent.get_current_navigation_path()
	print(raw_points)
	
	var unique_points: Array[Vector3] = []
	
	for p in raw_points:
		if unique_points.is_empty() or not unique_points[-1].is_equal_approx(p):
			unique_points.append(p)
			
	print(unique_points)
	
	var curve = Curve3D.new()
	for i in range(len(unique_points)):
		curve.add_point(unique_points[i])
	
	#for i in range(1, curve.get_point_count() - 1):
		#var prev = curve.get_point_position(i - 1)
		#var next = curve.get_point_position(i + 1)
		#var distance = prev.distance_to(next)
		#var tangent = (next - prev).normalized()
		#curve.set_point_in(i, -tangent)
		#curve.set_point_out(i, tangent)
	
	path_points.append_array(unique_points)
	#path_points = unique_points.duplicate()
	print(len(path_points))
	current_path_point_index = 0;
	is_moving = true
