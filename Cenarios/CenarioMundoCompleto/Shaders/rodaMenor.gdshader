shader_type spatial;

uniform float energy = 1.5; // Força do brilho
uniform float velocidade = 6.0; // Rapidez do piscar

void fragment() {
    // 1. Define a cor base puxando do próprio modelo 3D
    ALBEDO = COLOR.rgb; 
    
    // 2. Cria o efeito de piscar (retorna 0 ou 1)
    // Se quiser um piscar suave (pulsar gradativo), remova a palavra "round"
    float piscar = round(abs(sin(TIME * velocidade)));
    
    // 3. Emite a luz multiplicando a cor, a energia e o estado do piscar
    EMISSION = COLOR.rgb * energy * piscar;
}
