extends Node

# If you already have an AutoLoad script where you keep track of the player progress, you can just add there the code bellow and edit the 'progress' var in the DialogueSystem.gd file.

#warning-ignore:unused_class_variable
var dialogues = { # Everytime the player talks with an NPC it will be stored here so the system use the "repeat" block (if available) on the next interaction.
#	'question': true # This is here just for demonstration (and debugging) pourposes.
}

#warning-ignore:unused_class_variable
var variables = { # Variables used as conditions to know what dialogue block the player should see next. 
#	var1 = true # This is here just for demonstration (and debugging) pourposes.
	}