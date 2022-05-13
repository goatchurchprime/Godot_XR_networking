# Godot_XR_networking-modular

Attempt at modular (tool) version of Godot_XR_networking by GoatChurchPrime: https://github.com/goatchurchprime/Godot_XR_networking to insert into your OpenXR project.

This is a tempoarary repository, for review by GoatChurchPrime.  If it works, any future work will be done on his repository, not this one.

This is a minimal working VR networking module using the https://github.com/goatchurchprime/godot_multiplayer_networking_workbench as 
the basis for connecting using one of the three godot networking protocols (enet, websocket or webrtc) and spawning player avatars 
into the space on connection.  This works in Godot 3.4., and works with projects built for PCVR as well as Quest native.

It requires installation first of the OpenXR Asset Plugin and OpenXR-Tools asset plugin as described below into your project.


## Installation

There are two addons, that have to be installed in your project first which this module depends on to work.

1. **OpenXR Plugin**

Use the AssetLib in your project to install the OpenXR plugin, which will go into the /addons folder of your project.  Make sure to go to project settings and also activate the plugin.

https://github.com/GodotVR/godot_openxr

2. **Godot XR Tools**

Use the AssetLib to install the Godot XR Tools - AR and VR helper library plugin, which will go into the Godot_XR_networking/addons/godot-xr-tools directory

https://github.com/GodotVR/godot-xr-tools 


3. **Installing this asset into your project**

**Backup your project first.**  

ONLY THEN drag and drop the contents of this asset (not the master "Godot_XR_networking_modular" folder itself but rather all of its contents) into your project folder root directory.

This adds the following components:

-A "player-networking" asset folder to your "addons" directory, which is from here: 
https://github.com/goatchurchprime/godot_multiplayer_networking_workbench 

-A "webrtc" directory into the root of your project folder, which is the latest precompiled godot-webrtc-native-release-0.5.zip file.

-A Godot-OpenXR Networking Node (.tscn) and script, and a VRPlayerAvatar scene and script into your Open-XR-Tools/assets folder.

4.  **Using this asset in your project**

Once you have installed everything it is time to try it out.

Go to the root of your project scene and "instance child scene" and choose the OpenXR-Tools-Networking.tscn.  

By default, it believes your ARVROrigin is called "FPController" and that you have the same VR player avatar installed as called for in the XR-Tools instructions. 

So you should make sure you have followed the instructions already to implement the OpenXR asset's first person controller (see,example: https://www.youtube.com/watch?v=LZ9UKR48b0Y) and Open-XR-Tools left and right hand scenes into your project (see same video as well as https://github.com/GodotVR/godot-xr-tools/wiki/Hands).  

You should also have assigned a "pointer" function ("instance child scene") to one of the controllers following the instructions here: https://github.com/GodotVR/godot-xr-tools/wiki/PointerAndUI

If you have changed the names of the compoenents for your ARVROrigin or left or right hand controllers, click on the OpenXR-Tools-Networking node that is now in your scene and in the inspector click to select those nodes in your scene.

This will also create a 2Dto3DViewport node (https://github.com/GodotVR/godot-xr-tools/wiki/PointerAndUI)  your scene containing the NetworkGateway dashboard.  You can assign a controller button in the OpenXR-Tools-Networking node to make the menu appear or disappear.  

(Right now, restricted to right hand assignment for testing, will fix in near future)

If you just want to use local network multiplayer, you  can set the NetworkGateway dashboard in game to "Enet" in the top left corner drop down, and then set one player as "as server" in the top right drop down box, and other players as "local network" and the players should automatically connect.

For web-based multiplayer (Experimental) if you set the NetworkGateway dashboard in the top right corner dropdown to WebRTC via MQTT signalling, the 
instances should automatically connect if you then use the "as necessary" option in the top right corner drop down (the as-necessary option means that the first one online becomes the server).
For details of how it works (in an even more minimal example) go to the 
[godot multiplayer networking workbench](https://github.com/goatchurchprime/godot_multiplayer_networking_workbench) project 
and try it out.

It very closely follows the Godot Networking documentation, except that you can try out the different 
configurations and protocols using an graphical user interface rather than having to hack the code.

If you don't happen to have 2 QuestVR devices you can run the second (or both) instance(s) on your PC by going to the 
Godot_XR_networking directory itself and executing the godot executable, and it will start up 
immediately without the editor.  

(However to make this work properly we will probably need a [keyboard simulator](https://github.com/GodotVR/godot-xr-tools/issues/93) added.)

