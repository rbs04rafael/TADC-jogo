extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D):
	if "Kayke" in body.name:
		get_tree().change_scene_to_file("res://Fase2/Cenas/CenaLabirinto.tscn")
