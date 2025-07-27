extends CanvasLayer

func _on_ready() -> void:
	if OS.has_feature("dedicated_server"):
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(7050, 32)
		multiplayer.multiplayer_peer = peer
		print("server loaded... \\o/")
		multiplayer.peer_connected.connect(_on_player_connected)

func _on_player_connected(id):
	print("player " + str(id) + " connected, wouahou !")

func _on_button_pressed() -> void:
#	TODO Call HTTP request to auth server to authenticate
	get_tree().change_scene_to_file("res://2_main_page/main_page.tscn")
