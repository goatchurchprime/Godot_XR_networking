extends Node3D

# Corresponds to each bone, holds the vectors to parent and child joints from its inerrtial centre 
class SolidGeonGroups:
	var geonunits = [ ]
	var geonmass : float
	var nextboneunitjoints = [ ] # [ { jointvector, nextboneunit, nextboneunitjoint } ]  (0th joint is to the parent)
	var hingetoparentaxis = null 
	
	var bonequat0 : Quaternion
	var bonecentre0 : Vector3

var solidgeonunits = [ ]

func makegeongroups(geonobjects):
	solidgeonunits = [ ]
	var scannedgns = [ ]
	for gn0 in geonobjects:
		if not scannedgns.has(gn0):
			var geonunits = [ gn0 ]
			var gn = gn0
			while gn.lockedobjectnext != gn0:
				gn = gn.lockedobjectnext
				geonunits.append(gn)
				scannedgns.append(gn)
			var sgg = SolidGeonGroups.new()
			sgg.geonunits = geonunits
			solidgeonunits.append(sgg)

func createsolidgeonunits(geonobjects, geonheld):
	var i = geonobjects.find(geonheld)
	assert (i >= 0)
	geonobjects[i] = geonobjects[0]
	geonobjects[0] = geonheld
	makegeongroups(geonobjects)
	
"""
func createsolidgeonunits():
	var regex = RegEx.new()
	#regex.compile("(foot|leg|hand) \\.[LR]$")
	regex.compile("(foot|leg|fingers) \\.[LR]$")   # The hand has a twist between the bones

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
		if regex.search(skel.get_bone_name(j)) != null:
			var bup = boneunits[skel.get_bone_parent(j)]
			var quat = bup.bonequat0.inverse() * bu.bonequat0
			print(skel.get_bone_name(j), " ", quat)
			if skel.get_bone_name(j).contains("hand") or skel.get_bone_name(j).contains("fingers"):
				bu.hingetoparentaxis = Vector3(0,0,1)
			else:
				bu.hingetoparentaxis = Vector3(1,0,0)
		else:
			bu.hingetoparentaxis = null
"""
