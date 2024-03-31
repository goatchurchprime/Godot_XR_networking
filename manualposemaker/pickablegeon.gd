extends XRToolsPickable

signal pointer_event(event)

var rodlength = 1.5
var rodradtop = 0.09
var rodradbottom = 0.08
var rodbulgefac = 1.0
var rodhalved = false
var rodcolour = Color.BEIGE

const rodcolourcyle = [ Color.BEIGE, Color.DARK_GOLDENROD, Color.DARK_TURQUOISE, Color.LIME_GREEN, 
						Color.BLACK, Color.PLUM ]

# linked list of objects in lock group
var lockedobjectnext = self
var lockedtransformnext = Transform3D()  # right multiply

# joints are at the ends, defined by looking at the back links
var jointobjecttop = null
var jointobjectbottom = null

var skelbone = null

func setjointobject(btop, Njointobject):
	if btop:
		jointobjecttop = Njointobject
	else:
		jointobjectbottom = Njointobject

func getjointobject(btop):
	return jointobjecttop if btop else jointobjectbottom
		

func setupcsgrod():
	$CSGScaler/CSGRod.mesh.height = rodlength
	$CSGScaler/CSGRod.mesh.top_radius = rodradtop
	$CSGScaler/CSGRod/CSGSphereTop.radius = rodradtop
	$CSGScaler/CSGRod/CSGSphereTop.position.y = rodlength/2
	$CSGScaler/CSGRod.mesh.bottom_radius = rodradbottom
	$CSGScaler/CSGRod/CSGSphereBottom.radius = rodradbottom
	$CSGScaler/CSGRod/CSGSphereBottom.position.y = -rodlength/2
	$CSGScaler/CSGRod/CSGHalfBox.size.y = rodlength+rodradtop+rodradbottom + 1
	$CSGScaler/CSGRod/CSGHalfBox.size.z = max(rodradtop,rodradbottom)*2 + 1
	$CSGScaler/CSGRod/CSGHalfBox.visible = rodhalved
	$CSGScaler/CSGRod.scale.x = rodbulgefac
	$CSGScaler.material_override.albedo_color = rodcolour
	await get_tree().create_timer(0.5).timeout   # it takes a bit of time for the CSG to complete.  Maybe there should be a signal when it does
	var gm = $CSGScaler.get_meshes()
	#if gm: print("CSGSCALER ", gm[0])
	var gmm = gm[1] if gm else $CSGScaler/CSGRod.mesh
	$CollisionShape3D.shape = gmm.create_convex_shape()
	$MeshOutline.mesh = gmm.create_outline(0.02)
	setjointmarkers()
	
func setjointmarkers():
	$JointTopMarker.position = Vector3(0,rodlength/2,0)
	$JointTopMarker.visible = (jointobjecttop != null)
	$JointBottomMarker.position = Vector3(0,-rodlength/2,0)
	$JointBottomMarker.visible = (jointobjectbottom != null)

func checkjointapproaches(target):
	var jointtoppos = transform*Vector3(0,rodlength/2,0)
	var jointbotpos = transform*Vector3(0,-rodlength/2,0)
	var tjointtoppos = target.transform*Vector3(0,target.rodlength/2,0)
	var tjointbotpos = target.transform*Vector3(0,-target.rodlength/2,0)
	var dtoptop = (jointtoppos - tjointtoppos).length() - (rodradtop + target.rodradtop)
	var dtopbot = (jointtoppos - tjointbotpos).length() - (rodradtop + target.rodradbottom)
	var dbottop = (jointbotpos - tjointtoppos).length() - (rodradbottom + target.rodradtop)
	var dbotbot = (jointbotpos - tjointbotpos).length() - (rodradbottom + target.rodradbottom)
	var dtopmin = min(dtoptop, dtopbot)
	var dbotmin = min(dbottop, dbotbot)
	if min(dtopmin, dbotmin) <= 0:
		var jointcode = ("TT" if dtoptop <= dtopbot else "TB") if dtopmin <= dbotmin else ("BT" if dbottop <= dbotbot else "BB")
		var jointobject0 = getjointobject(jointcode[0] == "T")
		var jointobject1 = target.getjointobject(jointcode[1] == "T")
		
		if (jointobject0 == null) and (jointobject1 == null):
			return "join"+jointcode
		if (jointobject0 != null) and (jointobject1 != null):
			return "disjoin"+jointcode
	return ""
	
	
func on_pointer_event(e : XRToolsPointerEvent) -> void:
	if e.event_type == XRToolsPointerEvent.Type.ENTERED:
		$MeshOutline.visible = true
	if e.event_type == XRToolsPointerEvent.Type.EXITED:
		$MeshOutline.visible = false

func _ready():
	setupcsgrod()
	connect("pointer_event", on_pointer_event)

func duplicatefrom(g):
	rodlength = g.rodlength
	rodradtop = g.rodradtop
	rodradbottom = g.rodradbottom
	rodbulgefac = g.rodbulgefac
	rodhalved = g.rodhalved
	rodcolour = g.rodcolour

func contextmenucommands(pt):
	var dtop = ($CSGScaler/CSGRod/CSGSphereTop.global_position - pt).length()
	var dbottom = ($CSGScaler/CSGRod/CSGSphereBottom.global_position - pt).length()
	var dmiddle = ($CSGScaler/CSGRod.global_position - pt).length()
	var wext = ""
	if dtop < min(dbottom, dmiddle):
		wext = " top"
	if dbottom < min(dtop, dmiddle):
		wext = " bottom"
	var res = [ "delete", "longer", "shorter", 
				"thinner"+wext, "wider"+wext, 
				"squash", "bulge",
				"whole" if rodhalved else "halve", 
			  ]
	return res
	
func executecontextmenucommand(cmc):
	print(name, "-- contextmenucommand ", cmc)
	if cmc == "longer":
		rodlength *= 1.5
	if cmc == "shorter":
		rodlength /= 1.5
	if cmc == "bulge":
		rodbulgefac *= 1.5
	if cmc == "squash":
		rodbulgefac /= 1.5
	if cmc == "wider top" or cmc == "wider":
		rodradtop *= 1.5
	if cmc == "thinner top" or cmc == "thinner":
		rodradtop /= 1.5
	if cmc == "wider bottom" or cmc == "wider":
		rodradbottom *= 1.5
	if cmc == "thinner bottom" or cmc == "thinner":
		rodradbottom /= 1.5
	if cmc == "whole":
		rodhalved = false
	if cmc == "halve":
		rodhalved = true
	if cmc == "colour cycle":
		rodcolour = rodcolourcyle[(rodcolourcyle.find(rodcolour)+1) % len(rodcolourcyle)]
		print(rodcolour)
	setupcsgrod()
