extends Node

# TODO: workaround for export problem
export(String) var address = "127.0.0.1"
export(int) var port = 1961

export(String) var ship_name = "Elite Dekkerz"
export(String) var player_name = "vurpo"

export(bool) var retry_connection = true

var connection = StreamPeerTCP.new()
var is_connected = false
var name_ship_set = false

var radar_regex = RegEx.new()

var prompt = "Yuri>"

signal connected
signal disconnected

signal radaritem(item)

func _init():
	radar_regex.compile("(.+): (.+) (.+) (.+)")
	
func _ready():
	connect()

func connect():
	while connection.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		print("DEBUG: connecting to %s:%d" % [address, port])
		connection.connect_to_host(address, port)
		while connection.get_status() == StreamPeerTCP.STATUS_CONNECTING: pass
		if connection.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("DEBUG: not connected")
			emit_signal("disconnected")
			if !retry_connection:
				return
		else:
			is_connected = true
			print("DEBUG: connected")
			emit_signal("connected")
	read_until(prompt) #Read to first prompt
	set_name_and_ship(player_name, ship_name)
	send_command("generator set 1") #full power :^)
	#print(send_command("help"))

func set_name_and_ship(pname, ship):
	if is_connected:
		connection.put_data(("name "+pname+"\n").to_utf8())
		read_until(pname+">")
		connection.put_data(("join "+ship+"\n").to_utf8())
		prompt = "%s@%s>" % [pname, ship]
		read_until(prompt)
		name_ship_set = true

func send_command(cmd):
	if is_connected:
		connection.put_data((cmd+"\n").to_utf8())
		return read_until(prompt)

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
	if is_connected and name_ship_set:
		var response = send_command("radar scan")
		if "Radar is turned off".is_subsequence_of(response):
			send_command("radar on")
			response = send_command("radar scan")
		if response.begins_with("Ok\n"):
			response = response.substr(3, response.length()).strip_edges()
		else:
			return
		var object_strings = response.split("\n")
		var objects = []
		for object_string in object_strings:
			var matches = radar_regex.search(object_string)
			var name = matches.get_string(1)
			var range_ = float(matches.get_string(2))
			var pitch = float(matches.get_string(3))
			var yaw = float(matches.get_string(4))
			
			var pos = Vector3(
				range_*sin(pitch)*cos(yaw),
				range_*cos(pitch),
				range_*cos(pitch)*sin(yaw))
			
			var item = {
				"name":name,
				"relative_position":pos/4000
				}
			
			emit_signal("radaritem", item)