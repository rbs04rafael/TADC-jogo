extends Node3D

var background: TextureRect
var video_player: VideoStreamPlayer
var canvas: CanvasLayer
var label: Label
var state: int = 0 # 0: scene, 1: video

func _ready():
	canvas = CanvasLayer.new()
	add_child(canvas)
	
	# 1. Carregar a imagem de fundo em tela cheia (imagem_intro.png)
	background = TextureRect.new()
	var tex = load("res://imagem_intro.png")
	if tex:
		background.texture = tex
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		# Configura para esticar ignorando o tamanho real, mas cobrindo toda a tela
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		canvas.add_child(background)
	
	# 2. Configurar o texto (pressione qualquer tecla)
	label = Label.new()
	label.text = "Aperte qualquer tecla para continuar"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.position.y -= 100 # Sobe um pouco do limite inferior
	
	var style = LabelSettings.new()
	style.font_size = 48
	style.font_color = Color(1.0, 0.9, 0.1) # Amarelo vibrante
	style.outline_size = 12
	style.outline_color = Color(0.8, 0.1, 0.1) # Vermelho neon
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.8)
	label.label_settings = style
	
	canvas.add_child(label)
	
	# 3. Preparar o player de vídeo OGV
	video_player = VideoStreamPlayer.new()
	var stream = load("res://video_tela_inicial.ogv")
	video_player.stream = stream
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true # Estica para caber na tela
	video_player.visible = false
	video_player.finished.connect(_on_video_finished)
	canvas.add_child(video_player)

func _process(delta: float) -> void:
	if state == 0 and label != null:
		# Faz o texto piscar/pulsar suavemente
		label.modulate.a = 0.5 + (sin(Time.get_ticks_msec() * 0.005) * 0.5)

func _input(event):
	if state == 0:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			iniciar_video()

func iniciar_video():
	if state == 0:
		state = 1
		label.visible = false
		if background:
			background.visible = false
		
		# Define um fundo preto por trás do vídeo
		var color_rect = ColorRect.new()
		color_rect.color = Color(0, 0, 0)
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		canvas.add_child(color_rect)
		canvas.move_child(color_rect, 0)
		
		video_player.visible = true
		video_player.play()

func _on_video_finished():
	# Quando o vídeo acabar, inicia o jogo automaticamente
	get_tree().change_scene_to_file("res://Cenas/CenaMundoCompleto.tscn")
