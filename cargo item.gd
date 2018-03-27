extends HBoxContainer

var quantity = 0 setget set_quantity, get_quantity

func _ready():
	pass

func set_name(name_):
	name = name_
	$name.set_text(name)

func set_quantity(quantity_):
	quantity = quantity_
	$quantity.set_text(str(quantity))

func get_quantity(): return quantity	