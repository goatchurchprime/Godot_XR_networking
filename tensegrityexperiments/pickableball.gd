tool
class_name XRPickableBall
extends XRToolsPickable

var ballsumvec = Vector3(0,0,0)
var ballsumN = 0
var ballsumFrameN = 0

func get_class():
	return "XRPickableBall"

func addsumpt(pt, ballFrameN):
	if ballsumFrameN == ballFrameN:
		ballsumvec += pt
		ballsumN += 1
	else:
		ballsumFrameN = ballFrameN
		ballsumN = 1
		ballsumvec = pt

func settosumpt(ballFrameN):
	if ballsumFrameN == ballFrameN:
		translation = ballsumvec/ballsumN

func _ready() -> void:
	set_mode(RigidBody.MODE_KINEMATIC)
	reset_transform_on_pickup = false
	ranged_grab_method = RangedMethod.LERP
	$MeshBall.get_surface_material(0).albedo_color = Color.darkcyan

func _on_Ball_highlight_updated(pickable, enable):
	$MeshBall.get_surface_material(0).albedo_color = Color.yellow if enable else Color.darkcyan
