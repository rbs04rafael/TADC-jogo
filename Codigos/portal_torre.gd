extends Area3D

@export var cena_destino: String = "res://Cenas/DentroFarol.tscn"

# Fallback cego: garante a transição caso o motor de física falhe em disparar body_entered
func _physics_process(delta: float) -> void:
	var pomni = get_tree().get_root().find_child("Pomni", true, false)
	if pomni != null:
		# Compara apenas a distância horizontal (X e Z), ignorando a diferença de altura (Y)
		var pos_portal_2d = Vector2(global_position.x, global_position.z)
		var pos_pomni_2d = Vector2(pomni.global_position.x, pomni.global_position.z)
		
		if pos_portal_2d.distance_to(pos_pomni_2d) < 1.4:
			print("Distância horizontal atingida! Teletransportando Pomni...")
			get_tree().change_scene_to_file(cena_destino)

func _on_body_entered(body: Node3D) -> void:
	# O terminal vai escrever o nome do que quer que toque na área
	print("Objeto detectado na porta: ", body.name)
	
	# Filtro blindado: só funciona se for a Pomni
	if "Pomni" in body.name or body.has_method("entrar_no_caminho"):
		get_tree().change_scene_to_file(cena_destino)
