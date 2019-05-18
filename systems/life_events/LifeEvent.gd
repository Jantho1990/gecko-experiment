extends Control

###
# Onready Properties
###
onready var text_value = $MarginContainer/CenterContainer/VBoxContainer/TextValue
onready var cost_value = $MarginContainer/CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/CostContainer/CostValue
onready var reward_value = $MarginContainer/CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/RewardContainer/RewardValue

export(int) var cost = 200
export(int) var reward = 1000
export(String, MULTILINE) var text = "Your message goes here."

func _ready():
	text_value.text = text
#	cost_value.text = "-" + String(cost)
	cost_value.text = helpers.get_time_string(cost)
	reward_value.text = String(reward)

func _on_Reject_pressed():
	get_parent().reject_life_event()
	EventBus.dispatch("life_event_rejected", {})

func _on_Accept_pressed():
	get_parent().accept_life_event()
	EventBus.dispatch("hurt_player", { "amount": cost })
	EventBus.dispatch("life_event_accepted", {
		
	})
	Score.add(reward)
	get_parent().remove_life_event()

func set_cost(value):
	if sign(value) == 1:
		value = -value
	cost = String(value)