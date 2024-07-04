extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_skeleton():
	return $MonsterArmature/Skeleton3D
	
func MakeJointSkeleton(geonposemaker, spawnlocation):
	geonposemaker.makejointskeleton($PlayerFrame, spawnlocation)
	geonposemaker.setjointparentstohingesbyregex("(foot|leg|fingers) \\.[LR]$")
	geonposemaker.setjointparentstohingesbyregex("jaw$")
	
func ResetJointSkeleton(geonposemaker):
	geonposemaker.resetskeletonpose($PlayerFrame, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
