extends Area3D

var velocidade_y: float = 0.0
@export var gravidade: float = 10
@export var dano: float = 20.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Aplica a gravidade acelerando a queda
	velocidade_y -= gravidade * delta
	global_position.y += velocidade_y * delta
	
	# Faz o Gloink girar malucamente no ar enquanto cai!
	rotate_x(5.0 * delta)
	rotate_z(3.0 * delta)
	rotate_y(2.0 * delta)
	
	# Se ele cair pra baixo do chão (ex: y < -2), ele se destrói para não pesar o jogo
	if global_position.y < -5.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	# Se a hitbox encostar na Pomni
	if body.name == "Pomni" and body.has_method("receber_dano"):
		body.receber_dano(dano, global_position)
		queue_free() # Destrói o Gloink após acertar a Pomni!
