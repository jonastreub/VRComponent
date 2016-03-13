# VRComponent

A virtual reality component for [Framer](http://framerjs.com). The virtual enviroment is created using the [cubemap technique](https://en.wikipedia.org/wiki/Cube_mapping). The cube requires six images, one for each side. Your own layers can be projected on top of the virtual environment. Projected layers are positioned using `heading` and `elevation` values.

You can listen for orientation updates using the `OrientationDidChange` event. This event contains information about heading, elevation and tilt.

Read more on the associated [blogpost](http://blog.framerjs.com/posts/design-virtual-reality.html).

## Examples
- [Base setup](http://share.framerjs.com/04xirgfmtlw6/)
- [Event data](http://share.framerjs.com/lhqbyvlz5t9h/)
- [Space puzzle](http://share.framerjs.com/4v5wono2two5/)

On mobile the orientation is synced to that of your device. On desktop you can change the direction you are facing either by dragging the environment or by using your arrow keys.

## Properties
- **`front`** (set: imagePath *\<string>*, get: layer)
- **`right`** (set: imagePath *\<string>*, get: layer)
- **`back`** (set: imagePath *\<string>*, get: layer)
- **`left`** (set: imagePath *\<string>*, get: layer)
- **`top`** (set: imagePath *\<string>*, get: layer)
- **`bottom`** (set: imagePath *\<string>*, get: layer)
- **`heading`** *\<number>* (0 to 360 degrees)
- **`elevation`** *\<number>* (-90 to 90 degrees)
- **`tilt`** *\<number, readonly>* (-180 to 180 degrees)
- **`lookAtLatestProjectedLayer`** *\<bool>*
- **`panning`** *\<bool>*
- **`mobilePanning`** *\<bool>*
- **`arrowKeys`** *\<bool>*

```coffee
# Include the VRComponent
{VRComponent, VRLayer} = require "VRComponent"

# Create a new VRComponent, map images
vr = new VRComponent
	front:  "images/front.png"
	left:   "images/left.png"
	right:  "images/right.png"
	back:   "images/back.png"
	top:    "images/top.png"
	bottom: "images/bottom.png"
```

## Mapping images
To map your environment, you can look for cubemap images on the web. Each side is often named by the positive or negative X, Y, or Z axis.

- **right** - positive-x
- **top** - positive-y
- **front** - positive-z
- **left** - negative-x
- **bottom** - negative-y
- **back** - negative-z

## Projecting Layers
Creating a new Layer on top of your virtual environment will position them in 2D space by default. This is useful when looking to overlay interface elements, like sliders or printed values of heading, elevation or tilt. However, if you'd like to position layers with 3D space, you can use the **`projectLayer()`** method.

##### VRLayers
Any layer can be projected within your virtual environment, but if you'd like to adjust or animate their `heading` or `elevation` values later, you'll need to use a **`VRLayer`** instead.

```coffee
# Include VRComponent and VRLayer
{VRComponent, VRLayer} = require "VRComponent"

# Create layer
layerA = new VRLayer 

# Set layer heading and elevation before projecting
layerA.heading = 230
layerA.elevation = 10

# Project the layer
vr.projectLayer(layerA)
```

`distance` is a third positioning value which defaults to `1200`, equal to the default perspective. When distance and perspective are equal layers are rendered at the size they had before projecting.

## Animating VRLayers

The `heading` and `elevation` values of a `VRLayer` can be animated.

```coffee
# Include VRComponent and VRLayer
{VRComponent, VRLayer} = require "VRComponent"

# Create VRLayer
layerA = new VRLayer

# Project the VRLayer
vr.projectLayer(layerA)

# Animate the layer
layerA.animate
	properties:
		heading: 30
	time: 10
```

## Events
- **`Events.OrientationDidChange`**, (*\<object>* {heading, elevation, tilt})

```coffee
vr.on Events.OrientationDidChange, (data) ->
	heading = data.heading
	elevation = data.elevation
	tilt = data.tilt
```

## Devices

The module has been tested on the following devices.

Device | Performance
------ | -----------
iPhone 6 | Good
iPhone 6 Plus | Great
iPhone 5C | Poor
Nexus 5 | Poor

## Future plans
- Google Street View panoramas
- Stereoscopic VR
