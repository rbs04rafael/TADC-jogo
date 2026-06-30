shader_type sky;
	void sky() {
		vec3 dir = EYEDIR;
		float noise = fract(sin(dot(dir, vec3(12.9898, 78.233, 45.5432))) * 43758.5453);
		// Ajuste para quantidade de estrelas
		float star = step(0.993, noise);
		
		// Efeito de piscar baseado no tempo
		float pulse = (sin(TIME * 2.0 + noise * 100.0) + 1.0) * 0.5;
		star *= pulse;
		
		// Cor do fundo do espaço
		vec3 bg = vec3(0.01, 0.0, 0.04); 
		
		COLOR = bg + vec3(star) * vec3(0.8, 0.9, 1.0);
	}