extends Generic6DOFJoint

var ballA
var ballB
var orgleng = 1.0

const colshort = Color.blue
const collong = Color.yellowgreen

func _enter_tree():
	set("nodes/node_a", ballA.get_path()) 
	set("nodes/node_b", ballB.get_path())

	set("linear_limit_x/enabled", false)
	set("linear_limit_y/enabled", false)
	set("linear_limit_z/enabled", false)
	set("angular_limit_x/enabled", false)
	set("angular_limit_y/enabled", false)
	set("angular_limit_z/enabled", false)
	set("linear_spring_x/enabled", true)
	set("linear_spring_y/enabled", true)
	set("linear_spring_z/enabled", true)
	set("linear_spring_x/stiffness", 50)
	set("linear_spring_y/stiffness", 50)
	set("linear_spring_z/stiffness", 50)
	set("linear_spring_x/damping", 40)
	set("linear_spring_y/damping", 40)
	set("linear_spring_z/damping", 40)
	
	orgleng = (ballA.translation - ballB.translation).length()
	_process(1.0)

func _process(delta):
	var midpoint = (ballA.translation + ballB.translation)/2
	look_at_from_position(midpoint, ballA.translation, Vector3(0,1,0))
	var leng = (ballA.translation - ballB.translation).length()
	$RodMesh.scale.z = leng
	$RodMesh.get_surface_material(0).albedo_color = lerp(colshort, collong, clamp(leng/orgleng - 0.5, 0.0, 1.0))	
