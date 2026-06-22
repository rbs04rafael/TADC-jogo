extends Node

var concluido = false
var tempo_checagem = 1.0

func _process(delta):
	if concluido:
		return
		
	tempo_checagem -= delta
	if tempo_checagem <= 0:
		tempo_checagem = 1.0
		_checar_inimigos()

func _checar_inimigos():
	var grupo = get_tree().get_root().find_child("Abstracoes", true, false)
	if grupo:
		if grupo.get_child_count() == 0:
			concluido = true
			_finalizar_fase()

func _finalizar_fase():
	print("Todas as abstrações foram derrotadas!")
	# O usuário solicitou a remoção do caminho de bolas brilhantes.
	print("Fase 1 finalizada (Pronto pra transição da Fase 2).")
