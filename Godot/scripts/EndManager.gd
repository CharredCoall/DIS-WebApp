extends Node

@onready var announce_label = $AnnounceLabel
@onready var score_label = $ScoreLabel
@onready var level_up_label = $LevelUpLabel
@onready var levels_label = $LevelsLabel
@onready var goober = $Goober/AnimatedGoober

var score:int
var con:int
var chance:int

func set_score(new_score):
	score = new_score
	score_label.text = str(score)

func level_up(oldcon:int, intelligence:int):
	con = round(oldcon + (float(intelligence)/20.)*score**0.25)

func display_stuff(oldcon:int):
	announce_label.text = "Times Up!"
	score_label.text = str(score) + " Points!"
	level_up_label.text = "Leveled up!"
	levels_label.text = "Con: " + str(oldcon) + "+" + str(con-oldcon)
	goober.play("Munch")

func _on_go_back_to_menu_pressed():
	print("Go Back to the Menu")
