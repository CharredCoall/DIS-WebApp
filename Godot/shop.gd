extends Node2D

@onready var shop_button = $ShopButton
@onready var item_list = $ShopButton/ItemList
@onready var money_label = $ShopButton/MoneyLabel
@onready var sfx = $SFXs

var item_to_buy = null

# Called when the node enters the scene tree for the first time.
func _ready():
	money_label.text = "Money: " + str(GameVariables.money) + "g"
	
	for item in GameVariables.store_items:
		item_list.add_item(str(GameVariables.store_items[item][1]) + "g",load(GameVariables.store_items[item][0]))

func _on_item_list_item_clicked(index, at_position, mouse_button_index):
	item_to_buy = index

func _on_buy_button_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	if item_to_buy != null:
		if GameVariables.money >= GameVariables.store_items[item_to_buy][1]:
			$".."._start_request("/buy_hat", HTTPClient.METHOD_PUT, {"user": GameVariables.current_user_id, "hat": item_to_buy})
			if !item_to_buy in GameVariables.items:
				GameVariables.items[item_to_buy] = 0
			GameVariables.items[item_to_buy] += 1
			GameVariables.money -=  GameVariables.store_items[item_to_buy][1]
			print(GameVariables.items)
			
			money_label.text = "Money: " + str(GameVariables.money) + "g"

func _on_shop_button_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	money_label.text = "Money: " + str(GameVariables.money) + "g"
	for child in shop_button.get_children():
		child.visible = !child.visible
	GameVariables.shop_opened = !GameVariables.shop_opened
