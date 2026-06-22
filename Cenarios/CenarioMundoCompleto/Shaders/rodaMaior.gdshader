shader_type spatial;

uniform float energy = 1.5;
uniform float speed = 0.5;
uniform float trail_length = 1;
uniform float base_glow_intensity = 0.15;

varying vec3 posicao_local;

void vertex() {
    posicao_local = VERTEX;
}

void fragment() {
    ALBEDO = COLOR.rgb;
    
    float angulo = atan(posicao_local.y, posicao_local.x);
    
    float angulo_normalizado = (angulo + 3.14159) / 6.28318;
    
    float tempo_atual = fract(TIME * speed);
    
    float distancia = mod(tempo_atual - angulo_normalizado, 1.0);
    
    float mascara_luz = 1.0 - smoothstep(0.0, trail_length, distancia);
    
    EMISSION = (COLOR.rgb * base_glow_intensity) + (COLOR.rgb * energy * mascara_luz);
}