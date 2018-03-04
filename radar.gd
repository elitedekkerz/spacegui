extends Viewport

var radar_items = {}
var radar_dot = preload("res://radar_dot.tscn")

func _ready():
	#set_process(true)
	pass

func _process(delta):
	pass

func add_radar_item(item):
	var new_item = radar_dot.new()
	new_item.set_item_name(item["name"])
	radar_items[new_item.get_item_name()] = new_item
	$dots.add_child(new_item)