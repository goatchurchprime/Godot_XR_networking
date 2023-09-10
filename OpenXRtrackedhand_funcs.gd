class_name OpenXRtrackedhand_funcs

const hand_joint_node_shortnames = [ "hwr", 
	"ht0", "ht1", "ht2", "ht3",
	"hi0", "hi1", "hi2", "hi3", "hi4", 
	"hm0", "hm1", "hm2", "hm3", "hm4", 
	"hr0", "hr1", "hr2", "hr3", "hr4", 
	"hl0", "hl1", "hl2", "hl3", "hl4" ] 

static func gethandjointpositionsL(joint_transforms):
	assert (len(joint_transforms) == len(hand_joint_node_shortnames)+1)
	var handjointpositions = { }
	for i in range(len(hand_joint_node_shortnames)):
		handjointpositions[hand_joint_node_shortnames[i]] = joint_transforms[i+1].origin
	return handjointpositions

static func rotationtoalign(a, b):
	var axis = a.cross(b).normalized();
	if (axis.length_squared() != 0):
		var dot = a.dot(b)/(a.length()*b.length())
		dot = clamp(dot, -1.0, 1.0)
		var angle_rads = acos(dot)
		return Basis(axis, angle_rads)
	return Basis()

static func basisfrom(a, b):
	var vx = (b - a).normalized()
	var vy = vx.cross(-a.normalized())
	var vz = vx.cross(vy)
	return Basis(vx, vy, vz)

static func veclengstretchrat(vecB, vecT):
	var vecTleng = vecT.length()
	var vecBleng = vecB.length()
	var vecldiff = vecTleng - vecBleng
	return vecldiff/vecBleng

static func getovrhandrestdata(ovrhandmodel):
	var ovrhanddata = { "ovrhandmodel":ovrhandmodel }
	var slr = "r" if ovrhandmodel.has_node("ArmatureRight") else "l"
	var skel = ovrhandmodel.get_node("ArmatureRight/Skeleton3D") if ovrhandmodel.has_node("ArmatureRight") else ovrhandmodel.get_node("ArmatureLeft/Skeleton3D")	
	ovrhanddata["skel"] = skel
	for i in range(34):
		ovrhanddata[i] = skel.get_bone_rest(i)
		
	ovrhanddata["b_wrist"] = skel.find_bone("b_%s_wrist" % slr)
	ovrhanddata["b_thumb0"] = skel.find_bone("b_%s_thumb0" % slr)
	ovrhanddata["b_index1"] = skel.find_bone("b_%s_index1" % slr)
	ovrhanddata["b_middle1"] = skel.find_bone("b_%s_middle1" % slr)
	ovrhanddata["b_ring1"] = skel.find_bone("b_%s_ring1" % slr)
	ovrhanddata["b_pinky0"] = skel.find_bone("b_%s_pinky0" % slr)
	
	var hminverse = ovrhandmodel.global_transform.basis.inverse()
	var skelgtrans = skel.global_transform
	var globalbonepose6 = ovrhanddata[0]*ovrhanddata[ovrhanddata["b_index1"]]
	var globalbonepose14 = ovrhanddata[0]*ovrhanddata[ovrhanddata["b_ring1"]]

	ovrhanddata["posindex1"] = hminverse*((skelgtrans*globalbonepose6).origin - skelgtrans.origin)
	ovrhanddata["posring1"] = hminverse*((skelgtrans*globalbonepose14).origin - skelgtrans.origin)

	print("ppppooos  ", slr, " ", (ovrhanddata["posindex1"] - ovrhanddata["posring1"]).length())
	ovrhanddata["wristtransinverse"] = basisfrom(ovrhanddata["posindex1"], ovrhanddata["posring1"]).inverse()
	ovrhanddata["skeltrans"] = ovrhandmodel.global_transform.affine_inverse()*skelgtrans

	ovrhanddata["boneindexes"] = [ ovrhanddata["b_wrist"] ]
	for s in [ ovrhanddata["b_thumb0"]+1, ovrhanddata["b_index1"], ovrhanddata["b_middle1"], ovrhanddata["b_ring1"], ovrhanddata["b_pinky0"]+1 ]:
		for i in range(4):
			ovrhanddata["boneindexes"].push_back(s + i)
	return ovrhanddata

static func setvecstobonesG(ibR, ib0, p1, p2, p3, p4, ovrhandrestdata, ovrhandpose, tRboneposeG):
	var vec1 = p2 - p1
	var vec2 = p3 - p2
	var vec3 = p4 - p3
	var ib1 = ib0+1
	var ib2 = ib0+2
	var ib3 = ib0+3
	
	var Dskel = ovrhandrestdata["skel"]
	
	assert (Dskel.get_bone_parent(ib0) == ibR)
	assert (Dskel.get_bone_parent(ib1) == ib0)
	assert (Dskel.get_bone_parent(ib2) == ib1)
	assert (Dskel.get_bone_parent(ib3) == ib2)

	var t0bonerest = ovrhandrestdata[ib0]
	var t1bonerest = ovrhandrestdata[ib1]
	var t2bonerest = ovrhandrestdata[ib2]
	var t3bonerest = ovrhandrestdata[ib3]

	#tRboneposeG *= ovrhandrestdata[ibR]
	
	var t0bonerestG = tRboneposeG*t0bonerest
	# the rotation is to align within the coordinate frame of the bone (converted from the inverse of the basis tranform from global space vector)
	var t0boneposebasis = rotationtoalign(t1bonerest.origin, t0bonerestG.basis.inverse()*vec1)
	#var t0boneposeorigin = tRboneposeG.affine_inverse()*p1 - t0bonerest.origin
	var t0boneposeorigin = t0bonerestG.affine_inverse()*p1
	var t0bonepose = Transform3D(t0boneposebasis, t0boneposeorigin)
	var t0boneposeG = t0bonerestG*t0bonepose

	var t1bonerestG = t0boneposeG*t1bonerest
	var t1boneposebasis = rotationtoalign(t2bonerest.origin, t1bonerestG.basis.inverse()*vec2)
	var vec1rat = veclengstretchrat(t0boneposeG.basis*t1bonerest.origin, vec1)
	var t1bonepose = Transform3D(t1boneposebasis, t1bonerest.origin*vec1rat)
	var t1boneposeG = t1bonerestG*t1bonepose

	var t2bonerestG = t1boneposeG*t2bonerest
	var t2boneposebasis = rotationtoalign(t3bonerest.origin, t2bonerestG.basis.inverse()*vec3)
	var vec2rat = veclengstretchrat(t1boneposeG.basis*(t2bonerest.origin), vec2)
	var t2bonepose = Transform3D(t2boneposebasis, t2bonerest.origin*vec2rat)
	var t2boneposeG = t2bonerestG*t2bonepose

	var vec3rat = veclengstretchrat(t2boneposeG.basis*(t3bonerest.origin), vec3)
	var t3bonepose = Transform3D(Basis(), t3bonerest.origin*vec3rat)
	
	ovrhandpose[ib0] = t0bonepose
	ovrhandpose[ib1] = t1bonepose
	ovrhandpose[ib2] = t2bonepose
	ovrhandpose[ib3] = t3bonepose


static func setshapetobonesOVR(joint_transforms, ovrhandrestdata):
	var h = gethandjointpositionsL(joint_transforms)
#	OpenXRallhandsdata.Dcheckbonejointalignment(joint_transforms)
	var pknucklering = joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_RING_PROXIMAL_EXT].origin
	var pknuckleindex = joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_INDEX_PROXIMAL_EXT].origin
	var rhx = joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_MIDDLE_METACARPAL_EXT].basis.x
	#print("dd ", rhx.dot(pknucklering - pknuckleindex))
	
	if h["hi1"].is_equal_approx(h["hr1"]):
		return { "handtransform":joint_transforms[0] }
		
	var handbasis = basisfrom(h["hi1"] - h["hwr"], h["hr1"] - h["hwr"])

	var ovrhandmodelbasis = handbasis*ovrhandrestdata["wristtransinverse"]
	var ovrhandmodelorigin = h["hi1"] - ovrhandmodelbasis*ovrhandrestdata["posindex1"]
	var ovrhandpose = { "handtransform":Transform3D(ovrhandmodelbasis, ovrhandmodelorigin) }

	ovrhandpose[0] = Transform3D()
	var tRboneposeGR = ovrhandpose["handtransform"]*ovrhandrestdata["skeltrans"]
	var tRboneposeGR0 = tRboneposeGR*ovrhandrestdata[0]*ovrhandpose[0]

	ovrhandpose[1] = Transform3D()
	var tRboneposeGR1 = tRboneposeGR0*ovrhandrestdata[1]*ovrhandpose[1]
	setvecstobonesG(ovrhandrestdata["b_thumb0"], ovrhandrestdata["b_thumb0"]+1, h["ht0"], h["ht1"], h["ht2"], h["ht3"], ovrhandrestdata, ovrhandpose, tRboneposeGR1)

	setvecstobonesG(ovrhandrestdata["b_wrist"], ovrhandrestdata["b_index1"], h["hi1"], h["hi2"], h["hi3"], h["hi4"], ovrhandrestdata, ovrhandpose, tRboneposeGR0)
	setvecstobonesG(ovrhandrestdata["b_wrist"], ovrhandrestdata["b_middle1"], h["hm1"], h["hm2"], h["hm3"], h["hm4"], ovrhandrestdata, ovrhandpose, tRboneposeGR0)
	setvecstobonesG(ovrhandrestdata["b_wrist"], ovrhandrestdata["b_ring1"], h["hr1"], h["hr2"], h["hr3"], h["hr4"], ovrhandrestdata, ovrhandpose, tRboneposeGR0)

	var pinky0 = ovrhandrestdata["b_pinky0"]
	ovrhandpose[pinky0] = Transform3D()
	var tRboneposeGR18 = tRboneposeGR0*ovrhandrestdata[pinky0]*ovrhandpose[pinky0]
	setvecstobonesG(pinky0, pinky0+1, h["hl1"], h["hl2"], h["hl3"], h["hl4"], ovrhandrestdata, ovrhandpose, tRboneposeGR18)
	
	for i in ovrhandrestdata["boneindexes"]:
		ovrhandpose[i] = ovrhandrestdata[i] * ovrhandpose[i]
	return ovrhandpose

