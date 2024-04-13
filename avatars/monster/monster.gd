extends CharacterBody3D

enum {STATE_IDLE, STATE_ATTACK_LEFT, STATE_ATTACK_RIGHT,
  STATE_ATTACK_SMASH, STATE_GRAB, STATE_ROAR, STATE_EAT, STATE_THROW, STATE_DEAD}

signal died

@export var locked = false
@export var roar = false

var max_health = 1000
var health = max_health
var speed = 20.0
var camera_distance = 20.0
var state = STATE_IDLE
var grabbed_object = null

@onready var grab_area = $Origin/MonsterArmature/Skeleton3D/RightHandAnchor/GrabArea
@onready var lstomp_area = $Origin/MonsterArmature/Skeleton3D/LeftFootAnchor/LStompArea
@onready var rstomp_area = $Origin/MonsterArmature/Skeleton3D/RightFootAnchor/RStompArea
@onready var player = $Origin/AnimationPlayer


func _ready():
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process(false)
	set_physics_process(false)


#func _unhandled_input(event):
#	if event is InputEventMouseMotion:
#		var mouse_motion = event.relative * 0.1
#		$CameraPivot.rotation_degrees.x -= mouse_motion.y
#		$CameraPivot.rotation_degrees.y -= mouse_motion.x
#		$CameraPivot.rotation_degrees.x = clamp($CameraPivot.rotation_degrees.x, -75.0, 25.0)

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_R:
				player.play("roar")
			if event.keycode == KEY_T:
				player.play("walk-loop")
			if event.keycode == KEY_Y:
				player.play("smash")
			if event.keycode == KEY_U:
				player.play("poses")
			if event.keycode == KEY_I:
				player.play("throw")
			if event.keycode == KEY_G:
				player.play("attack-left")

#		$CameraPivot.rotation_degrees.x -= mouse_motion.y
#		$CameraPivot.rotation_degrees.y -= mouse_motion.x
#		$CameraPivot.rotation_degrees.x = clamp($CameraPivot.rotation_degrees.x, -75.0, 25.0)


	
func _physics_process(delta):
	# Camera update
	var camera_speed = 3.0
	$CameraPivot.rotation_degrees.x -= Input.get_action_strength("camera_down") * camera_speed
	$CameraPivot.rotation_degrees.x += Input.get_action_strength("camera_up") * camera_speed
	$CameraPivot.rotation_degrees.y -= Input.get_action_strength("camera_right") * camera_speed
	$CameraPivot.rotation_degrees.y += Input.get_action_strength("camera_left") * camera_speed
	$CameraPivot.rotation_degrees.x = clamp($CameraPivot.rotation_degrees.x, -75.0, 25.0)
		
	var target = Vector3.BACK.rotated(Vector3.UP, $CameraPivot.rotation.y) * 3.0
	target += Vector3.FORWARD.rotated(Vector3.UP, $Origin.rotation.y) * 5.0
	
	var vel = (target - $CameraPivot.position) * 0.025
	$CameraPivot.position += vel
	$CameraPivot.position.y = 2.5
	
	var time = $ShakeTimer.time_left
	time = clamp(time, 0.0, 1.0)
	time *= 0.25
	$CameraPivot/Camera3D.position = Vector3(randf() * time, randf() * time, camera_distance + randf() * time)
	
	# Monster update
	var velocity = Vector3.ZERO
	velocity.y = -10
	var direction = Vector3.ZERO
	
	if state != STATE_GRAB:
		grab_area.monitorable = false
	
	if state != STATE_ROAR:
		roar = false
	
	match state:
		STATE_IDLE:
			player.playback_speed = 1.3
			"""
			direction.z += Input.get_axis("move_forward", "move_back")
			direction.x += Input.get_axis("move_left", "move_right")
			"""
			direction.z -= Input.get_action_strength("move_forward")
			direction.z += Input.get_action_strength("move_back")
			direction.x -= Input.get_action_strength("move_left")
			direction.x += Input.get_action_strength("move_right")
	
			if direction != Vector3.ZERO:
				player.play("walk-loop")
				direction = direction.normalized()
				direction = direction.rotated(Vector3.UP, $CameraPivot.rotation.y)
				$Origin.look_at(position + direction, Vector3.UP)
				velocity += direction * speed
			else:
				player.play("idle-loop")
			
			
			if Input.is_action_just_pressed("attack"):
				set_state(STATE_ATTACK_LEFT, "attack-left")
			elif Input.is_action_just_pressed("smash"):
				set_state(STATE_ATTACK_SMASH, "smash")
			elif Input.is_action_just_pressed("grab"):
				if not perform_grab_action():
					set_state(STATE_GRAB, "grab")
			elif Input.is_action_just_pressed("roar"):
				set_state(STATE_ROAR, "roar")
		
		STATE_ATTACK_LEFT:
			player.playback_speed = 2.4
			if Input.is_action_just_pressed("attack") and not locked:
				set_state(STATE_ATTACK_RIGHT, "attack-right")
			if not player.is_playing():
				set_state(STATE_IDLE)
		
		STATE_ATTACK_RIGHT:
			player.playback_speed = 2.4
			if Input.is_action_just_pressed("attack") and not locked:
				set_state(STATE_ATTACK_LEFT, "attack-left")
			if not player.is_playing():
				set_state(STATE_IDLE)
		
		STATE_ATTACK_SMASH:
			player.playback_speed = 2.4
			if Input.is_action_just_pressed("smash") and not locked:
				player.stop()
				set_state(STATE_ATTACK_SMASH, "smash")
			if not player.is_playing():
				set_state(STATE_IDLE)
		
		STATE_GRAB:
			player.playback_speed = 1.0
			if Input.is_action_just_pressed("grab") and not locked:
				perform_grab_action()
			if not player.is_playing():
				set_state(STATE_IDLE)
		
		STATE_ROAR:
			player.playback_speed = 1.25
			if not player.is_playing():
				set_state(STATE_IDLE)
		
		STATE_EAT:
			player.playback_speed = 2.0
			if not player.is_playing():
				set_state(STATE_IDLE)
		
		STATE_THROW:
			player.playback_speed = 1.5
			if not player.is_playing():
				set_state(STATE_IDLE)
		
		STATE_DEAD:
			player.playback_speed = 1.0
		
		_:
			if not player.is_playing():
				set_state(STATE_IDLE)
	
	set_velocity(velocity)
	move_and_slide()


func perform_grab_action():
	if grabbed_object:
		if grabbed_object.is_in_group("humans"):
			set_state(STATE_EAT, "eat")
		else:
			set_state(STATE_THROW, "throw")
		return true
	else:
		return false


func set_state(new_state, anim = null):
	if new_state == STATE_DEAD and state != STATE_DEAD:
		emit_signal("died")
	if anim:
		player.play(anim)
	state = new_state
	locked = true
	lstomp_area.monitorable = false
	rstomp_area.monitorable = false


func grab(object):
	if grabbed_object:
		return false
	
	object.get_parent().call_deferred("remove_child", object)
	grab_area.call_deferred("add_child", object)
	object.position = Vector3.ZERO
	grabbed_object = object
	return true


func throw():
	if grabbed_object:
		var vel = Vector3.FORWARD.rotated(Vector3.UP, $Origin.rotation.y)
		vel *= 150.0
		vel.y = 50.0
		grabbed_object.throw(grab_area.global_position, vel)
		grabbed_object = null


func eat():
	if grabbed_object:
		if grabbed_object.alien:
			health += 100
		else:
			health += 30
		grabbed_object.eat()
		grabbed_object = null
		health = min(health, max_health)


func shake():
	$ShakeTimer.start()


func hit(area):
	if state == STATE_DEAD:
		return
	
	if area.get_collision_layer_value(10):
		health -= 1
		area.impact()

	if area.get_collision_layer_value(11):
		health -= 10
		area.impact()
	
	if area.get_collision_layer_value(12):
		health -= 3
		area.impact()
	
	if area.get_collision_layer_value(13):
		health -= 50
		area.impact(true)
	
	health = max(health, 0)
	
	if health == 0:
		set_state(STATE_DEAD, "die")
