extends Node3D

@export var cena_destino: String = "res://Cenarios/CenarioMundoCompleto/CenarioCircoDigital.tscn"
@export var porta_destino_nome: String = "PortaCima"

var area_teleporte: Area3D

func _ready():
	area_teleporte = find_child("AreaTeleporte", true, false)
	if area_teleporte:
		area_teleporte.body_entered.connect(_on_body_entered)
	else:
		print("ERRO: AreaTeleporte não encontrada em ", name)

func _realizar_teleporte():
	print("Teletransportando para a porta: ", porta_destino_nome)
	# Salva a porta alvo no Singleton
	if has_node("/root/Global"):
		get_node("/root/Global").porta_destino_nome = porta_destino_nome
	get_tree().call_deferred("change_scene_to_file", cena_destino)

func _on_body_entered(body: Node3D):
	if "Pomni" in body.name or body.is_in_group("jogador") or body.has_method("entrar_no_caminho"):
		_realizar_teleporte()

func _physics_process(delta: float) -> void:
	# Fallback garantido: checa constantemente se a Pomni está dentro da exata caixa de colisão do editor
	if area_teleporte:
		var corpos = area_teleporte.get_overlapping_bodies()
		for body in corpos:
			if "Pomni" in body.name or body.is_in_group("jogador") or body.has_method("entrar_no_caminho"):
				_realizar_teleporte()
