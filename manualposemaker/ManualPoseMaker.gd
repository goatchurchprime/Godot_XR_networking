extends Node3D

@onready var skel = get_node("../redoran3/MonsterArmature/Skeleton3D")
var bonestickscene = load("res://manualposemaker/vpickablebonestick.tscn")

var boneunits = [ ]

class BoneUnit:
	var boneindex : int
	var bonestick : Node
	var bonecentre : Vector3
	var bonequat : Quaternion
	var bonemass : float
	var nextboneunitjoints = [ ] # [ { jointvector, nextboneunit, nextboneunitjointindex } ]

func _ready():
	for j in range(skel.get_bone_count()):
		var bu = BoneUnit.new()
		bu.boneindex = j
		var jparent = skel.get_bone_parent(j)
		if jparent != -1:
			bu.nextboneunitjoints = [ { "nextboneunit":jparent, "nextboneunitjoint":skel.get_bone_children(jparent).find(j) }]
		else:
			bu.nextboneunitjoints = [ { } ]
		var buc = skel.get_bone_children(j)
		for k in range(len(buc)):
			bu.nextboneunitjoints.push_back({ "nextboneunit":buc[k], "nextboneunitjoint":0 })
		boneunits.push_back(bu)
		
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		var bonejoint0 = skel.global_transform*skel.get_bone_global_pose(bu.boneindex)
		bu.bonequat = bonejoint0.basis.get_rotation_quaternion()
		var boneunitjointspos = [ bonejoint0.origin ]
		var sumboneunitjointpos = bonejoint0.origin
		for i in range(1, len(bu.nextboneunitjoints)):
			var jchild = boneunits[bu.nextboneunitjoints[i]["nextboneunit"]].boneindex
			var bonejointj = bonejoint0*skel.get_bone_pose(jchild) 
			assert (bonejointj.is_equal_approx(skel.global_transform*skel.get_bone_global_pose(jchild)))
			boneunitjointspos.push_back(bonejointj.origin)
			sumboneunitjointpos += bonejointj.origin
		bu.bonecentre = sumboneunitjointpos/len(bu.nextboneunitjoints)
		var sumbonelengths = 0.0
		for i in range(len(bu.nextboneunitjoints)):
			bu.nextboneunitjoints[i]["jointvector"] = boneunitjointspos[i] - bu.bonecentre
			bu.bonemass += bu.nextboneunitjoints[i]["jointvector"].length()
		if len(bu.nextboneunitjoints) <= (2 if not bu.nextboneunitjoints[0].has("nextboneunit") else 1):
			print("bonemass 0 on unit ", j)
			bu.bonemass = 0.0

	for j in range(len(boneunits)):
		var bu = boneunits[j]
		if bu.bonemass != 0.0:
			var rj = bonestickscene.instantiate()
			rj.name = "bonestick%d" % j
			rj.picked_up.connect(onbonestickpickedup)
			rj.dropped.connect(onbonestickdropped)
			var vpb = bu.nextboneunitjoints[1]["jointvector"] - bu.nextboneunitjoints[0]["jointvector"]
			print(j, " ", len(bu.nextboneunitjoints), "  ", Basis(bu.bonequat).inverse()*vpb)
			var vpblen = vpb.length()
			rj.get_node("CollisionShape3D").shape.size.y = vpblen*1.8
			rj.get_node("MeshInstance3D").mesh.size.y = vpblen*0.9
			add_child(rj)
			bu.bonestick = rj
			bu.bonestick.transform = Transform3D(bu.bonequat, bu.bonecentre)


func minenergymove(jmoved):
	print("minenergymove(jmoved)")


var pickedbones = [ ]
func onbonestickpickedup(b):
	print("pickup ", b.get_path())
	pickedbones.append(b.name.to_int())
func onbonestickdropped(b):
	print("drop ", b.name, "  ", b.name.to_int()*1000)
	var jdropped = b.name.to_int()
	pickedbones.erase(jdropped)
	if len(pickedbones) == 0:
		minenergymove(jdropped)

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_P:
				get_node("bonestick7").transform.origin.x += 0.1
				minenergymove(7)
