extends Area3D

@onready var meu_carrinho = $"../PathFollow3D"

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("entrar_no_caminho"):
		var dist_total = global_position.distance_to(body.global_position)
		var diff_z = abs(global_position.z - body.global_position.z)
		
		# A Pomni precisa estar REALMENTE PERTO do gatilho para ser teleportada.
		# Isso impede o Godot de ativar o trigger de muito longe (devido a bounding boxes invisíveis).
		if dist_total < 3.0 and diff_z < 2.0:
			body.entrar_no_caminho(meu_carrinho)
		else:
			print("Bug de física ignorado! Pomni tentou entrar mas estava a ", dist_total, "m de distância (Z dist: ", diff_z, ")")
