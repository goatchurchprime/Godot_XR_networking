extends Node3D

@onready var skel = get_node("../redoran3/MonsterArmature/Skeleton3D")

static func rotationtoalign(a, b):
	var axis = a.cross(b).normalized()
	if (axis.length_squared() != 0):
		var dot = a.dot(b)/(a.length()*b.length())
		dot = clamp(dot, -1.0, 1.0)
		var angle_rads = acos(dot)
		return Basis(axis, angle_rads)
	return Basis()

func updatebones():
	var gs = skel.global_transform
	for j in range(skel.get_bone_count()):
		var pj = skel.get_bone_parent(j)
		var parenttransform = gs*(skel.get_bone_global_pose(pj) if pj != -1 else Transform3D())
		var bonetransform = parenttransform*skel.get_bone_pose(j)
		var vpb = bonetransform.origin - parenttransform.origin
		var byalign = rotationtoalign(Vector3(0,1,0), skel.get_bone_pose_position(j))
		var vpblen = vpb.length()
		
		var rj = get_node("bonestick%d" % j)
		remove_child(rj)
		rj.get_node("CollisionShape3D").shape.size.y = vpblen*1.8
		rj.get_node("MeshInstance3D").mesh.size.y = vpblen*0.9
		#byalign = byalign * (Basis().scaled(Vector3(1,vpblen,1)))
		rj.transform = Transform3D(parenttransform.basis.orthonormalized()*byalign, parenttransform.origin + vpb*0.5)
		if pj != -1:
			var joint = rj.get_node("Generic6DOFJoint3D")
			joint.transform.origin = Vector3(0,-vpblen/2,0)
			joint.node_a = NodePath("..")
			joint.node_b = NodePath("../../bonestick%d" % pj)
		add_child(rj)
		
	skel.reset_bone_poses()
		
func _ready():
	
	var bonestickscene = load("res://manualposemaker/pickablebonestick.tscn")
	var bonesticknode = $ExampleBoneStick
	#remove_child(bonesticknode)
	for j in range(skel.get_bone_count()):
		var rj = bonestickscene.instantiate()
		rj.get_node("CollisionShape3D").shape = rj.get_node("CollisionShape3D").shape.duplicate()
		rj.get_node("MeshInstance3D").mesh = rj.get_node("MeshInstance3D").mesh.duplicate()
		rj.name = "bonestick%d" % j
		add_child(rj)
	updatebones()


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_U:
				updatebones()


			if event.keycode == KEY_P:
				var X = get_node("/root/Main/HingeJoint3D")
				var Xp = X.get_parent()
				Xp.remove_child(X)
				Xp.add_child(X)
				print("removed and added ", X)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
