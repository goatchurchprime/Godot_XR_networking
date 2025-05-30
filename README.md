
This is a funciontal VR networking example using the https://github.com/goatchurchprime/godot_multiplayer_networking_workbench as 
the basis for connecting using one of the three godot networking protocols (ENet, WebSocket or WebRTC) and spawning player avatars 
into the space on connection.  This works in Godot 4.4.

The microphone in Godot is buggy for Android, so use this PR fork until it is merged: https://github.com/godotengine/godot/pull/100508


## Installation

There are many addons that need to be brought in.  We are using the https://github.com/imjp94/gd-plug plugins tool.

Before opening the project, please run the following command to download them:

> godot4 --xr-mode off --headless -s plug.gd install 

This will load the following plugins

* **Godot XR Tools** Version: 4.3.3, installs into addons/godot-xr-tools
* [**NetworkingWorkbench**](https://github.com/goatchurchprime/godot_multiplayer_networking_workbench)
*  **MQTT CLient** Version: 1.2 installs into addons/mqtt
*  **Godot XR Autohands** Version: 1.1 installs into addons/xr-autohandstracker
*  **XR Input Simulator** Version: 1.2.0 installs into addons/xr-simulator
*  **WebRTC plugin - Godot 4.1+** Version: 1.0.6, binary plugin pulled from goatchurchprime/paraviewgodot
*  **TwoVoip** Version: v3.4 install into addons/twovoip binary plugin pulled from goatchurchprime/paraviewgodot

This one needs loading directly
*  **Godot OpenXR Vendors plugin for Godot 4.3** Version: 3.0.0, installs into addons/godotopenxrvendors


## Branches

### steamaudio 
Currently waiting on a working Android build of:
*  **Godot-Steam-Audio**   (made a mess of the checkout as I need to fork and prepare the voip plugin to work with its streams)

### preclean

Contains a lot of subprojects including tensegrity, puppet monster, glaucoma tester




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
