extends Node


var current_user := ""
var current_user_id := -1 

var visiting = false
var shop_opened = false
var visited_pigeon

var money = 500

var tenants = {} #     {"pigID":{"hole":vector(1,2),"stats":[788,7,9]},"clothing":NULL}
var room_occupancy = {}
var pigeon_state = {}
var pigeonholes = {}

var items = {0: 1, 1: 1,2: 1}

var store_items = {0: ["res://Art/Items/Hat.png", 25], 1: ["res://Art/Items/SunHat.png", 50], 2: ["res://Art/Items/Cowboy.png",150], 3: ["res://Art/Items/Crown.png", 100], 4: ["res://Art/Items/Flower.png", 75], 5: ["res://Art/Items/Tinfoil.png", 25], 6:
	["res://Art/Items/Baret.png", 1], 7: ["res://Art/Items/Cap.png", 2], 8: ["res://Art/Items/ClownHair.png", 3], 9: ["res://Art/Items/DevilHorns.png", 1], 10: ["res://Art/Items/Fedora.png", 10], 11: ["res://Art/Items/GreenHat.png",2], 12: ["res://Art/Items/Luigi.png", 3],
	13: ["res://Art/Items/Mario.png", 3], 14: ["res://Art/Items/PinkHat.png", 1], 15: ["res://Art/Items/Shroom.png", 2], 16: ["res://Art/Items/SillyHat.png", 3], 17: ["res://Art/Items/VikingHat.png", 4], 18: ["res://Art/Items/AnimeHair.png", 1], 19: ["res://Art/Items/Baby.png", 10],
	20: ["res://Art/Items/BunnyEars.png", 3], 21: ["res://Art/Items/Sombrero.png", 5], 22: ["res://Art/Items/FancyHat.png", 50], 23: ["res://Art/Items/FrogHat.png",10]}
var pigeon_clothes = {} #Clothes pigeons are wearing

var pigeon_stats = {} #pigeon ID : [3,4,6]
# {"Pigeon":{"INT":50,"STR":15}}

var pigeon_pool #Pigeons that are availble for other players to adopt. Try making a pigeon fly to hotel

#temporary variables for mini games
var current_score = 0
var current_chance = 0
var current_con = 0
var current_int = 0

#Server variables
var url = "http://127.0.0.1:5000/"
var cookie := ""

var data
