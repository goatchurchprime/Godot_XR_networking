extends StaticBody3D

signal pointer_event(event)

func setnamepos(text, clock, rad):
	$Label3D.text = text
	$Label3D.visible = false
	$CollisionShape3D.disabled = false
	var ang = deg_to_rad(clock*30)
	transform.origin.x = sin(ang)*rad if (clock % 6) != 0 else 0.0
	transform.origin.y = cos(ang)*rad

func setbackgroundcollision():
	var t = $Label3D.get_aabb()
	$Label3D/MeshInstance3D.mesh.size = Vector2(t.size.x, t.size.y)
	$CollisionShape3D.shape.size = Vector3(t.size.x, t.size.y, 0.1)
	transform.origin.x += (t.size.x-t.size.y)*0.5*sign(transform.origin.x)
	$Label3D.visible = true
	$CollisionShape3D.disabled = false
	
func setselected(selectedsignmaterial):
	$Label3D/MeshInstance3D.set_surface_override_material(0, selectedsignmaterial)

func setunselected(unselectedsignmaterial):
	$Label3D/MeshInstance3D.set_surface_override_material(0, unselectedsignmaterial)
