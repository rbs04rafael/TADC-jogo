extends Area3D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node3D):
	if "Pomni" in body.name or body.is_in_group("jogador"):
		if body.has_method("entrar_na_escada"):
			body.entrar_na_escada(self)

func _on_body_exited(body: Node3D):
	if "Pomni" in body.name or body.is_in_group("jogador"):
		if body.has_method("sair_da_escada"):
			body.sair_da_escada()
