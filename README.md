
This is a minimal working VR networking example using the https://github.com/goatchurchprime/godot_multiplayer_networking_workbench as 
the basis for connecting using one of the three godot networking protocols (enet, websocket or webrtc) and spawning player avatars 
into the space on connection.  This works in Godot 3.4.


## Installation

There are four addons, that have to be copied over or installed because they are not committed into this repository.

1. **OpenXR Plugin**

Open this Godot_XR_networking project, ignore errors, and use the AssetLib to install the OpenXR plugin, which will go into the Godot_XR_networking/addons/godot-openxr directory

(Alternatively, if you are on Linux, you can take advantage of the full working demo project that is committed into the addons repository by 
checking out https://github.com/GodotVR/godot_openxr next to your Godot_XR_networking directory at one of the tags, copying over the .so and .dll bin 
files for the different operating systems from the tagged release (or pre-release) which has been created by their CI, and checking out at that tag
before then going into the Godot_XR_networking/addons directory 
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


5. **Opus libraries**

If you want to use the Opus audio compression libraries (which give a 100x efficiency) for a PTT voice communication interface 
install Godot-Opus from the AssetLib and it will be used by the record send and play features.

(Alternatively go into the Godot_XR_networking/addons directory and execute
`ln -s ../../libopus-gdnative-voip-demo/addons/opus/ opus`.)


## Operation

The NetworkGateway dashboard appears in VR and is operable.  If you set it to WebRTC via MQTT signalling, the 
instances should automatically connect (the as-necessary option means that the first one online becomes the server).
For details of how it works (in an even more minimal example) go to the 
[godot multiplayer networking workbench](https://github.com/goatchurchprime/godot_multiplayer_networking_workbench) project 
and try it out.
It very closely follows the Godot Networking documentation, except that you can try out the different 
configurations and protocols using an graphical user interface rather than having to hack the code.

If you don't happen to have 2 QuestVR devices you can run the second (or both) instance(s) on your PC by going to the 
Godot_XR_networking directory itself and executing the godot executable, and it will start up 
immediately without the editor.  

(However to make this work properly we will probably need a [keyboard simulator](https://github.com/GodotVR/godot-xr-tools/issues/93) added.)

