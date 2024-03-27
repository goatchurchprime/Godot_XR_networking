extends Node3D

var geonobjectclass = load("res://contextui/pickablegeon.tscn")

var selectedlocktarget = null

func makecontextmenufor(target, pt):
	if heldgeons:
		print("no context menu when holding")
		return [ ]
	if is_instance_valid(target) and target.has_method("contextmenucommands"):
		var res = target.contextmenucommands(pt)
		res.append_array(["duplicate", "new geon", "colour cycle"])
		if is_instance_valid(selectedlocktarget):
			if selectedlocktarget == target:
				if target.lockedobjectnext != target:
					res.append("delock self")
			else:
				res.append("lock to")
		else:
			res.append("select lock target")
		return res
	return [ "new geon" ]


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
	updateheldremotetransforms(false)
	heldgeons.append(geonobject)
	print("now holding ", heldgeons)
	updateheldremotetransforms(true)

func dropgeon(pickable, geonobject):
	updateheldremotetransforms(false)
	heldgeons.erase(geonobject)
	print("now holding ", heldgeons)
	updateheldremotetransforms(true)
	

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
		add_child(geonobject)
	elif cmitext == "duplicate" and is_instance_valid(target) and target.has_method("duplicatefrom"):
		var geonobject = newgeonobjectat(spawnlocation)
		geonobject.duplicatefrom(target)
		add_child(geonobject)
	elif cmitext == "delete":
		if is_instance_valid(target) and target.has_method("executecontextmenucommand"):
			if target.lockedobjectnext != target:
				delockobject(target)
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

	if cmitext != "select lock target":
		selectedlocktarget = null
