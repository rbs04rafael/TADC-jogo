shader_type spatial;

// Controla a força do brilho
uniform float energy = 1.1;

void fragment() {
    // Pega a cor original do modelo (Vertex Color)
    ALBEDO = COLOR.rgb; 
    
    // Faz essa mesma cor emitir luz multiplicada pela energia
    EMISSION = COLOR.rgb * energy; 
}