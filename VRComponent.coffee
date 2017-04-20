"""

VRComponent class

properties
- front (set: imagePath <string>, get: layer)
- right
- back
- left
- top
- bottom
- heading <number>
- elevation <number>
- tilt <number> readonly

- panning <bool>
- mobilePanning <bool>
- arrowKeys <bool>

- lookAtLatestProjectedLayer <bool>

methods
- projectLayer(layer) # heading and elevation are set as properties on the layer
- hideEnviroment()

events
- onOrientationChange (data {heading, elevation, tilt})

--------------------------------------------------------------------------------

VRLayer class

properties
- heading <number> (from 0 up to 360)
- elevation <number> (from -90 down to 90 up)

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

class VRAnchorLayer extends Layer

	constructor: (layer, cubeSide) ->
		super()
		@width = 2
		@height = 2
		@clip = false
		@name = "anchor"
		@cubeSide = cubeSide
		@backgroundColor = null

		@layer = layer
		layer.parent = @
		layer.center()

		layer.on "change:orientation", (newValue, layer) => @updatePosition(layer)
		@updatePosition(layer)

		layer._context.on "layer:destroy", (layer) => @destroy() if layer is @layer

	updatePosition: (layer) ->
		halfCubeSide = @cubeSide / 2
		@midX = halfCubeSide
		@midY = halfCubeSide
		@z = - layer.distance
		@originZ = layer.distance
		@rotationX = -90 - layer.elevation
		@rotationY = -layer.heading

class exports.VRLayer extends Layer

	constructor: (options = {}) ->
		options = _.defaults options,
			heading: 0
			elevation: 0
		super options

	@define "heading",
		get: -> @_heading
		set: (value) ->
			if value >= 360
				value = value % 360
			else if value < 0
				rest = Math.abs(value) % 360
				value = 360 - rest
			roundedValue = Math.round(value * 1000) / 1000
			if @_heading isnt roundedValue
				@_heading = roundedValue
				@emit("change:heading", @_heading)
				@emit("change:orientation", @_heading)

	@define "elevation",
		get: -> @_elevation
		set: (value) ->
			value = Utils.clamp(value, -90, 90)
			roundedValue = Math.round(value * 1000) / 1000
			if roundedValue isnt @_elevation
				@_elevation = roundedValue
				@emit("change:elevation", roundedValue)
				@emit("change:orientation", roundedValue)

	@define "distance",
		get: -> @_distance
		set: (value) ->
			if value isnt @_distance
				@_distance = value
				@emit("change:distance", value)
				@emit("change:orientation", value)

class exports.VRComponent extends Layer

	constructor: (options = {}) ->
		options = _.defaults options,
			cubeSide: 3000
			perspective: 1200
			lookAtLatestProjectedLayer: false
			width: Screen.width
			height: Screen.height
			arrowKeys: true
			panning: true
			mobilePanning: true
			flat: true
			clip: true
		super options

		# to hide the seems where the cube surfaces come together we disable the viewport perspective and set a black background
		Screen.backgroundColor = "black"
		Screen.perspective = 0

		@setupDefaultValues()
		@degToRad = Math.PI / 180
		@backgroundColor = null

		@createCube(options.cubeSide)
		@lookAtLatestProjectedLayer = options.lookAtLatestProjectedLayer
		@setupKeys(options.arrowKeys)

		@heading = options.heading if options.heading?
		@elevation = options.elevation if options.elevation?

		@setupPan(options.panning)
		@mobilePanning = options.mobilePanning

		if Utils.isMobile()
			window.addEventListener "deviceorientation", (event) => @orientationData = event

		Framer.Loop.on("update", @deviceOrientationUpdate)

		# Make sure we remove the update from the loop when we destroy the context
		Framer.CurrentContext.on "reset", -> Framer.Loop.off("update", @deviceOrientationUpdate)

		@on "change:frame", -> @desktopPan(0,0)

	setupDefaultValues: =>

		@_heading = 0
		@_elevation = 0
		@_tilt = 0

		@_headingOffset = 0
		@_elevationOffset = 0
		@_deviceHeading = 0
		@_deviceElevation = 0

	setupKeys: (enabled) ->

		@arrowKeys = enabled

		document.addEventListener "keydown", (event) =>
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

	@define "heading",
		get: ->
			heading = @_heading + @_headingOffset
			if heading > 360
				heading = heading % 360
			else if heading < 0
				rest = Math.abs(heading) % 360
				heading = 360 - rest
			return Math.round(heading * 1000) / 1000
		set: (value) ->
			@lookAt(value, @_elevation)

	@define "elevation",
		get: -> Math.round(@_elevation * 1000) / 1000
		set: (value) ->
			value = Utils.clamp(value, -90, 90)
			@lookAt(@_heading, value)

	@define "tilt",
		get: -> @_tilt
		set: (value) -> throw "Tilt is readonly"

	SIDES.map (face) =>
		@define face,
			get: -> @layerFromFace(face) # @getImage(face)
			set: (value) -> @setImage(face, value)

	createCube: (cubeSide = @cubeSide) =>
		@cubeSide = cubeSide

		@world?.destroy()
		@world = new Layer
			name: "world"
			superLayer: @
			size: cubeSide
			backgroundColor: null
			clip: false
		@world.center()

		@sides = []
		halfCubeSide = @cubeSide / 2
		colors = ["#866ccc", "#28affa", "#2dd7aa", "#ffc22c", "#7ddd11", "#f95faa"]
		sideNames = ["front", "right", "back", "left", "top", "bottom"]

		for sideIndex in [0...6]

			rotationX = 0
			rotationX = -90 if sideIndex in [0...4]
			rotationX = 180 if sideIndex is 4

			rotationY = 0
			rotationY = sideIndex * -90 if sideIndex in [0...4]

			side = new Layer
				size: cubeSide
				z: -halfCubeSide
				originZ: halfCubeSide
				rotationX: rotationX
				rotationY: rotationY
				parent: @world
				name: sideNames[sideIndex]
				html: sideNames[sideIndex]
				color: "white"
				backgroundColor: colors[sideIndex]
				style:
					lineHeight: "#{cubeSide}px"
					textAlign: "center"
					fontSize: "#{cubeSide / 10}px"
					fontWeight: "100"
					fontFamily: "Helvetica Neue"
			@sides.push(side)
			side._backgroundColor = side.backgroundColor

		for key of @sideImages when @sideImages?
			@setImage key, @sideImages[key]

	hideEnviroment: ->
		for side in @sides
			side.destroy()

	layerFromFace: (face) ->
		return unless @sides?
		map =
			north: @sides[0]
			front: @sides[0]
			east:  @sides[1]
			right: @sides[1]
			south: @sides[2]
			back:  @sides[2]
			west:  @sides[3]
			left:  @sides[3]
			top:   @sides[4]
			bottom:@sides[5]
		return map[face]

	setImage: (face, imagePath) ->

		throw Error "VRComponent setImage, wrong name for face: " + face + ", valid options: front, right, back, left, top, bottom, north, east, south, west" unless face in SIDES

		@sideImages = {} unless @sideImages?
		@sideImages[face] = imagePath

		layer = @layerFromFace(face)

		if imagePath?
			layer?.html = ""
			layer?.image = imagePath
		else
			layer?.html = layer?.name
			layer?.backgroundColor = layer?._backgroundColor

	getImage: (face) ->

		throw Error "VRComponent getImage, wrong name for face: " + face + ", valid options: front, right, back, left, top, bottom, north, east, south, west" unless face in SIDES

		layer = @layerFromFace(face)
		return layer.image if layer?

	projectLayer: (insertLayer) ->

		heading = insertLayer.heading
		heading = 0 unless heading?

		if heading >= 360
			heading = value % 360
		else if heading < 0
			rest = Math.abs(heading) % 360
			heading = 360 - rest

		elevation = insertLayer.elevation
		elevation = 0 unless elevation?
		elevation = Utils.clamp(elevation, -90, 90)

		distance = insertLayer.distance
		distance = 1200 unless distance?

		insertLayer.heading = heading
		insertLayer.elevation = elevation
		insertLayer.distance = distance

		anchor = new VRAnchorLayer(insertLayer, @cubeSide)
		anchor.superLayer = @world

		@lookAt(heading, elevation) if @lookAtLatestProjectedLayer

	# Mobile device orientation

	deviceOrientationUpdate: =>

		if Utils.isDesktop()
			if @arrowKeys
				if @_lastCallHorizontal is undefined
					@_lastCallHorizontal = 0
					@_lastCallVertical = 0
					@_accelerationHorizontal = 1
					@_accelerationVertical = 1
					@_goingUp = false
					@_goingLeft = false

				date = new Date()
				x = .1
				if KEYSDOWN.up or KEYSDOWN.down
					diff = date - @_lastCallVertical
					if diff < 30
						if @_accelerationVertical < 30
							@_accelerationVertical += 0.18
					if KEYSDOWN.up
						if @_goingUp is false
							@_accelerationVertical = 1
							@_goingUp = true
						@desktopPan(0, 1 * @_accelerationVertical * x)
					else
						if @_goingUp is true
							@_accelerationVertical = 1
							@_goingUp = false

						@desktopPan(0, -1 * @_accelerationVertical * x)
					@_lastCallVertical = date

				else
					@_accelerationVertical = 1

				if KEYSDOWN.left or KEYSDOWN.right
					diff = date - @_lastCallHorizontal
					if diff < 30
						if @_accelerationHorizontal < 25
							@_accelerationHorizontal += 0.18
					if KEYSDOWN.left
						if @_goingLeft is false
							@_accelerationHorizontal = 1
							@_goingLeft = true
						@desktopPan(1 * @_accelerationHorizontal * x, 0)
					else
						if @_goingLeft is true
							@_accelerationHorizontal = 1
							@_goingLeft = false
						@desktopPan(-1 * @_accelerationHorizontal * x, 0)
					@_lastCallHorizontal = date
				else
					@_accelerationHorizontal = 1

		else if @orientationData?

			alpha = @orientationData.alpha
			beta = @orientationData.beta
			gamma = @orientationData.gamma

			@directionParams(alpha, beta, gamma) if alpha isnt 0 and beta isnt 0 and gamma isnt 0

			@world.midX = @midX
			@world.midY = @midY
			@world.z = @perspective
			@world.rotation = -@_heading - @_headingOffset
			@world.rotationX = 90 + @_elevation
			@world.rotationY = @_tilt

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
		tilt -= 360 if tilt > 180
		@_tilt = tilt

		@_deviceHeading = @_heading
		@_deviceElevation = @_elevation
		@_emitOrientationDidChangeEvent()

	# Panning

	_canvasToComponentRatio: =>
		pointA = Utils.convertPointFromContext({x:0, y:0}, @, true)
		pointB = Utils.convertPointFromContext({x:1, y:1}, @, true)
		xDist = Math.abs(pointA.x - pointB.x)
		yDist = Math.abs(pointA.y - pointB.y)
		return {x:xDist, y:yDist}

	setupPan: (enabled) =>

		@panning = enabled
		@desktopPan(0, 0)

		@onMouseDown => @animateStop()

		@onPan (data) =>
			return if not @panning
			ratio = @_canvasToComponentRatio()
			deltaX = data.deltaX * ratio.x
			deltaY = data.deltaY * ratio.y
			strength = Utils.modulate(@perspective, [1200, 900], [22, 17.5])

			if Utils.isMobile()
				@_headingOffset -= (deltaX / strength) if @mobilePanning
			else
				@desktopPan(deltaX / strength, deltaY / strength)

			@_prevVeloX = data.velocityX
			@_prevVeloU = data.velocityY

		@onPanEnd (data) =>
			return if not @panning or Utils.isMobile()
			ratio = @_canvasToComponentRatio()
			velocityX = (data.velocityX + @_prevVeloX) * 0.5
			velocityY = (data.velocityY + @_prevVeloY) * 0.5
			velocityX *= velocityX
			velocityY *= velocityY
			velocityX *= ratio.x
			velocityY *= ratio.y
			strength = Utils.modulate(@perspective, [1200, 900], [22, 17.5])

			@animate
				heading: @heading - (data.velocityX * ratio.x * 200) / strength
				elevation: @elevation + (data.velocityY * ratio.y * 200) / strength
				options: curve: "spring(300,100)"

	desktopPan: (deltaDir, deltaHeight) ->
		halfCubeSide = @cubeSide/2
		@_heading -= deltaDir

		if @_heading > 360
			@_heading -= 360
		else if @_heading < 0
			@_heading += 360

		@_elevation += deltaHeight
		@_elevation = Utils.clamp(@_elevation, -90, 90)

		@world.midX = @midX
		@world.midY = @midY
		@world.z = @perspective
		@world.rotationX = 90 + @_elevation
		@world.rotation = -@_heading - @_headingOffset

		@_emitOrientationDidChangeEvent()

	lookAt: (heading, elevation) ->

		@world.midX = @midX
		@world.midY = @midY
		@world.z = @perspective
		@world.rotationX = 90 + @_elevation
		@world.rotation = -@_heading
		@world.rotationY = @_tilt

		@_heading = heading
		@_elevation = elevation
		@_headingOffset = @_heading - @_deviceHeading if Utils.isMobile()
		@_elevationOffset = @_elevation - @_deviceElevation

		heading = @_heading
		if heading < 0
			heading += 360
		else if heading > 360
			heading -= 360

		@_emitOrientationDidChangeEvent()

	_emitOrientationDidChangeEvent: =>
		@emit(Events.OrientationDidChange, {heading: @heading, elevation: @elevation, tilt: @tilt})

	# event shortcuts

	onOrientationChange:(cb) -> @on(Events.OrientationDidChange, cb)
