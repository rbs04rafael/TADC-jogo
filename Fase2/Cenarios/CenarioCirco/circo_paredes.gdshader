shader_type spatial;

// Cores
uniform vec3 cor_amarela : source_color = vec3(1.0, 0.9, 0.0);
uniform vec3 cor_vermelha : source_color = vec3(1.0, 0.1, 0.1);

// Configurações
uniform float largura_listras = 5.0; // Valores maiores = listras mais grossas

varying vec3 posicao_local;

void vertex() {
	posicao_local = VERTEX;
}

void fragment() {
	// Calcula a posição para fazer listras retas
	float valor_posicao = (posicao_local.x + posicao_local.z) / (largura_listras * 0.1);
	
	// Usa mod(..., 2.0) para alternar entre apenas DUAS cores
	float padrao = mod(valor_posicao, 2.0);
	
	vec3 cor_final;
	if (padrao < 1.0) {
		cor_final = cor_amarela;
	} else {
		cor_final = cor_vermelha;
	}
	
	ALBEDO = cor_final;
	
	// Parede fosca, sem brilho fluorescente
	ROUGHNESS = 0.85;
}
