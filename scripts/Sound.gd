extends Node

const MIN_VOLUME = 0.00
const MAX_VOLUME = 1.00

const MIN_DB = -80

const channels = [
	"Master",
	"Music",
	"Dialogue",
	"SFX"
]

# Audio buses
var audio_buses = {}

# Overall sound
var master = 1.00 setget _set_private

# Music
var music = 1.00 setget _set_private

# Dialogue
var dialogue = 1.00 setget _set_private

# Sound Effects
var sfx = 1.00 setget _set_private

###
# METHODS
###

func _ready():
	print(AudioServer.get_device_list())
	for channel in channels:
		var audio_bus = AudioBus.new()
		var bus = AudioServer.get_bus_index(channel)
		audio_bus.max_db = AudioServer.get_bus_volume_db(bus)
		audio_bus.min_db = MIN_DB
		audio_buses[channel] = audio_bus

func _set_private(_throwaway_):
	print("Private variable")

# Validate channel exists.
func _channel_exists(channel):
	return channels.has(channel)

# Set the volume of a specific channel.
func _set_channel_volume(channel, value):
	# Have to do it like this, set() triggers the private setget
#	match channel:
#		"master":
#			master = value
#		"dialogue":
#			dialogue = value
#		"music":
#			music = value
#		"sfx":
#			sfx = value
	var audio_bus = audio_buses[channel]
	var volume_range = audio_bus.max_db - audio_bus.min_db
	var new_volume = (value * volume_range) + (audio_bus.min_db + audio_bus.max_db)
	print("new_volume ", new_volume, " on ", AudioServer.get_bus_index(channel))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(channel), new_volume)
	print(channel, " volume: ", AudioServer.get_bus_volume_db(AudioServer.get_bus_index(channel)))
	
#	EventBus.dispatch("sound_updated", { "channel": channel, "value": value })

# Validate value is an acceptable volume.
func _value_allowed(value):
	if value < MIN_VOLUME or value > MAX_VOLUME:
		return false
	return true

# Set volume, preventing values from falling outside bounds.
func set_volume(channel, value):
	print("SET VOLUME", channel, value)
	if _channel_exists(channel) and _value_allowed(value):
		_set_channel_volume(channel, value)

# Add a volume level to channel.
func add_volume(channel, value):
	var new_volume = get(channel) + value
	
	if not _value_allowed(new_volume):
		new_volume = MAX_VOLUME
	
	_set_channel_volume(channel, new_volume)

# Subtract a volume level to channel.
func decrease(channel, value):
	var new_volume = get(channel) - value
	
	if not _value_allowed(new_volume):
		new_volume = MIN_VOLUME
	
	_set_channel_volume(channel, new_volume)

class AudioBus:
	var max_db
	var min_db