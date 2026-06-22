extends Area3D

var atraso_reativacao = 0.0

func _ready():
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	collision_mask = 0xFFFFFFFF

func _process(delta):
	if atraso_reativacao > 0:
		atraso_reativacao -= delta

func _on_body_entered(body: Node3D):
	if atraso_reativacao > 0:
		return
		
	if "Pomni" in body.name or body.is_in_group("jogador") or body.has_method("entrar_no_caminho"):
		var dist_total = global_position.distance_to(body.global_position)
		var diff_z = abs(global_position.z - body.global_position.z)
		
		# A Pomni precisa estar REALMENTE PERTO do gatilho para ser teleportada.
		# Evita bugs de bounding boxes gigantes do Godot.
		if dist_total < 4.0 and diff_z < 2.0:
			
			if "is_climbing" in body and body.is_climbing:
				if body.has_method("sair_da_escada"):
					body.sair_da_escada()
					
			var cena_raiz = get_tree().current_scene
			if not cena_raiz:
				cena_raiz = get_tree().get_root()
				
			var caminho = cena_raiz.find_child("CaminhoParque", true, false)
			var seguidor = null
			
			if caminho:
				for child in caminho.get_children():
					if child is PathFollow3D:
						seguidor = child
						break
				
				if not seguidor:
					seguidor = PathFollow3D.new()
					seguidor.name = "Seguidor"
					caminho.add_child(seguidor)
					
				seguidor.progress_ratio = 0.0
			
			if seguidor:
				if body.has_method("entrar_no_caminho"):
					body.entrar_no_caminho(seguidor)
					atraso_reativacao = 1.0 # 1 segundo de cooldown para evitar loop infinito de entrar e sair
			else:
				print("ERRO CRITICO: CaminhoParque não encontrado!")
