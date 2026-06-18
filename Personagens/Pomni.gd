extends CharacterBody3D

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
@export var speed: float = 5.0
@export var run_speed: float = 10.0
@export var jump_velocity: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 15

var vida: float = 100.0
var vida_maxima: float = 100.0
var regenerando: bool = true

var coracoes: Array = []
var qtd_coracoes: int = 5

var particulas_passos: CPUParticles3D

var z_inicial
var esta_correndo: bool = false

# Variáveis para controle do tempo no double-tap
var ultimo_click_esquerda: int = 0
var ultimo_click_direita: int = 0
var intervalo_double_tap: int = 300 # Tempo máximo em milissegundos entre os toques

# --- VARIÁVEIS DO CAMINHO ---
var is_on_path: bool = false
var trilho_atual: PathFollow3D = null # Guarda o carrinho que a Pomni está usando no momento

# Gravidade
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- REFERÊNCIAS DE NÓS ---
@onready var animation_player: AnimationPlayer = $Pomni/AnimationPlayer
@onready var visual_model: Node3D = $Pomni

func _ready():
	z_inicial = global_position.z
	
	# Criar Interface de Vida visível via código usando Corações
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(20, 20)
	hbox.add_theme_constant_override("separation", 10)
	canvas.add_child(hbox)
	
	var tex_vazio = load("res://coração sem vida.png")
	var tex_cheio = load("res://coração com vida.png")
	
	for i in range(qtd_coracoes):
		var tpb = TextureProgressBar.new()
		tpb.texture_under = tex_vazio
		tpb.texture_progress = tex_cheio
		tpb.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
		
		# Habilitar redimensionamento da textura (coração grande caber no cantinho da tela)
		tpb.nine_patch_stretch = true
		tpb.custom_minimum_size = Vector2(60, 60)
		
		tpb.max_value = vida_maxima / float(qtd_coracoes)
		tpb.value = tpb.max_value
		
		hbox.add_child(tpb)
		coracoes.append(tpb)

	# --- CRIAR PARTÍCULAS DE PASSOS (Ciano Fluorescente) ---
	particulas_passos = CPUParticles3D.new()
	particulas_passos.emitting = false
	particulas_passos.amount = 8 # Poucas partículas para ser suave
	particulas_passos.lifetime = 1.0
	particulas_passos.mesh = SphereMesh.new()
	particulas_passos.mesh.radius = 0.08
	particulas_passos.mesh.height = 0.16
	
	var mat_part = StandardMaterial3D.new()
	mat_part.albedo_color = Color(0.0, 1.0, 1.0, 0.7) # Ciano transparente
	mat_part.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_part.emission_enabled = true
	mat_part.emission = Color(0.0, 1.0, 1.0)
	mat_part.emission_energy_multiplier = 5.0 # Bem fluorescente e intenso
	particulas_passos.mesh.surface_set_material(0, mat_part)
	
	particulas_passos.direction = Vector3(0, 1, 0)
	particulas_passos.spread = 30.0
	particulas_passos.initial_velocity_min = 0.5
	particulas_passos.initial_velocity_max = 1.5
	particulas_passos.gravity = Vector3(0, 0.8, 0) # Sobem suavemente ao invés de cair
	
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0)) # Somem encolhendo
	particulas_passos.scale_amount_curve = curve
	
	# Posição nos pés da personagem
	particulas_passos.position = Vector3(0, -0.8, 0)
	add_child(particulas_passos)

func _process(delta: float) -> void:
	if regenerando and vida < vida_maxima:
		vida += 3.0 * delta # Recuperação mais lenta (3 de vida por segundo)
		if vida > vida_maxima:
			vida = vida_maxima
			
	# Atualiza a interface dos corações
	if coracoes.size() > 0:
		var vida_por_coracao = vida_maxima / float(qtd_coracoes)
		var vida_restante = vida
		
		for tpb in coracoes:
			if vida_restante >= vida_por_coracao:
				tpb.value = vida_por_coracao
				vida_restante -= vida_por_coracao
			else:
				tpb.value = max(0, vida_restante)
				vida_restante = 0

	# Controle de emissão das partículas de passos
	if particulas_passos != null:
		var andando = abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1
		var no_chao = is_on_floor() or is_on_path
		particulas_passos.emitting = (andando and no_chao)

func _input(event: InputEvent) -> void:
	# Detecta o toque duplo para a direita
	if event.is_action_pressed("move_right"):
		var tempo_atual = Time.get_ticks_msec()
		if tempo_atual - ultimo_click_direita <= intervalo_double_tap:
			esta_correndo = true
		ultimo_click_direita = tempo_atual
		
	# Detecta o toque duplo para a esquerda
	if event.is_action_pressed("move_left"):
		var tempo_atual = Time.get_ticks_msec()
		if tempo_atual - ultimo_click_esquerda <= intervalo_double_tap:
			esta_correndo = true
		ultimo_click_esquerda = tempo_atual

func _physics_process(delta: float) -> void:
	if is_on_path and trilho_atual != null:
		handle_path_movement(delta)
	else:
		apply_gravity(delta)
		handle_jump()
		handle_movement(delta)
		
		# Trava a posição no eixo Z para o formato 2.5D padrão
		velocity.z = 0.0
		global_position.z = z_inicial
		
		move_and_slide()
		
	update_animations()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_jump() -> void:
	if Input.is_action_just_pressed("move_up") and is_on_floor():
			velocity.y = jump_velocity

func handle_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if Input.is_physical_key_pressed(KEY_SHIFT):
		esta_correndo = true
	
	if direction == 0:
		esta_correndo = false
	
	var current_speed = run_speed if esta_correndo else speed
	
	if direction != 0:
		# Aceleração
		velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
		
		# Direção que a Pomni estará virada
		var rotacao_alvo = 0.0
		if direction == 1:
			rotacao_alvo = 0
		if direction == -1:
			rotacao_alvo = PI + 0.7
			
		visual_model.rotation.y = lerp_angle(visual_model.rotation.y, rotacao_alvo, 8 * delta)	
	else:
		# Desaceleração (atrito)
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_path_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if Input.is_physical_key_pressed(KEY_SHIFT):
		esta_correndo = true
	if direction == 0:
		esta_correndo = false
		
	var current_speed = run_speed if esta_correndo else speed
	
	if direction != 0:
		# Empurra o carrinho pelo caminho 3D
		trilho_atual.progress += direction * current_speed * delta
		
		# Verifica se chegou ao final do caminho
		if trilho_atual.progress_ratio >= 1.0:
			sair_do_caminho()
			return
		
		# Rotação visual continua respondendo ao botão apertado
		var rotacao_caminho = trilho_atual.global_rotation.y
		var rotacao_alvo = rotacao_caminho - PI - 1
		
		if direction == -1:
			rotacao_alvo = rotacao_alvo - PI
				
		visual_model.rotation.y = lerp_angle(visual_model.rotation.y, rotacao_alvo, 8 * delta)
	
	global_position = trilho_atual.global_position
	global_position.y += 1.0 
	
	# 2. Mantemos apenas a velocidade falsa no eixo X para a animação tocar
	velocity.x = direction * current_speed
	velocity.y = 0.0
	
func update_animations() -> void:
	if not is_on_floor() and not is_on_path:
		if velocity.y > 0.0:
			if animation_player.current_animation != "Jumping":
				animation_player.play("Jumping", 0.3)
		else:
			if animation_player.current_animation != "Falling":
				animation_player.play("Falling", 0.7)
	elif abs(velocity.x) > 0.1:
		if esta_correndo:
			if animation_player.current_animation != "Walk":
				animation_player.play("Walk", 0.2)
		else:
			if animation_player.current_animation != "Walk":
				animation_player.play("Walk", 0.2)
	else:
		if animation_player.current_animation != "Idle":
			animation_player.play("Idle", 0.3)

# ==========================================
# GATILHOS DE ENTRADA E SAÍDA (API EXTERNA)
# ==========================================
func entrar_no_caminho(carrinho: PathFollow3D) -> void:
	is_on_path = true
	trilho_atual = carrinho
	trilho_atual.loop = false # Garante que o caminho não é infinito
	# Anula as velocidades acumuladas para ela não escorregar
	velocity = Vector3.ZERO 

func sair_do_caminho() -> void:
	is_on_path = false
	trilho_atual = null
	# Atualiza o Z inicial para que ela assuma a nova profundidade onde o trilho terminou
	z_inicial = global_position.z

func receber_dano(quantidade: float) -> void:
	vida -= quantidade
	print("Pomni recebeu dano do morcego! Vida atual: ", int(vida))
	if vida <= 0:
		print("Pomni morreu!")
		get_tree().reload_current_scene()
