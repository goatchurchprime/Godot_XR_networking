extends Node3D

var geonobjectclass = load("res://contextui/pickablegeon.tscn")

func makecontextmenufor(target, pt):
	if is_instance_valid(target) and target.has_method("contextmenucommands"):
		return target.contextmenucommands(pt)
	return [ "new geon"]

func contextmenuitemselected(target, cmitext, spawnlocation):
	if cmitext == "new geon":
		var geonobject = geonobjectclass.instantiate()
		geonobject.transform.origin = spawnlocation
		print(geonobject.transform.origin)
		add_child(geonobject)
	elif cmitext == "duplicate" and is_instance_valid(target) and target.has_method("duplicatefrom"):
		var geonobject = geonobjectclass.instantiate()
		geonobject.transform.origin = spawnlocation
		geonobject.duplicatefrom(target)
		add_child(geonobject)
	elif is_instance_valid(target) and target.has_method("executecontextmenucommand"):
		target.executecontextmenucommand(cmitext)

