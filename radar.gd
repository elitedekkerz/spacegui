extends Viewport

var radar_items = {}
var radar_dot = preload("res://radar_dot.tscn")

var free_rotate = false
const default_rotate = Vector2(0, -0.523)

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	if !free_rotate:
		$"camera pivot".rotation.y = lerp($"camera pivot".rotation.y, default_rotate.x, 6*delta)
		$"camera pivot".rotation.x = lerp($"camera pivot".rotation.x, default_rotate.y, 6*delta)

func set_radar_item(item, name_):
	var new_item
	if radar_items.has(name_):
		new_item = radar_items[name_]
	else:
		new_item = radar_dot.instance()
		new_item.set_item_name(name_)
		radar_items[name_] = new_item
		$dots.add_child(new_item)
	new_item.translation = item["relative_position"]

func remove_radar_item(name_):
	radar_items[name_].queue_free()
	radar_items.erase(name_)

func update_radar_items(items):
	for item in radar_items.keys():
		if not item in items.keys():
			remove_radar_item(item)
	
	for item in items:
		set_radar_item(items[item], item)
	
func radar_rotate(vec):
	free_rotate = true
	$"camera pivot".rotation.y -= vec.x
	$"camera pivot".rotation.y = wrap($"camera pivot".rotation.y, -PI, PI)
	$"camera pivot".rotation.x = clamp($"camera pivot".rotation.x-vec.y, -PI/2, PI/2)

func return_rotate():
	free_rotate = false
	

func wrapMax(x, max_):
    return fmod(max_ + fmod(x, max_), max_)

func wrap(x, min_, max_):
    return min_ + wrapMax(x - min_, max_ - min_)