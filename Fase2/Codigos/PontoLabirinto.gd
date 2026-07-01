extends Area3D
class_name PontoLabirinto

@export_group("Caminhos Disponíveis")
@export var aberto_z_negativo_frente: bool = false
@export var aberto_z_positivo_tras: bool = false
@export var aberto_x_positivo_direita: bool = false
@export var aberto_x_negativo_esquerda: bool = false

func get_direcoes() -> Array:
	var direcoes = []
	
	# Mapeamento do mundo 3D (Eixos X e Z) para vetores 2D (visão de cima)
	if aberto_x_positivo_direita:
		direcoes.append(Vector2(1, 0)) # Direita
	
	if aberto_x_negativo_esquerda:
		direcoes.append(Vector2(-1, 0)) # Esquerda
		
	if aberto_z_positivo_tras:
		direcoes.append(Vector2(0, 1)) # Trás (Sul)
		
	if aberto_z_negativo_frente:
		direcoes.append(Vector2(0, -1)) # Frente (Norte)
		
	return direcoes
