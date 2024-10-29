extends Node3D

var geonobjectclass = load("res://manualposemaker/pickablegeon.tscn")

var selectedlocktarget = null

@onready var xr_camera : XRCamera3D = XRHelpers.get_xr_camera(get_node("../XROrigin3D"))

var activeplayerframe = null

# next begin to put the pose calculator into a physics loop with 
# control on the timing.  Or put it into a thread that we poll for updates

# then pinning nodes (for feet) and lifting them like crutches

# LERPs find their way into this node!
func getgeonobjects():
	var geonobjects = [ ]
	for gn in $GeonObjects.get_children():
		if gn.is_class("RigidBody3D"):
			geonobjects.append(gn)
	return geonobjects


func makecontextmenufor(target, pt):
	if len(heldgeons) > (1 if headlockedgeon != null else 0):
		print("no context menu when holding")
		return [ ]
	if is_instance_valid(target) and target.has_method("contextmenucommands"):
		var res = [ ]
		if is_instance_valid(selectedlocktarget):
			if selectedlocktarget == target:
				if target.lockedobjectnext != target:
					res.append("delock self")
				if headlockedgeon == target:
					res.append("degrab head")
				else:
					res.append("grab head")
			else:
				res.append("lock to")
				res.append_array(selectedlocktarget.checkjointapproaches(target))
			res.append("solve continuous" if Danimateupdateondrop else "solve ondrop")
			res.append("reset pose")
		else:
			res.append_array(target.contextmenucommands(pt))
			res.append_array(["duplicate", "new geon", "colour cycle"])
			res.append("select lock target")
		return res
	var res = [ "new geon" ]
	if is_instance_valid(target):
		if target.get_parent().has_method("MakeJointSkeleton"):
			res.append("geon skeleton")
		if target.get_parent().has_method("ResetJointSkeleton"):
			res.append("reset pose")
	else:
		res.append("")
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
	$PoseCalculator.invalidategeonunits()


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
		$PoseCalculator.invalidategeonunits()

func changejoint(jointcommand, gn1, gn2):
	var c1 = jointcommand[-2]
	var c2 = jointcommand[-1]
	if jointcommand.begins_with("join"):
		if gn1.getjointobject(c1 == "T") == null and gn2.getjointobject(c2 == "T") == null:
			gn1.setjointobject(c1 == "T", gn2)
			gn2.setjointobject(c2 == "T", gn1)
			$PoseCalculator.invalidategeonunits()
	elif gn1.getjointobject(c1 == "T") == gn2 and gn2.getjointobject(c2 == "T") == gn1:
		if jointcommand.begins_with("disjoin"):
			gn1.setjointobject(c1 == "T", null)
			gn2.setjointobject(c2 == "T", null)
		elif jointcommand.begins_with("hinge"):
			var hingeaxis = (gn1.basis.y.cross(gn2.basis.y)).normalized()
			gn1.setjointhingevector(c1 == "T", gn1.basis.inverse()*hingeaxis)
			gn2.setjointhingevector(c2 == "T", gn2.basis.inverse()*hingeaxis)
		elif jointcommand.begins_with("dehinge"):
			gn1.setjointhingevector(c1 == "T", null)
			gn2.setjointhingevector(c2 == "T", null)
		else:
			print("unknown command ", jointcommand)	
	else:
		print("did not apply ", jointcommand)
	gn1.setjointmarkers()
	gn2.setjointmarkers()
	$PoseCalculator.invalidategeonunits()

var heldgeons = [ ]
var headlockedgeon = null
var headloccambasis = null
var headlocorgcampos = null

func _process(delta):
	if headlockedgeon != null:
		headlockedgeon.transform.basis = xr_camera.transform.basis * headloccambasis
		headlockedgeon.transform.origin = xr_camera.global_transform.origin + headlocorgcampos
		
func resetskeletonpose(playerframe, btoposerest):
	var skel : Skeleton3D = playerframe.get_parent().get_skeleton()
	#btoposerest = false
	var bvalidate = false
	if btoposerest:
		for j in range(skel.get_bone_count()):
			var rtr = skel.get_bone_rest(j)
			skel.set_bone_pose_rotation(j, rtr.basis.get_rotation_quaternion())
			skel.set_bone_pose_position(j, rtr.origin)
	var geonobjects = getgeonobjects()
	var lockedgeons = [ ]
	for gn in geonobjects:
		if gn.skelbone == null:
			lockedgeons.append(gn)
			continue
		if skel != gn.skelbone.skel:
			continue
		var j = gn.skelbone.j
		var Djparent = skel.get_bone_parent(j)
		var skeltransform = skel.global_transform
		#		geonobject.skelbone["conjskelleft"] = trj.inverse()
		var Dbonejoint0parent = skeltransform*(skel.get_bone_global_pose(Djparent) if Djparent != -1 else Transform3D())
		var Dbonejoint0 = gn.skelbone["conjskelleft"] * gn.transform * gn.skelbone["conjskelright"]
		var Dbonejoint0rel = Dbonejoint0parent.affine_inverse()*Dbonejoint0
		
		var sca = skeltransform.basis.get_scale()
		var Dsbonejoint0rel = Transform3D(Basis(skel.get_bone_pose_rotation(j)).scaled(Vector3(1/sca.x, 1/sca.y, 1/sca.z)), skel.get_bone_pose_position(j))
		if bvalidate:
			assert (Dsbonejoint0rel.is_equal_approx(Dbonejoint0rel))
			assert (Dbonejoint0rel.origin.is_equal_approx(skel.get_bone_pose_position(j)))
			assert (Dbonejoint0rel.basis.get_rotation_quaternion().is_equal_approx(skel.get_bone_pose_rotation(j)))
		else:
			var Dsbonejoint0 = Dbonejoint0parent*Dsbonejoint0rel
			var gntransform = gn.skelbone["conjskelleft"].affine_inverse()*Dsbonejoint0*gn.skelbone["conjskelright"].inverse()
			gn.transform = gntransform.orthonormalized()

	for gnl in lockedgeons:
		var tr = Transform3D()
		var gn = gnl
		while gn.skelbone == null:
			tr = tr*gn.lockedtransformnext
			gn = gn.lockedobjectnext
			if gn == gnl:
				break
		if gn.skelbone != null and skel == gn.skelbone.skel:
			gnl.transform = gn.transform*tr.inverse()
	$PoseCalculator.invalidategeonunits()
	
func makejointskeleton(playerframe, ptloc):
	activeplayerframe = playerframe
	var skel : Skeleton3D = playerframe.get_parent().get_skeleton()
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
			print("bonemass 0 on unit ", j, "  ", skel.get_bone_name(j), "  ", len(bu.nextboneunitjoints))
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
			if geonobject.name == "Ear03_L_j2":
				print(geonobject)
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
				geonobject.skelbone = { "skel":skel, "j":j, "bonename":skel.get_bone_name(j) }
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

	$PoseCalculator.invalidategeonunits()
	#$PoseCalculator.makegeongroups(getgeonobjects())
	#$PoseCalculator.Dcheckbonejoints()
	#await get_tree().create_timer(1.0).timeout
	#$PoseCalculator.Dsetfrombonequat0()
	#setboneposefromunits(true)

#setjointparentstohingesbyregex("(foot|leg|fingers) \\.[LR]$")
func setjointparentstohingesbyregex(regexmatch):
	print("setting to hinges ", regexmatch)
	var regex = RegEx.new()
	regex.compile(regexmatch)
	var geonobjects = getgeonobjects()
	for gn in geonobjects:
		if gn.skelbone == null:
			continue
		if regex.search(gn.skelbone.bonename) == null:
			continue
		var skel = gn.skelbone.skel
		var j = gn.skelbone.j
		var jparent = skel.get_bone_parent(j)
		assert (gn.jointobjectbottom != null)
		var gnparent = gn.jointobjectbottom
		if gnparent.skelbone == null:
			print("do later")
			continue
		print(" Hingifying bone ", gn.skelbone.bonename, " to ", gnparent.skelbone.bonename)
		assert (gnparent.jointobjecttop == gn)
			#need to find how to match up these.  and then apply all the hinges properly
			# then start the simulation on hinges
		changejoint("hingeTB", gnparent, gn)
		#print("SKIPPING MORE HINGES")
		#break

func findbonenodefromname(bonecontrolname):
	for gn in getgeonobjects():
		if gn.skelbone != null and gn.skelbone["bonename"] == bonecontrolname:
			return gn
	return null
	
# This assumes that the bonepositions are set in order
# so that the previous bone global pose can be used
# Should upgrade this to handle the root properly and the conjskelleft value being carried across
func setboneposefromunits(playerframe):
	var geonobjects = getgeonobjects()
	var skel = playerframe.get_parent().get_skeleton()
	var sca = skel.global_transform.basis.get_scale()
	var vd = { }
	var bonejointparenttransforms = { }
	for gn in geonobjects:
		if gn.skelbone == null:
			continue
		if gn.skelbone.skel != skel:
			continue
		var j = gn.skelbone.j
		var jtrans = Transform3D(gn.transform.basis, gn.transform.origin + gn.transform.basis.y*(-gn.rodlength/2))

		var jparent = skel.get_bone_parent(j)
		var bonejoint0parent = skel.global_transform
		if jparent != -1:
			if bonejointparenttransforms.has(jparent):
				bonejoint0parent = bonejointparenttransforms[jparent]
			else:
				bonejoint0parent = skel.global_transform*skel.get_bone_global_pose(jparent)

		var conjskelright = Transform3D(gn.skelbone["conjskelright"].basis, Vector3(0,-gn.rodlength/2,0))
		var bonejoint0 = gn.skelbone["conjskelleft"] * gn.transform * conjskelright
		bonejointparenttransforms[j] = bonejoint0.scaled_local(sca)
		var bonejoint0rel = bonejoint0parent.affine_inverse()*bonejoint0
#m		vd[NCONSTANTS2.CFI_SKELETON_BONE_POSITIONS + j] = bonejoint0rel.origin
		vd[NCONSTANTS2.CFI_SKELETON_BONE_ROTATIONS + j] = bonejoint0rel.basis.get_rotation_quaternion()
		#skel.set_bone_pose_position(j, bonejoint0rel.origin)
		#skel.set_bone_pose_rotation(j, bonejoint0rel.basis.get_rotation_quaternion())
	return vd



	
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

var Danimateupdateondrop = false  # opposite of continuous

func pickupgeon(pickable, geonobject, geonobjectsecondary=null):
	removeremotetransforms()
	if len(heldgeons) == 0:
		$PoseCalculator.makegeongroupsIfInvalid(getgeonobjects())
		#$PoseCalculator.Dcheckbonejoints()
		#$PoseCalculator.Dcheckbonejoints()
		#$PoseCalculator.Dsetfrombonequat0()
	heldgeons.append(geonobject)
	if geonobjectsecondary != null:
		heldgeons.append(geonobjectsecondary)

	if $PoseCalculator.derivejointsequenceIfNecessary(heldgeons[0]):
		bonejointgradsteps = 0
	$PoseCalculator.setisconstorientation(heldgeons)
	print("now holding ", heldgeons)
	createremotetransforms()

func dropgeon(pickable, geonobject, geonobjectsecondary=null):
	removeremotetransforms()
	$PoseCalculator.copybacksolidedgeunit0(geonobject)

	if geonobjectsecondary != null:
		$PoseCalculator.copybacksolidedgeunit0(geonobjectsecondary)
		heldgeons.erase(geonobjectsecondary)

	assert (heldgeons.has(geonobject))
	heldgeons.erase(geonobject)
	print("now holding ", heldgeons)
	createremotetransforms()

	if len(heldgeons) == 0:
		if Danimateupdateondrop:
			for i in range(10):
				$PoseCalculator.sgmakegradstep(i)
				$PoseCalculator.sgseebonequatscentres(false)
				$PoseCalculator.Dcheckbonejoints()
				await get_tree().create_timer(0.1).timeout
			$PoseCalculator.sgseebonequatscentres(true)
			#$PoseCalculator.Dsetfrombonequat0()
			#$PoseCalculator.makegeongroups(getgeonobjects())
			#$PoseCalculator.bonejointsequence = [ ]
			#$PoseCalculator.Dcheckbonejoints()
			if activeplayerframe != null:
				var fd = setboneposefromunits(activeplayerframe)
				activeplayerframe.get_parent().PF_framedatatoavatar(fd)

	else:
		if $PoseCalculator.derivejointsequenceIfNecessary(heldgeons[0]):
			bonejointgradsteps = 0
		$PoseCalculator.setisconstorientation(heldgeons)
	
var bonejointseqstartticks = 0
var bonejointgradsteps = 0



func _physics_process(delta):
	if Danimateupdateondrop:
		return
	if len(heldgeons) == 0 and bonejointgradsteps == 0:
		return
	var physt0 = Time.get_ticks_usec()
	if bonejointgradsteps == 0:
		bonejointseqstartticks = physt0
		for geonobject in heldgeons:
			$PoseCalculator.copybacksolidedgeunit0(geonobject)
	for Ci in range(10):
		var bstepped = $PoseCalculator.sgmakegradstep(Ci)
		#print(" make gradstep ", bonejointgradsteps, " ", bstepped)
		bonejointgradsteps += 1
		if not bstepped:
			bonejointgradsteps = -1
			break
		if bonejointgradsteps >= 15:
			bonejointgradsteps = -1
			break
		var physt = Time.get_ticks_usec()
		if physt - bonejointseqstartticks > 200000:
			bonejointgradsteps = -1
			break
		if physt - physt0 > 1000:
			break
	if bonejointgradsteps == -1:
		#print(" setbonepose from units")
		$PoseCalculator.sgseebonequatscentres(true)
		if activeplayerframe != null:
			var fd = setboneposefromunits(activeplayerframe)
			fd[NCONSTANTS2.CFI_NOTHINFRAME] = 1
			var vd = activeplayerframe.get_parent().PF_intendedskelposes(fd)
			#activeplayerframe.get_parent().PF_framedatatoavatar(fd)
			activeplayerframe.networkedavatarthinnedframedata(vd)

		bonejointseqstartticks = Time.get_ticks_usec()
		bonejointgradsteps = 0

func newgeonobjectat(pt=null):
	var geonobject = geonobjectclass.instantiate()
	if pt != null:
		geonobject.transform.origin = pt
	geonobject.connect("picked_up", pickupgeon.bind(geonobject))
	geonobject.connect("dropped", dropgeon.bind(geonobject))
	return geonobject

func contextmenuitemselected(target, cmitext, spawnlocation):
	if len(heldgeons) > (1 if headlockedgeon != null else 0):
		print("context menu disabled when holding geons")
		pass
	elif cmitext == "new geon":
		var geonobject = newgeonobjectat(spawnlocation)
		print("new geon at ", geonobject.transform.origin)
		$GeonObjects.add_child(geonobject)
		$PoseCalculator.invalidategeonunits()
	elif cmitext == "duplicate" and is_instance_valid(target) and target.has_method("duplicatefrom"):
		var geonobject = newgeonobjectat(spawnlocation)
		geonobject.duplicatefrom(target)
		$GeonObjects.add_child(geonobject)
		$PoseCalculator.invalidategeonunits()
	elif cmitext == "delete":
		if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
			if target.lockedobjectnext != target:
				delockobject(target)
			$GeonObjects.remove_child(target)
			target.queue_free()
			$PoseCalculator.invalidategeonunits()
	elif cmitext == "select lock target":
		if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
			selectedlocktarget = target
	elif cmitext == "lock to":
		if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
			if is_instance_valid(selectedlocktarget) and selectedlocktarget.has_method("executecontextmenucommand"):
				lockobjectstogether(selectedlocktarget, target)
	elif cmitext.begins_with("disjoin") or cmitext.begins_with("join") or cmitext.begins_with("hinge") or cmitext.begins_with("dehinge"):
		if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
			if is_instance_valid(selectedlocktarget) and selectedlocktarget.has_method("executecontextmenucommand"):
				changejoint(cmitext, selectedlocktarget, target)

	elif cmitext == "delock self":
		if is_instance_valid(selectedlocktarget) and selectedlocktarget.has_method("executecontextmenucommand"):
			delockobject(selectedlocktarget)

	elif cmitext == "geon skeleton":
		if is_instance_valid(target) and target.get_parent().has_method("MakeJointSkeleton"):
			target.get_parent().MakeJointSkeleton(self, spawnlocation)
			
	elif cmitext == "reset pose":
		if is_instance_valid(target) and target.get_parent().has_method("ResetJointSkeleton"):
			target.get_parent().ResetJointSkeleton(self)
		
	elif cmitext == "solve continuous":
		Danimateupdateondrop = false
	elif cmitext == "solve ondrop":
		Danimateupdateondrop = true

	elif cmitext == "grab head" or cmitext == "degrab head":
		if headlockedgeon != null:
			dropgeon(null, headlockedgeon)
			headlockedgeon = null
			headloccambasis = null
			headlocorgcampos = null

		if cmitext == "grab head":
			if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
				headlockedgeon = target
				pickupgeon(null, headlockedgeon)
				headloccambasis = xr_camera.transform.basis.inverse()*headlockedgeon.transform.basis
				headlocorgcampos = headlockedgeon.transform.origin - xr_camera.global_transform.origin

	elif is_instance_valid(target) and target.has_method("executecontextmenucommand"):
		target.executecontextmenucommand(cmitext)
		if cmitext == "shorter" or cmitext == "longer":
			$PoseCalculator.invalidategeonunits()

	if cmitext != "select lock target":
		selectedlocktarget = null
