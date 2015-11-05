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

- orientationLayer <bool>
- arrowKeys <bool>
- lookAtLatestProjectedLayer <bool>

methods
- projectLayer(layer, heading, elevation) # heading and elevation can also be set as properties on the layer
- hideEnviroment()

- lookAtLayer(layer <Layer>, animated = true <bool>)
- lookAtHeading(heading <number>, animated = true <bool>)

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

KEYSDOWN = {
	left: false
	up: false
	right: false
	down: false
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
			orientationLayer: true
			arrowKeys: true
		super options
		@perspective = options.perspective
		@backgroundColor = null
		@createCube(options.cubeSide)
		@degToRad = Math.PI / 180
		@layersToKeepLevel = []
		@lookAtLatestProjectedLayer = options.lookAtLatestProjectedLayer
		@arrowKeys = options.arrowKeys
		@_keys()

		@currentDesktopDir = 0
		@_heading = 0
		@_elevation = 0
		@_tilt = 0

		@_headingOffset = 0
		@_elevationOffset = 0
		@_deviceHeading = 0
		@_deviceElevation = 0

		@orientationLayer = options.orientationLayer

		@desktopPan(0, 0)

		# tilting and panning
		if Utils.isMobile()
			window.addEventListener "deviceorientation", (event) =>
				@orientationData = event

		Framer.Loop.on "update", =>
			@deviceOrientationUpdate()

		@on "change:frame", ->
			@desktopPan(0,0)

	_keys: ->
		document.addEventListener "keydown", (event) =>
			if @arrowKeys
				switch event.which
					when KEYS.UpArrow
						KEYSDOWN.up = true
						event.preventDefault()
					when KEYS.DownArrow
						KEYSDOWN.down = true
						event.preventDefault()
					when KEYS.LeftArrow
						KEYSDOWN.left = true
						event.preventDefault()
					when KEYS.RightArrow
						KEYSDOWN.right = true
						event.preventDefault()

		document.addEventListener "keyup", (event) =>
			if @arrowKeys
				switch event.which
					when KEYS.UpArrow
						KEYSDOWN.up = false
						event.preventDefault()
					when KEYS.DownArrow
						KEYSDOWN.down = false
						event.preventDefault()
					when KEYS.LeftArrow
						KEYSDOWN.left = false
						event.preventDefault()
					when KEYS.RightArrow
						KEYSDOWN.right = false
						event.preventDefault()

		window.onblur = ->
			KEYSDOWN.up = false
			KEYSDOWN.down = false
			KEYSDOWN.left = false
			KEYSDOWN.right = false

	@define "orientationLayer",
		get: -> return @desktopOrientationLayer != null && @desktopOrientationLayer != undefined
		set: (value) ->
			if @cube != undefined
				if Utils.isDesktop()
					if value == true
						@addDesktopPanLayer()
					else if value == false
						@removeDesktopPanLayer()

	@define "heading",
		get: ->
			heading = @_heading + @_headingOffset
			if heading > 360
				heading = heading % 360
			else if heading < 0
				rest = Math.abs(heading) % 360
				heading = 360 - rest
			return heading
		set: (value) ->
			@lookAt(value, @_elevation)

	@define "elevation",
		get: -> @_elevation
		set: (value) -> @lookAt(@_heading, value)

	@define "tilt",
		get: -> @_tilt
		set: (value) -> throw "Tilt is readonly"

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
		@side4.style["webkitTransform"] = "rotateY(-180deg) translateZ(-#{halfCubSide}px) rotateZ(180deg)"
		@side5 = new Layer
		@side5.style["webkitTransform"] = "translateZ(-#{halfCubSide}px)"

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

	hideEnviroment: ->
		for side in @sides
			side.destroy()

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
		insertLayer.heading = heading
		insertLayer.elevation = elevation
		halfCubSide = @cubeSide/2
		anchor.style["webkitTransform"] = "translateX(#{(@cubeSide - anchor.width)/2}px) translateY(#{(@cubeSide - anchor.height)/2}px) rotateZ(#{heading}deg) rotateX(#{90-elevation}deg) translateZ(#{halfCubSide*.9}px) rotateX(180deg)"
		if @lookAtLatestProjectedLayer
			@lookAt(heading, elevation)

	lookAtLayer: (layer, animated = true) ->
		@lookAtHeading(layer.heading, animated)

	lookAtHeading: (heading, animated = true) ->
		if animated
			options = _.clone(@animationOptions)
			options.properties = heading: heading
			@animate options
		else
			@lookAt(heading, @_elevation)

	# Mobile device orientation

	deviceOrientationUpdate: =>

		if Utils.isDesktop()
			if @arrowKeys
				if @_lastCallHorizontal == undefined
					@_lastCallHorizontal = 0
					@_lastCallVertical = 0
					@_accelerationHorizontal = 1
					@_accelerationVertical = 1
					@_goingUp = false
					@_goingLeft = false

				date = new Date()
				x = .1
				if KEYSDOWN.up || KEYSDOWN.down
					diff = date - @_lastCallVertical
					if diff < 30
						if @_accelerationVertical < 30
							@_accelerationVertical += 0.18
					if KEYSDOWN.up
						if @_goingUp == false
							@_accelerationVertical = 1
							@_goingUp = true
						@desktopPan(0, 1 * @_accelerationVertical * x)
					else
						if @_goingUp == true
							@_accelerationVertical = 1
							@_goingUp = false
						
						@desktopPan(0, -1 * @_accelerationVertical * x)
					@_lastCallVertical = date

				else
					@_accelerationVertical = 1

				if KEYSDOWN.left || KEYSDOWN.right
					diff = date - @_lastCallHorizontal
					if diff < 30
						if @_accelerationHorizontal < 25
							@_accelerationHorizontal += 0.18
					if KEYSDOWN.left
						if @_goingLeft == false
							@_accelerationHorizontal = 1
							@_goingLeft = true
						@desktopPan(1 * @_accelerationHorizontal * x, 0)
					else
						if @_goingLeft == true
							@_accelerationHorizontal = 1
							@_goingLeft = false
						@desktopPan(-1 * @_accelerationHorizontal * x, 0)
					@_lastCallHorizontal = date
				else
					@_accelerationHorizontal = 1

		else if @orientationData

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
			rotation = translationX + translationY + orientation + " rotateY(#{yAngle}deg) rotateX(#{xAngle}deg) rotateZ(#{zAngle}deg)" + " rotateZ(#{-@_headingOffset}deg)"
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

		@_deviceHeading = @_heading
		@_deviceElevation = @_elevation

		@_emitOrientationDidChangeEvent()

	# Desktop tilt

	removeDesktopPanLayer: =>
		@desktopOrientationLayer?.destroy()

	addDesktopPanLayer: =>
		@desktopOrientationLayer?.destroy()
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
		@_heading -= deltaDir

		if @_heading > 360
			@_heading -= 360
		else if @_heading < 0
			@_heading += 360

		@_elevation += deltaHeight
		@_elevation = Utils.clamp(@_elevation, -90, 90)

		rotation = translationX + translationY + " rotateX(#{@_elevation + 90}deg) rotateZ(#{360 - @_heading}deg)" + " rotateZ(#{-@_headingOffset}deg)"
		@cube.style["webkitTransform"] = rotation

		@_heading = Math.round(@_heading * 1000) / 1000
		@_tilt = 0
		@_emitOrientationDidChangeEvent()

	lookAt: (heading, elevation) ->
		halfCubSide = @cubeSide/2
		translationX = "translateX(#{(@width / 2) - halfCubSide}px)"
		translationY = " translateY(#{(@height / 2) - halfCubSide}px)"
		rotation = translationX + translationY + " rotateX(#{elevation + 90}deg) rotateZ(#{-heading}deg)"
		@cube.style["webkitTransform"] = rotation
		@currentDesktopDir = -heading
		@_heading = heading
		@_elevation = elevation
		if Utils.isMobile()
			@_headingOffset = @_heading - @_deviceHeading

		@_elevationOffset = @_elevation - @_deviceElevation
		@emit(Events.OrientationDidChange, {heading: @_heading, elevation: @_elevation, tilt: @_tilt})

	_emitOrientationDidChangeEvent: ->
		@emit(Events.OrientationDidChange, {heading: @heading, elevation: @_elevation, tilt: @_tilt})
