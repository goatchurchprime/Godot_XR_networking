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
			bu.nextboneunitjoints = [ { "nextboneunit":jparent, "nextboneunitjoint":skel.get_bone_children(jparent).find(j)+1 }]
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
			var jointvectorabs = boneunitjointspos[i] - bu.bonecentre
			bu.nextboneunitjoints[i]["jointvector"] = bu.bonequat.inverse()*jointvectorabs
			bu.bonemass += jointvectorabs.length()
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
			#print(j, " ", len(bu.nextboneunitjoints), "  ", Basis(bu.bonequat).inverse()*vpb)
			var vpblen = vpb.length()
			rj.get_node("CollisionShape3D").shape.size.y = vpblen*1.8
			rj.get_node("MeshInstance3D").mesh.size.y = vpblen*0.9
			add_child(rj)
			bu.bonestick = rj
			bu.bonestick.transform = Transform3D(bu.bonequat, bu.bonecentre)


var propbonequats = [ ]
var propbonedisplacements = [ ]
var bonejointsequence = [ ]  # [ [ boneunitindexj, nextjointindex ], ... ]

func calcbonedisplacementsfromquats():
	for i in range(len(bonejointsequence)):
		var j = bonejointsequence[i][0]
		var nextjointindex = bonejointsequence[i][1]
		var bu = boneunits[j]
		var buquat = bu.bonequat*propbonequats[j]
		var bucentre = bu.bonecentre + propbonedisplacements[j]
		var nexjnt = bu.nextboneunitjoints[nextjointindex]
		var jointpos = bucentre + buquat*nexjnt["jointvector"]
		var jnext = nexjnt["nextboneunit"]
		var bunext = boneunits[jnext]
		var nexjntback = bunext.nextboneunitjoints[nexjnt["nextboneunitjoint"]]
		assert (nexjntback["nextboneunit"] == j and nexjntback["nextboneunitjoint"] == nextjointindex)
		var bunextquat = bunext.bonequat*propbonequats[jnext]
		var bunextgcentre = jointpos - bunextquat*nexjntback["jointvector"]
		propbonedisplacements[jnext] = bunextgcentre - bunext.bonecentre
	print(propbonedisplacements)

func applybonequatsdisplacements():
	propbonequats = [ ]
	for j in range(len(boneunits)):
		propbonequats.push_back(Quaternion())
		propbonedisplacements.push_back(Vector3())
		var bu = boneunits[j]
		if bu.bonestick != null:
			bu.bonequat = bu.bonequat*propbonequats[j]
			bu.bonecentre = bu.bonecentre + propbonedisplacements[j]
			bu.bonestick.transform = Transform3D(bu.bonequat, bu.bonecentre)

func minenergymove(jmoved):
	propbonequats = [ ]
	propbonedisplacements = [ ]
	for j in range(len(boneunits)):
		propbonequats.push_back(Quaternion())
		propbonedisplacements.push_back(Vector3())

	boneunits[jmoved].bonequat = boneunits[jmoved].bonestick.transform.basis.get_rotation_quaternion()
	boneunits[jmoved].bonecentre = boneunits[jmoved].bonestick.transform.origin
	propbonequats[jmoved] = Quaternion()
	propbonedisplacements[jmoved] = Vector3(0,0,0)
	
	var boneunitsvisited = [ jmoved ]
	var boneunitsvisitedProcessed = 0
	while boneunitsvisitedProcessed < len(boneunitsvisited):
		var bu = boneunits[boneunitsvisited[boneunitsvisitedProcessed]]
		for i in range(len(bu.nextboneunitjoints)):
			if bu.nextboneunitjoints[i].has("nextboneunit"):
				var ni = bu.nextboneunitjoints[i]["nextboneunit"]
				if not boneunitsvisited.has(ni):
					bonejointsequence.push_back([bu.boneindex, i])
					boneunitsvisited.push_back(ni)
		boneunitsvisitedProcessed += 1
		
	calcbonedisplacementsfromquats()
	applybonequatsdisplacements()

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
