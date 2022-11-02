extends Spatial

var ballA
var ballB
var orgleng = 1.0

const colshort = Color.blue
const collong = Color.yellowgreen

func _enter_tree():
	orgleng = (ballA.translation - ballB.translation).length()
	_process(0.0)

func _process(delta):
	var midpoint = (ballA.translation + ballB.translation)/2
	look_at_from_position(midpoint, ballA.translation, Vector3(0,1,0))
	var vec = ballA.translation - ballB.translation
	var leng = vec.length()
	$RodMesh.scale.z = leng
	$RodMesh.get_surface_material(0).albedo_color = lerp(colshort, collong, clamp(leng/orgleng - 0.5, 0.0, 1.0))	
