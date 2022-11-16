extends Spatial


onready var ovrhandmodel = $ovr_right_hand_model
#onready var skel = $ovr_right_hand_model/ArmatureRight/Skeleton
onready var rpmavatar = $readyplayerme_avatar

const Dapply_readyplayerme_hand = false

func _process(delta):
	pass
	

	#setbonestorods()
	#hand()
	#sethandpos()

var jointransforms1 = str2var("[ Transform( 0.763934, 0.636679, 0.105093, -0.1919, 0.379641, -0.905012, -0.6161, 0.671202, 0.4122, -0.00185875, 0.979083, -0.225783 ), Transform( 0.763934, 0.636679, 0.105093, -0.1919, 0.379641, -0.905012, -0.6161, 0.671202, 0.4122, 0.0048456, 0.934733, -0.205102 ), Transform( 0.205111, -0.575577, 0.791606, 0.911957, -0.181249, -0.368081, 0.355336, 0.797408, 0.487725, -0.0336159, 0.966016, -0.219091 ), Transform( 0.395387, -0.700653, 0.593931, 0.869325, 0.0766836, -0.488256, 0.296553, 0.709369, 0.639415, -0.0601839, 0.97837, -0.23546 ), Transform( 0.194895, -0.682283, 0.704631, 0.921546, -0.118585, -0.369716, 0.33581, 0.721406, 0.605644, -0.0809025, 0.995402, -0.257766 ), Transform( 0.194895, -0.682283, 0.704631, 0.921546, -0.118586, -0.369717, 0.33581, 0.721406, 0.605644, -0.0993775, 1.0053, -0.272142 ), Transform( 0.763934, 0.636679, 0.105093, -0.1919, 0.379641, -0.905012, -0.6161, 0.671202, 0.4122, -0.021144, 0.96867, -0.218284 ), Transform( 0.817149, 0.548315, 0.177812, -0.289382, 0.65701, -0.696129, -0.498523, 0.517386, 0.695548, -0.0289489, 1.02621, -0.23604 ), Transform( 0.790578, 0.503933, 0.347904, -0.332431, 0.830317, -0.447284, -0.514272, 0.237959, 0.823954, -0.0359105, 1.05347, -0.263272 ), Transform( 0.790055, 0.545118, 0.280464, -0.383217, 0.796251, -0.468111, -0.478495, 0.262355, 0.837981, -0.0446387, 1.06469, -0.283943 ), Transform( 0.790055, 0.545118, 0.280463, -0.383217, 0.796251, -0.468111, -0.478495, 0.262354, 0.837981, -0.0502953, 1.07622, -0.303157 ), Transform( 0.763934, 0.636679, 0.105093, -0.1919, 0.379641, -0.905012, -0.6161, 0.671202, 0.4122, -0.00604683, 0.96468, -0.22548 ), Transform( 0.765134, 0.62384, 0.159355, -0.351586, 0.612143, -0.708285, -0.539405, 0.485905, 0.687705, -0.00856308, 1.02343, -0.246464 ), Transform( 0.751791, 0.535043, 0.385408, -0.372005, 0.826728, -0.422059, -0.544446, 0.173926, 0.820565, -0.0156245, 1.05482, -0.276938 ), Transform( 0.703524, 0.602859, 0.376317, -0.442059, 0.785838, -0.432483, -0.556451, 0.137907, 0.819356, -0.026585, 1.06682, -0.300274 ), Transform( 0.703524, 0.602859, 0.376317, -0.442059, 0.785838, -0.432483, -0.556451, 0.137907, 0.819356, -0.035351, 1.07875, -0.321405 ), Transform( 0.763934, 0.636679, 0.105093, -0.1919, 0.379641, -0.905012, -0.6161, 0.671202, 0.4122, 0.00894202, 0.961893, -0.233602 ), Transform( 0.70549, 0.69828, 0.121198, -0.400402, 0.533809, -0.7448, -0.584775, 0.47692, 0.65619, 0.00470529, 1.01157, -0.258473 ), Transform( 0.649964, 0.595619, 0.472001, -0.447387, 0.80194, -0.395899, -0.614322, 0.0461529, 0.787705, -0.000173481, 1.04156, -0.284888 ), Transform( 0.61193, 0.560968, 0.557545, -0.436036, 0.827412, -0.353924, -0.65986, -0.0265331, 0.75092, -0.0131209, 1.05242, -0.306495 ), Transform( 0.61193, 0.560968, 0.557545, -0.436036, 0.827412, -0.353924, -0.65986, -0.0265332, 0.75092, -0.0260273, 1.06256, -0.325572 ), Transform( 0.445769, 0.894193, -0.0413262, -0.570881, 0.248427, -0.782546, -0.689481, 0.372427, 0.621219, 0.0130946, 0.958318, -0.240754 ), Transform( 0.60121, 0.798902, 0.0173408, -0.495026, 0.389389, -0.776741, -0.627292, 0.4584, 0.629582, 0.0150401, 0.995195, -0.270027 ), Transform( 0.521341, 0.794031, 0.3126, -0.596683, 0.601079, -0.53167, -0.61006, 0.0906581, 0.787152, 0.0144902, 1.01983, -0.289992 ), Transform( 0.480036, 0.671801, 0.564135, -0.549112, 0.731617, -0.403996, -0.684136, -0.115841, 0.720097, 0.00793593, 1.03097, -0.306496 ), Transform( 0.480036, 0.671801, 0.564135, -0.549112, 0.731618, -0.403996, -0.684136, -0.115841, 0.720097, -0.00410914, 1.04117, -0.322763 ) ]")
var jointransforms2 = str2var("[ Transform( 0.0568722, 0.997616, -0.039092, -0.900991, 0.0344173, -0.432469, -0.430093, 0.059817, 0.900801, 0.0140669, 0.960979, -0.26718 ), Transform( 0.0568722, 0.997616, -0.039092, -0.900991, 0.0344173, -0.432469, -0.430093, 0.059817, 0.900801, 0.0134972, 0.938872, -0.223015 ), Transform( 0.939285, 0.319308, 0.12564, -0.0236496, 0.425522, -0.904639, -0.342321, 0.846743, 0.407238, -0.00235501, 0.982168, -0.24182 ), Transform( 0.882143, 0.470972, 0.00279835, -0.2194, 0.416185, -0.882413, -0.416757, 0.777801, 0.470467, -0.00657177, 1.01253, -0.255488 ), Transform( 0.947526, 0.318255, 0.0301435, -0.0338866, 0.193754, -0.980464, -0.317878, 0.927994, 0.194372, -0.0066694, 1.04331, -0.2719 ), Transform( 0.947526, 0.318255, 0.0301435, -0.0338866, 0.193754, -0.980464, -0.317878, 0.927994, 0.194372, -0.0064415, 1.06838, -0.27607 ), Transform( 0.0568722, 0.997616, -0.039092, -0.900991, 0.0344173, -0.432469, -0.430093, 0.059817, 0.900801, 0.0045624, 0.97342, -0.24827 ), Transform( 0.143312, 0.380619, 0.913559, -0.858444, 0.50715, -0.0766295, -0.492478, -0.773258, 0.399422, 0.00845379, 1.00337, -0.302276 ), Transform( 0.13528, -0.956574, 0.258196, -0.883433, 0.00153482, 0.468555, -0.448604, -0.291486, -0.844861, -0.0273132, 1.00637, -0.317913 ), Transform( 0.164046, -0.84985, -0.500843, -0.860935, -0.371191, 0.347861, -0.481538, 0.374128, -0.792558, -0.0337909, 0.994616, -0.296718 ), Transform( 0.164046, -0.84985, -0.500843, -0.860935, -0.371191, 0.347861, -0.481538, 0.374128, -0.792558, -0.0230781, 0.98593, -0.278172 ), Transform( 0.0568722, 0.997616, -0.039092, -0.900991, 0.0344173, -0.432469, -0.430093, 0.059817, 0.900801, 0.00705209, 0.957435, -0.253358 ), Transform( 0.044574, 0.277152, 0.959791, -0.914207, 0.398679, -0.0726665, -0.402789, -0.874209, 0.271145, 0.0146366, 0.983086, -0.311345 ), Transform( 0.0479952, -0.941439, 0.333749, -0.924445, 0.0846757, 0.371794, -0.378282, -0.326377, -0.866245, -0.0278941, 0.986306, -0.32336 ), Transform( 0.220726, -0.772857, -0.594955, -0.907627, -0.386078, 0.164795, -0.357062, 0.503623, -0.786684, -0.0373855, 0.975733, -0.298725 ), Transform( 0.220726, -0.772857, -0.594955, -0.907627, -0.386078, 0.164795, -0.357062, 0.503623, -0.786683, -0.0228901, 0.970743, -0.277974 ), Transform( 0.0568722, 0.997616, -0.039092, -0.900991, 0.0344173, -0.432469, -0.430093, 0.059817, 0.900801, 0.00958553, 0.940239, -0.26238 ), Transform( -0.0415731, 0.275382, 0.960435, -0.927454, 0.346897, -0.13961, -0.371618, -0.896564, 0.240983, 0.0113777, 0.961991, -0.313647 ), Transform( -0.0383057, -0.968029, 0.247897, -0.958312, 0.105881, 0.265381, -0.283144, -0.227397, -0.93173, -0.0272843, 0.967611, -0.323347 ), Transform( 0.0264407, -0.738158, -0.67411, -0.969615, -0.182998, 0.162354, -0.243204, 0.649334, -0.720568, -0.0340843, 0.960332, -0.297789 ), Transform( 0.0264406, -0.738158, -0.67411, -0.969615, -0.182999, 0.162354, -0.243204, 0.649334, -0.720568, -0.018375, 0.955693, -0.278682 ), Transform( -0.355918, 0.933626, 0.0407944, -0.922666, -0.344139, -0.173941, -0.148357, -0.0995485, 0.983911, 0.0065217, 0.932358, -0.265492 ), Transform( -0.227983, 0.347223, 0.909648, -0.929378, 0.200954, -0.309634, -0.290309, -0.915999, 0.276888, 0.00459915, 0.940558, -0.311857 ), Transform( -0.145871, -0.956724, 0.251796, -0.979748, 0.174993, 0.0973123, -0.137163, -0.232502, -0.962875, -0.0242475, 0.950377, -0.320638 ), Transform( -0.129099, -0.716498, -0.685539, -0.990163, 0.0555344, 0.128423, -0.053944, 0.695375, -0.716619, -0.0295269, 0.948336, -0.300449 ), Transform( -0.1291, -0.716498, -0.685539, -0.990163, 0.0555344, 0.128423, -0.053944, 0.695375, -0.716619, -0.0148798, 0.945752, -0.283346 ) ]")
var jointransforms3 = str2var("[ Transform( 0.0634282, -0.993399, 0.0955754, 0.996042, 0.0570382, -0.0681709, 0.0622695, 0.0995211, 0.993085, -0.0555168, 0.998378, -0.357373 ), Transform( 0.0634282, -0.993399, 0.0955754, 0.996042, 0.0570382, -0.0681709, 0.0622695, 0.0995211, 0.993085, -0.0520461, 0.995975, -0.308161 ), Transform( -0.815712, 0.0340706, -0.577454, -0.177378, -0.964906, 0.193633, -0.550591, 0.260377, 0.793129, -0.0323824, 0.974704, -0.351154 ), Transform( -0.88338, 0.00535922, -0.468628, -0.00120317, -0.999957, -0.00916749, -0.468657, -0.00753447, 0.883348, -0.0130018, 0.968205, -0.377773 ), Transform( -0.815848, 0.328598, -0.475832, -0.131924, -0.906924, -0.400106, -0.563018, -0.263652, 0.783262, 0.00334567, 0.968525, -0.408588 ), Transform( -0.815848, 0.328598, -0.475832, -0.131924, -0.906924, -0.400106, -0.563018, -0.263652, 0.783262, 0.0152082, 0.977628, -0.429139 ), Transform( 0.0634282, -0.993399, 0.0955754, 0.996042, 0.0570382, -0.0681709, 0.0622694, 0.0995211, 0.993085, -0.0429163, 0.981761, -0.349793 ), Transform( -0.0101328, -0.84282, -0.5381, 0.985753, 0.0819322, -0.146892, 0.167891, -0.531923, 0.829983, -0.0555563, 0.978085, -0.408836 ), Transform( 0.0247917, -0.231541, -0.972509, 0.978265, 0.205954, -0.0240966, 0.205872, -0.950774, 0.231615, -0.034489, 0.983836, -0.441331 ), Transform( -0.0188001, 0.0452657, -0.998798, 0.969811, 0.243751, -0.00720771, 0.243132, -0.968781, -0.0484818, -0.0100907, 0.98444, -0.447141 ), Transform( -0.0188001, 0.0452657, -0.998798, 0.969811, 0.243751, -0.00720775, 0.243132, -0.968781, -0.0484817, 0.0130088, 0.98516, -0.446973 ), Transform( 0.0634282, -0.993399, 0.0955754, 0.996042, 0.0570382, -0.0681709, 0.0622694, 0.0995211, 0.993085, -0.0456384, 0.998505, -0.346133 ), Transform( 0.0908061, -0.951679, -0.293362, 0.93566, 0.182404, -0.302107, 0.341019, -0.247054, 0.907012, -0.0589876, 1.00078, -0.406584 ), Transform( 0.110386, -0.740131, -0.66334, 0.92842, 0.315014, -0.196984, 0.354755, -0.594114, 0.721926, -0.0459881, 1.01417, -0.446776 ), Transform( 0.181654, -0.642287, -0.744627, 0.892475, 0.425633, -0.149413, 0.412904, -0.63742, 0.650543, -0.0271236, 1.01977, -0.467307 ), Transform( 0.181654, -0.642287, -0.744627, 0.892475, 0.425633, -0.149413, 0.412904, -0.63742, 0.650543, -0.00863028, 1.0244, -0.484688 ), Transform( 0.0634282, -0.993399, 0.0955754, 0.996042, 0.0570382, -0.0681709, 0.0622694, 0.0995211, 0.993085, -0.0483265, 1.01348, -0.343465 ), Transform( 0.173889, -0.96557, -0.193489, 0.839972, 0.247987, -0.482648, 0.514013, -0.0785985, 0.854174, -0.0529575, 1.01979, -0.398633 ), Transform( 0.247053, -0.721639, -0.646685, 0.813658, 0.516921, -0.265993, 0.526236, -0.460466, 0.714875, -0.0451687, 1.03922, -0.433017 ), Transform( 0.29998, -0.594921, -0.745709, 0.815732, 0.565244, -0.122799, 0.494563, -0.571462, 0.654858, -0.0274295, 1.04651, -0.452627 ), Transform( 0.29998, -0.594921, -0.745709, 0.815732, 0.565244, -0.122799, 0.494563, -0.571462, 0.654858, -0.00961157, 1.05075, -0.469888 ), Transform( 0.475273, -0.879655, -0.0179547, 0.829807, 0.454937, -0.323191, 0.292464, 0.138705, 0.946164, -0.0442423, 1.02146, -0.342581 ), Transform( 0.246481, -0.958103, -0.145895, 0.619519, 0.271531, -0.736524, 0.745281, 0.0911544, 0.66049, -0.0433964, 1.03669, -0.387168 ), Transform( 0.329488, -0.660259, -0.674904, 0.517153, 0.72426, -0.45607, 0.789931, -0.198759, 0.58009, -0.0387697, 1.06005, -0.408114 ), Transform( 0.392193, -0.682388, -0.616873, 0.561594, 0.708741, -0.426964, 0.728558, -0.17898, 0.661188, -0.0246191, 1.06961, -0.420276 ), Transform( 0.392193, -0.682388, -0.616873, 0.561594, 0.708741, -0.426964, 0.728558, -0.17898, 0.661188, -0.0116157, 1.08002, -0.435649 ) ]")
var jointtransforms = [jointransforms1,jointransforms2,jointransforms3]

var hand_joint_node_shortnames = [ "hwr", 
	"ht0", "ht1", "ht2", "ht3",
	"hi0", "hi1", "hi2", "hi3", "hi4", 
	"hm0", "hm1", "hm2", "hm3", "hm4", 
	"hr0", "hr1", "hr2", "hr3", "hr4", 
	"hl0", "hl1", "hl2", "hl3", "hl4" ] 

func rotationtoalign(a, b):
	var axis = a.cross(b).normalized();
	if (axis.length_squared() != 0):
		var dot = a.dot(b)/(a.length()*b.length())
		dot = clamp(dot, -1.0, 1.0)
		var angle_rads = acos(dot)
		return Basis(axis, angle_rads)
	return Basis()

func basisfrom(a, b):
	var vx = (b - a).normalized()
	var vy = vx.cross(-a.normalized())
	var vz = vx.cross(vy)
	return Basis(vx, vy, vz)

func veclengstretchrat(vecB, vecT):
	var vecTleng = vecT.length()
	var vecBleng = vecB.length()
	var vecldiff = vecTleng - vecBleng
	return vecldiff/vecBleng


func applyjointpose(jointtransform):
	for i in range(26):
		$quickjointnodes.get_child(i).transform = jointtransform[i]
	sethandposfromnodes()
	
var ovrhandrestdata = null
var lowpolyhandrestdata = null
var rpmavatarhandrestdata = null
var gxthandrestdata = null
func _ready():
	ovrhandrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata(ovrhandmodel)
	lowpolyhandrestdata = OpenXRtrackedhand_funcs.getlowpolyhandrestdata($RightHand)
	rpmavatarhandrestdata = OpenXRtrackedhand_funcs.getrpmhandrestdata(rpmavatar)
	gxthandrestdata = OpenXRtrackedhand_funcs.getGXThandrestdata($RightHandGXT)
	$RightHandGXT/AnimationTree.active = false

	var mi = $quickjointnodes.get_child(0)
	for i in range(25):
		$quickjointnodes.add_child(mi.duplicate())
	applyjointpose(jointtransforms[0])
	$TrackballCameraOrigin.transform.origin = jointtransforms[0][0].origin


# (A.basis, A.origin)*(B.basis, B.origin) = (A.basis*B.basis, A.origin + A.basis*B.origin)ovrhandrestdata
func sethandposfromnodes():
	var joint_transforms = jointtransforms[0]
	var h = OpenXRtrackedhand_funcs.gethandjointpositionsL(joint_transforms)
	
	#$MeshInstance_marker2.global_transform = $Right_hand/Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal/ThumbTip.global_transform
#	$MeshInstance_marker2.global_transform = $Right_hand/Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal.global_transform
	$MeshInstance_marker2.global_transform.origin = h["ht3"]

	if $RightHandGXT.visible:
		var gxthandpose = OpenXRtrackedhand_funcs.setshapetobonesLowPoly(joint_transforms, gxthandrestdata, true)
		var skel = gxthandrestdata["skel"]
		print(skel, " ", $RightHandGXT/hand_r/Armature_Left/Skeleton)
		for i in range(20):
			skel.set_bone_pose(i, gxthandpose[i])
		$RightHandGXT.transform = gxthandpose["handtransform"]
		$MeshInstance_marker.global_transform = skel.global_transform*skel.get_bone_global_pose(3)

		#$MeshInstance_marker/MeshInstance_marker.scale = Vector3(0.1,0.1,1)
		#return 		
		
	
	if $RightHand.visible:
		var lowpolyhandpose = OpenXRtrackedhand_funcs.setshapetobonesLowPoly(joint_transforms, lowpolyhandrestdata, true)
		var skel = lowpolyhandrestdata["skel"]

		print("sdfsf")
		print(skel.get_bone_rest(0)*skel.get_bone_pose(0))
		print(skel.get_bone_global_pose(0))
		print(skel.get_bone_rest(0)*skel.get_bone_pose(0)*skel.get_bone_rest(4)*skel.get_bone_pose(4))
		print(skel.get_bone_global_pose(4))

		for i in range(20):
			skel.set_bone_pose(i, lowpolyhandpose[i])

		print(skel.get_bone_pose(4))
		print(lowpolyhandpose[4])
		print("ggg")
		print(skel.get_bone_rest(0)*skel.get_bone_pose(0)*skel.get_bone_rest(4)*skel.get_bone_pose(4))
		print(skel.get_bone_global_pose(4))

#		$RightHand.transform = lowpolyhandpose["handtransform"]
#		$MeshInstance_marker.global_transform = skel.global_transform*skel.get_bone_global_pose(6)
		
#		$MeshInstance_marker.global_transform = skel.global_transform*skel.get_bone_global_pose(4)
		#$MeshInstance_marker/MeshInstance_marker.scale = Vector3(0.1,0.1,1)
		return 		

	if Dapply_readyplayerme_hand:
		var rpmavatar = rpmavatarhandrestdata["rpmavatar"]
		var skel = rpmavatarhandrestdata["skel"]
		assert (skel.get_bone_name(33) == "RightShoulder")
		assert (skel.get_bone_name(34) == "RightArm")
		assert (skel.get_bone_name(35) == "RightForeArm")

		var skelrightshouldergtrans = skel.global_transform*skel.get_bone_global_pose(33)
		var skelrightarmrest = skelrightshouldergtrans*rpmavatarhandrestdata[34]

		#var skelrightarmgtrans = skel.global_transform*skel.get_bone_global_pose(34)

		var rpmhandspose = { }
		OpenXRtrackedhand_funcs.setshapetobonesRPM(h, skelrightarmrest, rpmhandspose, rpmavatarhandrestdata, true)
		for i in range(34, 57):
			skel.set_bone_pose(i, rpmhandspose[i])
			skel.set_bone_pose(i, Transform(rpmhandspose[i].basis))
		$MeshInstance_marker.global_transform = skelrightarmrest
		$MeshInstance_marker.global_transform = skel.global_transform*skel.get_bone_global_pose(34)
		$MeshInstance_marker3.global_transform = skel.global_transform*skel.get_bone_global_pose(35)
		print($MeshInstance_marker.global_transform.origin, $MeshInstance_marker3.global_transform.origin)
		$MeshInstance_marker2.global_transform = skel.global_transform*skel.get_bone_global_pose(36)
		return

	var ovrhandpose = OpenXRtrackedhand_funcs.setshapetobonesOVR(joint_transforms, ovrhandrestdata)
	var skel = ovrhandrestdata["skel"]
	ovrhandmodel.transform = ovrhandpose["handtransform"]
	for i in range(23):
		skel.set_bone_pose(i, ovrhandpose[i])

	#$MeshInstance.global_transform.origin = $Right_hand.global_transform*h["hi1"]
	#$MeshInstance_marker.global_transform = skel.global_transform*skel.get_bone_global_pose(5)
	#$MeshInstance_marker/MeshInstance_marker.scale = Vector3(100,100,100)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_P:
			jointtransforms.push_back(jointtransforms.pop_front())
			applyjointpose(jointtransforms[0])	
