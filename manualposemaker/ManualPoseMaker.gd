extends Node3D

@onready var skel = get_node("../redoran3/MonsterArmature/Skeleton3D")


class VerletJoint:
	var pj
	var pjheadtail
	var pjlen
	var pjbone
	var j
	var jheadtail
	var jlen
	var jbone
	
	func init(lj, skel, posescene):
		j = lj
		jbone = posescene.get_node("bonestick%d" % j)
		jheadtail = true
		pj = skel.get_bone_parent(j)
		assert (pj != -1)
		pjbone = posescene.get_node("bonestick%d" % pj)
		pjheadtail = false
		var ppj = skel.get_bone_parent(pj)
		var ptransform = skel.global_transform*skel.get_bone_global_pose(pj)
		var btransform = ptransform*skel.get_bone_pose(j) 
		var pptransform = skel.global_transform*(skel.get_bone_global_pose(ppj) if ppj != -1 else Transform3D())
		pjlen = (ptransform.origin - pptransform.origin).length()
		jlen = (btransform.origin - ptransform.origin).length()

	func movebone(moveparent, clam, posescene):
		var jointpos = jbone.transform.origin - jbone.transform.basis.y*(jlen/2)
		var pjointpos = pjbone.transform.origin + pjbone.transform.basis.y*(pjlen/2)
		if moveparent:
			var cenrot = pjbone.transform.origin + pjbone.transform.basis.y*clam
			var b = posescene.rotationtoalign(pjbone.transform.basis.y, jointpos - cenrot)
			pjbone.transform.basis = b*pjbone.transform.basis
			pjointpos = pjbone.transform.origin + pjbone.transform.basis.y*(pjlen/2)
			pjbone.transform.origin += jointpos - pjointpos


		else:
			var cenrot = jbone.transform.origin + jbone.transform.basis.y*clam
			var b = posescene.rotationtoalign(jbone.transform.basis.y, jbone.transform.origin - pjointpos)
			jbone.transform.basis = b*jbone.transform.basis
			jointpos = jbone.transform.origin - jbone.transform.basis.y*(jlen/2)
			jbone.transform.origin += pjointpos - jointpos 

var vjoints = [ ]


func minenergymove(j):
	var bonesvisited = [ j ]
	var bonesprocessing = [ j ]
	while len(bonesprocessing) != 0:
		var lj = bonesprocessing.pop_front()
		var vjs = [ ]
		for vjoint in vjoints:
			if vjoint.j == lj and not bonesvisited.has(vjoint.pj):
				vjoint.movebone(true, -0.5, self)
				vjs.append(vjoint.pj)
			if vjoint.pj == lj and not bonesvisited.has(vjoint.j):
				vjoint.movebone(false, 0.5, self)
				vjs.append(vjoint.j)
		bonesprocessing.append_array(vjs)
		bonesvisited.append_array(vjs)

		
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
			var joint = rj.get_node_or_null("Generic6DOFJoint3D")
			if joint:
				joint.transform.origin = Vector3(0,-vpblen/2,0)
				joint.node_a = NodePath("..")
				joint.node_b = NodePath("../../bonestick%d" % pj)
		add_child(rj)
		
	#for vjoint in vjoints:
	#	vjoint.movebone(true)


	skel.reset_bone_poses()

var pickedbones = [ ]
var disableverlet = true

func onbonestickpickedup(b):
	print("pickup ", b.get_path())
	pickedbones.append(b.name.to_int())
func onbonestickdropped(b):
	print("drop ", b.name, "  ", b.name.to_int()*1000)
	var jdropped = b.name.to_int()
	pickedbones.erase(jdropped)
	if len(pickedbones) == 0 and disableverlet:
		minenergymove(jdropped)


func verletrun():
	for j in pickedbones:
		var bonesvisited = pickedbones.duplicate()
		var bonesprocessing = [ j ]
		while len(bonesprocessing) != 0:
			var lj = bonesprocessing.pop_front()
			var vjs = [ ]
			for vjoint in vjoints:
				if vjoint.j == lj and not bonesvisited.has(vjoint.pj):
					vjoint.movebone(true, -0.5, self)
					vjs.append(vjoint.pj)
				if vjoint.pj == lj and not bonesvisited.has(vjoint.j):
					vjoint.movebone(false, 0.5, self)
					vjs.append(vjoint.j)
			bonesprocessing.append_array(vjs)
			bonesvisited.append_array(vjs)

func _process(delta):
	if not disableverlet:
		verletrun()
		verletrun()

func _ready():
	#var bonestickscene = load("res://manualposemaker/pickablebonestick.tscn")
	var bonestickscene = load("res://manualposemaker/vpickablebonestick.tscn")
	var bonesticknode = $ExampleBoneStick
	#remove_child(bonesticknode)
	for j in range(skel.get_bone_count()):
		var rj = bonestickscene.instantiate()
		#rj.get_node("CollisionShape3D").shape = rj.get_node("CollisionShape3D").shape.duplicate()
		#rj.get_node("MeshInstance3D").mesh = rj.get_node("MeshInstance3D").mesh.duplicate()
		rj.name = "bonestick%d" % j
		rj.picked_up.connect(onbonestickpickedup)
		rj.dropped.connect(onbonestickdropped)
		add_child(rj)
		if skel.get_bone_parent(j) != -1:
			var vjoint = VerletJoint.new()
			vjoint.init(j, skel, self)
			vjoints.push_back(vjoint)
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


