extends Node3D

@onready var skel = get_node("../redoran3/MonsterArmature/Skeleton3D")
var bonestickscene = load("res://manualposemaker/vpickablebonestick.tscn")


# Then ready to extend to two hand holding.
# Move the image back

# Ability to fabricate connections to these bones on the fly 
# and connect to your head or hands


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
#var propbonequats = [ ]
#var propbonecentres = [ ]


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
	var overridepropbonequat : Quaternion
	var gradE : Vector3

	func derivebointjointcentre(prevquat, prevcentre, quat):
		var jointpos = prevcentre + prevquat*prevbonejointvector
		return jointpos - quat*incomingbonejointvector

	
var bonejointsequence = null
var fixedboneslist = [ ]
var bonejointseqstartticks = 0

func calcbonecentresfromquatsE():
	var Ergsum = 0.0
	for i in range(len(bonejointsequence)):
		var bje = bonejointsequence[i]
		var prevcentre
		var prevquat
		if bje.prevbonejointel == -1:
			var bu0 = boneunits[bonejointsequence[0].prevboneunitindex]
			prevcentre = bu0.bonecentre0
			prevquat = bu0.bonequat0
		else:
			prevcentre = bonejointsequence[bje.prevbonejointel].propbonecentre
			prevquat = bonejointsequence[bje.prevbonejointel].propbonequat
		bje.propbonecentre = bje.derivebointjointcentre(prevquat, prevcentre, bje.propbonequat)
		var bu = boneunits[bje.boneunitindex]
		Ergsum += bu.bonemass*(bje.propbonecentre - bu.bonecentre0).length_squared()
	return Ergsum

func calcEsinglequat(k, kaddpropbonequat):
	var koverridepropbonequat = bonejointsequence[k].propbonequat*kaddpropbonequat
	var bjeK = bonejointsequence[k]
	var prevcentre
	var prevquat
	if bjeK.prevbonejointel == -1:
		var bu0 = boneunits[bjeK.prevboneunitindex]
		prevcentre = bu0.bonecentre0
		prevquat = bu0.bonequat0
	else:
		var bjeprev = bonejointsequence[bjeK.prevbonejointel]
		prevcentre = bjeprev.propbonecentre
		prevquat = bjeprev.propbonequat

	# could use overridepropbonequat also to save on the second test against k
	bjeK.overridepropbonecentre = bjeK.derivebointjointcentre(prevquat, prevcentre, koverridepropbonequat)
	var buK = boneunits[bjeK.boneunitindex]
	var Ergsum = buK.bonemass*(bjeK.overridepropbonecentre - buK.bonecentre0).length_squared()
	var Ergorg = buK.bonemass*(bjeK.propbonecentre - buK.bonecentre0).length_squared()
	for i in bjeK.nextboneellist:
		var bje = bonejointsequence[i]
		assert (bje.prevbonejointel != -1)
		var bjeprev = bonejointsequence[bje.prevbonejointel]
		prevcentre = bjeprev.overridepropbonecentre
		prevquat = koverridepropbonequat if bje.prevbonejointel == k else bjeprev.propbonequat 
		bje.overridepropbonecentre = bje.derivebointjointcentre(prevquat, prevcentre, bje.propbonequat)
		var bu = boneunits[bje.boneunitindex]
		Ergsum += bu.bonemass*(bje.overridepropbonecentre - bu.bonecentre0).length_squared()
		Ergorg += bu.bonemass*(bje.propbonecentre - bu.bonecentre0).length_squared()
	return Ergsum - Ergorg


func calcEgraddelta(delta):
	var Ergsum = 0.0
	for i in range(len(bonejointsequence)):
		var bje = bonejointsequence[i]

		var prevcentre
		var prevquat
		if bje.prevbonejointel == -1:
			var bu0 = boneunits[bje.prevboneunitindex]
			prevcentre = bu0.bonecentre0
			prevquat = bu0.bonequat0
		else:
			prevcentre = bonejointsequence[bje.prevbonejointel].overridepropbonecentre
			prevquat = bonejointsequence[bje.prevbonejointel].overridepropbonequat

		var v = bje.gradE*delta
		var addpropbonequat = Quaternion(v.x, v.y, v.z, sqrt(1.0 - v.length_squared()))
		bje.overridepropbonequat = bje.propbonequat*addpropbonequat
		bje.overridepropbonecentre = bje.derivebointjointcentre(prevquat, prevcentre, bje.overridepropbonequat)
		var bu = boneunits[bje.boneunitindex]
		Ergsum += bu.bonemass*(bje.overridepropbonecentre - bu.bonecentre0).length_squared()
	return Ergsum



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


func seebonequatscentres(bapply):
	for i in range(len(bonejointsequence)):
		var bje = bonejointsequence[i]
		var bu = boneunits[bje.boneunitindex]
		if bu.bonestick != null:
			bu.bonestick.transform = Transform3D(bje.propbonequat, bje.propbonecentre)
		if bapply:
			bu.bonequat0 = bje.propbonequat
			bu.bonecentre0 = bje.propbonecentre


func calcnumericalgradient(eps):
	var qeps = sqrt(1.0 - eps*eps)
	var sumgradEsq = 0.0
	for k in range(len(bonejointsequence)):
		var gx = calcEsinglequat(k, Quaternion(eps, 0, 0, qeps))
		var gy = calcEsinglequat(k, Quaternion(0, eps, 0, qeps))
		var gz = calcEsinglequat(k, Quaternion(0, 0, eps, qeps))
		var gradE = Vector3(gx, gy, gz)/eps
		bonejointsequence[k].gradE = gradE
		sumgradEsq += gradE.length_squared()
	return sumgradEsq


func derivejointsequence(jstart):
	bonejointsequence = [ ]
	fixedboneslist = [ jstart ]
	bonejointseqstartticks = Time.get_ticks_usec()

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
					bje.propbonequat = bunext.bonequat0
					bje.propbonecentre = bunext.bonecentre0

					var backbonejointel = len(bonejointsequence) - 1
					while backbonejointel >= 0:
						if bonejointsequence[backbonejointel].boneunitindex == bje.prevboneunitindex:
							break
						backbonejointel -= 1
					bje.prevbonejointel = backbonejointel
					bje.nextboneellist = [ ]
					var cbonejointel = len(bonejointsequence)
					while backbonejointel >= 0:
						bonejointsequence[backbonejointel].nextboneellist.push_back(cbonejointel)
						backbonejointel = bonejointsequence[backbonejointel].prevbonejointel
					bonejointsequence.push_back(bje)
					boneunitsvisited.push_back(nj)
		boneunitsvisitedProcessed += 1



func minenergymove(pickedbones):
	var jmoved = pickedbones[0]
	derivejointsequence(jmoved)
	boneunits[jmoved].bonequat0 = boneunits[jmoved].bonestick.transform.basis.get_rotation_quaternion()
	boneunits[jmoved].bonecentre0 = boneunits[jmoved].bonestick.transform.origin

	var t0 = Time.get_ticks_usec()
	for i in range(10):
		var bstepped = makegradstep(i)
		var t1 = Time.get_ticks_usec()
		if not bstepped:
			break
		#seebonequatscentres(false)
		#await get_tree().create_timer(0.1).timeout
		print("Ticks ", t1 - t0)
		t0 = t1
	seebonequatscentres(true)
	setboneposefromunits()
	bonejointsequence = null


func makegradstep(Ni):
	var E0 = calcbonecentresfromquatsE()
	var sumgradEsq = calcnumericalgradient(0.0001)

	var c = 0.5
	var tau = 0.5
	var delta = 0.2
	
	if Ni == 10 or Ni == 100 or Ni == 1000 or Ni == 9000:
		print(Ni, " ", E0, " g", sumgradEsq)
	
	for ii in range(10):
		var DEd = calcEgraddelta(-delta)
		if DEd < E0 - delta*c*sumgradEsq:
			for i in range(len(bonejointsequence)):
				var bje = bonejointsequence[i]
				bje.propbonequat = bje.overridepropbonequat
				bje.propbonecentre = bje.overridepropbonecentre
			return true
		delta = delta*tau
	print("Bailing out at step ", Ni)
	return false

var pickedbones = [ ]
var allpickedbones = [ ]
func onbonestickpickedup(b):
	var jpicked = b.name.to_int()
	print("pickup ", b.get_path())
	pickedbones.push_back(jpicked)
	allpickedbones.erase(jpicked)
	allpickedbones.push_back(jpicked)

var bupdatefinalondrop = false
func onbonestickdropped(b):
	print("drop ", b.name, "  ", b.name.to_int()*1000)
	var jdropped = b.name.to_int()
	pickedbones.erase(jdropped)
	if len(pickedbones) == 0:
		if bupdatefinalondrop:
			minenergymove(allpickedbones)
		allpickedbones = [ ]

var Pjpickedbone = -1
func _physics_process(delta):
	if bupdatefinalondrop:
		return
	var physt0 = Time.get_ticks_usec()
	if len(allpickedbones) and allpickedbones[0] != Pjpickedbone:
		Pjpickedbone = allpickedbones[0]
		derivejointsequence(Pjpickedbone)
		bonejointseqstartticks = physt0
		
	if allpickedbones.has(Pjpickedbone):
		boneunits[Pjpickedbone].bonequat0 = boneunits[Pjpickedbone].bonestick.transform.basis.get_rotation_quaternion()
		boneunits[Pjpickedbone].bonecentre0 = boneunits[Pjpickedbone].bonestick.transform.origin
		
	if bonejointsequence != null:
		var bEndIteration = false
		for Ci in range(10):
			var bstepped = makegradstep(Ci)
			if not bstepped:
				bEndIteration = true
				break
			var physt = Time.get_ticks_usec()
			if physt - bonejointseqstartticks > 200000:
				bEndIteration = true
				break
			if physt - physt0 > 20000:
				break
		if bEndIteration:
			seebonequatscentres(true)
			setboneposefromunits()
			if Pjpickedbone == -1:
				bonejointsequence = null


var Ddd = 0
func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_P:
				if Ddd < 3:
					get_node("bonestick7").transform.origin.z += 0.1
				else:
					get_node("bonestick7").transform.origin.z += -0.01
				Ddd += 1
				minenergymove([7])
				
			if event.keycode == KEY_O:
				var bonetomove = get_node("bonestick7")
				onbonestickpickedup(bonetomove)
				for i in range(10):
					bonetomove.transform.origin.z += 0.01
					await get_tree().create_timer(0.1).timeout
				onbonestickdropped(bonetomove)

