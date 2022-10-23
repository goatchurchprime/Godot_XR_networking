class_name OpenXRtrackedhand_funcs

const hand_joint_node_names = [
	"Wrist",
	"Wrist/ThumbMetacarpal",
	"Wrist/ThumbMetacarpal/ThumbProximal",
	"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal",
	"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal/ThumbTip",
	"Wrist/IndexMetacarpal",
	"Wrist/IndexMetacarpal/IndexProximal",
	"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate",
	"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal",
	"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip",
	"Wrist/MiddleMetacarpal",
	"Wrist/MiddleMetacarpal/MiddleProximal",
	"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate",
	"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal",
	"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal/MiddleTip",
	"Wrist/RingMetacarpal",
	"Wrist/RingMetacarpal/RingProximal",
	"Wrist/RingMetacarpal/RingProximal/RingIntermediate",
	"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal",
	"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal/RingTip",
	"Wrist/LittleMetacarpal",
	"Wrist/LittleMetacarpal/LittleProximal",
	"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate",
	"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal",
	"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal/LittleTip"
]
const hand_joint_node_shortnames = [ "hwr", 
	"ht0", "ht1", "ht2", "ht3",
	"hi0", "hi1", "hi2", "hi3", "hi4", 
	"hm0", "hm1", "hm2", "hm3", "hm4", 
	"hr0", "hr1", "hr2", "hr3", "hr4", 
	"hl0", "hl1", "hl2", "hl3", "hl4" ] 

static func gethandjointpositions(hand):
	assert (len(hand_joint_node_names) == len(hand_joint_node_shortnames))
	var handjointpositions = { }
	var handtransinverse = hand.get_parent().global_transform.affine_inverse()
	for i in range(len(hand_joint_node_names)):
		handjointpositions[hand_joint_node_shortnames[i]] = (handtransinverse*hand.get_node(hand_joint_node_names[i]).global_transform).origin
	return handjointpositions

static func gethandjointpositionsL(joint_transforms):
	assert (len(joint_transforms) == len(hand_joint_node_shortnames)+1)
	var handjointpositions = { }
	for i in range(len(hand_joint_node_names)):
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
	var skel = ovrhandmodel.get_node("ArmatureRight/Skeleton") if ovrhandmodel.has_node("ArmatureRight") else ovrhandmodel.get_node("ArmatureLeft/Skeleton")	
	ovrhanddata["skel"] = skel
	for i in range(24):
		ovrhanddata[i] = skel.get_bone_rest(i)
		
	var hminverse = ovrhandmodel.global_transform.basis.inverse()
	var skelgtrans = skel.global_transform
	var globalbonepose6 = ovrhanddata[0]*ovrhanddata[6]
	var globalbonepose14 = ovrhanddata[0]*ovrhanddata[14]
	ovrhanddata["posindex1"] = hminverse*((skelgtrans*globalbonepose6).origin - skelgtrans.origin)
	ovrhanddata["posring1"] = hminverse*((skelgtrans*globalbonepose14).origin - skelgtrans.origin)
	ovrhanddata["wristtransinverse"] = basisfrom(ovrhanddata["posindex1"], ovrhanddata["posring1"]).inverse()
	ovrhanddata["skeltrans"] = ovrhandmodel.global_transform.affine_inverse()*skelgtrans
	
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
	var t0bonepose = Transform(t0boneposebasis, t0boneposeorigin)
	var t0boneposeG = t0bonerestG*t0bonepose

	var t1bonerestG = t0boneposeG*t1bonerest
	var t1boneposebasis = rotationtoalign(t2bonerest.origin, t1bonerestG.basis.inverse()*vec2)
	var vec1rat = veclengstretchrat(t0boneposeG.basis*t1bonerest.origin, vec1)
	var t1bonepose = Transform(t1boneposebasis, t1bonerest.origin*vec1rat)
	var t1boneposeG = t1bonerestG*t1bonepose

	var t2bonerestG = t1boneposeG*t2bonerest
	var t2boneposebasis = rotationtoalign(t3bonerest.origin, t2bonerestG.basis.inverse()*vec3)
	var vec2rat = veclengstretchrat(t1boneposeG.basis*(t2bonerest.origin), vec2)
	var t2bonepose = Transform(t2boneposebasis, t2bonerest.origin*vec2rat)
	var t2boneposeG = t2bonerestG*t2bonepose

	var vec3rat = veclengstretchrat(t2boneposeG.basis*(t3bonerest.origin), vec3)
	var t3bonepose = Transform(Basis(), t3bonerest.origin*vec3rat)
	
	ovrhandpose[ib0] = t0bonepose
	ovrhandpose[ib1] = t1bonepose
	ovrhandpose[ib2] = t2bonepose
	ovrhandpose[ib3] = t3bonepose


static func setshapetobonesG(handjointpositions, ovrhandrestdata):
	var handbasis = basisfrom(handjointpositions["hi1"] - handjointpositions["hwr"], handjointpositions["hr1"] - handjointpositions["hwr"])
	var ovrhandmodelbasis = handbasis*ovrhandrestdata["wristtransinverse"]
	var ovrhandmodelorigin = handjointpositions["hi1"] - ovrhandmodelbasis*ovrhandrestdata["posindex1"]
	var ovrhandpose = { "handtransform":Transform(ovrhandmodelbasis, ovrhandmodelorigin) }
	return ovrhandpose

static func setshapetobonesOVR(h, ovrhandrestdata):
	var handbasis = basisfrom(h["hi1"] - h["hwr"], h["hr1"] - h["hwr"])
	var ovrhandmodelbasis = handbasis*ovrhandrestdata["wristtransinverse"]
	var ovrhandmodelorigin = h["hi1"] - ovrhandmodelbasis*ovrhandrestdata["posindex1"]
	var ovrhandpose = { "handtransform":Transform(ovrhandmodelbasis, ovrhandmodelorigin) }

	ovrhandpose[0] = Transform()
	var tRboneposeGR = ovrhandpose["handtransform"]*ovrhandrestdata["skeltrans"]
	var tRboneposeGR0 = tRboneposeGR*ovrhandrestdata[0]*ovrhandpose[0]

	ovrhandpose[1] = Transform()
	var tRboneposeGR1 = tRboneposeGR0*ovrhandrestdata[1]*ovrhandpose[1]
	setvecstobonesG(1, 2, h["ht0"], h["ht1"], h["ht2"], h["ht3"], ovrhandrestdata, ovrhandpose, tRboneposeGR1)

	setvecstobonesG(0, 6, h["hi1"], h["hi2"], h["hi3"], h["hi4"], ovrhandrestdata, ovrhandpose, tRboneposeGR0)
	setvecstobonesG(0, 10, h["hm1"], h["hm2"], h["hm3"], h["hm4"], ovrhandrestdata, ovrhandpose, tRboneposeGR0)
	setvecstobonesG(0, 14, h["hr1"], h["hr2"], h["hr3"], h["hr4"], ovrhandrestdata, ovrhandpose, tRboneposeGR0)

	ovrhandpose[18] = Transform()
	var tRboneposeGR18 = tRboneposeGR0*ovrhandrestdata[18]*ovrhandpose[18]
	setvecstobonesG(18, 19, h["hl1"], h["hl2"], h["hl3"], h["hl4"], ovrhandrestdata, ovrhandpose, tRboneposeGR18)
	
	return ovrhandpose


static func setshapetobonesRPM(h, skelarmrest, rpmhandspose, rpmhandrestdata, bleft):
	var handbasis = basisfrom(h["hi1"] - h["hwr"], h["hr1"] - h["hwr"])
	if bleft:
		handbasis = basisfrom(h["hr1"] - h["hwr"], h["hi1"] - h["hwr"])

	var di = 24 if bleft else 0
	assert (rpmhandrestdata["skel"].get_bone_name(36-di) == "LeftHand" if bleft else "RightHand")

	var shoulderpos = skelarmrest.origin
	var wristpos = h["hwr"]
	#rpmhandspose[34-di].origin = Vector3(0,0,0)
	#skelarmtrans = skelarmrest*rpmhandspose[34-di]
	#shoulderpos = skelarmtrans.origin
	#skelforearmrest = skelarmtrans*rpmhandrestdata[35-di]
	#skelforearmtrans = skelforearmrest*rpmhandspose[35-di]
	#elbowpos = skelforearmtrans.origin
	#skelhandrest = skelforearmtrans*rpmhandrestdata[36-di]
	#skelhandtrans = skelhandrest*rpmhandspose[36-di]
	#skelhandtrans = Transform(wristbasis, wristpos)
	var upperarmlengthSq = rpmhandrestdata[35-di].origin.length_squared()
	var forearmlengthSq = rpmhandrestdata[36-di].origin.length_squared()
	var armvector = wristpos - shoulderpos
	var elbowperpN = armvector.cross(Vector3(0, -1 if bleft else 1, 0)).normalized()
	var armvectorlengthSq = armvector.length_squared()
	var lex = (armvectorlengthSq + upperarmlengthSq - forearmlengthSq)/(2*armvectorlengthSq)
	var ey = sqrt(max(0.0, upperarmlengthSq - lex*lex*armvectorlengthSq))

	var elbowpos = lerp(shoulderpos, wristpos, lex) + elbowperpN*ey
	
	var vecupperarm = elbowpos - shoulderpos
	var vecforearm = wristpos - elbowpos
	var skelarmposebasis = rotationtoalign(rpmhandrestdata[35-di].origin, skelarmrest.basis.inverse()*vecupperarm)
	rpmhandspose[34-di] = Transform(skelarmposebasis, Vector3(0,0,0))
	#rpmhandspose[34-di] = Transform()
	
	var skelarmtrans = skelarmrest*rpmhandspose[34-di]
	#shoulderpos = skelarmtrans.origin
	var skelforearmrest = skelarmtrans*rpmhandrestdata[35-di]
	#skelforearmtrans = skelforearmrest*rpmhandspose[35-di]
	#elbowpos = skelforearmtrans.origin
	#skelhandrest = skelforearmtrans*rpmhandrestdata[36-di]
	#skelhandtrans = skelhandrest*rpmhandspose[36-di]
	#wristpos = skelhandtrans.origin

	# (A.basis, A.origin)*(B.basis, B.origin) = (A.basis*B.basis, A.origin + A.basis*B.origin)
	#skelforearmtrans = skelforearmrest*(skelforearmposebasis, skelforearmposeorigin)
	#elbowpos = skelforearmtrans.origin = skelforearmrest.origin + skelforearmrest.basis*skelforearmposeorigin
	var skelforearmposeorigin = skelforearmrest.basis.inverse()*(elbowpos - skelforearmrest.origin)
	var skelforearmposebasis = rotationtoalign(rpmhandrestdata[36-di].origin, skelforearmrest.basis.inverse()*vecforearm)
	rpmhandspose[35-di] = Transform(skelforearmposebasis, skelforearmposeorigin)
	var skelforearmtrans = skelforearmrest*rpmhandspose[35-di]
	var skelhandrest = skelforearmtrans*rpmhandrestdata[36-di]

	var restwristbasis = rpmhandrestdata["wristleftbasis" if bleft else "wristrightbasis"]
	#skelhandrest = skelforearmtrans*rpmhandrestdata[36-di]

	#skelhandtrans = skelhandrest*rpmhandspose[36-di]
	#skelhandtrans = Transform(wristbasis, wristpos)

	#wristbasis = skelhandrest.basis*skelhandposebasis
	var skelhandposebasis = skelhandrest.basis.inverse()*handbasis*restwristbasis.inverse()
	#skelhandtrans = skelhandrest*Transform(skelhandposebasis, skelhandposeorigin)
	#wristpos = skelhandtrans.origin = skelhandrest.origin + skelhandrest.basis*skelhandposeorigin
	var skelhandposeorigin = skelhandrest.basis.inverse()*(wristpos - skelhandrest.origin)
	rpmhandspose[36-di] = Transform(skelhandposebasis, skelhandposeorigin)
	var skelhandtrans = skelforearmtrans*rpmhandrestdata[36-di]*rpmhandspose[36-di]

	setvecstobonesG(36-di, 37-di, h["ht0"], h["ht1"], h["ht2"], h["ht3"], rpmhandrestdata, rpmhandspose, skelhandtrans)
	setvecstobonesG(36-di, 41-di, h["hi1"], h["hi2"], h["hi3"], h["hi4"], rpmhandrestdata, rpmhandspose, skelhandtrans)
	setvecstobonesG(36-di, 45-di, h["hm1"], h["hm2"], h["hm3"], h["hm4"], rpmhandrestdata, rpmhandspose, skelhandtrans)
	setvecstobonesG(36-di, 49-di, h["hr1"], h["hr2"], h["hr3"], h["hr4"], rpmhandrestdata, rpmhandspose, skelhandtrans)
	setvecstobonesG(36-di, 53-di, h["hl1"], h["hl2"], h["hl3"], h["hl4"], rpmhandrestdata, rpmhandspose, skelhandtrans)

static func getrpmhandrestdata(rpmavatar):
	var rpmavatardata = { "rpmavatar":rpmavatar }
	var skel = rpmavatar.get_node("Armature/Skeleton")
	rpmavatardata["skel"] = skel

	for i in range(34, 57):
		rpmavatardata[i] = skel.get_bone_rest(i)
	for i in range(10, 33):
		rpmavatardata[i] = skel.get_bone_rest(i)
		
	assert (skel.get_bone_name(33) == "RightShoulder")
	assert (skel.get_bone_name(34) == "RightArm")
	assert (skel.get_bone_name(35) == "RightForeArm")
	assert (skel.get_bone_name(36) == "RightHand")
	assert (skel.get_bone_name(41) == "RightHandIndex1")
	assert (skel.get_bone_name(49) == "RightHandRing1")
	var boneposeI1right = rpmavatardata[36]*rpmavatardata[41]
	var boneposeR1right = rpmavatardata[36]*rpmavatardata[49]
	var wristposright = Vector3(0,0,0)
	rpmavatardata["posindex1right"] = boneposeI1right.origin - wristposright
	rpmavatardata["posring1right"] = boneposeR1right.origin - wristposright
	rpmavatardata["wristrightbasis"] = basisfrom(rpmavatardata["posindex1right"], rpmavatardata["posring1right"])
	rpmavatardata["wristrightbasisinverse"] = basisfrom(rpmavatardata["posindex1right"], rpmavatardata["posring1right"]).inverse()

	assert (skel.get_bone_name(10) == "LeftArm")
	assert (skel.get_bone_name(11) == "LeftForeArm")
	assert (skel.get_bone_name(12) == "LeftHand")
	assert (skel.get_bone_name(17) == "LeftHandIndex1")
	assert (skel.get_bone_name(25) == "LeftHandRing1")
	var boneposeI1left = rpmavatardata[12]*rpmavatardata[17]
	var boneposeR1left = rpmavatardata[12]*rpmavatardata[25]
	var wristposleft = Vector3(0,0,0)
	rpmavatardata["posindex1left"] = boneposeI1left.origin - wristposleft
	rpmavatardata["posring1left"] = boneposeR1left.origin - wristposleft
	#rpmavatardata["wristleftbasisinverse"] = basisfrom(rpmavatardata["posindex1left"], rpmavatardata["posring1left"]).inverse()
	rpmavatardata["wristleftbasis"] = basisfrom(rpmavatardata["posring1left"], rpmavatardata["posindex1left"])
	rpmavatardata["wristleftbasisinverse"] = basisfrom(rpmavatardata["posring1left"], rpmavatardata["posindex1left"]).inverse()
	
	return rpmavatardata

