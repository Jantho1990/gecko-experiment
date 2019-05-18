extends Node

###
# Various helper functions
###

# Filter an array by a funcref.
func array_filter(arr, function):
	var ret = []
	for ent in arr:
		if function.call_func(ent) == true:
			ret.push_back(ent)
	return ret

# Find an array item by a funcref
func array_find(arr, function):
	for ent in arr:
		if function.call_func(ent) == true:
			return ent
	return null

func get_months(value): # convert to months
	return value / 10

func get_years(value): # convert to years
	return value / 120

func get_time_string(value): # get the time cost in a string
	var time = get_months(value)
	if time > 11:
		time = get_years(value)
		if time == 1:
			return String(time) + " year"
		else:
			return String(time) + " years"
	else:
		if time == 1:
			return String(time) + " month"
		else:
			return String(time) + " months"