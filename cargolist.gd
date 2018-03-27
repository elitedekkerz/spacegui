extends VBoxContainer

var cargo = {}

var item_preload = preload("res://cargo item.tscn")

func _ready():
	pass

func update_list(items_):
	cargo = items_
	for child in get_children():
		if child.get_name() in cargo:
			child.set_quantity(cargo[child.get_name()])
		else:
			child.queue_free()
	var list_names = []
	for child in get_children(): list_names.append(child.get_name())
	for item in cargo:
		if not item in list_names:
			var new_item = item_preload.instance()
			new_item.set_name(item)
			new_item.set_quantity(cargo[item])
			add_child(new_item)