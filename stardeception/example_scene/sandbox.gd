extends Node3D

func _on_ready() -> void:
	# create client
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 7050)
	multiplayer.multiplayer_peer = peer
