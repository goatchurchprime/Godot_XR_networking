extends "res://addons/gd-plug/plug.gd"

func _plugging():
	# plug("imjp94/gd-YAFSM") # By default, gd-plug will only install anything from "addons/" directory
	# plug("imjp94/gd-YAFSM", {"include": ["addons/"]})
	plug("GodotVR/godot-xr-tools", {"commit": "4d53140015ba5feb6f6ec07873f050311ffe1fdc"})
	plug("Cafezinhu/godot-vr-simulator", {"commit": "5bedbbacf6fe40af10e0bfea99487c84387b19f3"})
	#plug("onze/godot-stl-io", {"include":["addons/stl-io"]})
	plug("goatchurchprime/godot-mqtt")
	plug("goatchurchprime/godot_multiplayer_networking_workbench", {"include":["addons/player-networking"]})
	plug("Godot-Dojo/Godot-XR-AH", {"include":["addons/xr-autohandtracker"]})


	# large binary addons unpacked and put into a spare repo for the moment
	plug("https://github.com/goatchurchprime/two-voip-godot-4/releases/download/v3.10/TwoVoIP.zip")
	plug("https://github.com/godotengine/webrtc-native/releases/download/1.0.6-stable/godot-extension-4.1-webrtc.zip", { "branch":"addons/webrtc"})
	#plug("https://github.com/CraterCrash/godot-orchestrator/releases/download/v2.1.2.stable/godot-orchestrator-v2.1.2-stable-plugin.zip", { "branch":"addons", "tag":"addons"})


	#var stashedaddons = ["addons/twovoip", "addons/webrtc"]
	#plug("goatchurchprime/paraviewgodot", {"branch":"stashedaddons", "include":stashedaddons})
	#plug("goatchurchprime/paraviewgodot", {"branch":"stashedaddons", "include":["addons/webrtc"]})
