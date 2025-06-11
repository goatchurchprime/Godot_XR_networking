extends "res://addons/gd-plug/plug.gd"

func _plugging():
	plug("goatchurchprime/godot-xr-tools", {"branch": "handle-missing-rumble", "include":["addons/godot-xr-tools"]})
	plug("Cafezinhu/godot-vr-simulator", {"commit": "5bedbbacf6fe40af10e0bfea99487c84387b19f3"})
	plug("goatchurchprime/godot-mqtt", {"include":["addons/mqtt"]})
	plug("goatchurchprime/godot_multiplayer_networking_workbench", {"include":["addons/player-networking"]})
	plug("Godot-Dojo/Godot-XR-AH", {"include":["addons/xr-autohandtracker", "addons/xr-radialmenu"]})

	# large binary addons unpacked and put into a spare repo 
	var stashedaddons = [
		"addons/twovoip", 
		"addons/webrtc"
	]
	plug("goatchurchprime/paraviewgodot", {"branch":"stashedaddons", "include":stashedaddons})

	# The way we would like to do it using plug.gd if it worked
	#plug("https://github.com/goatchurchprime/two-voip-godot-4/releases/download/v3.10/TwoVoIP.zip")
	#plug("https://github.com/godotengine/webrtc-native/releases/download/1.0.6-stable/godot-extension-4.1-webrtc.zip", { "branch":"addons/webrtc"})
