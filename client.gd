extends Node

# TODO: workaround for export problem
export(String) var address = "localhost"
export(int) var port = 1961

export(String) var ship_name = "Elite Dekkerz"
export(String) var player_name = "vurpo"

var connection = StreamPeerTCP.new()
var is_connected = false

var prompt = "Yuri>"

signal connected
signal disconnected

signal radaritem(item)

func _init():
	pass

func _ready():
	connect()
	for i in range(20):
		var item = {
			"name":"item-%d"%i,
			"relative_position":Vector3(rand_range(-7,7),rand_range(-5,5),rand_range(-7,7))
			};
		emit_signal("radaritem", item)

func connect():
	connection.connect_to_host(address, port)
	while connection.get_status() == StreamPeerTCP.STATUS_CONNECTING: pass
	if connection.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		emit_signal("disconnected")
		return
	else:
		is_connected = true
		emit_signal("connected")
	read_until(prompt) #Read to first prompt
	set_name_and_ship(player_name, ship_name)
	print(send_command("help"))

func set_name_and_ship(pname, ship):
	if is_connected:
		connection.put_utf8_string("name "+pname)
		read_until(pname+">")
		connection.put_utf8_string("join "+ship)
		prompt = "%s@%s>" % [pname, ship]
		read_until(prompt)

func send_command(cmd):
	if is_connected:
		connection.put_utf8_string(cmd)
		connection.put_utf8_string("\n")
		return read_until(prompt, true)

func read_until(delim, include_delim=false): #helper to read from connection until delimiter
	var delim_len = delim.to_utf8().size()
	var out_array = PoolByteArray()
	while true:
		out_array.append(connection.get_u8())
		if out_array.size() >= delim_len && out_array.get_string_from_utf8().ends_with(delim):
			break
	var out = out_array.get_string_from_utf8()
	if not include_delim:
		return out.substr(0, out.length()-delim_len)
	return out

func radar_scan():
	var items = []
	