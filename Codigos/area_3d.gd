extends Area3D

@onready var meu_carrinho = $"../PathFollow3D"

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("entrar_no_caminho"):
		# Previne que colisões distorcidas ou gigantes (bug no mapa) ativem o caminho se a Pomni estiver longe
		if global_position.distance_to(body.global_position) < 8.0:
			body.entrar_no_caminho(meu_carrinho)
			print("POMNI ENTROU")
		else:
			print("Pomni tocou no caminho mas estava muito longe! Ignorando teleport.")
