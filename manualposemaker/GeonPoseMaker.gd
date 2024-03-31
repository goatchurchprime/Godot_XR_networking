extends Node3D

var geonobjectclass = load("res://manualposemaker/pickablegeon.tscn")

var selectedlocktarget = null

# next begin to put the pose calculator into a physics loop with 
# control on the timing.  Or put it into a thread that we poll for updates

# then pinning nodes (for feet) and lifting them like crutches
									

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
	assert (Dchecklocktransformcycle(gn1))
	
func Dchecklocktransformcycle(gn0):
	var Dgn = gn0
	var Dtr = Dgn.lockedtransformnext
	var Dgnlist = [ Dgn ]
	while Dgn.lockedobjectnext != gn0:
		Dgn = Dgn.lockedobjectnext
		Dtr = Dtr*Dgn.lockedtransformnext
		Dgnlist.append(Dgn)
	assert (Dtr.is_equal_approx(Transform3D()))
	return true
	
	
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

func makejointskeleton(skel : Skeleton3D, ptloc):
	#var trj = Transform3D(Basis(), ptloc - skel.global_position)
	var trj = Transform3D(Basis(), ptloc)*Transform3D(Basis(Vector3(0,1,0), deg_to_rad(180)), Vector3(0,0,0))*Transform3D(Basis(), -skel.global_position)
	var skeltransform = skel.global_transform

	# generate the boneunits
	var boneunits = [ ]
	for j in range(skel.get_bone_count()):
		var bu = { "j":j, "nextboneunitjoints":[ ] }
		var jparent = skel.get_bone_parent(j)
		if jparent != -1:
			bu.nextboneunitjoints.append({ "nextboneunit":jparent, "nextboneunitjoint":skel.get_bone_children(jparent).find(j)+1 })
		else:
			bu.nextboneunitjoints.append({  })
		var buc = skel.get_bone_children(j)
		for k in range(len(buc)):
			bu.nextboneunitjoints.append({ "nextboneunit":buc[k], "nextboneunitjoint":0 })
		boneunits.push_back(bu)
		
	# generate the links between the boneunits
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		var bonejoint0 = skeltransform*skel.get_bone_global_pose(j)
		bu.bonequat0 = bonejoint0.basis.get_rotation_quaternion()
		var boneunitjointspos = [ bonejoint0.origin ]
		var sumboneunitjointpos = bonejoint0.origin
		for i in range(1, len(bu.nextboneunitjoints)):
			var jchild = bu.nextboneunitjoints[i]["nextboneunit"]
			var bonejointj = bonejoint0*skel.get_bone_pose(jchild)
			assert (bonejointj.is_equal_approx(skeltransform*skel.get_bone_global_pose(jchild)))
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

	# record the boneunits that have hinges
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

	# create the geon objects for each boneunit
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		if bu.bonemass == 0.0:
			continue
		var gname = skel.get_bone_name(j)
		var butr = Transform3D(bu.bonequat0, bu.bonecentre0)
		
		for i in range(1, len(bu.nextboneunitjoints)):
			var geonobject = newgeonobjectat()
			geonobject.set_name(gname + (("_j%d" % i) if i > 1 else ""))
			var vj0 = bu.nextboneunitjoints[0]["jointvector"]
			var vji = bu.nextboneunitjoints[i]["jointvector"]
			var vpbcen = (vji + vj0)/2
			var vpb = vji - vj0
			var vpblen = vpb.length()
			var vjbasis = Basis()
			if not is_zero_approx(vpb.x) or not is_zero_approx(vpb.z):
				var axis = Vector3(0,1,0).cross(vpb).normalized()
				var angle_rads = acos(vpb.y/vpblen)
				#print("angle_rads ", angle_rads, vpb, i, [vpb.x, vpb.z])
				vjbasis = Basis(axis, angle_rads)
			else:
				pass # print(vpbcen)
			geonobject.transform = trj*butr*Transform3D(vjbasis, vpbcen)
			geonobject.rodlength = vpblen
			geonobject.rodradtop = 0.025
			geonobject.rodradbottom = 0.02
			geonobject.rodcolour = Color.GOLD if i == 1 else Color.GOLDENROD
			$GeonObjects.add_child(geonobject)  # this calls ready which calls setupcsgrod
			bu.nextboneunitjoints[i].geonobject = geonobject
			if i >= 2:
				lockobjectstogether(bu.nextboneunitjoints[i-1].geonobject, geonobject)
			else:
				geonobject.skelbone = { "skel":skel, "j":j, "buskeltrans":skeltransform*skel.get_bone_global_pose(j)*geonobject.transform.inverse() }
				geonobject.skelbone["conjskelleft"] = trj.inverse()
				geonobject.skelbone["conjskelright"] = Transform3D(vjbasis, vpbcen).inverse()*Transform3D(Basis(), vj0)
				#print(geonobject.skelbone["conjskelright"], geonobject.rodlength/2, " ", geonobject.name)
				assert (geonobject.skelbone["conjskelright"].origin.is_equal_approx(Vector3(0,-geonobject.rodlength/2,0)))
				# validation of the reversing calculation
				var Djparent = skel.get_bone_parent(j)
				var Dbonejoint0parent = skeltransform*(skel.get_bone_global_pose(Djparent) if Djparent != -1 else Transform3D())
				var Dbutr = trj.inverse()*geonobject.transform*Transform3D(vjbasis, vpbcen).inverse()
				var Dbonejoint0 = Dbutr*Transform3D(Basis(), vj0)
				Dbonejoint0 = geonobject.skelbone["conjskelleft"] * geonobject.transform * geonobject.skelbone["conjskelright"]
				var Dbonejoint0rel = Dbonejoint0parent.affine_inverse()*Dbonejoint0
				assert (Dbonejoint0rel.origin.is_equal_approx(skel.get_bone_pose_position(j)))
				assert (Dbonejoint0rel.basis.get_rotation_quaternion().is_equal_approx(skel.get_bone_pose_rotation(j)))
	
	# generate the joints between each of the bone units
	for j in range(len(boneunits)):
		var bu = boneunits[j]
		if bu.bonemass == 0.0:
			continue
		for i in range(0, len(bu.nextboneunitjoints)):
			if bu.nextboneunitjoints[i].has("nextboneunit"):
				var nextbu = boneunits[bu.nextboneunitjoints[i]["nextboneunit"]]
				if nextbu.bonemass == 0.0:
					continue
				var ni = bu.nextboneunitjoints[i]["nextboneunitjoint"]
				var nextgeonobject = nextbu.nextboneunitjoints[1 if ni == 0 else ni].geonobject
				var geonobject = bu.nextboneunitjoints[1 if i == 0 else i].geonobject
				if i == 0:
					geonobject.jointobjectbottom = nextgeonobject
				else:
					geonobject.jointobjecttop = nextgeonobject
				geonobject.setjointmarkers()

	$PoseCalculator.makegeongroups($GeonObjects.get_children())
	$PoseCalculator.Dcheckbonejoints()
	#await get_tree().create_timer(1.0).timeout
	#$PoseCalculator.Dsetfrombonequat0()
	setboneposefromunits(true)
			
# This assumes that the bonepositions are set in order
# so that the previous bone global pose can be used
# Should upgrade this to handle the root properly and the conjskelleft value being carried across
func setboneposefromunits(Dverify=false):
	var geonobjects = $GeonObjects.get_children()
	for gn in geonobjects:
		if gn.skelbone == null:
			continue
		var skel = gn.skelbone.skel
		var j = gn.skelbone.j
		var sca = skel.global_transform.basis.get_scale()
		var jtrans = Transform3D(gn.transform.basis, gn.transform.origin + gn.transform.basis.y*(-gn.rodlength/2))

		var jparent = skel.get_bone_parent(j)
		var bonejoint0parent = skel.global_transform*(skel.get_bone_global_pose(jparent) if jparent != -1 else Transform3D())
		var conjskelright = Transform3D(gn.skelbone["conjskelright"].basis, Vector3(0,-gn.rodlength/2,0))
		var bonejoint0 = gn.skelbone["conjskelleft"] * gn.transform * conjskelright
		var bonejoint0rel = bonejoint0parent.affine_inverse()*bonejoint0
		if Dverify:
			assert (bonejoint0rel.origin.is_equal_approx(skel.get_bone_pose_position(j)))
			assert (bonejoint0rel.basis.get_rotation_quaternion().is_equal_approx(skel.get_bone_pose_rotation(j)))

		skel.set_bone_pose_position(j, bonejoint0rel.origin)
		skel.set_bone_pose_rotation(j, bonejoint0rel.basis.get_rotation_quaternion())

	
func removeremotetransforms():
	for gn in heldgeons:
		var gnrts = gn.get_node_or_null("RemoteTransforms")
		if is_instance_valid(gnrts):
			gn.remove_child(gnrts)
			gnrts.queue_free()
		
func createremotetransforms():
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
			tr = tr*gn.lockedtransformnext
			gnrt.transform = tr
			gnrt.remote_path = gnrt.get_path_to(gn.lockedobjectnext)
			Dcount -= 1
			assert (Dcount >= 0)
			gn = gn.lockedobjectnext


func pickupgeon(pickable, geonobject):
	removeremotetransforms()
	if len(heldgeons) == 0:
		$PoseCalculator.createsolidgeonunits($GeonObjects.get_children(), geonobject)
		$PoseCalculator.Dcheckbonejoints()
		$PoseCalculator.derivejointsequence(geonobject)
		$PoseCalculator.Dcheckbonejoints()
		#$PoseCalculator.Dsetfrombonequat0()
	heldgeons.append(geonobject)
	print("now holding ", heldgeons)
	createremotetransforms()



func dropgeon(pickable, geonobject):
	removeremotetransforms()

	$PoseCalculator.copybacksolidedgeunit0(geonobject)
	heldgeons.erase(geonobject)
	print("now holding ", heldgeons)
	createremotetransforms()

	if len(heldgeons) == 0:
		for i in range(10):
			$PoseCalculator.sgmakegradstep(i)
			$PoseCalculator.sgseebonequatscentres(false)
			$PoseCalculator.Dcheckbonejoints()
			await get_tree().create_timer(0.1).timeout
		$PoseCalculator.sgseebonequatscentres(true)

		#$PoseCalculator.Dsetfrombonequat0()

		#$PoseCalculator.createsolidgeonunits($GeonObjects.get_children(), geonobject)
		#$PoseCalculator.bonejointsequence = [ ]
		#$PoseCalculator.Dcheckbonejoints()

		setboneposefromunits()

	
func newgeonobjectat(pt=null):
	var geonobject = geonobjectclass.instantiate()
	if pt != null:
		geonobject.transform.origin = pt
	geonobject.connect("picked_up", pickupgeon.bind(geonobject))
	geonobject.connect("dropped", dropgeon.bind(geonobject))
	return geonobject

func contextmenuitemselected(target, cmitext, spawnlocation):
	if heldgeons:
		print("context menu disabled when holding geons")
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
