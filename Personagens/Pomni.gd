extends CharacterBody3D

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
@export var speed: float = 5.0
@export var jump_velocity: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 15

var z_inicial

# Gravidade
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- REFERÊNCIAS DE NÓS ---
@onready var animation_player: AnimationPlayer = $Pomni/AnimationPlayer
@onready var visual_model: Node3D = $Pomni

func _ready():
	z_inicial = global_position.z

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	
	# Trava a posição no eixo Z para garantir o formato 2.5D
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
	
	if direction != 0:
		# Aceleração
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		
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

func update_animations() -> void:
	if not is_on_floor():
		if velocity.y > 0.0:
			if animation_player.current_animation != "Jumping":
				animation_player.play("Jumping", 0.3)
		else:
			if animation_player.current_animation != "Falling":
				animation_player.play("Falling", 0.7)
	elif abs(velocity.x) > 0.1:
		if animation_player.current_animation != "Walk":
			animation_player.play("Walk", 0.2)
	else:
		if animation_player.current_animation != "Idle":
			animation_player.play("Idle", 0.3)
