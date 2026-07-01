extends CanvasLayer

var proxima_fase: String = "res://Fase2.1/Cenas/Fase2.1.tscn"

func _ready():
	# Faz a UI rodar mesmo quando a árvore estiver pausada
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Camada para ficar acima de tudo
	layer = 100
	
	var texture_rect = TextureRect.new()
	texture_rect.texture = load("res://Fase1/Congratulations.png")
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(texture_rect)
	
	# Botão de Próxima Fase
	var btn = Button.new()
	btn.text = ""
	btn.flat = true # Botão invisível, usando o visual da imagem de fundo
	
	# Tamanho da área clicável
	btn.custom_minimum_size = Vector2(500, 120)
	
	# Ancorar embaixo no centro
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	
	# Ajustar a posição (o x é negativo porque o centro é 0,0 do botão se ancorado no centro)
	# Se a âncora é CENTER_BOTTOM, a posição x é -largura/2, y é -altura - offset.
	btn.position = Vector2(-250, -180)
	
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_btn_pressed)
	add_child(btn)

func _on_btn_pressed():
	# Retorna o mouse para o modo capturado (oculto) para a próxima fase
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	get_tree().change_scene_to_file(proxima_fase)
	queue_free()
