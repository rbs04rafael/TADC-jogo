extends Area3D

var pomni: CharacterBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pomni = get_tree().get_root().find_child("Pomni", true, false)
	
	body_entered.connect(on_body_entered)

func on_body_entered(body: Node3D):
	if body == pomni:
		# Usa call_deferred para esperar a física terminar de processar a colisão antes de destruir a cena
		get_tree().call_deferred("change_scene_to_file", "res://Cenas/BatalhaFinal.tscn")
