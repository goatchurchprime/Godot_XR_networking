extends Spatial


onready var ovrhandmodel = $ovr_right_hand_model
#onready var skel = $ovr_right_hand_model/ArmatureRight/Skeleton
onready var rpmavatar = $readyplayerme_avatar


var ib = 6
var ibm = 0
var x = 0
var y = 0
var l = 0.06
var x1 = 0
var y1 = 0
var l1 = 0.06
var x2 = 0
var y2 = 0
var l2 = 0.04
var rdt : Transform
func _process(delta):
	if Input.is_key_pressed(KEY_CONTROL):
		if Input.is_key_pressed(KEY_W):  y2 += delta
		if Input.is_key_pressed(KEY_S):  y2 -= delta
		if Input.is_key_pressed(KEY_A):  x2 -= delta
		if Input.is_key_pressed(KEY_D):  x2 += delta
		if Input.is_key_pressed(KEY_Q):  l2 *= (1+delta)
		if Input.is_key_pressed(KEY_E):  l2 /= (1+delta)
	elif Input.is_key_pressed(KEY_SHIFT):
		if Input.is_key_pressed(KEY_W):  y1 += delta
		if Input.is_key_pressed(KEY_S):  y1 -= delta
		if Input.is_key_pressed(KEY_A):  x1 -= delta
		if Input.is_key_pressed(KEY_D):  x1 += delta
		if Input.is_key_pressed(KEY_Q):  l1 *= (1+delta)
		if Input.is_key_pressed(KEY_E):  l1 /= (1+delta)
	else:
		if Input.is_key_pressed(KEY_W):  y += delta
		if Input.is_key_pressed(KEY_S):  y -= delta
		if Input.is_key_pressed(KEY_A):  x -= delta
		if Input.is_key_pressed(KEY_D):  x += delta
		if Input.is_key_pressed(KEY_Q):  l *= (1+delta)
		if Input.is_key_pressed(KEY_E):  l /= (1+delta)

	#setbonestorods()
	#setrodstobones()
	#sethandpos()

var handpos1 = str2var("""{"Wrist": Transform( 1, -1.49012e-08, -1.49012e-08, -1.49012e-08, 1, 2.98023e-08, -1.49012e-08, 2.98023e-08, 1, 0.000875115, 0.00128956, 0.048497 ),"Wrist/IndexMetacarpal": Transform( 1, -1.49012e-08, -1.49012e-08, -1.49012e-08, 1, 2.98023e-08, -1.49012e-08, 2.98023e-08, 1, -0.0149897, -0.0142533, -0.0389789 ),"Wrist/IndexMetacarpal/IndexProximal": Transform( 0.997233, -0.0739956, -0.00716936, 0.0701365, 0.904458, 0.420757, -0.0246499, -0.420096, 0.907145, -0.00889266, 0.00683381, -0.0583695 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate": Transform( 0.998593, 0.0530155, 0.00124479, -0.0510631, 0.954953, 0.29233, 0.0143093, -0.291982, 0.956317, -5.96046e-08, 0, -0.0384617 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal": Transform( 0.998124, 0.033774, -0.0510681, -0.0322731, 0.999031, 0.0299365, 0.0520296, -0.028232, 0.998246, 0, 0, -0.024646 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip": Transform( 1, 0, -3.81842e-08, 0, 1, 1.63913e-07, -3.81842e-08, 1.63913e-07, 1, 0.000299752, 0.00103953, -0.0226783 ),"Wrist/LittleMetacarpal": Transform( 0.87488, 0.405979, -0.264133, -0.395699, 0.913601, 0.0935652, 0.279298, 0.0226588, 0.959937, 0.0233226, -0.00955255, -0.0345535 ),"Wrist/LittleMetacarpal/LittleProximal": Transform( 0.984967, -0.167347, -0.0428373, 0.172735, 0.956505, 0.235075, 0.00163497, -0.238941, 0.971033, -2.26498e-06, -1.01328e-06, -0.0462936 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate": Transform( 0.992866, 0.0942488, -0.0730423, -0.0835226, 0.986891, 0.138092, 0.0850998, -0.131006, 0.987722, -5.96046e-08, 0, -0.0311532 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal": Transform( 0.995163, 0.000343934, 0.0982347, 0.00301549, 0.999416, -0.0340467, -0.098189, 0.0341783, 0.994581, 0, 2.98023e-08, -0.0205976 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal/LittleTip": Transform( 1, 2.98023e-08, 7.45058e-09, 2.98023e-08, 1, -5.96046e-08, 7.45058e-09, -5.96046e-08, 1, -0.000249982, 0.00123319, -0.0222311 ),"Wrist/MiddleMetacarpal": Transform( 1, -1.49012e-08, -1.49012e-08, -1.49012e-08, 1, 2.98023e-08, -1.49012e-08, 2.98023e-08, 1, 0.00144798, -0.0100623, -0.0367861 ),"Wrist/MiddleMetacarpal/MiddleProximal": Transform( 0.999586, 0.00298747, 0.0286031, -0.0162867, 0.87853, 0.477409, -0.0237025, -0.477677, 0.878216, -0.00319815, 0.00748329, -0.0602078 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate": Transform( 0.999706, 0.0230437, -0.00745088, -0.0225956, 0.998204, 0.0554724, 0.00871583, -0.0552881, 0.998432, -5.96046e-08, 2.98023e-08, -0.0435317 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal": Transform( 0.99484, 0.100642, 0.0127749, -0.101427, 0.984014, 0.146387, 0.00216212, -0.146928, 0.989145, 5.96046e-08, 0, -0.0279376 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal/MiddleTip": Transform( 1, -1.49012e-08, 1.49012e-08, -1.49012e-08, 1, -1.71363e-07, 1.49012e-08, -1.71363e-07, 1, 0.000313103, 0.00115329, -0.0253165 ),"Wrist/RingMetacarpal": Transform( 1, -1.49012e-08, -1.49012e-08, -1.49012e-08, 1, 2.98023e-08, -1.49012e-08, 2.98023e-08, 1, 0.0152036, -0.00610052, -0.0352654 ),"Wrist/RingMetacarpal/RingProximal": Transform( 0.968434, 0.180062, -0.172377, -0.0913197, 0.899727, 0.426793, 0.231942, -0.39758, 0.887769, 0.00250769, -0.000520766, -0.0546778 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate": Transform( 0.99772, 0.0672937, -0.00510492, -0.0672235, 0.997655, 0.0128596, 0.00595828, -0.012487, 0.999904, -5.96046e-08, 2.98023e-08, -0.0395455 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal": Transform( 0.99816, 0.0110448, 0.0596211, -0.0170633, 0.994699, 0.101403, -0.058185, -0.102234, 0.993057, 5.96046e-08, -2.98023e-08, -0.0269478 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal/RingTip": Transform( 1, -8.3819e-09, 1.58325e-08, -8.3819e-09, 1, -8.9407e-08, 1.58325e-08, -8.9407e-08, 1, 0.000261545, 0.00163084, -0.0246687 ),"Wrist/ThumbMetacarpal": Transform( -0.102971, -0.95987, 0.260858, 0.992537, -0.0819281, 0.0903254, -0.0653291, 0.268212, 0.961142, -0.0204266, -0.0255387, -0.0390185 ),"Wrist/ThumbMetacarpal/ThumbProximal": Transform( 0.988925, 0.141367, 0.045188, -0.105915, 0.458951, 0.882126, 0.103964, -0.877143, 0.468841, 4.47035e-08, -2.98023e-08, -0.0329708 ),"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal": Transform( 0.990597, -0.135831, -0.0163848, 0.101412, 0.648592, 0.75435, -0.0918371, -0.748918, 0.656268, 2.98023e-08, 0, -0.0342691 ),"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal/ThumbTip": Transform( 1, 2.98023e-08, 0, 2.98023e-08, 1, -1.49012e-08, 0, -1.49012e-08, 1, 0.000679791, 0.00104147, -0.0249371 )}""")
var handpos2 = str2var("""{"Wrist": Transform( 1, -2.98023e-08, 8.9407e-08, -2.98023e-08, 1, 1.49012e-08, 8.9407e-08, 1.49012e-08, 1, 0.000875086, 0.00128949, 0.0484969 ),"Wrist/IndexMetacarpal": Transform( 1, -2.98023e-08, 8.9407e-08, -2.98023e-08, 1, 1.49012e-08, 8.9407e-08, 1.49012e-08, 1, -0.0176635, -0.0125184, -0.0382929 ),"Wrist/IndexMetacarpal/IndexProximal": Transform( 0.996654, -0.0742931, 0.0340736, 0.0632182, 0.964932, 0.254775, -0.0518066, -0.251768, 0.9664, -0.00621897, 0.00509897, -0.0590555 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate": Transform( 0.9986, 0.0527103, 0.0045335, -0.0509444, 0.934945, 0.351116, 0.0142689, -0.350855, 0.936321, 2.98023e-08, -5.96046e-08, -0.0384616 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal": Transform( 0.998072, 0.0314343, -0.0535139, -0.033857, 0.998414, -0.0449838, 0.052015, 0.046709, 0.997553, 0, -5.96046e-08, -0.024646 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip": Transform( 1, -5.58794e-08, -2.98023e-08, -5.58794e-08, 1, 4.47035e-08, -2.98023e-08, 4.47035e-08, 1, 0.000299692, 0.00103951, -0.0226783 ),"Wrist/LittleMetacarpal": Transform( 0.87488, 0.405979, -0.264133, -0.395699, 0.913602, 0.0935653, 0.279298, 0.0226588, 0.959937, 0.0233226, -0.00955248, -0.0345535 ),"Wrist/LittleMetacarpal/LittleProximal": Transform( 0.982218, -0.183567, 0.0393926, 0.176325, 0.973996, 0.142272, -0.0644847, -0.132796, 0.989044, -2.20537e-06, -1.01328e-06, -0.0462936 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate": Transform( 0.991081, 0.128986, -0.0334735, -0.0984278, 0.877895, 0.468628, 0.0898328, -0.461153, 0.882761, 0, 2.98023e-08, -0.0311531 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal": Transform( 0.995261, -0.0148366, 0.0961036, -0.0102183, 0.966864, 0.255089, -0.0967037, -0.254862, 0.96213, 5.96046e-08, 0, -0.0205975 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal/LittleTip": Transform( 1, 2.98023e-08, 2.98023e-08, 2.98023e-08, 1, 0, 2.98023e-08, 0, 1, -0.000249982, 0.00123322, -0.0222312 ),"Wrist/MiddleMetacarpal": Transform( 1, -2.98023e-08, 8.9407e-08, -2.98023e-08, 1, 1.49012e-08, 8.9407e-08, 1.49012e-08, 1, -0.00122571, -0.00919488, -0.0361 ),"Wrist/MiddleMetacarpal/MiddleProximal": Transform( 0.998369, 0.0271851, -0.0502036, -0.0141391, 0.969694, 0.243911, 0.055313, -0.242804, 0.968497, -0.000524521, 0.00661594, -0.0608939 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate": Transform( 0.999687, 0.0249354, 0.0017837, -0.0233586, 0.90628, 0.422032, 0.00890699, -0.421942, 0.906579, 2.98023e-08, 5.96046e-08, -0.0435316 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal": Transform( 0.996197, 0.0871252, -0.00114202, -0.0871257, 0.996197, -0.000382049, 0.00110435, 0.000480168, 0.999999, 0, -5.96046e-08, -0.0279377 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal/MiddleTip": Transform( 1, 4.47035e-08, -2.98023e-08, 4.47035e-08, 1, -7.45058e-09, -2.98023e-08, -7.45058e-09, 1, 0.000313044, 0.00115329, -0.0253166 ),"Wrist/RingMetacarpal": Transform( 1, -2.98023e-08, 8.9407e-08, -2.98023e-08, 1, 1.49012e-08, 8.9407e-08, 1.49012e-08, 1, 0.0152036, -0.00610051, -0.0352654 ),"Wrist/RingMetacarpal/RingProximal": Transform( 0.981082, 0.139548, -0.134181, -0.0965528, 0.953461, 0.285639, 0.167797, -0.26728, 0.948897, 0.00250766, -0.000520766, -0.0546778 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate": Transform( 0.996893, 0.0719723, 0.0319995, -0.0782436, 0.858201, 0.507316, 0.00905061, -0.508244, 0.861166, 0, 0, -0.0395453 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal": Transform( 0.998156, 0.0111247, 0.0596748, -0.01743, 0.994192, 0.106203, -0.0581466, -0.107047, 0.992552, 0, 0, -0.0269477 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal/RingTip": Transform( 1, -4.47035e-08, 5.96046e-08, -4.47035e-08, 1, 1.49012e-08, 5.96046e-08, 1.49012e-08, 1, 0.000261486, 0.0016309, -0.0246687 ),"Wrist/ThumbMetacarpal": Transform( -0.246623, -0.904765, 0.347243, 0.7072, 0.0769642, 0.702812, -0.662605, 0.4189, 0.620869, -0.0257741, -0.0220691, -0.0376465 ),"Wrist/ThumbMetacarpal/ThumbProximal": Transform( 0.977841, 0.173589, -0.11702, -0.156464, 0.977365, 0.142395, 0.13909, -0.120931, 0.982868, -1.19209e-07, 0, -0.0329709 ),"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal": Transform( 0.978778, -0.162586, 0.124734, 0.166144, 0.985926, -0.0185994, -0.119955, 0.0389285, 0.992016, 5.96046e-08, -2.98023e-08, -0.034269 ),"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal/ThumbTip": Transform( 1, 5.21541e-08, 5.96046e-08, 5.21541e-08, 1, 0, 5.96046e-08, 0, 1, 0.000679851, 0.00104143, -0.0249371 )}""")
var handpos3 = str2var("""{"Wrist": Transform( 1, 1.49012e-08, 2.98023e-08, 1.49012e-08, 1, -2.98023e-08, 2.98023e-08, -2.98023e-08, 1, 0.000875115, 0.00128953, 0.0484969 ),"Wrist/IndexMetacarpal": Transform( 1, 1.49012e-08, 2.98023e-08, 1.49012e-08, 1, -2.98023e-08, 2.98023e-08, -2.98023e-08, 1, -0.0203679, -0.00915016, -0.0367215 ),"Wrist/IndexMetacarpal/IndexProximal": Transform( 0.969654, 0.030379, -0.242584, 0.0840262, 0.890391, 0.447373, 0.229585, -0.454181, 0.860819, -0.00351453, 0.00173067, -0.060627 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate": Transform( 0.998573, 0.0527349, -0.00836299, -0.0514202, 0.991982, 0.11544, 0.0143838, -0.114846, 0.993279, -1.19209e-07, -2.98023e-08, -0.0384616 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal": Transform( 0.998094, 0.0324795, -0.0524665, -0.033165, 0.999375, -0.0122468, 0.0520361, 0.0139635, 0.998548, -1.19209e-07, 4.47035e-08, -0.024646 ),"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip": Transform( 1, -3.72529e-08, 2.98023e-08, -3.72529e-08, 1, 2.98023e-08, 2.98023e-08, 2.98023e-08, 1, 0.000299692, 0.00103953, -0.0226784 ),"Wrist/LittleMetacarpal": Transform( 0.87488, 0.405979, -0.264133, -0.395699, 0.913601, 0.0935653, 0.279298, 0.0226589, 0.959937, 0.0233226, -0.00955255, -0.0345535 ),"Wrist/LittleMetacarpal/LittleProximal": Transform( 0.99059, -0.00324041, -0.136828, 0.136452, 0.101049, 0.98548, 0.010633, -0.994876, 0.100541, -2.26498e-06, -9.83477e-07, -0.0462935 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate": Transform( 0.984536, 0.13498, 0.111661, -0.12194, 0.0704264, 0.990036, 0.125771, -0.988342, 0.0857969, 0, 1.49012e-08, -0.0311531 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal": Transform( 0.995991, -0.0397246, 0.0801494, -0.032214, 0.676592, 0.735653, -0.083452, -0.735285, 0.6726, 0, 7.45058e-09, -0.0205975 ),"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal/LittleTip": Transform( 1, -2.98023e-08, 5.58794e-09, -2.98023e-08, 1, 7.45058e-09, 5.58794e-09, 7.45058e-09, 1, -0.000250101, 0.00123324, -0.0222312 ),"Wrist/MiddleMetacarpal": Transform( 1, 1.49012e-08, 2.98023e-08, 1.49012e-08, 1, -2.98023e-08, 2.98023e-08, -2.98023e-08, 1, -0.00393021, -0.00751078, -0.0345285 ),"Wrist/MiddleMetacarpal/MiddleProximal": Transform( 0.973527, 0.228158, -0.0137741, -0.0018796, 0.0682499, 0.997666, 0.228566, -0.971229, 0.0668718, 0.0021801, 0.00493179, -0.0624653 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate": Transform( 0.999643, 0.013461, 0.0230731, -0.0245454, 0.122077, 0.992217, 0.0105394, -0.992429, 0.122364, 0, 1.49012e-08, -0.0435317 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal": Transform( 0.985016, 0.129761, 0.113601, -0.166862, 0.550579, 0.817936, 0.0435898, -0.824637, 0.563981, 0, 0, -0.0279376 ),"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal/MiddleTip": Transform( 1, 4.09782e-08, -4.42378e-08, 4.09782e-08, 1, -3.72529e-08, -4.42378e-08, -3.72529e-08, 1, 0.000313163, 0.00115332, -0.0253166 ),"Wrist/RingMetacarpal": Transform( 1, 1.49012e-08, 2.98023e-08, 1.49012e-08, 1, -2.98023e-08, 2.98023e-08, -2.98023e-08, 1, 0.0152035, -0.00610057, -0.0352654 ),"Wrist/RingMetacarpal/RingProximal": Transform( 0.975447, 0.19928, 0.0937618, -0.0878144, -0.0384967, 0.995393, 0.201972, -0.979186, -0.0200518, 0.00250775, -0.000520721, -0.0546777 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate": Transform( 0.99566, 0.0322024, 0.0873116, -0.0890967, 0.0589417, 0.994277, 0.0268719, -0.997742, 0.0615549, 0, 2.98023e-08, -0.0395454 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal": Transform( 0.997124, 0.0196611, 0.0731919, -0.0705988, 0.592149, 0.80273, -0.0275581, -0.805588, 0.591834, -1.19209e-07, 1.49012e-08, -0.0269477 ),"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal/RingTip": Transform( 1, -2.23517e-08, -3.95812e-08, -2.23517e-08, 1, 9.68575e-08, -3.95812e-08, 9.68575e-08, 1, 0.000261545, 0.00163081, -0.0246688 ),"Wrist/ThumbMetacarpal": Transform( 0.122182, -0.736223, 0.665618, 0.897189, 0.368703, 0.243123, -0.424408, 0.56748, 0.70558, -0.031183, -0.0153325, -0.0345036 ),"Wrist/ThumbMetacarpal/ThumbProximal": Transform( 0.974964, 0.15532, -0.159127, -0.173577, 0.978876, -0.108043, 0.138984, 0.132959, 0.981328, 1.49012e-08, 0, -0.0329709 ),"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal": Transform( 0.97439, -0.138523, 0.177129, 0.193868, 0.916602, -0.349651, -0.113922, 0.375036, 0.919983, 0, -5.96046e-08, -0.0342691 ),"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal/ThumbTip": Transform( 1, 2.98023e-08, 2.98023e-08, 2.98023e-08, 1, -3.72529e-08, 2.98023e-08, -3.72529e-08, 1, 0.000679836, 0.00104141, -0.0249372 )}""")
var handposes = [handpos1,handpos2,handpos3]

var hand_joint_node_names = [
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

func getrpmhandrestdata(rpmavatar):
	var rpmavatardata = { "rpmavatar":rpmavatar }
	var skel = rpmavatar.get_node("Armature/Skeleton")
	rpmavatardata["skel"] = skel

	for i in range(36, 57):
		rpmavatardata[i] = skel.get_bone_rest(i)
		
	var boneposeI1 = rpmavatardata[36]*rpmavatardata[41]
	var boneposeR1 = rpmavatardata[36]*rpmavatardata[49]
	var wristpos = Vector3(0,0,0)
	rpmavatardata["posindex1"] = boneposeI1.origin - wristpos
	rpmavatardata["posring1"] = boneposeR1.origin - wristpos
	rpmavatardata["wristtransinverse"] = basisfrom(rpmavatardata["posindex1"], rpmavatardata["posring1"]).inverse()
	
	return rpmavatardata

func applyhandpose(handpose):
	var hand = $Right_hand
	var dat = handposes[0]
	for hjnname in handpose:
		hand.get_node(hjnname).transform = handpose[hjnname]
	sethandpos()

var ovrhandrestdata = null
var rpmavatarhandrestdata = null
func _ready():
	$Right_hand/Wrist.set_process(false)
	$Right_hand/Wrist.set_physics_process(false)
	ovrhandrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata(ovrhandmodel)
	rpmavatarhandrestdata = getrpmhandrestdata(rpmavatar)
	applyhandpose(handposes[0])

var Nokey = 0
func setvecstobonesG(ibR, ib0, p1, p2, p3, p4, ovrhandrestdata, ovrhandpose):
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

	var tRboneposeG = ovrhandpose["handtransform"]*ovrhandrestdata["skeltrans"]
	if ibR != 0:
		assert (Dskel.get_bone_parent(ibR) == 0)
		tRboneposeG *= ovrhandrestdata[0]
		ovrhandpose[ibR] = Transform()
	tRboneposeG *= ovrhandrestdata[ibR]
	
	var t0bonerestG = tRboneposeG*t0bonerest
	var t0boneposebasis = rotationtoalign(t1bonerest.origin, t0bonerestG.basis.inverse()*vec1)
	var t0boneposeorigin = tRboneposeG.affine_inverse()*p1 - t0bonerest.origin
	if (Nokey%2) == 0:
		t0boneposeorigin = Vector3.ZERO
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


func setvecstobonesG_RPM(ibR, ib0, p1, p2, p3, p4, handrestdata, handpose, tRboneposeG):
	var vec1 = p2 - p1
	var vec2 = p3 - p2
	var vec3 = p4 - p3
	var ib1 = ib0+1
	var ib2 = ib0+2
	var ib3 = ib0+3
	
	var Dskel = handrestdata["skel"]
	assert (Dskel.get_bone_parent(ib0) == ibR)
	assert (Dskel.get_bone_parent(ib1) == ib0)
	assert (Dskel.get_bone_parent(ib2) == ib1)
	assert (Dskel.get_bone_parent(ib3) == ib2)

	var t0bonerest = handrestdata[ib0]
	var t1bonerest = handrestdata[ib1]
	var t2bonerest = handrestdata[ib2]
	var t3bonerest = handrestdata[ib3]

	#if ibR != 0:
	#	assert (Dskel.get_bone_parent(ibR) == 0)
	#	tRboneposeG *= ovrhandrestdata[0]
	#	ovrhandpose[ibR] = Transform()
	#tRboneposeG *= handrestdata[ibR]
	
	var t0bonerestG = tRboneposeG*t0bonerest
	var t0boneposebasis = rotationtoalign(t1bonerest.origin, t0bonerestG.basis.inverse()*vec1)
	var t0boneposeorigin = tRboneposeG.affine_inverse()*p1 - t0bonerest.origin
	#if (Nokey%2) == 0:
	#	t0boneposeorigin = Vector3.ZERO
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
	
	handpose[ib0] = t0bonepose
	handpose[ib1] = t1bonepose
	handpose[ib2] = t2bonepose
	handpose[ib3] = t3bonepose


func setshapetobonesRPM(h, skelrightarmgtrans, rpmhandrestdata):
	var handbasis = basisfrom(h["hi1"] - h["hwr"], h["hr1"] - h["hwr"])
	#var ovrhandmodelbasis = handbasis*ovrhandrestdata["wristtransinverse"]
# a*b = (a.basis*b.basis, a.origin + a.basis*b.origin)
# a*b*c = (a.basis*b.basis*c.basis, a.origin + a.basis*b.origin + a.basis*b.basis*c.origin)
	var rpmhandpose = { }
	# solve h["hwr"] = skelrightarmgtrans.origin + skelrightarmgtrans.basis*rpmhandrestdata[36].origin + skelrightarmgtrans.basis*rpmhandrestdata[36].basis*rpmhandpose[36].origin
	var lh = h["hwr"] - skelrightarmgtrans.origin - skelrightarmgtrans.basis*rpmhandrestdata[36].origin 
	var lhb = skelrightarmgtrans.basis*rpmhandrestdata[36].basis
	var p36 = lhb.inverse()*lh
	# solve skelrightarmgtrans.basis*rpmhandrestdata[36].basis*rpmpose[36].basis*wristbasis = handbasis 
	var b36 = lhb.inverse()*handbasis*rpmhandrestdata["wristtransinverse"]
	rpmhandpose[36] = Transform(b36, p36)

	#var skelrightarmgtrans = skel.global_transform*skel.get_bone_global_pose(35)
	var tRboneposeG = skelrightarmgtrans*rpmhandrestdata[36]*rpmhandpose[36]
	#var t0bonerestG = tRboneposeG*t0bonerest
	#var t0boneposeorigin = tRboneposeG.affine_inverse()*p1 - t0bonerest.origin

	setvecstobonesG_RPM(36, 37, h["ht0"], h["ht1"], h["ht2"], h["ht3"], rpmhandrestdata, rpmhandpose, tRboneposeG)
	setvecstobonesG_RPM(36, 41, h["hi1"], h["hi2"], h["hi3"], h["hi4"], rpmhandrestdata, rpmhandpose, tRboneposeG)
	setvecstobonesG_RPM(36, 45, h["hm1"], h["hm2"], h["hm3"], h["hm4"], rpmhandrestdata, rpmhandpose, tRboneposeG)
	setvecstobonesG_RPM(36, 49, h["hr1"], h["hr2"], h["hr3"], h["hr4"], rpmhandrestdata, rpmhandpose, tRboneposeG)
	setvecstobonesG_RPM(36, 53, h["hl1"], h["hl2"], h["hl3"], h["hl4"], rpmhandrestdata, rpmhandpose, tRboneposeG)
	return rpmhandpose


const Dapply_readyplayerme_hand = false	
func sethandpos():
	var h = OpenXRtrackedhand_funcs.gethandjointpositions($Right_hand)
	if Dapply_readyplayerme_hand:
		var rpmavatar = rpmavatarhandrestdata["rpmavatar"]
		var skel = rpmavatarhandrestdata["skel"] # rpmavatar.get_node("Armature/Skeleton")
		var skelrightarmgtrans = skel.global_transform*skel.get_bone_global_pose(35)
		var rpmhandpose = setshapetobonesRPM(h, skelrightarmgtrans, rpmavatarhandrestdata)
		for i in range(36, 57):
			if rpmhandpose.has(i):
				skel.set_bone_pose(i, rpmhandpose[i])
		return

	var ovrhandpose = OpenXRtrackedhand_funcs.setshapetobones(h, ovrhandrestdata)	
	ovrhandmodel.transform = ovrhandpose["handtransform"]
	for i in range(23):
		ovrhandrestdata["skel"].set_bone_pose(i, ovrhandpose[i])
	#$MeshInstance.global_transform.origin = $Right_hand.global_transform*h["hi1"]


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_P:
			handposes.push_back(handposes.pop_front())
			applyhandpose(handposes[0])
		if event.scancode == KEY_O:
			Nokey += 1
			print(Nokey%2)
