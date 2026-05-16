extends CharacterBody3D

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
@export var speed: float = 5.0
@export var jump_velocity: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 15

# Captura a gravidade global configurada no projeto
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- REFERÊNCIAS DE NÓS ---
# Ajuste os caminhos abaixo conforme a estrutura da sua árvore de cena
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visual_model: Node3D = $Pomni/Armature

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	
	# Trava a posição no eixo Z para garantir o formato 2.5D
	velocity.z = 0.0
	global_position.z = 0.0
	
	move_and_slide()
	update_animations()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_jump() -> void:
	# "ui_up" é o padrão da Godot para a seta para cima / espaço
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

func handle_movement(delta: float) -> void:
	# Retorna -1 (esquerda), 1 (direita) ou 0 (parado)
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		# Aceleração suave
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		
		# Gira o modelo visual para olhar para a direção do movimento
		# Usa lerp_angle para uma rotação suave em vez de virar bruscamente
		var target_rotation = atan2(-direction, 0)
		visual_model.rotation.y = lerp_angle(visual_model.rotation.y, target_rotation, 15.0 * delta)
	else:
		# Desaceleração (atrito)
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func update_animations() -> void:
	# Nomes das animações devem ser idênticos aos que estão no seu AnimationPlayer
	if not is_on_floor():
		if animation_player.current_animation != "standing":
			animation_player.play("standing", 0.3)
	#	animation_player.play("jump")
	elif abs(velocity.x) > 0.1:
		if animation_player.current_animation != "walk":
			animation_player.play("walk", 0.2)
	else:
		if animation_player.current_animation != "standing":
			animation_player.play("standing", 0.3)
	#	animation_player.play("idle")
