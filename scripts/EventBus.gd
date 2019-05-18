#warnings-disable:
extends Node

# EventBus
# Provides a global event handler which connects any dispatched event to any connected listener.

signal dispatch_event

#warning-ignore:return_value_discarded
func _init():
	connect("dispatch_event", self, "_add_event_to_queue")
#	Engine.time_scale = 0.25

var _event_listeners = {}
var _event_queue = []

# Don't process events until everything is ready
var ready = false

# We are going to rely on the physics process, instead
# of the default _process(), because we need to keep our
# event processing in sync with the frame rate. Otherwise,
# the render order of some things could become out of sync
# and cause visual gaffes.
#warning-ignore:unused_argument
func _physics_process(delta):
	if not ready:
		ready = true
	_process_events()

# Add event to the queue
func _add_event_to_queue(event):
	if ready and not event_is_deferred(event):
		callback(event)
	else:
		_event_queue.push_back(event)

func event_is_deferred(event):
	return event.has("defer") and \
		event.defer == true

# Process the event queue
func _process_events():
	for event in _event_queue:
		var i = _event_queue.find(event)
		callback(event)
		_event_queue.remove(i)

# Clear the queue and listeners
func clear():
	_event_queue = []
	_event_listeners = {}

# Listen for an event
func listen(event_name, node, method_name):
	###
	# Should we instead pass in a FuncRef instead of the node and method name?
	###
	if _event_listeners.has(event_name) == false:
		_event_listeners[event_name] = []
	_event_listeners[event_name].push_front({ 'node': node, 'method_name': method_name })

# Remove an event
func remove(event_name, node, method_name):
	var listener = { node: node, method_name: method_name }
	if _event_listeners[event_name].has(listener):
		_event_listeners[event_name].erase(listener)
	
	if _event_listeners[event_name].empty():
		_event_listeners.erase(event_name)

# Dispatch an event
# event_name The name of the event being dispatched.
# data An array of data being passed with the event.
func dispatch(event_name, data = null):
	emit_signal('dispatch_event', { 'name': event_name, 'data': data })

# Invoke an event listener
func callback(event):
	var name = event.name
	var data = event.data
	
	if not _event_listeners.has(name):
		print('Warning: event name not found: ', name)
		return
	
	var listeners = _event_listeners[name]
	for listener in listeners:
		# If the listener has been freed, remove it
		if !weakref(listener.node).get_ref():
			remove(name, weakref(listener.node), listener.method_name)
			continue
		
		var node = listener.node
		# The callback function will have to accept a single argument for data
		# As far as I know, there is no way for Godot to ignore unused arguments,
		# so having a throwaway variable when the data is not needed is
		# unfortunately necessary.
		if data == null:
			node.call(listener.method_name)
		else:
			node.call(listener.method_name, data)