@tool
class_name XRPickableBall
extends XRToolsPickable

var ballsumvec = Vector3(0,0,0)
var ballsumN = 0
var ballsumFrameN = 0


func addsumpt(pt, ballFrameN):
	if ballsumFrameN == ballFrameN:
		ballsumvec += pt
		ballsumN += 1
	else:
		ballsumFrameN = ballFrameN
		ballsumN = 1
		ballsumvec = pt

func getsumpt(ballFrameN):
	if ballsumFrameN == ballFrameN:
		return ballsumvec/ballsumN
	return position
	
func _ready() -> void:
	set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	ranged_grab_method = RangedMethod.LERP
	$MeshBall.get_surface_override_material(0).albedo_color = Color.DARK_CYAN

func _on_Ball_highlight_updated(pickable, enable):
	$MeshBall.get_surface_override_material(0).albedo_color = Color.YELLOW if enable else Color.DARK_CYAN
