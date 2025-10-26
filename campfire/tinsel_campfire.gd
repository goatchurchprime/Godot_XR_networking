extends Node3D

func _process(delta):
	$OmniLight3D.light_projector.noise.offset.x += delta*100
	
