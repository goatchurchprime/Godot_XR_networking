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
var propbonedeltaquats = [ ] 
var propbonedisplacements = [ ]
var bonejointsequence = [ ]  # [ [ boneunitindexj, nextjointindex ], ... ]

# Set a tiny propbonedeltaquats for each rotation parameter and calculate the energy differential numerically

# interpolate in the direction of that quat gradient descent to find a lower value

# Iterate this process on a keystroke

# (also minimize against a sum including moment of inertia energy for a rod)

# If it works, then do the direct calculation of the differential

# leave the iterations going in a process

# apply iterations on dragging as well, perhaps

# map back to pose of the dinosaur

func calcbonedisplacementsfromquats(lpropbonequats):
	var lpropbonedisplacements = [ ]
	for j in range(len(boneunits)):
		lpropbonedisplacements.push_back(Vector3())

	for i in range(len(bonejointsequence)):
		var j = bonejointsequence[i][0]
		var nextjointindex = bonejointsequence[i][1]
		var bu = boneunits[j]
		var buquat = bu.bonequat*lpropbonequats[j]
		var bucentre = bu.bonecentre + lpropbonedisplacements[j]
		var nexjnt = bu.nextboneunitjoints[nextjointindex]
		var jointpos = bucentre + buquat*nexjnt["jointvector"]
		var jnext = nexjnt["nextboneunit"]
		var bunext = boneunits[jnext]
		var nexjntback = bunext.nextboneunitjoints[nexjnt["nextboneunitjoint"]]
		assert (nexjntback["nextboneunit"] == j and nexjntback["nextboneunitjoint"] == nextjointindex)
		var bunextquat = bunext.bonequat*lpropbonequats[jnext]
		var bunextgcentre = jointpos - bunextquat*nexjntback["jointvector"]
		lpropbonedisplacements[jnext] = bunextgcentre - bunext.bonecentre
	return lpropbonedisplacements

func calcboneenergy(lpropbonedisplacements):
	var E = 0.0
	for j in range(len(boneunits)):
		E += boneunits[j].bonemass*lpropbonedisplacements[j].length_squared()
	return E


func seebonequatsdisplacements(lpropbonedisplacements, lpropbonequats, bapply):
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		var lbonequat = bu.bonequat*lpropbonequats[j]
		var lbonecentre = bu.bonecentre + lpropbonedisplacements[j]
		if bu.bonestick != null:
			bu.bonestick.transform = Transform3D(lbonequat, lbonecentre)
		if bapply:
			bu.bonequat = lbonequat
			lpropbonequats[j] = Quaternion()
			bu.bonecentre = lbonecentre
			lpropbonedisplacements[j] = Vector3()

func applyeps(lpropbonequats, di, eps):
	var llpropbonequats = lpropbonequats.duplicate()
	var w = sqrt(1 - eps*eps)
	var di3 = di%3
	var diI = int(di/3)
	var qeps = Quaternion(eps, 0, 0, w)
	if di3 == 1:
		qeps = Quaternion(0, eps, 0, w)
	if di3 == 2:
		qeps = Quaternion(0, 0, eps, w)
	llpropbonequats[diI] = lpropbonequats[diI]*qeps
	return llpropbonequats

func numericalgradient(E0, eps):
	var gradv = [ ]
	for di in range(len(boneunits)*3):
		if int(di/3) != Djmoved:
			var lpropbonequats = applyeps(propbonequats, di, eps)
			var lpropbonedisplacements = calcbonedisplacementsfromquats(lpropbonequats)
			var Ed = calcboneenergy(lpropbonedisplacements)
			gradv.push_back((Ed - E0)/eps)
		else:
			gradv.push_back(0.0)
	return gradv
	
func applygvdel(lpropbonequats, gv, delta):
	var llpropbonequats = [ ]
	for j in range(len(boneunits)):
		var qx = gv[j*3]*delta
		var qy = gv[j*3+1]*delta
		var qz = gv[j*3+2]*delta
		var q = Quaternion(qx, qy, qz, sqrt(1 - qx*qx - qy*qy - qz*qz))
		llpropbonequats.push_back(lpropbonequats[j]*q)
	return llpropbonequats


var Djmoved = -1
func minenergymove(jmoved):
	Djmoved = jmoved
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
		
	makegradstep()
	#propbonedisplacements = calcbonedisplacementsfromquats(propbonequats)
	#applybonequatsdisplacements()

func makegradstep():
	propbonedisplacements = calcbonedisplacementsfromquats(propbonequats)
	var E0 = calcboneenergy(propbonedisplacements)
	var gradv = numericalgradient(E0, 0.0001)
	var m = 0.0
	for i in range(len(gradv)):
		m += gradv[i]*gradv[i]
	print("Energy0 ", E0, "  ", m)
	var c = 0.5
	var tau = 0.5
	var delta = 0.2
	
	for i in range(10):
		var lpropbonequats = applygvdel(propbonequats, gradv, -delta)
		var lpropbonedisplacements = calcbonedisplacementsfromquats(lpropbonequats)
		var Ed = calcboneenergy(lpropbonedisplacements)
		print(Ed, " ", delta)
		if Ed < E0 - delta*c*m:
			propbonequats = lpropbonequats
			propbonedisplacements = lpropbonedisplacements
			break
		delta = delta*tau
	seebonequatsdisplacements(propbonedisplacements, propbonequats, false)

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

var Ddd = 0
func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_P:
				if Ddd < 3:
					get_node("bonestick7").transform.origin.x += 0.1
				else:
					get_node("bonestick7").transform.origin.x += -0.1
				Ddd += 1
				minenergymove(7)
			if event.keycode == KEY_O:
				makegradstep()
			if event.keycode == KEY_I:
				seebonequatsdisplacements(propbonedisplacements, propbonequats, true)
				
