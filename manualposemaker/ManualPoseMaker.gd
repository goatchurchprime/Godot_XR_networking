extends Node3D

@onready var skel = get_node("../redoran3/MonsterArmature/Skeleton3D")
var bonestickscene = load("res://manualposemaker/vpickablebonestick.tscn")

# (also minimize against a sum including moment of inertia energy for a rod)

# If it works, then do the direct calculation of the differential

# apply iterations on dragging as well, perhaps



var boneunits = [ ]

class BoneUnit:
	var boneindex : int
	var bonestick : Node
	var bonemass : float
	var nextboneunitjoints = [ ] # [ { jointvector, nextboneunit, nextboneunitjointindex } ]

	var bonequat0 : Quaternion
	var bonecentre0 : Vector3
	

func setboneposefromunits():
	var sca = skel.global_transform.basis.get_scale()
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		var jtrans = Transform3D(bu.bonequat0, bu.bonecentre0 + bu.bonequat0*bu.nextboneunitjoints[0]["jointvector"])
		var jparent = skel.get_bone_parent(j)
		var ptrans
		if jparent != -1:
			var bup = boneunits[jparent]
			ptrans = Transform3D(bup.bonequat0, bup.bonecentre0 + bup.bonequat0*bup.nextboneunitjoints[0]["jointvector"])
		else:
			ptrans = Transform3D(Quaternion(skel.global_transform.basis), skel.global_transform.origin)
			
		var btrans = ptrans.inverse()*jtrans
#		print(j, skel.get_bone_pose_position(j), btrans.origin/sca)
#		print(j, skel.get_bone_pose_rotation(j), btrans.basis.get_rotation_quaternion())
		skel.set_bone_pose_position(j, btrans.origin/sca)
		skel.set_bone_pose_rotation(j, btrans.basis.get_rotation_quaternion())
	
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
		bu.bonequat0 = bonejoint0.basis.get_rotation_quaternion()
		var boneunitjointspos = [ bonejoint0.origin ]
		var sumboneunitjointpos = bonejoint0.origin
		for i in range(1, len(bu.nextboneunitjoints)):
			var jchild = boneunits[bu.nextboneunitjoints[i]["nextboneunit"]].boneindex
			var bonejointj = bonejoint0*skel.get_bone_pose(jchild) 
			assert (bonejointj.is_equal_approx(skel.global_transform*skel.get_bone_global_pose(jchild)))
			boneunitjointspos.push_back(bonejointj.origin)
			sumboneunitjointpos += bonejointj.origin
		bu.bonecentre0 = sumboneunitjointpos/len(bu.nextboneunitjoints)
		var sumbonelengths = 0.0
		for i in range(len(bu.nextboneunitjoints)):
			var jointvectorabs = boneunitjointspos[i] - bu.bonecentre0
			bu.nextboneunitjoints[i]["jointvector"] = bu.bonequat0.inverse()*jointvectorabs
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
			#print(j, " ", len(bu.nextboneunitjoints), "  ", Basis(bu.bonequat0).inverse()*vpb)
			var vpblen = vpb.length()
			rj.get_node("CollisionShape3D").shape.size.y = vpblen*1.8
			rj.get_node("MeshInstance3D").mesh.size.y = vpblen*0.9
			add_child(rj)
			bu.bonestick = rj
			bu.bonestick.transform = Transform3D(bu.bonequat0, bu.bonecentre0)

	setboneposefromunits()


var bonejointsequence = [ ]  # [ [ boneunitindexj, nextjointindex ], ... ]

var propbonequats = [ ]
var propbonecentres = [ ]



func calcbonecentresfromquats(lpropbonequats):
	var lpropbonecentres = [ ]
	for j in range(len(boneunits)):
		lpropbonecentres.push_back(boneunits[j].bonecentre0)

	for i in range(len(bonejointsequence)):
		var j = bonejointsequence[i][0]
		var nextjointindex = bonejointsequence[i][1]
		var bu = boneunits[j]
		var buquat = lpropbonequats[j]
		var bucentre = lpropbonecentres[j]
		var nexjnt = bu.nextboneunitjoints[nextjointindex]
		var jointpos = bucentre + buquat*nexjnt["jointvector"]
		var jnext = nexjnt["nextboneunit"]
		var bunext = boneunits[jnext]
		var nexjntback = bunext.nextboneunitjoints[nexjnt["nextboneunitjoint"]]
		assert (nexjntback["nextboneunit"] == j and nexjntback["nextboneunitjoint"] == nextjointindex)
		var bunextquat = lpropbonequats[jnext]
		var bunextgcentre = jointpos - bunextquat*nexjntback["jointvector"]
		lpropbonecentres[jnext] = bunextgcentre
	return lpropbonecentres

func calcboneenergy(lpropbonecentres):
	var E = 0.0
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		E += bu.bonemass*(lpropbonecentres[j] - bu.bonecentre0).length_squared()
	return E

func seebonequatscentres(bapply):
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		var lbonequat = propbonequats[j]
		var lbonecentre = propbonecentres[j]
		if bu.bonestick != null:
			bu.bonestick.transform = Transform3D(lbonequat, lbonecentre)
		if bapply:
			bu.bonequat0 = lbonequat
			propbonequats[j] = lbonequat
			bu.bonecentre0 = lbonecentre
			propbonecentres[j] = lbonecentre

func quatfromvec(v):
	var vlensq = v.length_squared()
	return Quaternion(v.x, v.y, v.z, sqrt(1.0 - vlensq))

func applyepsErg(lpropbonequats, j, v, eps, E0):
	var llpropbonequats = lpropbonequats.duplicate()
	llpropbonequats[j] = lpropbonequats[j]*quatfromvec(v*eps)
	var llpropbonecentres = calcbonecentresfromquats(llpropbonequats)
	var Ed = calcboneenergy(llpropbonecentres)
	return (Ed - E0)/eps
	
func numericalgradient(E0, eps):
	var gradv = [ ]
	for j in range(len(boneunits)):
		if j != Djmoved:
			var gx = applyepsErg(propbonequats, j, Vector3(1,0,0), eps, E0)
			var gy = applyepsErg(propbonequats, j, Vector3(0,1,0), eps, E0)
			var gz = applyepsErg(propbonequats, j, Vector3(0,0,1), eps, E0)
			gradv.push_back(Vector3(gx, gy, gz))
		else:
			gradv.push_back(Vector3(0,0,0))
	return gradv
	
func applygvdel(lpropbonequats, gv, delta):
	var llpropbonequats = [ ]
	for j in range(len(boneunits)):
		var q = quatfromvec(gv[j]*delta)
		llpropbonequats.push_back(lpropbonequats[j]*q)
	return llpropbonequats


var Djmoved = -1
func minenergymove(jmoved):
	Djmoved = jmoved
	propbonequats = [ ]
	propbonecentres = [ ]
	for j in range(len(boneunits)):
		propbonequats.push_back(boneunits[j].bonequat0)
		propbonecentres.push_back(boneunits[j].bonecentre0)

	boneunits[jmoved].bonequat0 = boneunits[jmoved].bonestick.transform.basis.get_rotation_quaternion()
	boneunits[jmoved].bonecentre0 = boneunits[jmoved].bonestick.transform.origin
	propbonequats[jmoved] = boneunits[jmoved].bonequat0
	propbonecentres[jmoved] = boneunits[jmoved].bonecentre0
	
	var boneunitsvisited = [ jmoved ]
	bonejointsequence = [ ]
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
		
	for i in range(10):
		makegradstep()
		await get_tree().create_timer(0.1).timeout
	seebonequatscentres(true)
	setboneposefromunits()


func makegradstep():
	propbonecentres = calcbonecentresfromquats(propbonequats)
	var E0 = calcboneenergy(propbonecentres)
	var gradv = numericalgradient(E0, 0.0001)
	var m = 0.0
	for i in range(len(gradv)):
		m += gradv[i].length_squared()
	print("Energy0 ", E0, "  ", m)
	var c = 0.5
	var tau = 0.5
	var delta = 0.2
	
	for i in range(10):
		var lpropbonequats = applygvdel(propbonequats, gradv, -delta)
		var lpropbonecentres = calcbonecentresfromquats(lpropbonequats)
		var Ed = calcboneenergy(lpropbonecentres)
		if Ed < E0 - delta*c*m:
			propbonequats = lpropbonequats
			propbonecentres = lpropbonecentres
			print(Ed, " ", delta)
			break
		delta = delta*tau
	seebonequatscentres(false)

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
					get_node("bonestick7").transform.origin.z += 0.1
				else:
					get_node("bonestick7").transform.origin.z += -0.1
				Ddd += 1
				minenergymove(7)
			if event.keycode == KEY_O:
				makegradstep()
				
