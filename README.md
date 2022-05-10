
This is a minimal working VR networking example using the https://github.com/goatchurchprime/godot_multiplayer_networking_workbench as 
the basis for connecting using one of the three godot networking protocols (enet, websocket or webrtc) and spawning player avatars 
into the space on connection.

There are four addons, that have to be copied over or installed because they are not committed into this repository.

1. **OpenXR Plugin**

Open this Godot_XR_networking project, ignore errors, and use the AssetLib to install the OpenXR plugin, which will go into the Godot_XR_networking/addons/godot-openxr directory

(Alternatively, if you are on Linux, you can take advantage of the full working demo project that is committed into the addons repository by 
checking out https://github.com/GodotVR/godot_openxr next to your Godot_XR_networking directory before then going into the Godot_XR_networking/addons directory 
and executing `ln -s ../../godot_openxr/demo/addons/godot-openxr/ godot-openxr` to create a symlink.)


2. **Godot XR Tools**

Use the AssetLib to install the Godot XR Tools - AR and VR helper library plugin, which will go into the Godot_XR_networking/addons/godot-xr-tools directory

(Alternatively, to use a symlink, which will make it easier to update any changes to these base libraries and spot any unintentional edits 
check out https://github.com/GodotVR/godot-xr-tools next to your Godot_XR_networking directory before going into the Godot_XR_networking/addons directory 
and executing `ln -s ../../godot-xr-tools/addons/godot-xr-tools/ godot-xr-tools`.)


3. **Networking workbench**

The networking workbench is not in the AssetLib, so you will need to check out or download the repository 
https://github.com/goatchurchprime/godot_multiplayer_networking_workbench and copy its
godot_multiplayer_networking_workbench/addons/player-networking directory into the Godot_XR_networking/addons directory.

(Alternatively go into the Godot_XR_networking/addons directory and execute
`ln -s ../../godot_multiplayer_networking_workbench/addons/player-networking/ player-networking`.)


4. **WebRTC libraries**

If you also want to use WebRTC capability you will need to download the latest precompiled godot-webrtc-native-release-0.5.zip file, and 
copy its webrtc directory into the top level of this project so it becomes the directory Godot_XR_networking/webrtc.


