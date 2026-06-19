extends Area3D

var cutscene_ativa = false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node3D):
	if cutscene_ativa:
		return
		
	if "Pomni" in body.name or body.is_in_group("jogador"):
		# Se ela estiver escalando ainda ao tocar no chão, solte a escada!
		if "is_climbing" in body and body.is_climbing:
			if body.has_method("sair_da_escada"):
				body.sair_da_escada()
			
		print("Iniciando cutscene para o parque!")
		cutscene_ativa = true
		
		# Procura o Seguidor globalmente, já que ele pode estar em CaminhoParque ou CaminhoParque2
		var cena_raiz = get_tree().get_root()
		var seguidor = cena_raiz.find_child("Seguidor", true, false)
		
		if seguidor:
			# Chama a função na Pomni para usar esse carrinho (ela já tem `entrar_no_caminho`)
			if body.has_method("entrar_no_caminho"):
				body.entrar_no_caminho(seguidor)
				# Força lanterna ligada (se tiver)
				if body.has_method("equipar_lanterna"):
					body.lanterna_ligada = true
					if body.ref_spotlight:
						body.ref_spotlight.visible = true
			
			# Adiciona uma propriedade para mover automaticamente (via script ou tween)
			var tween = create_tween()
			tween.tween_property(seguidor, "progress_ratio", 1.0, 8.0).set_trans(Tween.TRANS_LINEAR)
			tween.tween_callback(func(): _fim_cutscene(body))

func _fim_cutscene(pomni):
	if pomni.has_method("sair_do_caminho"):
		pomni.sair_do_caminho()
	print("Chegou no Parque de Diversões!")
	queue_free() # Destrói o gatilho
