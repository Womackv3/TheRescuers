extends Node

# Singleton: NetworkManager
# Wraps ENetMultiplayerPeer.

var _peer: ENetMultiplayerPeer
const DEFAULT_PORT: int = 7777

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func host_game() -> void:
    _peer = ENetMultiplayerPeer.new()
    var error = _peer.create_server(DEFAULT_PORT, 4)
    if error != OK:
        printerr("Failed to start server: %d" % error)
        return
        
    multiplayer.multiplayer_peer = _peer
    print("Hosting Game...")

func join_game(ip: String) -> void:
    _peer = ENetMultiplayerPeer.new()
    if ip.is_empty(): ip = "127.0.0.1"
    
    var error = _peer.create_client(ip, DEFAULT_PORT)
    if error != OK:
        printerr("Failed to connect: %d" % error)
        return
        
    multiplayer.multiplayer_peer = _peer
    print("Joining %s..." % ip)

func _on_peer_connected(id: int) -> void:
    print("Peer Connected: %d" % id)

func _on_peer_disconnected(id: int) -> void:
    print("Peer Disconnected: %d" % id)
