extends Node3D

var geonobjectclass = load("res://manualposemaker/pickablegeon.tscn")

var selectedlocktarget = null

func makecontextmenufor(target, pt):
	if heldgeons:
		print("no context menu when holding")
		return [ ]
	if is_instance_valid(target) and target.has_method("contextmenucommands"):
		var res = target.contextmenucommands(pt)
		if is_instance_valid(selectedlocktarget):
			if selectedlocktarget == target:
				if target.lockedobjectnext != target:
					res.append("delock self")
			else:
				res.append("lock to")
				res.append("join to")
				res.append("hinge to")
		else:
			res.append_array(["duplicate", "new geon", "colour cycle"])
			res.append("select lock target")
		return res
	var res = [ "new geon" ]
	if is_instance_valid(target) and is_instance_of(target.get_parent(), Skeleton3D):
		res.append("joint skeleton")
	return res

#var lockedobjectnext = self
#var lockedtransformnext = Transform3D()
func lockobjectstogether(gn1, gn2):
	assert (gn1 != gn2)
	var gn0 = gn1
	while gn0.lockedobjectnext != gn1:
		gn0 = gn0.lockedobjectnext
		if gn0 == gn2:
			print("already locked together")
			return
	var gn3 = gn2.lockedobjectnext
	gn2.lockedobjectnext = gn1
	gn0.lockedobjectnext = gn3
	gn2.lockedtransformnext = gn2.transform.inverse()*gn1.transform
	gn0.lockedtransformnext = gn0.transform.inverse()*gn3.transform
	
func delockobject(gn1):
	var gn0 = gn1
	while gn0.lockedobjectnext != gn1:
		gn0 = gn0.lockedobjectnext
	if gn0 != gn1:
		gn0.lockedobjectnext = gn1.lockedobjectnext
		gn0.lockedtransformnext = gn0.lockedtransformnext*gn1.lockedtransformnext
		gn1.lockedobjectnext = gn1
		gn1.lockedtransformnext = Transform3D()
	

var heldgeons = [ ]

func updateheldremotetransforms(bcreateorclear):
	for gn0 in heldgeons:
		var gn = gn0
		var Dcount = get_child_count() + 5
		while not heldgeons.has(gn.lockedobjectnext):
			if bcreateorclear:
				var gnrt = RemoteTransform3D.new()
				gnrt.set_name("HeldRemoteTransform")
				gn.add_child(gnrt)
				gnrt.transform = gn.lockedtransformnext
				gnrt.remote_path = gnrt.get_path_to(gn.lockedobjectnext)
			else:
				var gnrt = gn.get_node("HeldRemoteTransform")
				gnrt.remote_path = NodePath()
				gn.remove_child(gnrt)
				gnrt.queue_free()
			Dcount -= 1
			assert (Dcount >= 0)
			gn = gn.lockedobjectnext

func makejointskeleton(skel : Skeleton3D, ptloc):
	var trj = Transform3D(Basis(), ptloc - skel.global_position)
	var boneunits = [ ]
	for j in range(skel.get_bone_count()):
		var geonobject = newgeonobjectat(Vector3())
		var bu = { "j":j, "geonobject":geonobject, "nextboneunitjoints":[ ] }
		var jparent = skel.get_bone_parent(j)
		if jparent != -1:
			bu.nextboneunitjoints.append({ "nextboneunit":jparent, "nextboneunitjoint":skel.get_bone_children(jparent).find(j)+1 })
		var buc = skel.get_bone_children(j)
		for k in range(len(buc)):
			bu.nextboneunitjoints.append({ "nextboneunit":buc[k], "nextboneunitjoint":0 })
		boneunits.push_back(bu)
		
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		var bonejoint0 = skel.global_transform*skel.get_bone_global_pose(j)
		bu.bonequat0 = bonejoint0.basis.get_rotation_quaternion()
		var boneunitjointspos = [ bonejoint0.origin ]
		var sumboneunitjointpos = bonejoint0.origin
		for i in range(1, len(bu.nextboneunitjoints)):
			var jchild = bu.nextboneunitjoints[i]["nextboneunit"]
			var bonejointj = bonejoint0*skel.get_bone_pose(jchild)
			assert (bonejointj.is_equal_approx(skel.global_transform*skel.get_bone_global_pose(jchild)))
			boneunitjointspos.push_back(bonejointj.origin)
			sumboneunitjointpos += bonejointj.origin
		bu.bonecentre0 = sumboneunitjointpos/len(bu.nextboneunitjoints)
		bu.bonemass = 0.0
		for i in range(len(bu.nextboneunitjoints)):
			var jointvectorabs = boneunitjointspos[i] - bu.bonecentre0
			bu.nextboneunitjoints[i]["jointvector"] = bu.bonequat0.inverse()*jointvectorabs
			bu.bonemass += jointvectorabs.length()
		if len(bu.nextboneunitjoints) <= (2 if not bu.nextboneunitjoints[0].has("nextboneunit") else 1):
			print("bonemass 0 on unit ", j)
			bu.bonemass = 0.0

	var regex = RegEx.new()
	regex.compile("(foot|leg|fingers) \\.[LR]$")   # The hand has a twist between the bones
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
	pass
	
func removeremotetransforms(bcreateorclear):
	if not bcreateorclear:
		for gn in heldgeons:
			var gnrts = gn.get_node_or_null("RemoteTransforms")
			if is_instance_valid(gnrts):
				gn.remove_child(gnrts)
				gnrts.queue_free()
		return
		
	for gn0 in heldgeons:
		var gnrts = Node3D.new()
		gnrts.set_name("RemoteTransforms")
		gn0.add_child(gnrts)

		var gn = gn0
		var tr = Transform3D()
		var Dcount = get_child_count() + 10
		while not heldgeons.has(gn.lockedobjectnext):
			var gnrt = RemoteTransform3D.new()
			gnrts.add_child(gnrt)
			tr = gn.lockedtransformnext*tr
			gnrt.transform = tr
			gnrt.remote_path = gnrt.get_path_to(gn.lockedobjectnext)
			Dcount -= 1
			assert (Dcount >= 0)
			gn = gn.lockedobjectnext


func pickupgeon(pickable, geonobject):
	removeremotetransforms(false)
	heldgeons.append(geonobject)
	print("now holding ", heldgeons)
	removeremotetransforms(true)
	$PoseCalculator.createsolidgeonunits($GeonObjects.get_children(), geonobject)

func dropgeon(pickable, geonobject):
	removeremotetransforms(false)
	heldgeons.erase(geonobject)
	print("now holding ", heldgeons)
	removeremotetransforms(true)
	

func newgeonobjectat(pt):
	var geonobject = geonobjectclass.instantiate()
	geonobject.transform.origin = pt
	geonobject.connect("picked_up", pickupgeon.bind(geonobject))
	geonobject.connect("dropped", dropgeon.bind(geonobject))
	return geonobject

func contextmenuitemselected(target, cmitext, spawnlocation):
	if heldgeons:
		print("contet menu disabled when holding geons")
		pass
	elif cmitext == "new geon":
		var geonobject = newgeonobjectat(spawnlocation)
		print("new geon at ", geonobject.transform.origin)
		$GeonObjects.add_child(geonobject)
	elif cmitext == "duplicate" and is_instance_valid(target) and target.has_method("duplicatefrom"):
		var geonobject = newgeonobjectat(spawnlocation)
		geonobject.duplicatefrom(target)
		$GeonObjects.add_child(geonobject)
	elif cmitext == "delete":
		if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
			if target.lockedobjectnext != target:
				delockobject(target)
			$GeonObjects.remove_child(target)
			target.queue_free()
	elif cmitext == "select lock target":
		if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
			selectedlocktarget = target
	elif cmitext == "lock to":
		if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
			if is_instance_valid(selectedlocktarget) and selectedlocktarget.has_method("executecontextmenucommand"):
				lockobjectstogether(selectedlocktarget, target)
	elif cmitext == "delock self":
		if is_instance_valid(selectedlocktarget) and selectedlocktarget.has_method("executecontextmenucommand"):
			delockobject(selectedlocktarget)

	elif is_instance_valid(target) and target.has_method("executecontextmenucommand"):
		target.executecontextmenucommand(cmitext)

	elif cmitext == "joint skeleton":
		if is_instance_valid(target) and is_instance_of(target.get_parent(), Skeleton3D):
			makejointskeleton(target.get_parent(), spawnlocation)
		
	if cmitext != "select lock target":
		selectedlocktarget = null
