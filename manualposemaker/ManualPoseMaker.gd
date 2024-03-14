extends Node3D

@onready var skel = get_node("../redoran3/MonsterArmature/Skeleton3D")
var bonestickscene = load("res://manualposemaker/vpickablebonestick.tscn")

# Two handed holding next
# bonejointsequence should be the order of the boneunits that are pulling from
# the previous unit values (the fixed ones)
# we could make the come from index as members of the boneunit
# and make the calculating of the current bone unit position a member function.
# For 2 joint limiting the previous joint is fully constrained (but for twist)
# and the joint before that is constrained by deflection to end on sphere

# the bone sequence can be computed very quickly, run through of transforms and vectors
# problem is that it's n^2 on the joints due to having to calculate the energy difference per dimension
# this doesn't improve for an analytic differential (still n^2 problem)
# we could try a running sum of doing 3 rot values at once per joint
# also do in order of the bonejointsequence to reduce scan distance by half

# velocities and gravity (feet are heavy).  keyframing the dinosaur.
# through the multiplayer code (as a doppelganger).  Pinning arms and head 
# to the player.  trying to do the nodding of the head

# (also minimize against a sum including moment of inertia energy for a rod)

# If it works, then do the direct calculation of the differential

# apply iterations on dragging as well, perhaps






# we iterate on settings of these searching for the minimum, 
# with a further lpropbonequats value to do the epsilons in different directions
# and then do the backtracking line search samples in the direction of the gradient
var propbonequats = [ ]
var propbonecentres = [ ]


# Corresponds to each bone, holds the vectors to parent and child joints from its inerrtial centre 
class BoneUnit:
	var boneindex : int
	var bonestick : Node
	var bonemass : float
	var nextboneunitjoints = [ ] # [ { jointvector, nextboneunit, nextboneunitjoint } ]

	var bonequat0 : Quaternion
	var bonecentre0 : Vector3

var boneunits = [ ]  # All boneunits for the skeleton


# Corresponds to the sequence of joints map forward froom boneunit to boneunit 
class BoneJointEl:
	var prevboneunitindex : int
	var prevjointindex : int
	var prevbonejointvector : Vector3
	
	var boneunitindex : int
	var incomingjointindex : int
	var incomingbonejointvector : Vector3

	var propbonequat : Quaternion
	var propbonecentre : Vector3
	var prevbonejointel : int
	var nextboneellist 

	var overridepropbonecentre : Vector3
	var gradE : Vector3

	func derivebointjointcentre(prevquat, prevcentre, quat):
		var jointpos = prevcentre + prevquat*prevbonejointvector
		return jointpos - quat*incomingbonejointvector
	
var bonejointsequence = [ ]  # [ [ boneunitindexj, nextjointindex ], ... ]
var Dbonejointsequence = [ ]  # The calculating sequence of Joint elements

# swap this out for calcbonecentresfromquats now it's validated
# then make one that efficiently adds the epsilon steps
# then the main iteration steps.
# try running the iteration live in use (while holding and dragging)
# work on the two point drag (with reduced degrees of freedom)
# pin head to head rod.  
# make it something we wear
func calcbonecentresfromquats(lpropbonequats):
	var lpropbonecentres = [ ]
	for j in range(len(boneunits)):
		lpropbonecentres.push_back(boneunits[j].bonecentre0)
	for i in range(len(Dbonejointsequence)):
		var bje = Dbonejointsequence[i]
		lpropbonecentres[bje.boneunitindex] = bje.derivebointjointcentre(lpropbonequats[bje.prevboneunitindex], lpropbonecentres[bje.prevboneunitindex], lpropbonequats[bje.boneunitindex])
	return lpropbonecentres




func calcbonecentresfromquatsE():
	for i in range(len(Dbonejointsequence)):
		var bje = Dbonejointsequence[i]
		bje.propbonequat = propbonequats[bje.boneunitindex]

	var Ergsum = 0.0
	for i in range(len(Dbonejointsequence)):
		var bje = Dbonejointsequence[i]

		var prevcentre
		var prevquat
		if bje.prevbonejointel == -1:
			var bu0 = boneunits[Dbonejointsequence[0].prevboneunitindex]
			prevcentre = bu0.bonecentre0
			prevquat = bu0.bonequat0
		else:
			prevcentre = Dbonejointsequence[bje.prevbonejointel].propbonecentre
			prevquat = Dbonejointsequence[bje.prevbonejointel].propbonequat

		#bje.propbonequat = propbonequats[bje.boneunitindex]
		bje.propbonecentre = bje.derivebointjointcentre(prevquat, prevcentre, bje.propbonequat)
		var bu = boneunits[bje.boneunitindex]
		Ergsum += bu.bonemass*(bje.propbonecentre - bu.bonecentre0).length_squared()
		#print("  EEE j ", bje.boneunitindex, " ", bje.propbonecentre, (bje.propbonecentre - bu.bonecentre0).length_squared())
	return Ergsum



func calcEsinglequat(k, kaddpropbonequat):
	var koverridepropbonequat = Dbonejointsequence[k].propbonequat*kaddpropbonequat
	var bjeK = Dbonejointsequence[k]
	var prevcentre
	var prevquat
	if bjeK.prevbonejointel == -1:
		var bu0 = boneunits[Dbonejointsequence[0].prevboneunitindex]
		prevcentre = bu0.bonecentre0
		prevquat = bu0.bonequat0
	else:
		var bjeprev = Dbonejointsequence[bjeK.prevbonejointel]
		prevcentre = bjeprev.propbonecentre
		prevquat = bjeprev.propbonequat

	bjeK.overridepropbonecentre = bjeK.derivebointjointcentre(prevquat, prevcentre, koverridepropbonequat)
	var buK = boneunits[bjeK.boneunitindex]
	var Ergsum = buK.bonemass*(bjeK.overridepropbonecentre - buK.bonecentre0).length_squared()
	var Ergorg = buK.bonemass*(bjeK.propbonecentre - buK.bonecentre0).length_squared()
	for i in bjeK.nextboneellist:
		var bje = Dbonejointsequence[i]
		assert (bje.prevbonejointel != -1)
		var bjeprev = Dbonejointsequence[bje.prevbonejointel]
		prevcentre = bjeprev.overridepropbonecentre
		prevquat = koverridepropbonequat if bje.prevbonejointel == k else bjeprev.propbonequat 
		bje.overridepropbonecentre = bje.derivebointjointcentre(prevquat, prevcentre, bje.propbonequat)
		var bu = boneunits[bje.boneunitindex]
		Ergsum += bu.bonemass*(bje.overridepropbonecentre - bu.bonecentre0).length_squared()
		Ergorg += bu.bonemass*(bje.propbonecentre - bu.bonecentre0).length_squared()
	return Ergsum - Ergorg

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



func calcboneenergy(lpropbonecentres):
	var E = 0.0
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		E += bu.bonemass*(lpropbonecentres[j] - bu.bonecentre0).length_squared()
		#print("  EE j ", j, " ", lpropbonecentres[j], (lpropbonecentres[j] - bu.bonecentre0).length_squared())

	return E

func seebonequatscentres(bapply):
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		if bu.bonestick != null:
			bu.bonestick.transform = Transform3D(propbonequats[j], propbonecentres[j])
		if bapply:
			bu.bonequat0 = propbonequats[j]
			bu.bonecentre0 = propbonecentres[j]

func quatfromvec(v):
	var vlensq = v.length_squared()
	return Quaternion(v.x, v.y, v.z, sqrt(1.0 - vlensq))

func applyepsErg(j, v, eps, E0):
	var llpropbonequats = propbonequats.duplicate()
	llpropbonequats[j] = propbonequats[j]*quatfromvec(v*eps)
	var llpropbonecentres = calcbonecentresfromquats(llpropbonequats)
	var Ed = calcboneenergy(llpropbonecentres)
	return (Ed - E0)/eps

func calcnumericalgradient(E0, eps):
	var qeps = sqrt(1.0 - eps*eps)
	var sumgradEsq = 0.0
	for k in range(len(Dbonejointsequence)):
		var gx = calcEsinglequat(k, Quaternion(eps, 0, 0, qeps))
		var gy = calcEsinglequat(k, Quaternion(0, eps, 0, qeps))
		var gz = calcEsinglequat(k, Quaternion(0, 0, eps, qeps))
		var gradE = Vector3(gx, gy, gz)/eps
		Dbonejointsequence[k].gradE = gradE
		sumgradEsq += gradE.length_squared()
	return sumgradEsq

func numericalgradient(E0, eps):
	var gradv = [ ]
	for j in range(len(boneunits)):
		if not Dpickedbones.has(j):
			var gx = applyepsErg(j, Vector3(1,0,0), eps, E0)
			var gy = applyepsErg(j, Vector3(0,1,0), eps, E0)
			var gz = applyepsErg(j, Vector3(0,0,1), eps, E0)
			gradv.push_back(Vector3(gx, gy, gz))
		else:
			gradv.push_back(Vector3(0,0,0))
	return gradv


func applygvdel(gv, delta):
	var llpropbonequats = [ ]
	for j in range(len(boneunits)):
		var q = quatfromvec(gv[j]*delta)
		llpropbonequats.push_back(propbonequats[j]*q)
	return llpropbonequats



func derivejointsequence(jstart):
	var Dbonejointsequence = [ ]
	var boneunitsvisited = [ jstart ]
	var boneunitsvisitedProcessed = 0
	while boneunitsvisitedProcessed < len(boneunitsvisited):
		var j = boneunitsvisited[boneunitsvisitedProcessed]
		var bu = boneunits[j]
		for i in range(len(bu.nextboneunitjoints)):
			if bu.nextboneunitjoints[i].has("nextboneunit"):
				var bnti = bu.nextboneunitjoints[i]
				var nj = bnti["nextboneunit"]
				if not boneunitsvisited.has(nj):
					var bje = BoneJointEl.new()
					bje.prevboneunitindex = j
					bje.prevjointindex = i
					bje.prevbonejointvector = bnti["jointvector"]

					var bunext = boneunits[nj]
					bje.incomingjointindex = bu.nextboneunitjoints[i]["nextboneunitjoint"]
					var bntinext = bunext.nextboneunitjoints[bje.incomingjointindex]
					bje.boneunitindex = nj
					bje.incomingbonejointvector = bntinext["jointvector"]
					assert (bntinext["nextboneunit"] == j and bntinext["nextboneunitjoint"] == i)
		
					# initialize at original position
					bje.propbonequat = bu.bonequat0
					bje.propbonecentre = bu.bonecentre0

					var backbonejointel = len(Dbonejointsequence) - 1
					while backbonejointel >= 0:
						if Dbonejointsequence[backbonejointel].boneunitindex == bje.prevboneunitindex:
							break
						backbonejointel -= 1
					bje.prevbonejointel = backbonejointel
					bje.nextboneellist = [ ]
					var cbonejointel = len(Dbonejointsequence)
					while backbonejointel >= 0:
						Dbonejointsequence[backbonejointel].nextboneellist.push_back(cbonejointel)
						backbonejointel = Dbonejointsequence[backbonejointel].prevbonejointel
					Dbonejointsequence.push_back(bje)
					boneunitsvisited.push_back(nj)
		boneunitsvisitedProcessed += 1
	return Dbonejointsequence

var Dpickedbones = -1
func minenergymove(pickedbones):
	Dpickedbones = pickedbones
	var jmoved = pickedbones[0]


	propbonequats = [ ]
	propbonecentres = [ ]
	for j in range(len(boneunits)):
		propbonequats.push_back(boneunits[j].bonequat0)
		propbonecentres.push_back(boneunits[j].bonecentre0)

	boneunits[jmoved].bonequat0 = boneunits[jmoved].bonestick.transform.basis.get_rotation_quaternion()
	boneunits[jmoved].bonecentre0 = boneunits[jmoved].bonestick.transform.origin
	Dbonejointsequence = derivejointsequence(jmoved)  # replaces the below


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
	#var E0 = calcboneenergy(propbonecentres)
	var E0 = calcbonecentresfromquatsE()
	var gradv = numericalgradient(E0, 0.0001)
	var sumgradEsq = calcnumericalgradient(E0, 0.0001)
	var m = 0.0
	for i in range(len(gradv)):
		m += gradv[i].length_squared()
	print("Energy0 ", E0, "  ", m, " _ ", sumgradEsq)
	var c = 0.5
	var tau = 0.5
	var delta = 0.2
	
	for i in range(10):
		var lpropbonequats = applygvdel(gradv, -delta)
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
var allpickedbones = [ ]
func onbonestickpickedup(b):
	var jpicked = b.name.to_int()
	print("pickup ", b.get_path())
	pickedbones.push_back(jpicked)
	allpickedbones.erase(jpicked)
	allpickedbones.push_back(jpicked)

func onbonestickdropped(b):
	print("drop ", b.name, "  ", b.name.to_int()*1000)
	var jdropped = b.name.to_int()
	pickedbones.erase(jdropped)
	if len(pickedbones) == 0:
		minenergymove(allpickedbones)
		
	allpickedbones = [ ]
	
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
				minenergymove([7])
			if event.keycode == KEY_O:
				makegradstep()
				
