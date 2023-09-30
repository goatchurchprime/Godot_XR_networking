
This is a funciontal VR networking example using the https://github.com/goatchurchprime/godot_multiplayer_networking_workbench as 
the basis for connecting using one of the three godot networking protocols (ENet, WebSocket or WebRTC) and spawning player avatars 
into the space on connection.  This works in Godot 4.2 (to take advantage of its more advanced OpenXR interface).


## Installation

There are several addons that need to be copied or linked from the addons directory.

1. **Godot OpenXR Loaders**

See them here, for your version.  https://github.com/GodotVR/godot_openxr_loaders/releases

(OpenXR is now part of the core of Godot, but the loaders need to be installed and set up, along with the android templates and export options 
for your platform.  Don't forget to enable hand tracking and passthrough.

2. **Godot XR Tools**

Use the AssetLib to install the "Godot XR Tools - AR and VR helper library" plugin, which will go into the Godot_XR_networking/addons/godot-xr-tools directory

(Alternatively, to use a symlink, which will make it easier to update any changes to these base libraries and spot any unintentional edits 
check out https://github.com/GodotVR/godot-xr-tools next to your Godot_XR_networking directory before going into the Godot_XR_networking/addons directory 
and executing `ln -s ../../godot-xr-tools/addons/godot-xr-tools/ godot-xr-tools`.)


3. **Networking workbench**

The networking workbench is not in the AssetLib, so you will need to check out or download the repository 
https://github.com/goatchurchprime/godot_multiplayer_networking_workbench and copy its
godot_multiplayer_networking_workbench/addons/player-networking directory into the Godot_XR_networking/addons directory.

(Alternatively go into the Godot_XR_networking/addons directory and execute
`ln -s ../../godot_multiplayer_networking_workbench/addons/player-networking/ player-networking`.)

4. **MQTT**

Use the AssetLib to install the "MQTT Client" plugin, which will go into the Godot_XR_networking/addons/mqtt directory

This is also available at: https://github.com/goatchurchprime/godot-mqtt/

This is used by the Networking workbench as the signalling protocol for WebRTC


5. **WebRTC libraries**

If you also want to use WebRTC capability you will need to download the latest precompiled set of libraries from https://github.com/godotengine/webrtc-native/releases
 *Godot_XR_networking/webrtc*.  Make sure you don't have arm7 selected as a feature as this makes it difficult for the GDExtension system to find 
 the correct arm8 libaries


6. **Opus library**

These haven't been recompiled for Godot4, but should done at some point.  This will enable VOIP over the networks using the 
similar logic of buffering and syncronizing as we do for the avatar motions 


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

