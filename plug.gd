extends "res://addons/gd-plug/plug.gd"

# from clean clone run `godot4 --headless --xr-mode off -s plug.gd update debug`
# You will also need to install openxrvendorsplugin (v 4.0.0) from the assetlib

func _plugging():
	plug("GodotVR/godot-xr-tools", {"commit": "4d53140015ba5feb6f6ec07873f050311ffe1fdc"})
	plug("Cafezinhu/godot-vr-simulator", {"commit": "5bedbbacf6fe40af10e0bfea99487c84387b19f3"})
	plug("goatchurchprime/godot-mqtt")
	plug("goatchurchprime/godot_multiplayer_networking_workbench", {"include":["addons/player-networking"], "branch":"main"})
	var stashedaddons = ["addons/twovoip", "addons/webrtc"]  # large binary addons unpacked and put into a spare repo for the moment
	plug("goatchurchprime/paraviewgodot", {"branch":"stashedaddons", "include":stashedaddons})
