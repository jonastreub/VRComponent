"""
VRComponent

properties
- front (set: imagePath <string>, get: layer)
- right
- back
- left
- top
- bottom
- heading <number>
- elevation <number>
- tilt <number>

- lookAtLatestSubLayer (bool)

methods
- addSubLayer(layer, heading, elevation) # heading and elevation can also be set as properties on the layer
- hideCube()

events
- Events.OrientationDidChange, (data {heading, elevation, tilt})

"""

SIDES = [
	"north", 
	"front", 
	"east",
	"right", 
	"south", 
	"back", 
	"west", 
	"left", 
	"top", 
	"bottom", 
]

KEYS = {
	LeftArrow: 37
	UpArrow: 38
	RightArrow: 39
	DownArrow: 40
}

Events.OrientationDidChange = "orientationdidchange"

class exports.VRComponent extends Layer

	constructor: (options = {}) ->
		options = _.defaults options,
			cubeSide: 3000
			perspective: 1200
			lookAtLatestProjectedLayer: false
			width: Screen.width
			height: Screen.height
		super options
		@perspective = options.perspective
		@backgroundColor = null
		@createCube(options.cubeSide)
		@degToRad = Math.PI / 180
		@layersToKeepLevel = []
		@lookAtLatestProjectedLayer = options.lookAtLatestProjectedLayer

		@_heading = 0
		@_elevation = 0
		@_tilt = 0

		# tilting and panning
		if Utils.isDesktop()
			@addDesktopPanLayer()
		else
			window.addEventListener "deviceorientation", (event) =>
				@orientationData = event
			Framer.Loop.on "update", =>
				@deviceOrientationUpdate()

		# update screen on orientation change
		if Utils.isMobile()
			window.onresize = =>
				@screenOrientationUpdate()
		else
			Framer.Device.on "change:orientation", =>
				@screenOrientationUpdate(true)

		@useArrowKeys()

	useArrowKeys: ->
		document.addEventListener "keydown", (event) =>
			switch event.which
				when KEYS.UpArrow
					@desktopPan(0, 1)
					event.preventDefault()
				when KEYS.DownArrow
					@desktopPan(0, -1)
					event.preventDefault()
				when KEYS.LeftArrow
					@desktopPan(1, 0)
					event.preventDefault()
				when KEYS.RightArrow
					@desktopPan(-1, 0)
					event.preventDefault()

	@define "heading",
		get: -> @_heading
		set: (value) -> console.log("Heading is readonly")

	@define "elevation",
		get: -> @_elevation
		set: (value) -> console.log("Elevation is readonly")

	@define "tilt",
		get: -> @_tilt
		set: (value) -> console.log("Tilt is readonly")

	SIDES.map (face) =>
		@define face,
			get: -> @layerFromFace(face) # @getImage(face)
			set: (value) -> @setImage(face, value)

	createCube: (cubeSide = @cubeSide) =>
		@cubeSide = cubeSide

		@cube?.destroy()
		@cube = new Layer
			name: "cube"
			superLayer: @
			width: cubeSide, height: cubeSide
			backgroundColor: null
			clip: false
		@cube.style.webkitTransformStyle = "preserve-3d"
		@cube.center()

		halfCubSide = @cubeSide/2

		@side0 = new Layer
		@side0.style["webkitTransform"] = "rotateX(-90deg) translateZ(-#{halfCubSide}px)"
		@side1 = new Layer
		@side1.style["webkitTransform"] = "rotateY(-90deg) translateZ(-#{halfCubSide}px) rotateZ(90deg)"
		@side2 = new Layer
		@side2.style["webkitTransform"] = "rotateX(90deg) translateZ(-#{halfCubSide}px) rotateZ(180deg)"
		@side3 = new Layer
		@side3.style["webkitTransform"] = "rotateY(90deg) translateZ(-#{halfCubSide}px) rotateZ(-90deg)"
		@side4 = new Layer
		@side4.style["webkitTransform"] = "rotateY(-180deg) translateZ(-#{halfCubSide}px)"
		@side5 = new Layer
		@side5.style["webkitTransform"] = "translateZ(-#{halfCubSide}px)  rotateZ(180deg)"

		@sides = [@side0, @side1, @side2, @side3, @side4, @side5]
		colors = ["#866ccc", "#28affa", "#2dd7aa", "#ffc22c", "#7ddd11", "#f95faa"]
		sideNames = ["front", "right", "back", "left", "top", "bottom"]

		index = 0
		for side in @sides
			side.name = sideNames[index]
			side.width = side.height = cubeSide
			side.superLayer = @cube
			side.html = sideNames[index]
			side.color = "white"
			side._backgroundColor = colors[index]
			side.backgroundColor = colors[index]
			side.style =
				lineHeight: "#{cubeSide}px"
				textAlign: "center"
				fontSize: "#{cubeSide / 4}px"
				fontWeight: "100"
				fontFamily: "Helvetica Neue"
			index++

		if @sideImages
			for key of @sideImages
				@setImage key, @sideImages[key]

	hideCube: ->
		for side in @sides
			side.destroy()

	screenOrientationUpdate: (desktop=false) =>
		if desktop
			@width = Screen.height
			@height = Screen.width
		else
			@width = Screen.width
			@height = Screen.height

		@cube?.center()

	layerFromFace: (face) ->
		map =
			north: @side0
			front: @side0
			east:  @side1
			right: @side1
			south: @side2
			back:  @side2
			west:  @side3
			left:  @side3
			top:   @side4
			bottom:@side5
		return map[face]

	setImage: (face, imagePath) ->
		
		if not face in SIDES
			throw Error "VRComponent setImage, wrong name for face: " + face + ", valid options: front, right, back, left, top, bottom, north, east, south, west"

		if not @sideImages
			@sideImages = {}
		@sideImages[face] = imagePath

		layer = @layerFromFace(face)
		
		if imagePath
			layer?.html = ""
			layer?.image = imagePath
		else
			layer?.html = layer?.name
			layer?.backgroundColor = layer?._backgroundColor

	getImage: (face) ->

		if not face in SIDES
			throw Error "VRComponent getImage, wrong name for face: " + face + ", valid options: front, right, back, left, top, bottom, north, east, south, west"

		layer = @layerFromFace(face)
		if layer
			layer.image

	projectLayer: (insertLayer, heading, elevation) ->
		anchor = new Layer
			width: 0, height:0
			clip: false
			name: "augmentAnchor"
		anchor.superLayer = @cube
		insertLayer.superLayer = anchor
		insertLayer.center()

		if heading == undefined
			heading = insertLayer.heading
			if heading == undefined
				heading = 0
		if elevation == undefined
			elevation = insertLayer.elevation
			if elevation == undefined
				elevation = 0
		elevation = Utils.clamp(elevation, -90, 90)
		halfCubSide = @cubeSide/2
		anchor.style["webkitTransform"] = "translateX(#{(@cubeSide - anchor.width)/2}px) translateY(#{(@cubeSide - anchor.height)/2}px) rotateZ(#{heading}deg) rotateX(#{90-elevation}deg) translateZ(#{halfCubSide*.9}px) rotateX(180deg)"
		if @lookAtLatestProjectedLayer
			@lookAt(heading, elevation)

		Framer.CurrentContext.on "layer:destroy", (layer) ->
			print "layer removed: #{layer.name}"

	# Mobile device orientation

	deviceOrientationUpdate: =>

		if @orientationData

			alpha = @orientationData.alpha
			beta = @orientationData.beta
			gamma = @orientationData.gamma

			if alpha != 0 && beta != 0 && gamma != 0
				@directionParams(alpha, beta, gamma)

			xAngle = beta
			yAngle = -gamma
			zAngle = alpha

			halfCubSide = @cubeSide/2
			orientation = "rotate(#{window.orientation * -1}deg) "
			translationX = "translateX(#{(@width / 2) - halfCubSide}px)"
			translationY = " translateY(#{(@height / 2) - halfCubSide}px)"
			rotation = translationX + translationY + orientation + " rotateY(#{yAngle}deg) rotateX(#{xAngle}deg) rotateZ(#{zAngle}deg)"
			@cube.style["webkitTransform"] = rotation

	directionParams: (alpha, beta, gamma) ->

		alphaRad = alpha * @degToRad
		betaRad = beta * @degToRad
		gammaRad = gamma * @degToRad

		# Calculate equation components
		cA = Math.cos(alphaRad)
		sA = Math.sin(alphaRad)
		cB = Math.cos(betaRad)
		sB = Math.sin(betaRad)
		cG = Math.cos(gammaRad)
		sG = Math.sin(gammaRad)

		# x unitvector
		xrA = -sA * sB * sG + cA * cG
		xrB = cA * sB * sG + sA * cG
		xrC = cB * sG

		# y unitvector
		yrA = -sA * cB
		yrB = cA * cB
		yrC = -sB

		# -z unitvector
		zrA = -sA * sB * cG - cA * sG
		zrB = cA * sB * cG - sA * sG
		zrC = cB * cG

		# Calculate heading
		heading = Math.atan(zrA / zrB)

		# Convert from half unit circle to whole unit circle
		if zrB < 0
			heading += Math.PI
		else if zrA < 0
			heading += 2 * Math.PI

		# # Calculate Altitude (in degrees)
		elevation = Math.PI / 2 - Math.acos(-zrC)

		cH = Math.sqrt(1 - (zrC * zrC))
		tilt = Math.acos(-xrC / cH) * Math.sign(yrC)

		# Convert radians to degrees
		heading *= 180 / Math.PI
		elevation *= 180 / Math.PI
		tilt *= 180 / Math.PI

		@_heading = Math.round(heading * 1000) / 1000
		@_elevation = Math.round(elevation * 1000) / 1000

		tilt = Math.round(tilt * 1000) / 1000
		orientationTiltOffset = (window.orientation * -1) + 90
		tilt += orientationTiltOffset
		if tilt > 180
			diff = tilt - 180
			tilt = -180 + diff
		@_tilt = tilt

		@_emitOrientationDidChangeEvent()

	# Desktop tilt

	addDesktopPanLayer: =>
		@desktopOrientationLayer?.destroy()
		@currentDesktopDir = 0
		@currentDesktopHeight = 0
		@desktopPan(0, 0)
		@desktopOrientationLayer = new Layer
			width: 100000, height: 10000
			backgroundColor: null
			superLayer:@
			name: "desktopOrientationLayer"
		@desktopOrientationLayer.center()
		@desktopOrientationLayer.draggable.enabled = true
		
		@prevDesktopDir = @desktopOrientationLayer.x
		@prevDesktopHeight = @desktopOrientationLayer.y
		
		@desktopOrientationLayer.on Events.DragStart, =>
			@prevDesktopDir = @desktopOrientationLayer.x
			@prevDesktopHeight = @desktopOrientationLayer.y
			@desktopDraggableActive = true
			
		@desktopOrientationLayer.on Events.Move, =>
			if @desktopDraggableActive
				deltaDir = (@desktopOrientationLayer.x - @prevDesktopDir) / 9
				deltaHeight = (@desktopOrientationLayer.y - @prevDesktopHeight) / 8
				@desktopPan(deltaDir, deltaHeight)
				@prevDesktopDir = @desktopOrientationLayer.x
				@prevDesktopHeight = @desktopOrientationLayer.y
		
		@desktopOrientationLayer.on Events.AnimationEnd, =>
			@desktopDraggableActive = false
			@desktopOrientationLayer?.center()

	desktopPan: (deltaDir, deltaHeight) ->
		halfCubSide = @cubeSide/2
		translationX = "translateX(#{(@width / 2) - halfCubSide}px)"
		translationY = " translateY(#{(@height / 2) - halfCubSide}px)"
		@currentDesktopDir += deltaDir

		if @currentDesktopDir > 360
			@currentDesktopDir -= 360
		else if @currentDesktopDir < 0
			@currentDesktopDir += 360

		@currentDesktopHeight += deltaHeight
		@currentDesktopHeight = Utils.clamp(@currentDesktopHeight, -90, 90)
		rotation = translationX + translationY + " rotateX(#{@currentDesktopHeight + 90}deg) rotateZ(#{@currentDesktopDir}deg)"
		@cube.style["webkitTransform"] = rotation

		@_heading = Math.round(Math.abs(360 - @currentDesktopDir) * 1000) / 1000
		@_elevation = @currentDesktopHeight
		@_tilt = 0
		@_emitOrientationDidChangeEvent()

	lookAt: (heading, elevation) ->
		halfCubSide = @cubeSide/2
		translationX = "translateX(#{(@width / 2) - halfCubSide}px)"
		translationY = " translateY(#{(@height / 2) - halfCubSide}px)"
		rotation = translationX + translationY + " rotateX(#{elevation + 90}deg) rotateZ(#{-heading}deg)"
		@cube.style["webkitTransform"] = rotation
		@currentDesktopDir = -heading
		@currentDesktopHeight = elevation
		@_emitOrientationDidChangeEvent()

	_emitOrientationDidChangeEvent: ->
		@emit(Events.OrientationDidChange, {heading: @_heading, elevation: @_elevation, tilt: @_tilt})
