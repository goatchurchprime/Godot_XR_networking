extends "res://addons/gd-plug/plug.gd"

func _plugging():
	plug("GodotVR/godot-xr-tools", {"commit": "4d53140015ba5feb6f6ec07873f050311ffe1fdc"})
	plug("Cafezinhu/godot-vr-simulator", {"commit": "5bedbbacf6fe40af10e0bfea99487c84387b19f3"})
	plug("goatchurchprime/godot-mqtt")
	plug("goatchurchprime/godot_multiplayer_networking_workbench", {"include":["addons/player-networking", "branch":"main"]})
	plug("Godot-Dojo/Godot-XR-AH", {"include":["addons/xr-autohandtracker"]})
	var stashedaddons = ["addons/twovoip", "addons/webrtc"]  # large binary addons unpacked and put into a spare repo for the moment
	plug("goatchurchprime/paraviewgodot", {"branch":"stashedaddons", "include":stashedaddons})
