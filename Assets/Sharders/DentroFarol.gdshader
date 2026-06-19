shader_type spatial;
render_mode cull_disabled;

uniform vec3 cor_escura : source_color = vec3(0.1, 0.1, 0.15); // Preto / Azul bem escuro
uniform vec3 cor_clara : source_color = vec3(0.9, 0.9, 0.9);   // Branco / Creme
uniform float tamanho_dos_quadrados = 12.0;

varying vec3 world_pos;

void vertex() {
	// Calcula a posição global no mundo para que a textura seja contínua em múltiplos objetos
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// 1. Multiplica a posição global XZ pelo tamanho para criar os blocos (fator ajustado para deixar os quadrados bem maiores)
	vec2 grid = floor(world_pos.xz * (tamanho_dos_quadrados * 0.05));
	
	// 2. Lógica booleana de par ou ímpar (módulo de 2) para intercalar os quadrados
	float xadrez = mod(grid.x + grid.y, 2.0);
	
	// 3. Mistura a cor 1 e a cor 2 baseada no resultado da matriz
	ALBEDO = mix(cor_escura, cor_clara, xadrez);
	
	// Físicas de brinquedo
	ROUGHNESS = 0.2;
}