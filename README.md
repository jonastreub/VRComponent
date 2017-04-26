# VRComponent

A virtual reality component for [Framer](http://framerjs.com). The virtual enviroment is created using the [cubemap technique](https://en.wikipedia.org/wiki/Cube_mapping). The cube requires six images, one for each side. Your own layers can be projected on top of the virtual environment. Projected layers are positioned using `heading` and `elevation` values.

You can listen for orientation updates using the `onOrientationChange` event. This event contains information about heading, elevation and tilt.

Read more on the associated [blogpost](https://blog.framer.com/design-for-virtual-reality-b510b4641ca9#.jua87j76h).

## Examples
- [Base setup](http://share.framerjs.com/ka167ltz631v/)
- [Event data](http://share.framerjs.com/jz980s21ienj/)
- [Space puzzle](http://share.framerjs.com/otx1jolma4u3/)
- [Interactive resume](http://share.framerjs.com/ojd9q3dg5xem/) by [Jonathan](http://jonathanravasz.com)

On mobile the orientation is synced to that of your device. On desktop you can change the direction you are facing either by dragging the environment or by using your arrow keys.

## Properties
- **`front`** (set: imagePath *\<string>*, get: layer)
- **`right`** (set: imagePath *\<string>*, get: layer)
- **`back`** (set: imagePath *\<string>*, get: layer)
- **`left`** (set: imagePath *\<string>*, get: layer)
- **`top`** (set: imagePath *\<string>*, get: layer)
- **`bottom`** (set: imagePath *\<string>*, get: layer)
- **`panning`** *\<bool>*
- **`mobilePanning`** *\<bool>*
- **`arrowKeys`** *\<bool>*
- **`lookAtLatestProjectedLayer`** *\<bool>* (handy during initial setup)

--
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

Note: This [tool](https://www.360toolkit.co/convert-spherical-equirectangular-to-cubemap.html) can convert your spherical panoramas to a cubemap.

## Projecting Layers
Creating a new Layer on top of your virtual environment will position them in 2D space by default. This is useful when looking to overlay interface elements, like sliders or printed values of heading, elevation or tilt. However, if you'd like to position layers within the 3D space, you can use the **`projectLayer()`** method.

![sherical projection](http://github.jonastreub.com/sphere.png)

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
- **`onOrientationChange`** (*\<object>* {heading, elevation, tilt})

```coffee
vr.onOrientationChange (data) ->
	heading = data.heading
	elevation = data.elevation
	tilt = data.tilt
```

## Devices

The module has been tested on the following devices.

Device | Performance
------ | -----------
iPhone 7 | Great
iPhone 6 | Good
iPhone 6 Plus | Great
iPhone 5C | Poor
Nexus 5 | Poor
