extends Node

var visiting = false
var shop_opened = false
var visited_pigeon

var money = 500

var tenants = {}
var room_occupancy = {}
var pigeon_state = {}

var items = ["res://Art/Items/Hat.png", "res://Art/Items/SunHat.png", "res://Art/Items/Cowboy.png"]

var store_items = {"res://Art/Items/Hat.png":25, "res://Art/Items/SunHat.png":50, "res://Art/Items/Cowboy.png":150,"res://Art/Items/Crown.png":100,"res://Art/Items/Flower.png":75,"res://Art/Items/Tinfoil.png":25,
	"res://Art/Items/Baret.png":1, "res://Art/Items/Cap.png":2, "res://Art/Items/ClownHair.png":3,"res://Art/Items/DevilHorns.png":1, "res://Art/Items/Fedora.png":10, "res://Art/Items/GreenHat.png":2, "res://Art/Items/Luigi.png":3,
	"res://Art/Items/Mario.png":3, "res://Art/Items/PinkHat.png":1, "res://Art/Items/Shroom.png":2, "res://Art/Items/SillyHat.png":3, "res://Art/Items/VikingHat.png":4, "res://Art/Items/AnimeHair.png":1, "res://Art/Items/Baby.png":10,
	"res://Art/Items/BunnyEars.png":3, "res://Art/Items/Sombrero.png":5, "res://Art/Items/FancyHat.png":50, "res://Art/Items/FrogHat.png":10}
var pigeon_clothes = {} #Clothes pigeons are wearing

# {"Pigeon":{"INT":50,"STR":15}}

var pigeon_pool #Pigeons that are availble for other players to adopt. Try making a pigeon fly to hotel

