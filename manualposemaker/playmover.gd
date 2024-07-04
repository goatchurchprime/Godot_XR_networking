extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func MakeJointSkeleton(geonposemaker, spawnlocation):
	geonposemaker.makejointskeleton($MonsterArmature/Skeleton3D, spawnlocation)
	geonposemaker.setjointparentstohingesbyregex("(foot|leg|fingers) \\.[LR]$")
	geonposemaker.setjointparentstohingesbyregex("jaw$")
	
func ResetJointSkeleton(geonposemaker):
	geonposemaker.resetskeletonpose($MonsterArmature/Skeleton3D, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
