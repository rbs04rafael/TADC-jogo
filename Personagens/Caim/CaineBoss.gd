extends CharacterBody3D

var hp: float = 500.0
var max_hp: float = 500.0

@onready var visual = $CaimFinalForm

func _ready():
	add_to_group("boss")
	print("Boss Caine spawnou com ", hp, " de vida.")

func receber_dano(quantidade: float):
	hp -= quantidade
	print("Caine recebeu ", quantidade, " de dano! HP restante: ", hp)
	
	# Efeito de piscar vermelho ou sumir rápido para dar feedback de hit
	if visual:
		visual.visible = false
		await get_tree().create_timer(0.05).timeout
		visual.visible = true
		
	if hp <= 0:
		morrer()

func morrer():
	print("Caine Final Form derrotado!")
	# Aqui você pode carregar a cena de zeramento ou animação de morte!
	queue_free()
