# Real-time autostereogram shader

A shader that generates an autostereogram from a 3D environment, by using the depth map.
A first-person environment is included for testing and demonstration purposes.

Made with Godot 4.1.1


## What is an autostereogram?

An autostereogram is an image featuring repeating patterns in such a way that, by changing the point of convergence of the eyes, a three-dimensional effect appears.
https://en.wikipedia.org/wiki/Autostereogram

The most common type is random-dot autostereogram, wher the pattern is made of randomly-generated noise. It is the one used by the test environment here, though there is also provision for using a specific image instead in the shader if desired.

Ther are two main categories of autostereograms: wall-eyed, and cross-eyed. To see a wall-eyed one, you must let your eyes diverge compared to where the image is, as if you were looking at a wall far behind the image. To see a cross-eyed one, you must do the opposite, as if you were looking at an object much closer than the image. Wall-eyed autostereograms create a three-dimensional effect that appears to be behind the image, while cross-eyed ones create an effect that apperas to be in front of the image. Attempting to use one as the other will still generate an effect, but inversed: what is far in one will appear close in the other, and vice-versa.
The test environment here is set to wall-eyed, but the shader is capable of doing either.

Autostereograms are generally fixed images, such as ones that can be found in a book. As this one is not, the test environment uses a constantly changing noise pattern akin to old TV static, as a fixed noise pattern can make it more difficult to keep the effect while moving.


## Recommendations for use

It is recommended to not use this autostereogram effect more than a few minutes at a time without pause, to avoid eye fatigue and disorientation afterwards.

The effect can initially be difficult to see. It is not uncommon for first-time users of autostereograms to need several minutes before starting to see the effect. It becomes easier with practice however.
For ease of use, the autostereogram generated here features two small reference dots, corresponding to the central point of the screen. To see the effect, let your eyes diverge until the two dots appear to be at the same place.
This may cause the image to become blurry initially, as your eyes focus on a more distant point corresponding to the new convergence point. I recommend not trying to fight this, even a blurred image will still generate the effect as the noise pattern is large enough to still be perceived. Once the effect appears, it becomes much easier to then focus on the image itself, so it becomes sharp again.

The eye distance as set initially may not be correct for you, depending on your own eye distance and screen pixel density. It can be set in the setting menu if needed.
A setting smaller than your own eye distance will be easier to see to an extent, and may be good for people unaccustomed to autostereograms. However the distances will appear to be shorter than they should, which can lead to some disorientation when moving, and makes it more difficult to see smaller distant objects due to smaller distance contrast.
It is highly recommended to not use a setting larger than your own eye distance. It will be either impossible to see at long distance, as your eyes try to diverge more than they naturally should.
If you are unsure, it is probably better to veer towards a setting somewhat smaller than your acutal eye distance.

The autostereogram effect is initially disabled in the test environment, so you can have an idea of what environment to expect.


## How to use the test environment

You can access the menu with the Escape key, which will also pause the environment. The command keys are displayed there.
In the menu, the Settings tab will let you adjust the eye distance. The number shows the distance in pixels, the bar displays the acutal distance.

To toggle the autostereogram effect, press the Backspace key.

You can toggle a faint image overly with the Enter key when the autostereogram effect is active. This makes seeing the autostereogram effect harder, but can be useful for testing or if you are disoriented.

You can shoot small balls with mouse left-click and larger balls with right-click. Maintaining left-click will throw the small ball harder.


## How to use the shader for your own Godot project

The autostereogram shader lives in the ScreenProjectionMesh scene. This is a simple quad that is projected in front of the camera, in order for the shader to both cover the entire screen and have access to the depth map.
You can use it by adding it as a child to the camera. To toggle it, toggle its visibility.

The shader itself has parameters that you can change, such as what noise is used, whether to use a texture for the pattern instead, whether to use colored or greyscale noise, wall-eyed or cross-eyed... The script attached to the mesh is a natural entry point for controlling those parameters through script. The test environment uses several, you can take inspiration from the existing script if you wish to use more.
The Events pattern, with an Events singleton containing signals and signal connections through scripts, is used for controlling some of those in the test environment, as this is a global single effect with relatively few commands.

Note that having very close and very far objects can make the effect difficult to see or even create echo ghosts, as the eyes are faced with several apparently valid solutions to the repeating patterns, such as with the traditional FPS weapon holding on a wide empty plane.
You may want to experiment with different setups there, to make sure they work as autostereograms.