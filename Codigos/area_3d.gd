extends Area3D

@onready var meu_carrinho = $"../PathFollow3D"

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("entrar_no_caminho"):
		body.entrar_no_caminho(meu_carrinho)
