
Building a VR networking based on https://github.com/BastiaanOlij/godot-xr-tools after the OQ_Networking one has become obsolete

This example has two addon dependencies which are imported via symlinks rather than copied over;

https://github.com/goatchurchprime/godot_multiplayer_networking_workbench

ln -s ../../godot_multiplayer_networking_workbench/addons/player-networking/ player-networking

From https://github.com/goatchurchprime/godot-xr-tools/tree/fix-grip-key

ln -s ../../godot-xr-tools/addons/godot-xr-tools/ godot-xr-tools

To make this fully work you will also need to create a top level webrtc directory from https://github.com/godotengine/webrtc-native/releases 
(See the multiplayer networking workbench readme for more details)
