extends Node

var data = {} setget _private_set,_private_get

func _private_set(_throwaway):
	print("Do not try to manipulate the private data object.")

func _private_get():
	print("Do not try to manipulate the private data object.")

# Set a value in the data store.
func set(key, value):
	match typeof(value):
		_:
			data[key] = value

# Get data from data store.
# If retrieving from a multidimensional dictionary, use "." to get deeper levels.
func get(key):
	# Should we add an event here to say data is being accessed?
	if key.find('.') == -1:
		return data[key]
		
	var keys = key.split('.')
	var ret = data
	for _key in keys:
		if ret.has(_key):
			print("Key not found in global data: ", _key)
			return
		ret = ret[_key]
	# Should we add an event here to say data was retrieved?
	return ret