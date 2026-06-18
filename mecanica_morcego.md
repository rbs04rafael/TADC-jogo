# Sistema do Morcego no Farol

Este documento explica as decisões tomadas para implementar a mecânica onde o morcego acompanha a luz do farol e causa dano à personagem Pomni quando ela é iluminada.

## 1. Localização e Posicionamento do Morcego
Em vez de depender da hierarquia (onde pequenos offsets podem fazer o morcego sair do visual do feixe) ou de instanciar via código, o sistema agora encontra automaticamente o nó do morcego inserido por você na cena (independente de ser filho do Farol, da Luz ou do MainMundoCompleto).
* **Decisão de Posicionamento:** O centro do feixe de luz reflete exatamente no alvo do farol no chão (`alvo_do_farol.global_position`). Portanto, o script agora define a posição global (`global_position`) do morcego para seguir continuamente esse ponto exato do alvo de luz no chão, mantendo-o voando a uma pequena altura (`Vector3(0, 3.5, 0)`). Isso garante que o morcego nunca saia do círculo luminoso visível no cenário, não importa a distância ou escala da câmera.

## 2. Lógica de Dano
A lógica de dano foi inserida no método `_process` do script `eixo_giratório.gd`, pois este já possuía a detecção exata de quando a personagem (Pomni) está iluminada usando vetores e ângulos da luz.
* **Sistema de Vida na Pomni:** Modifiquei o script `Pomni.gd` para incluir uma variável `vida` (inicializada em 100) e um método `receber_dano(quantidade)`. Quando a vida chega a zero, o jogo é reiniciado (`get_tree().reload_current_scene()`).
* **Temporizador de Ataque:** No `eixo_giratório.gd`, criei as variáveis `dano_do_morcego` e `intervalo_dano`. Usando o `delta`, contabilizamos o tempo em `tempo_ultimo_dano`. Se Pomni permanecer na luz, ela toma dano a cada `1.0` segundo.
* **Animação Básica de Ataque:** Enquanto Pomni sofre dano, o morcego usa um `lerp` em sua posição global em direção à Pomni. Quando ela sai da luz, o morcego usa o mesmo processo para voltar à sua posição original (`Vector3(0, 0, -75)`).

Essas decisões tornam o sistema modular e aproveitam a estrutura matemática que já existia para calcular se a Pomni estava dentro do ângulo e direção da luz do farol.
