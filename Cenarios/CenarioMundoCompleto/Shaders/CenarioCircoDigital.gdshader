shader_type spatial;
render_mode unshaded; // Garante que a escuridão do ambiente (luz 0.0) não afete o objeto!

uniform vec4 cor_principal : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float forca_brilho = 1.5; // Aumentado e renomeado para resetar no inspector

void fragment() {
    // Combina a cor selecionada no painel com a cor original do vértice (Vertex Color)
    vec3 cor_final = cor_principal.rgb * COLOR.rgb;
    
    ALBEDO = cor_final;
    
    // Multiplica a cor pelo brilho para o efeito de "Glow" do WorldEnvironment
    EMISSION = cor_final * forca_brilho; 
}