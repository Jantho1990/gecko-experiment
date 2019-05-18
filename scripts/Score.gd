extends Node

var points = 0

func add(value):
	points += value
	EventBus.dispatch("score_updated", { "value": value, "points": points })

func subtract(value):
	points -= value
	EventBus.dispatch("score_updated", { "value": value, "points": points })

func multiply(value):
	points *= value
	EventBus.dispatch("score_updated", { "value": value, "points": points })

func divide(value):
	points /= value
	EventBus.dispatch("score_updated", { "value": value, "points": points })

func set_points(value):
	points = value
	EventBus.dispatch("score_set", { "value": value })

func reset():
	points = 0
	EventBus.dispatch("score_reset")