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

var lockedobjectnext = self
var lockedtransformnext = Transform3D()

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
	if gm:  
		print("CSGSCALER ", gm[0])
	var gmm = gm[1] if gm else $CSGScaler/CSGRod.mesh
	$CollisionShape3D.shape = gmm.create_convex_shape()
	$MeshOutline.mesh = gmm.create_outline(0.02)
	
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
