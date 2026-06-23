extends Node3D

var background: TextureRect
var video_player: VideoStreamPlayer
var canvas: CanvasLayer
var label: Label
var audio_player: AudioStreamPlayer
var state: int = 0 # 0: tocando video, 1: tela de inicio com imagem e audio

func _ready():
	canvas = CanvasLayer.new()
	add_child(canvas)
	
	# --- 1. Imagem de fundo (oculta no inicio) ---
	background = TextureRect.new()
	var tex = load("res://Assets/UI/imagem_intro.png")
	if tex:
		background.texture = tex
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.visible = false
		canvas.add_child(background)
	
	# --- 2. Texto de iniciar (oculto no inicio) ---
	label = Label.new()
	label.text = "Aperte qualquer botão para iniciar"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.position.y -= 100 
	
	var style = LabelSettings.new()
	style.font_size = 48
	style.font_color = Color(1.0, 0.9, 0.1) 
	style.outline_size = 12
	style.outline_color = Color(0.8, 0.1, 0.1) 
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.8)
	label.label_settings = style
	label.visible = false
	canvas.add_child(label)
	
	# --- 3. Audio (pronto para tocar) ---
	audio_player = AudioStreamPlayer.new()
	var audio_stream = load("res://Assets/Audio/TemaCortado.mp3")
	if audio_stream:
		audio_player.stream = audio_stream
	audio_player.finished.connect(_on_audio_finished)
	add_child(audio_player)
	
	# --- 4. Video Player (visivel e tocando) ---
	video_player = VideoStreamPlayer.new()
	var stream = load("res://Assets/Video/Intro.ogv")
	
	if stream:
		video_player.stream = stream
		video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
		video_player.expand = true
		video_player.visible = true
		video_player.finished.connect(_on_video_finished)
		canvas.add_child(video_player)
		video_player.play()
	else:
		# Se não carregar o vídeo, pula direto pra tela
		print("AVISO: Não foi possível carregar Intro.ogv. Pulando vídeo...")
		_on_video_finished()

func _process(delta: float) -> void:
	if state == 1 and label != null:
		# Faz o texto piscar/pulsar suavemente
		label.modulate.a = 0.5 + (sin(Time.get_ticks_msec() * 0.005) * 0.5)

func _input(event):
	# No state 0 (video tocando), o input é ignorado, então o jogador não pode pular.
	# No state 1 (tela inicial ativada), o jogador pode apertar para iniciar.
	if state == 1:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			iniciar_jogo()

func _on_video_finished():
	if state == 0:
		state = 1
		
		# Esconde e para o vídeo
		if video_player:
			video_player.visible = false
			video_player.stop()
		
		# Mostra a imagem e o texto
		if background:
			background.visible = true
		if label:
			label.visible = true
		
		# Toca o áudio
		if audio_player and audio_player.stream:
			audio_player.play()

func _on_audio_finished():
	# Faz o áudio rodar em loop
	if state == 1 and audio_player:
		audio_player.play()

func iniciar_jogo():
	get_tree().change_scene_to_file("res://Cenas/CenaMundoCompleto.tscn")
