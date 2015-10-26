# VRComponent

A virtual reality component for [Framer](http://framerjs.com). The virtual enviroment is created using the [cubemap technique](https://en.wikipedia.org/wiki/Cube_mapping). The cube requires six images, one for each side. Your own layers can be projected on top of the virtual environment. Projected layers are positioned using `heading` and `elevation` values.

You can listen for orientation updates using the `OrientationDidChange` event. This event contains information about heading, elevation and tilt.

Read more on the associated [blogpost]().

## Examples
- [Base setup](http://share.framerjs.com/dqsd8kr5exij/)
- [Event data](http://share.framerjs.com/lhe5hjvrn23a/)
- [VR shape puzzle](http://share.framerjs.com/vfa1wqhsqldw/)

On mobile the orientation is synced to that of your device. On desktop you can change the direction you are facing either by dragging the `orientationLayer` or by using your arrow keys. The  `orientationLayer` blocks all click and tap events of projected layers. If these events are important for your prototype you can disable the `orientationLayer`.

## Properties
- **`front`** (set: imagePath *\<string>*, get: layer)
- **`right`** (set: imagePath *\<string>*, get: layer)
- **`back`** (set: imagePath *\<string>*, get: layer)
- **`left`** (set: imagePath *\<string>*, get: layer)
- **`top`** (set: imagePath *\<string>*, get: layer)
- **`bottom`** (set: imagePath *\<string>*, get: layer)
- **`heading`** *\<number>* (0 to 360 degrees)
- **`elevation`** *\<number>* (-90 to 90 degrees)
- **`tilt`** *\<number>* (-180 to 180 degrees)
- **`lookAtLatestProjectedLayer`** *\<bool>*
- **`orientationLayer`** *\<bool>*
- **`arrowKeys`** *\<bool>*

```coffee
{VRComponent} = require "VRComponent"

vr = new VRComponent
	front: "images/front.png"
	left: "images/left.png"
	right: "images/right.png"
	back: "images/back.png"
	top: "images/top.png"
	bottom: "images/bottom.png"
```

## Functions
- **`projectLayer`(**layer, heading, elevation**)**
- **`hideEnviroment`()**

```coffee
# either project a layer by giving the heading and elevation as function parameters
layer = new Layer
vr.projectLayer(layer, 230, 10)

# or set these values on the layer before projecting
layer.heading = 230
layer.elevation = 10
vr.projectLayer(layer)
```

## Events
- **`Events.OrientationDidChange`**, (*\<object>* {heading, elevation, tilt})

```coffee
vr.on Events.OrientationDidChange, (data) ->
	heading = data.heading
	elevation = data.elevation
	tilt = data.tilt
```

## Future plans
- Integrate support for Google Street View panoramas
- Add support for spheremap projection (WebGL)
