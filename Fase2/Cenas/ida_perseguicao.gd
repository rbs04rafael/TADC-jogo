extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D):
	if "Rafael" in body.name or "Pomni" in body.name:
		# Destrava o mouse para o jogador clicar no botão
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		# Carrega a tela de fim de fase (a mesma do mundo completo)
		var script_tela = load("res://Codigos/tela_fim_fase.gd")
		if script_tela:
			var tela = script_tela.new()
			# Diz para a tela qual é a próxima fase
			tela.proxima_fase = "res://Cenas/CenaPerseguicao.tscn"
			get_tree().get_root().call_deferred("add_child", tela)
			
		# Pausa o jogo para mostrar a tela
		get_tree().paused = true
