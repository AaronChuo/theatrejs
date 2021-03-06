Foxie = require 'foxie'
_ItemView = require './_ItemView'

module.exports = class PointView extends _ItemView

	constructor: (@prop, @model) ->

		super

		@x = 0

		@y = 0

		@pacs = @model.pacs

		@heightUsage = 0.7

		@svgArea = @prop.svgArea

		@timelineEditor = @prop.timelineEditor

		@_active = no

		@_lastValue = @model.value

		@_tempKilidScope = @rootView.kilid.getTempScope()

		@_tempKilidScope.on 'enter', => do @_commitValueAndDeactivate

		@_tempKilidScope.on 'esc', => do @_discardValueAndDeactivate

		do @_prepareNode

		do @_prepareHandlers

		do @_prepareValueInputNode

		do @relayHorizontally

		do @relayVertically

		@model.on 'value-change', =>

			do @relayVertically

		@model.on 'handler-change', =>

			do @_moveHandlers

		@model.on 'time-change', =>

			do @relayHorizontally

		@model.on 'remove', =>

			do @_remove

	_prepareNode: ->

		@node = Foxie('.theatrejs-timelineEditor-prop-pacs-point').putIn @prop.pacsNode

		do @_prepareNodeActivationInteractions
		do @_prepareNodeRemovalInteractions
		do @_prepareNodeConnectionInteractions
		do @_prepareNodeMoveInteractions

	_prepareNodeActivationInteractions: ->

		@rootView.moosh.onClick @node, =>

			do @_activate

		.withNoKeys()

		@rootView.moosh.onMiddleClick @node
		.onUp =>

			do @_showPointModificationOptions

		.withNoKeys()

	_prepareNodeRemovalInteractions: ->

		@rootView.moosh.onHover(@node)
		.withKeys('ctrl')
		.onEnter =>

			@node.addClass 'hint-remove'

		.onLeave =>

			@node.removeClass 'hint-remove'

		@rootView.moosh.onClick(@node)
		.withKeys('ctrl')
		.onUp =>

			@model.remove()

			@pacs.done()

			@prop._tick()

	_prepareNodeConnectionInteractions: ->

		couldConnectToLeft = no
		couldConnectToRight = no
		sideToConnect = 0

		@rootView.moosh.onDrag(@node)
		.withKeys('ctrl')
		.onDown =>

			couldConnectToLeft = @model.canConnectToLeft()
			couldConnectToRight = @model.canConnectToRight()

			sideToConnect = 0

		.onDrag (e) =>

			sideToConnect = 0

			if e.absX < 0

				if couldConnectToLeft

					@_showHypotheticalConnectorToTheLeft()

					sideToConnect = -1

				else

					@_hideHypothericalConnector()

					@rootView.cursor.use 'not-allowed'

			else if e.absX > 0

				if couldConnectToRight

					@_showHypotheticalConnectorToTheRight()

					sideToConnect = 1

				else

					@_hideHypothericalConnector()

					@rootView.cursor.use 'not-allowed'

		.onUp =>

			@_hideHypothericalConnector()

			@rootView.cursor.free()

			if sideToConnect is 1

				@model.connectToTheRight()
				@model.pacs.done()

			else if sideToConnect is -1

				@model.connectToTheLeft()
				@model.pacs.done()

			return

	_prepareNodeMoveInteractions: ->

		@rootView.moosh.onDrag(@node)
		.withNoKeys()
		.onDown =>

			@node.addClass 'moving'

			@rootView.cursor.use @node

			do @_hideHandlers

		.onDrag (e) =>

			@node.moveX e.relX
			@node.moveY e.relY

		.onUp (e) =>

			@node.removeClass 'moving'

			@rootView.cursor.free()

			do @_showHandlers

			timeChange = @timelineEditor._XToTime e.absX

			@model.setTime @model.t + timeChange

			valDiff = @prop._YToNormalizedVal e.absY

			@model.setValue @model.value + valDiff

			@pacs.done()

			@prop._tick()

		.onCancel =>

			do @relayHorizontally

			@node.removeClass 'moving'

			@rootView.cursor.free()

			do @_showHandlers

		do @_prepareNodeDragValueInteractions
		do @_prepareNodeDragTimeInteractions

	_prepareNodeDragValueInteractions: ->

		@rootView.moosh.onHover(@node)
		.withKeys('alt')
		.onEnter =>

			@node.addClass 'mightChangeValue'
			@rootView.cursor.use @node

		.onLeave =>

			@node.removeClass 'mightChangeValue'
			@rootView.cursor.free()

		@rootView.moosh.onDrag(@node)
		.withKeys('alt')
		.onDown =>

			@rootView.cursor.use @node

		.onDrag (e) =>

			add = @prop._YToNormalizedVal e.relY

			@model.setValue @model.value + add

			@prop._tick()

		.onUp =>

			@rootView.cursor.free()

			@pacs.done()

			@prop._tick()

		return

	_prepareNodeDragTimeInteractions: ->

		@rootView.moosh.onHover(@node)
		.withKeys('shift')
		.onEnter =>

			@node.addClass 'mightChangeTime'

		.onLeave =>

			@node.removeClass 'mightChangeTime'

		@rootView.moosh.onDrag(@node)
		.withKeys('shift')
		.onDown =>

			@node.addClass 'changingTime'

			@rootView.cursor.use @node

			do @_hideHandlers

		.onDrag (e) =>

			@node.moveX e.relX

		.onUp (e) =>

			timeChange = @timelineEditor._XToTime e.absX

			@model.setTime @model.t + timeChange

			@pacs.done()

			@prop._tick()

			@node.removeClass 'changingTime'

			@rootView.cursor.free()

			do @_showHandlers

		.onCancel =>

			do @relayHorizontally

			@node.removeClass 'changingTime'

			@rootView.cursor.free()

			do @_showHandlers

	_hideHandlers: ->

		@leftHandler.setOpacity(0)
		@rightHandler.setOpacity(0)
		@leftHandlerLine.setOpacity(0)
		@rightHandlerLine.setOpacity(0)

	_showHandlers: ->

		@leftHandler.setOpacity(1)
		@rightHandler.setOpacity(1)
		@leftHandlerLine.setOpacity(1)
		@rightHandlerLine.setOpacity(1)

	_showHypotheticalConnectorToTheLeft: ->

		leftPoint = @model.getLeftPoint()

		@prop.drawHypotheticalConnector @model.t, @model.value, leftPoint.t, leftPoint.value

	_showHypotheticalConnectorToTheRight: ->

		rightPoint = @model.getRightPoint()

		@prop.drawHypotheticalConnector @model.t, @model.value, rightPoint.t, rightPoint.value

	_hideHypothericalConnector: ->

		@prop.hideHypotheticalConnector()

	_moveNode: ->

		@node.moveXTo @x

		@node.moveYTo @y

		return

	_prepareHandlers: ->

		@leftHandler = Foxie('.theatrejs-timelineEditor-prop-pacs-point-handler.left').putIn @node

		@leftHandlerLine = Foxie('svg:path').putIn(@svgArea.node)
		.attr('stroke', '#272727')
		.attr('stroke-width', '1px')
		.attr('fill', 'transparent')

		@rightHandlerLine = Foxie('svg:path').putIn(@svgArea.node)
		.attr('stroke', '#272727')
		.attr('stroke-width', '1px')
		.attr('fill', 'transparent')

		@rightHandler = Foxie('.theatrejs-timelineEditor-prop-pacs-point-handler.right').putIn @node

		do @_setupHandlerModifications
		do @_setupDragForRightHandler
		do @_setupDragForLeftHandler

	_setupHandlerModifications: ->

		@rootView.moosh.onMiddleClick @leftHandler
		.onUp =>

			@_showHandlerModificationOptions 'left'

		.withNoKeys()

		@rootView.moosh.onMiddleClick @rightHandler
		.onUp =>

			@_showHandlerModificationOptions 'right'

		.withNoKeys()

	_setupDragForRightHandler: ->

		startX = startY = nextX = nextY = 0

		@rootView.moosh.onDrag(@rightHandler)

		.onDown =>

			startX = @rightHandler.getMovement()[0]
			startY = @rightHandler.getMovement()[1]

		.onUp =>

			@pacs.done()

		.onDrag (e) =>

			nextX = startX + e.absX
			nextY = startY + e.absY

			nextX = 0 if nextX < 0

			nextT = @timelineEditor._XToTime nextX
			nextVal = @prop._YToNormalizedVal nextY

			@model.setRightHandler nextT, nextVal

			@prop._tick()

		return

	_setupDragForLeftHandler: ->

		startX = startY = nextX = nextY = 0

		@rootView.moosh.onDrag(@leftHandler)

		.onDown =>

			startX = -@leftHandler.getMovement()[0]
			startY = @leftHandler.getMovement()[1]

		.onUp =>

			@pacs.done()

		.onDrag (e) =>

			nextX = startX - e.absX
			nextY = startY + e.absY

			nextX = 0 if nextX < 0

			nextT = @timelineEditor._XToTime nextX
			nextVal = @prop._YToNormalizedVal nextY

			@model.setLeftHandler nextT, nextVal

			@prop._tick()

		return

	_moveHandlers: ->

		@leftHandler.moveXTo @timelineEditor._timeToX -@model.leftHandler[0]
		@leftHandler.moveYTo @prop._normalizedValToY @model.leftHandler[1]

		@rightHandler.moveXTo @timelineEditor._timeToX @model.rightHandler[0]
		@rightHandler.moveYTo @prop._normalizedValToY @model.rightHandler[1]

		@leftHandlerLine.attr 'd',

			"M#{@x} #{@y} L " +
			"#{@timelineEditor._timeToX(@model.t - @model.leftHandler[0])} #{@prop._valToY(@model.value + @model.leftHandler[1])}"

		@rightHandlerLine.attr 'd',

			"M#{@x} #{@y} L " +
			"#{@timelineEditor._timeToX(@model.t + @model.rightHandler[0])} #{@prop._valToY(@model.value + @model.rightHandler[1])}"

	_prepareValueInputNode: ->

		@valueContainer = Foxie('.theatrejs-timelineEditor-prop-pacs-point-valueContainer').putIn @node

		@valueInput = Foxie('input').putIn @valueContainer

		@valueInput.node.addEventListener 'keyup', =>

			if @_active

				@_setValue @valueInput.node.value

	_moveValueContainer: ->

		if @y > 30

			@valueContainer.removeClass 'hang'

		else

			@valueContainer.addClass 'hang'

		return

	_setValue: (newVal) ->

		newVal = Number newVal

		return unless Number.isFinite newVal

		@model.setValue newVal

		@pacs.done()

		@prop._tick()

		return

	relayHorizontally: ->

		@x = @timelineEditor._timeToX @model.t

		do @_moveNode

		do @_moveHandlers

		return

	relayVertically: ->

		@y = @prop._valToY @model.value

		do @_moveNode

		do @_moveValueContainer

		do @_moveHandlers

		return

	_remove: ->

		@rootView.moosh.forgetNode(@node)
		@rootView.moosh.forgetNode(@leftHandler)
		@rootView.moosh.forgetNode(@rightHandler)

		@node.quit()
		@leftHandler.quit()
		@leftHandlerLine.quit()
		@rightHandler.quit()
		@rightHandlerLine.quit()

		super

	_activate: ->

		return if @_active

		@_active = yes

		@valueInput.node.value = parseFloat(parseFloat(@model.value).toFixed(3))

		@node.addClass 'active'

		@valueInput.node.focus()

		@rootView.moosh.ignore(@valueInput)

		@_tempKilidScope.activate()

		@_lastValue = @model.value

		@rootView.moosh.onClickOutside @node, =>

			do @_commitValueAndDeactivate

		return

	_deactivate: ->

		@_active = no

		@node.removeClass 'active'

		@_tempKilidScope.deactivate()

		@rootView.moosh.discardClickOutside @node

		@rootView.moosh.unignore(@valueInput)

		return

	_showPointModificationOptions: ->

		@rootView.chooser.choose '', ['Set Time'], (success, choice) =>

			return unless success

			if choice is 'Set Time'

				do @_askSetTime

	_askSetTime: ->

		@rootView.asker.ask

			question: 'Time: (ms)'

			validate: 'number'

			defaultValue: @model.t

			cb: (success, t) =>

				return unless success

				t = parseInt t

				return unless 0 <= t and isFinite t

				@model.setTime t

				@pacs.done()

				@prop._tick()

	_showHandlerModificationOptions: (side) ->

		@rootView.chooser.choose '', [

			'Mirror Other Handler', 'Horizontalize'

			], (success, choice) =>

			return unless success

			if choice is 'Mirror Other Handler'

				@_mirrorOtherHandler side

			else if choice is 'Horizontalize'

				@_horizontalizeHandler side

	_mirrorOtherHandler: (side) ->

		if side is 'left'

			@model.setLeftHandler @model.rightHandler[0], @model.rightHandler[1]

		else

			@model.setRightHandler @model.leftHandler[0], @model.leftHandler[1]

		@model.pacs.done()

	_horizontalizeHandler: (side) ->

		if side is 'left'

			@model.setLeftHandler @model.leftHandler[0], 0

		else

			@model.setRightHandler @model.rightHandler[0], 0

		@model.pacs.done()

	_commitValueAndDeactivate: ->

		@_setValue @valueInput.node.value

		do @_deactivate

		return

	_discardValueAndDeactivate: ->

		@_setValue @_lastValue

		do @_deactivate

		return