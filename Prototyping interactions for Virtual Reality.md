# Prototyping Virtual Reality with Framer

Before joining the Framer team in Amsterdam as a product engineer, I was studying architecture. Since architecture is expensive to build you are mostly working on drawings, scale models or your computer screen. These techniques require quite some spatial imagination as they stand far away from reality. Only in your mind you are able to imagine how a space might eventually be used. The concept of Virtual Reality (VR) could finally narrow the gap between imagination and reality. Being able to walk through and shape your designs seems to be right around the corner. That insight started my interest for VR.

VR technology has seen huge advancements in the last couple of years. Facebook with Oculus and Google with Cardboard are trying to make VR available to the masses. As a new medium a lot of the interactions still need to be discovered and refined. As such I felt an urge to start experimenting with VR in [Framer](http://framerjs.com).

Along the way, I experienced quite a few roadblocks. The first objective was to create a panoramic environment whose orientation was fixed with the real world. Next, I wanted to create an easy way to project Framer layers on top of this environment. Then I had to figure out what direction the user is facing to make this data available for interactions. In the end I was able to create a solution for these objectives and combined them into a single component. You can get this [VRComponent from Github](https://github.com/jonastreub/VRComponent).

In the remainder of this post I will highlight the basic concepts and workings of the VRComponent.

## Creating a panoramic environment

Virtual reality replicates the physical presence in real or imagined environments. To pull the most out of the experience you might want to simulate a panoramic view all around. There are multiple ways of achieving this. The VRComponent uses the [cubemap technique](https://en.wikipedia.org/wiki/Cube_mapping) whereby the environment is projected on the sides of a cube. The user is positioned in the center of this cube while the orientation of the cube is fixed with the real world. By instantiating a VRComponent this cube shows up, although without any textures.

On mobile the orientation is synced to that of your device. When viewing the prototype on desktop you can change the direction you are facing either by dragging the environment or using your arrow keys.

```coffee
{VRComponent} = require "VRComponent"

vr = new VRComponent
```

[insert GIF of spinning cube without textures]
[Base setup](http://share.framerjs.com/dqsd8kr5exij/)

By specifying images for all six sides, the cube seems to be replaced by the new environment.

```coffee
vr = new VRComponent
	front: "images/front.png"
	left: "images/left.png"
	right: "images/right.png"
	back: "images/back.png"
	top: "images/top.png"
	bottom: "images/bottom.png"
```

[insert GIF of spinning cube with textures]
[VR with environment](http://share.framerjs.com/arjr2gxl3g63/)

## Projecting layers

As you might know layers in Framer are positioned using a set of coordinates, the `x` and `y` values. These are otherwise known as the Cartesian coordinate system. For virtual reality we need to start thinking about the third dimension, thereby increasing the complexity.

An alternative to the Cartesian system is the Spherical coordinate system. Here, each position is described in space around a central origin. Coordinates consist of a heading (polar angle), elevation (zenith angle) and distance value. The heading goes from `0` up to `360` degrees. Hereby North is 0, East 90 and so on. The elevation goes from `-90` up to `90` degrees. Hereby 0 lies on the horizon, -90 is straight down and 90 straight up. By fixing the distance at a default value, we end up with 3D coordinates consisting of only two values, heading and elevation. The VRComponent makes use of this simplified Spherical coordinate system.

[insert GIF which shows how a layer position changes using heading and elevation]

```coffee
# either project a layer by giving the heading and elevation as function parameters
layer = new Layer
vr.projectLayer(layer, 230, 10)

# or set these values on the layer before projecting
layer.heading = 230
layer.elevation = 10
vr.projectLayer(layer)
```

The component wraps each projected layer inside an anchor layer. This anchor layer uses the heading and elevation values to position itself. As a result of the anchor the actual projected layer can still be moved using its x and y coordinates.

[insert GIF how the projected layer can be animated on a 2D plane tangent with the sphere]

## Line of sight

To get the direction the user is facing you can imagine a vector sticking out of the back of your mobile device. The VRComponent is able to determine the heading and elevation of this vector as well as the tilt around that axis. The tilt goes from `-180` up to `180` degrees. You can listen for orientation changes using the `OrientationDidChange` event.

The heading and elevation values are important to determine what the user is looking at and what part of the UI needs focus. Meanwhile the tilt value can for example be used to keep text layers aligned with the viewer, and thus readable.

```
vr.on Events.OrientationDidChange, (data) ->
	heading = data.heading
	elevation = data.elevation
	tilt = data.tilt
```

[Event data](http://share.framerjs.com/lhe5hjvrn23a/)

## Shape puzzle

To give you an idea what can be done using the VRComponent I created a puzzle. The goal of the game is to align a given shape with an identical shape found somewhere in space around you. Each time you succeed you will get the next shape.

[insert GIF of and link to shape puzzle]

If you already have some Framer experience creating a VR prototype should not be that much different. Let me know when you run into any issues and please do not be shy to share your VR prototypes on the Facebook group. I can’t wait to see your explorations.