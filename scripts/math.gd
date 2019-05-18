extends Node

func randfl(minimum, maximum):
	randomize()
	return randf() * (maximum - minimum) + minimum

func rand(minimum, maximum = null):
	randomize()
	if maximum == null:
		maximum = minimum
		minimum = 0
	return floor(randf() * (maximum - minimum + 1)) + minimum

func randOneIn(maximum = 2):
	return rand(0, maximum) == 0

func randOneFrom(items):
	return items[rand(items.size() - 1)]