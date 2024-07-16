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




var framedata0 = { NCONSTANTS.CFI_TIMESTAMP:0.0, NCONSTANTS.CFI_TIMESTAMP_F0:0.0 }
var heartbeatfullframeseconds = 5.0
func PF_intendedskelposes(fd):
	var tstamp = Time.get_ticks_msec()*0.001
	var dft = tstamp - framedata0[NCONSTANTS.CFI_TIMESTAMP]
	framedata0[NCONSTANTS.CFI_TIMESTAMPPREV] = framedata0[NCONSTANTS.CFI_TIMESTAMP_F0]
	framedata0[NCONSTANTS.CFI_TIMESTAMP_F0] = tstamp
	var bnothinning = (dft >= heartbeatfullframeseconds) or (fd.get(NCONSTANTS.CFI_NOTHINFRAME) == 1)
	var vd = thinframedata_updatef0(framedata0, fd, bnothinning)
	if len(vd) == 0:
		return
	framedata0[NCONSTANTS.CFI_TIMESTAMP] = tstamp
	vd[NCONSTANTS.CFI_TIMESTAMPPREV] = framedata0[NCONSTANTS.CFI_TIMESTAMPPREV]
	vd[NCONSTANTS.CFI_TIMESTAMP] = tstamp
	#print("vv ", vd)
	return vd


func PF_framedatatoavatar(vd):
	var skel = get_skeleton()
	for j in range(skel.get_bone_count()):
		if vd.has(NCONSTANTS2.CFI_SKELETON_BONE_POSITIONS + j):
			skel.set_bone_pose_position(j, vd[NCONSTANTS2.CFI_SKELETON_BONE_POSITIONS + j])
		if vd.has(NCONSTANTS2.CFI_SKELETON_BONE_ROTATIONS + j):
			skel.set_bone_pose_rotation(j, vd[NCONSTANTS2.CFI_SKELETON_BONE_ROTATIONS + j])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


static func thinframedata_updatef0(fd0, fd, bnothinning):
	var vd = { }
	for k in fd:
		assert (k != NCONSTANTS.CFI_TIMESTAMP)
		var v = fd[k]
		var v0 = fd0.get(k, null)
		if v0 != null:
			var ty = typeof(v)
			if bnothinning:
				pass
			elif ty == TYPE_QUATERNION:
				var dv = v0*v.inverse()
				if dv.w > 0.9994:  # 2 degrees
					v = null
			elif ty == TYPE_VECTOR3:
				var dv = v0 - v
				if dv.length() < 0.002:
					v = null
			elif ty == TYPE_VECTOR2:
				var dv = v0 - v
				if dv.length() < 0.02:
					v = null
			elif ty == TYPE_INT:
				if v0 == v:
					v = null
			elif ty == TYPE_BOOL:
				if v0 == v:
					v = null
			elif ty == TYPE_FLOAT:
				if abs(v0 - v) < 0.001:
					v = null
			else:
				print("unknown type ", ty, " ", v)
		if v != null:
			vd[k] = v
			fd0[k] = v
	return vd
