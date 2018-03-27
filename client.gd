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
var cargo_list_regex = RegEx.new()

var thread = Thread.new()

signal connected
signal disconnected

signal radaritems(items)
signal cargolabel(text)
signal cargolist(list)
signal membername(name)
signal shipname(name)

func _init():
	radar_regex.compile("(.+): (.+) (.+) (.+)")
	cargo_list_regex.compile("([^\\s]+)[\\s]+([^\\s]+)")
	
func _ready():
	connect()
	thread.start(self, "update_client_thread")

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
	read_until_newline() #Read to first prompt
	send_command("json on")
	set_name_and_ship(player_name, ship_name)
	send_command("generator set 1") #full power :^)

func set_name_and_ship(pname, ship):
	if is_connected:
		send_command("name %s" % pname)
		emit_signal("membername", pname)
		send_command("join %s" % ship)
		emit_signal("shipname", ship)
		name_ship_set = true

func send_command(cmd):
	if is_connected:
		connection.put_data((cmd+"\n").to_utf8())
		return JSON.parse(read_until_newline()).result

func read_until_newline():
	var out_array = PoolByteArray()
	while true:
		var byte = connection.get_u8()
		if byte == 10: #newline
			break
		out_array.append(byte)
	return out_array.get_string_from_utf8()

func update_client_thread(_userdata):
	while true:
		check_cargo()
		radar_scan()
		OS.delay_msec(500)

func radar_scan():
	if is_connected and name_ship_set:
		var response = send_command("radar scan")
		if response["status"] == "Error":
			send_command("radar on")
			response = send_command("radar scan")
		if response["status"] == "Ok":
			response = response["text"]
		else:
			return
		var object_strings = response.split("\n")
		var items = {}
		for object_string in object_strings:
			var matches = radar_regex.search(object_string)
			var name_
			var range_
			var inclination
			var azimuth
			if matches != null and matches.get_group_count() >= 4:
				name_ = matches.get_string(1)
				range_ = float(matches.get_string(2))
				inclination = float(matches.get_string(4))
				azimuth = float(matches.get_string(3))
			else:
				continue
			
			var pos = Vector3(
				range_*sin(deg2rad(inclination))*cos(deg2rad(azimuth)),
				range_*cos(deg2rad(inclination)),
				range_*cos(deg2rad(inclination))*sin(deg2rad(azimuth)))
			
			items[name_] = {
				"relative_position":pos/4000
				}
			
		emit_signal("radaritems", items)

func check_cargo():
	if is_connected and name_ship_set:
		var mass_response = send_command("cargo mass")
		if mass_response["status"] == "Ok":
			emit_signal("cargolabel", mass_response["text"])
		var list_response = send_command("cargo list")
		if list_response["status"] == "Ok":
			list_response = list_response["text"]
		else: return
		var cargo_items = list_response.split("\n")
		cargo_items.remove(0)
		var out = {}
		for item_string in cargo_items:
			var matches = cargo_list_regex.search(item_string)
			var name_
			var quantity
			if matches != null and matches.get_group_count() >= 2:
				name_ = matches.get_string(1)
				quantity = float(matches.get_string(2))
			else:
				continue
			out[name_] = quantity
		emit_signal("cargolist", out)