extends Node3D

# Corresponds to each bone, holds the vectors to parent and child joints from its inerrtial centre 
class SolidGeonGroups:
	var geonunits = [ ]

	var bonequat0 : Quaternion
	var bonecentre0 : Vector3
	var geonunitsremotetransforms = [ ]

	var geonmass : float
	var nextboneunitbyjoints = [ ]
	
	# [ { jointvector, nextboneunit, nextboneunitjoint } ]
	# should be nextsolidgeongroup, nextsolidgeongroupjoint, but for historical reasons
	var nextboneunitjoints = [ ]
	var hingetoparentaxis = null 
	
	func setgeonunits(lgeonunits, lgeonunittransforms):
		geonunits = lgeonunits
		assert (len(geonunits) == len(lgeonunittransforms))
		geonmass = 0.0
		var boneunitjointspos = [  ]
		var sumboneunitjointpos = Vector3()
		for gn in geonunits:
			# the gn.transform should come from the remote linkstransforms to keep it rigid
			if gn.jointobjectbottom != null:
				assert (gn.jointobjectbottom.jointobjecttop == gn or gn.jointobjectbottom.jointobjectbottom == gn)
				nextboneunitbyjoints.append(gn.jointobjectbottom)
				boneunitjointspos.append(gn.transform*Vector3(0,-gn.rodlength/2,0))
				sumboneunitjointpos += boneunitjointspos[-1]
			if gn.jointobjecttop != null:
				assert (gn.jointobjecttop.jointobjecttop == gn or gn.jointobjecttop.jointobjectbottom == gn)
				nextboneunitbyjoints.append(gn.jointobjecttop)
				boneunitjointspos.append(gn.transform*Vector3(0,gn.rodlength/2,0))
				sumboneunitjointpos += boneunitjointspos[-1]
			geonmass += gn.rodlength + gn.rodradtop + gn.rodradbottom

		bonequat0 = geonunits[0].transform.basis.get_rotation_quaternion()
		bonecentre0 = sumboneunitjointpos/len(nextboneunitbyjoints)
		for i in range(len(nextboneunitbyjoints)):
			var jointvectorabs = boneunitjointspos[i] - bonecentre0
			nextboneunitjoints.append({ "jointvector":bonequat0.inverse()*jointvectorabs })

		geonunitsremotetransforms = [ ]
		var butr = Transform3D(bonequat0, bonecentre0).inverse()*geonunits[0].transform
		for gut in lgeonunittransforms:
			geonunitsremotetransforms.append(butr*gut)


# the generated interlink of groups of geons and their joints
var solidgeonunits = [ ]
var geonstogroups = { }

func invalidategeonunits():
	solidgeonunits = [ ]
	geonstogroups = { }
	bonejointsequence = [ ]
	fixedboneslist = [ ]
	bonejointseqjstart = -1

func makegeongroupsIfInvalid(geonobjects):
	if solidgeonunits and len(solidgeonunits) == len(geonstogroups):
		return
	solidgeonunits = [ ]
	geonstogroups = { }
	for gn0 in geonobjects:
		if not geonstogroups.has(gn0):
			var geonunits = [ gn0 ]
			var geonunittransforms = [ Transform3D() ]
			var gn = gn0
			var sgg = SolidGeonGroups.new()
			geonstogroups[gn0] = sgg
			while gn.lockedobjectnext != gn0:
				geonunittransforms.append(geonunittransforms[-1]*gn.lockedtransformnext)
				gn = gn.lockedobjectnext
				geonunits.append(gn)
				geonstogroups[gn] = sgg
			var Dgntrans0 = geonunittransforms[-1]*gn.lockedtransformnext
			assert (Dgntrans0.is_equal_approx(geonunittransforms[0]))
			
			sgg.setgeonunits(geonunits, geonunittransforms)
			solidgeonunits.append(sgg)

	# create the link backs between the sggs from the boneunit linkbacks
	for sgg in solidgeonunits:
		for i in range(len(sgg.nextboneunitbyjoints)):
			var sggbuj = sgg.nextboneunitbyjoints[i]
			var sggj = geonstogroups[sggbuj]
			sgg.nextboneunitjoints[i]["nextboneunit"] = solidgeonunits.find(sggj)
			assert (sgg.nextboneunitjoints[i]["nextboneunit"] >= 0)

			var backjointindex = -1
			for gn in sgg.geonunits:
				var lbackjointindex = sggj.nextboneunitbyjoints.find(gn)
				if lbackjointindex != -1:
					assert (backjointindex == -1)
					backjointindex = lbackjointindex
			assert (backjointindex != -1)
			sgg.nextboneunitjoints[i]["nextboneunitjoint"] = backjointindex
	pass
	

# Corresponds to the sequence of joints map forward froom boneunit to boneunit 
class SolidGeonJointEl:
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

	var isconstorientation : bool
	var hingejointaxis = null

	func derivebointjointcentre(prevquat, prevcentre, quat):
		var jointpos = prevcentre + prevquat*prevbonejointvector
		return jointpos - quat*incomingbonejointvector
	
var bonejointsequence = [ ]
var bonejointseqjstart = -1
var fixedboneslist = [ ]

func derivejointsequenceIfNecessary(geonheld):
	var jstart = solidgeonunits.find(geonstogroups[geonheld])
	assert (jstart >= 0)
	if len(bonejointsequence) != 0 and bonejointseqjstart == jstart:
		return false
	bonejointsequence = [ ]
	fixedboneslist = [ jstart ]

	var boneunitsvisited = [ jstart ]
	var boneunitsvisitedProcessed = 0
	while boneunitsvisitedProcessed < len(boneunitsvisited):
		var j = boneunitsvisited[boneunitsvisitedProcessed]
		var bu = solidgeonunits[j]
		for i in range(len(bu.nextboneunitjoints)):
			if not bu.nextboneunitjoints[i].has("nextboneunit"):
				continue
			var bnti = bu.nextboneunitjoints[i]
			var nj = bnti["nextboneunit"]
			if boneunitsvisited.has(nj):
				continue

			var bje = SolidGeonJointEl.new()
			bje.prevboneunitindex = j
			bje.prevjointindex = i
			bje.prevbonejointvector = bnti["jointvector"]

			var bunext = solidgeonunits[nj]
			bje.incomingjointindex = bu.nextboneunitjoints[i]["nextboneunitjoint"]
			var bntinext = bunext.nextboneunitjoints[bje.incomingjointindex]
			bje.boneunitindex = nj
			bje.incomingbonejointvector = bntinext["jointvector"]
			assert (bntinext["nextboneunit"] == j and bntinext["nextboneunitjoint"] == i)

			# initialize at original position
			bje.propbonequat = bunext.bonequat0
			bje.propbonecentre = bunext.bonecentre0

			# back joint pointers and forward dependence joints list
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
	assert (len(bonejointsequence) == 0 or bonejointsequence[0].prevboneunitindex == jstart)
	return true

func sgcalcbonecentresfromquatsE():
	var Ergsum = 0.0
	for i in range(len(bonejointsequence)):
		var bje = bonejointsequence[i]
		var prevcentre
		var prevquat
		if bje.prevbonejointel == -1:
			var bu0 = solidgeonunits[bonejointsequence[0].prevboneunitindex]
			prevcentre = bu0.bonecentre0
			prevquat = bu0.bonequat0
		else:
			prevcentre = bonejointsequence[bje.prevbonejointel].propbonecentre
			prevquat = bonejointsequence[bje.prevbonejointel].propbonequat
		var bu = solidgeonunits[bje.boneunitindex]
		if bje.isconstorientation:
			bje.propbonequat = bu.bonequat0

		bje.propbonecentre = bje.derivebointjointcentre(prevquat, prevcentre, bje.propbonequat)
		Ergsum += bu.geonmass*(bje.propbonecentre - bu.bonecentre0).length_squared()
	return Ergsum


func Dcheckbonejoints():
	var sggtrs = [ ]
	for j in range(len(solidgeonunits)):
		var bu = solidgeonunits[j]
		sggtrs.append(Transform3D(bu.bonequat0, bu.bonecentre0))

	for i in range(len(bonejointsequence)):
		var bje = bonejointsequence[i]
		var bu = solidgeonunits[bje.boneunitindex]
		sggtrs[bje.boneunitindex] = Transform3D(bje.propbonequat, bje.propbonecentre)
	for j in range(len(solidgeonunits)):
		var bu = solidgeonunits[j]
		for i in range(len(bu.nextboneunitjoints)):
			var bunj = bu.nextboneunitjoints[i]
			var jointpos = sggtrs[j]*bunj["jointvector"]
			var nj = bunj["nextboneunit"]
			var bujo = solidgeonunits[nj]
			var bujoj = bujo.nextboneunitjoints[bunj["nextboneunitjoint"]]
			assert (bujoj["nextboneunit"] == j)
			assert (bujoj["nextboneunitjoint"] == i)
			var jointposN = sggtrs[nj]*bujoj["jointvector"]
			if not jointpos.is_equal_approx(jointposN):
				print("jointpos not equal ", jointpos - jointposN)
	return true
	
func Dsetfrombonequat0():
	for bu in solidgeonunits:
		var butr = Transform3D(bu.bonequat0, bu.bonecentre0)
		for j in range(len(bu.geonunits)):
			bu.geonunits[j].transform = butr*bu.geonunitsremotetransforms[j]
	
func sgseebonequatscentres(bapply):
	for i in range(len(bonejointsequence)):
		var bje = bonejointsequence[i]
		var bu = solidgeonunits[bje.boneunitindex]
		var butr = Transform3D(bje.propbonequat, bje.propbonecentre)
		for j in range(len(bu.geonunits)):
			bu.geonunits[j].transform = butr*bu.geonunitsremotetransforms[j]
		if bapply:
			bu.bonequat0 = bje.propbonequat
			bu.bonecentre0 = bje.propbonecentre

func copybacksolidedgeunit0(geonobject):
	var bu = geonstogroups[geonobject]
	var j = bu.geonunits.find(geonobject)
	assert (j >= 0)
	var butr = bu.geonunits[j].transform*bu.geonunitsremotetransforms[j].inverse()
	bu.bonequat0 = butr.basis.get_rotation_quaternion()
	bu.bonecentre0 = butr.origin

	
	
func calcEsinglequat(k, kaddpropbonequat):
	var koverridepropbonequat = bonejointsequence[k].propbonequat*kaddpropbonequat
	var bjeK = bonejointsequence[k]
	var prevcentre
	var prevquat
	if bjeK.prevbonejointel == -1:
		var bu0 = solidgeonunits[bjeK.prevboneunitindex]
		prevcentre = bu0.bonecentre0
		prevquat = bu0.bonequat0
	else:
		var bjeprev = bonejointsequence[bjeK.prevbonejointel]
		prevcentre = bjeprev.propbonecentre
		prevquat = bjeprev.propbonequat

	# could use overridepropbonequat also to save on the second test against k
	bjeK.overridepropbonecentre = bjeK.derivebointjointcentre(prevquat, prevcentre, koverridepropbonequat)
	var buK = solidgeonunits[bjeK.boneunitindex]
	var Ergsum = buK.geonmass*(bjeK.overridepropbonecentre - buK.bonecentre0).length_squared()
	var Ergorg = buK.geonmass*(bjeK.propbonecentre - buK.bonecentre0).length_squared()
	for i in bjeK.nextboneellist:
		var bje = bonejointsequence[i]
		assert (bje.prevbonejointel != -1)
		var bjeprev = bonejointsequence[bje.prevbonejointel]
		prevcentre = bjeprev.overridepropbonecentre
		prevquat = koverridepropbonequat if bje.prevbonejointel == k else bjeprev.propbonequat 
		bje.overridepropbonecentre = bje.derivebointjointcentre(prevquat, prevcentre, bje.propbonequat)
		var bu = solidgeonunits[bje.boneunitindex]
		Ergsum += bu.geonmass*(bje.overridepropbonecentre - bu.bonecentre0).length_squared()
		Ergorg += bu.geonmass*(bje.propbonecentre - bu.bonecentre0).length_squared()
	return Ergsum - Ergorg


func sgcalcnumericalgradient(eps):
	var qeps = sqrt(1.0 - eps*eps)
	var sumgradEsq = 0.0
	for k in range(len(bonejointsequence)):
		var bjeK = bonejointsequence[k]
		if bjeK.isconstorientation:
			bonejointsequence[k].gradE = Vector3(0,0,0)
		else:
			var gx = calcEsinglequat(k, Quaternion(eps, 0, 0, qeps))
			var gy = calcEsinglequat(k, Quaternion(0, eps, 0, qeps))
			var gz = calcEsinglequat(k, Quaternion(0, 0, eps, qeps))
			var gradE = Vector3(gx, gy, gz)/eps
			bonejointsequence[k].gradE = gradE
			sumgradEsq += gradE.length_squared()
			
	return sumgradEsq

func calcEgraddelta(delta):
	var Ergsum = 0.0
	for i in range(len(bonejointsequence)):
		var bje = bonejointsequence[i]

		var prevcentre
		var prevquat
		if bje.prevbonejointel == -1:
			var bu0 = solidgeonunits[bje.prevboneunitindex]
			prevcentre = bu0.bonecentre0
			prevquat = bu0.bonequat0
		else:
			prevcentre = bonejointsequence[bje.prevbonejointel].overridepropbonecentre
			prevquat = bonejointsequence[bje.prevbonejointel].overridepropbonequat

		var v = bje.gradE*delta

		if bje.hingejointaxis == null:
			var addpropbonequat = Quaternion(v.x, v.y, v.z, sqrt(1.0 - v.length_squared()))
			bje.overridepropbonequat = bje.propbonequat*addpropbonequat
		else:
			var addpropbonequat = Quaternion(v.x, v.y, v.z, sqrt(1.0 - v.length_squared()))
			bje.overridepropbonequat = bje.propbonequat*addpropbonequat

		bje.overridepropbonecentre = bje.derivebointjointcentre(prevquat, prevcentre, bje.overridepropbonequat)
		
		var bu = solidgeonunits[bje.boneunitindex]
		Ergsum += bu.geonmass*(bje.overridepropbonecentre - bu.bonecentre0).length_squared()
	return Ergsum


var DDEd = 0
func sgmakegradstep(Ni):
	var E0 = sgcalcbonecentresfromquatsE()
	var sumgradEsq = sgcalcnumericalgradient(0.0001)

	var c = 0.5
	var tau = 0.5
	var delta = 0.2
	
	if Ni == 10 or Ni == 100 or Ni == 1000 or Ni == 9000:
		print(Ni, " ", E0, " g", sumgradEsq)
	
	for ii in range(10):
		var DEd = calcEgraddelta(-delta)
		#print(" ", ii, " ", delta, "  ", DEd, "  E0 ", E0)
		DDEd = DEd
		if DEd < E0 - delta*c*sumgradEsq:
			for i in range(len(bonejointsequence)):
				var bje = bonejointsequence[i]
				bje.propbonequat = bje.overridepropbonequat
				bje.propbonecentre = bje.overridepropbonecentre
			return true
		delta = delta*tau
	#print("Bailing out at step ", Ni, " E0 ", E0)
	return false


func setisconstorientation(constrainedbones):
	var constrainedsgindexes = [ ]
	for j in range(1, len(constrainedbones)):
		var sggj = geonstogroups[constrainedbones[j]]
		constrainedsgindexes.append(solidgeonunits.find(sggj))
	for i in range(len(bonejointsequence)):
		var bje = bonejointsequence[i]
		assert (bonejointsequence[0].prevboneunitindex != bje.boneunitindex)
		bje.isconstorientation = constrainedsgindexes.has(bje.boneunitindex)


