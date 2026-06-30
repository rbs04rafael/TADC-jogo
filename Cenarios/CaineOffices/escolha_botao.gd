extends Area3D

var label1_3d: Label3D = null
var label2_3d: Label3D = null
var esperando_escolha: bool = false
var esperando_fim: bool = false
var video_player: VideoStreamPlayer = null
var animacao_atual: String = ""
var pomni_ref: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Pomni" and not esperando_escolha:
		mostrar_opcoes(body)

func mostrar_opcoes(pomni: Node3D) -> void:
	esperando_escolha = true
	
	# Desativa a movimentação da Pomni
	pomni.set_physics_process(false)
	pomni.velocity = Vector3.ZERO
	if pomni.get("animation_player"):
		var ap = pomni.animation_player
		
		# Busca segura pela animação de Idle (restaurando caso o nome seja diferente)
		var anim_tocada = false
		var nome_anim_escolhida = ""
		
		if ap.has_animation("Idle"):
			nome_anim_escolhida = "Idle"
			anim_tocada = true
		else:
			for a in ap.get_animation_list():
				if "idle" in a.to_lower():
					nome_anim_escolhida = a
					anim_tocada = true
					break
		
		# Se não achou 'idle', tenta 'parado' ou similar
		if not anim_tocada:
			for a in ap.get_animation_list():
				if "stand" in a.to_lower() or "parado" in a.to_lower():
					nome_anim_escolhida = a
					break
					
		if nome_anim_escolhida != "":
			animacao_atual = nome_anim_escolhida
			pomni_ref = pomni
			
			# Tenta ligar o loop na própria animação (pode falhar se o recurso for read-only do modelo 3D)
			var anim = ap.get_animation(nome_anim_escolhida)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
				
			ap.play(nome_anim_escolhida)
			
			# Conecta o sinal para forçar o loop manualmente caso a animação termine e não tenha loop
			if not ap.animation_finished.is_connected(_on_pomni_animation_finished):
				ap.animation_finished.connect(_on_pomni_animation_finished)
					
	if pomni.get("particulas_passos") and pomni.particulas_passos != null:
		pomni.particulas_passos.emitting = false
	
	# Usamos a Câmera para garantir que "Esquerda" e "Direita" sejam do ponto de vista do jogador
	var dir_frente = Vector3.FORWARD
	var dir_direita = Vector3.RIGHT
	var camera = get_viewport().get_camera_3d()
	
	if camera:
		dir_frente = -camera.global_transform.basis.z.normalized()
		dir_direita = camera.global_transform.basis.x.normalized()
		
	# Posição base: 4 metros à frente (na visão da câmera) e 4 metros de altura
	var pos_base = pomni.global_position + (dir_frente * 4.0) + Vector3(0, 4, 0)
	
	# Carrega a fonte requisitada
	var fonte_custom = load("res://Fase3/Fonte/Super Warming.ttf")
	
	# Cria o número 1 em 3D
	label1_3d = Label3D.new()
	label1_3d.text = "1"
	label1_3d.font = fonte_custom
	label1_3d.font_size = 300 # Aumenta a resolução interna para não ficar pixelado
	label1_3d.pixel_size = 0.005 # Reduz o tamanho físico do pixel para manter o tamanho no mundo
	label1_3d.modulate = Color.RED
	label1_3d.outline_modulate = Color.BLACK
	label1_3d.outline_size = 40
	label1_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label1_3d.no_depth_test = true # Garante que nada vai esconder os números
	add_child(label1_3d)
	# O 1 deve ir para a esquerda da tela (-dir_direita)
	label1_3d.global_position = pos_base - (dir_direita * 2.0)
	
	# Cria o número 2 em 3D
	label2_3d = Label3D.new()
	label2_3d.text = "2"
	label2_3d.font = fonte_custom
	label2_3d.font_size = 300
	label2_3d.pixel_size = 0.005
	label2_3d.modulate = Color.AQUA
	label2_3d.outline_modulate = Color.BLACK
	label2_3d.outline_size = 40
	label2_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label2_3d.no_depth_test = true # Garante que nada vai esconder os números
	add_child(label2_3d)
	# O 2 deve ir para a direita da tela (+dir_direita)
	label2_3d.global_position = pos_base + (dir_direita * 2.0)

func _input(event: InputEvent) -> void:
	if esperando_escolha:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_1 or event.physical_keycode == KEY_KP_1:
				escolher_final(1)
			elif event.physical_keycode == KEY_2 or event.physical_keycode == KEY_KP_2:
				escolher_final(2)
	elif esperando_fim:
		if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
			get_tree().quit()

func escolher_final(opcao: int) -> void:
	esperando_escolha = false
	
	if label1_3d:
		label1_3d.queue_free()
		label1_3d = null
	if label2_3d:
		label2_3d.queue_free()
		label2_3d = null
		
	var caminho_video = ""
	if opcao == 1:
		caminho_video = "res://Fase3/VideosFinais/FinalRuim.ogv"
	else:
		caminho_video = "res://Fase3/VideosFinais/FinalBom.ogv"
		
	var stream = load(caminho_video)
	if stream == null:
		print("ERRO: Vídeo não encontrado no caminho: ", caminho_video)
		return
		
	var canvas_video = CanvasLayer.new()
	canvas_video.layer = 100
	get_tree().get_root().add_child(canvas_video)
	
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_video.add_child(bg)
	
	video_player = VideoStreamPlayer.new()
	video_player.stream = stream
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.volume_db = 0.0
	canvas_video.add_child(video_player)
	
	video_player.play()
	video_player.finished.connect(_on_video_finished)

func _on_video_finished() -> void:
	print("Vídeo finalizado! Mostrando tela final...")
	
	# Cria uma nova camada acima do vídeo
	var canvas_fim = CanvasLayer.new()
	canvas_fim.layer = 105
	get_tree().get_root().add_child(canvas_fim)
	
	# Fundo preto para garantir cobertura
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_fim.add_child(bg)
	
	# Imagem Final
	var textura_final = load("res://Fase3/Imagens/ImagemFinal.jpeg")
	if textura_final:
		var rect_img = TextureRect.new()
		rect_img.texture = textura_final
		rect_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect_img.set_anchors_preset(Control.PRESET_FULL_RECT)
		canvas_fim.add_child(rect_img)
	
	# Texto para sair
	var label_sair = Label.new()
	label_sair.text = "Aperte qualquer botão para sair"
	label_sair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_sair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var fonte_custom = load("res://Fase3/Fonte/Super Warming.ttf")
	if fonte_custom:
		label_sair.add_theme_font_override("font", fonte_custom)
	label_sair.add_theme_font_size_override("font_size", 50)
	label_sair.add_theme_color_override("font_color", Color.WHITE)
	label_sair.add_theme_color_override("font_outline_color", Color.BLACK)
	label_sair.add_theme_constant_override("outline_size", 15)
	
	# Posiciona o texto na parte de baixo
	label_sair.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label_sair.offset_top = -150
	label_sair.offset_bottom = -50
	canvas_fim.add_child(label_sair)
	
	# Toca o Áudio
	var stream_audio = load("res://Assets/Audio/TemaCortado.mp3")
	if stream_audio:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = stream_audio
		audio_player.volume_db = 0.0
		canvas_fim.add_child(audio_player)
		audio_player.play()
		
	# Limpa o player de vídeo se necessário e libera o input de encerramento
	if video_player:
		video_player.queue_free()
		video_player = null
		
	# Espera um tempinho mínimo antes de permitir sair para o jogador não fechar sem querer 
	await get_tree().create_timer(1.5).timeout
	esperando_fim = true

func _on_pomni_animation_finished(anim_name: String) -> void:
	# Força a animação a tocar novamente se ela acabar enquanto a Pomni aguarda a escolha
	if esperando_escolha and anim_name == animacao_atual and pomni_ref:
		if pomni_ref.get("animation_player"):
			pomni_ref.animation_player.play(animacao_atual)
