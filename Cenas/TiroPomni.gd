extends Area3D

var speed: float = 30.0
var direction: Vector3 = Vector3(0, 0, -1) # Por padrão, atira pro fundo da tela (-Z)
var life_time: float = 3.0

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Destrói o tiro após alguns segundos para não pesar o jogo
	var timer = get_tree().create_timer(life_time)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float):
	# Move o projétil na direção configurada
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D):
	# Se acertar algum corpo que tenha a função receber_dano (e não for a Pomni)
	if body.has_method("receber_dano") and body.name != "Pomni":
		body.receber_dano(10.0) # Aplica 10 de dano
		queue_free()

func _on_area_entered(area: Area3D):
	# Pode ser que o hitbox do Boss seja um Area3D
	if area.has_method("receber_dano"):
		area.receber_dano(10.0)
		queue_free()
