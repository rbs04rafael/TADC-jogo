extends Area3D

@onready var carrinho = $"../PathFollow3D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(on_body_entered)


func on_body_entered(body: Node3D) -> void:
	if body.has_method("entrar_no_caminho"):
		body.entrar_no_caminho(carrinho)
