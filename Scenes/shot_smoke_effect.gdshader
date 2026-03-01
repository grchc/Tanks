shader_type canvas_item;

uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Проверяем соседние пиксели — если рядом есть непрозрачный пиксель,
    // но текущий прозрачный — рисуем обводку
    vec2 size = outline_width * TEXTURE_PIXEL_SIZE;

    float alpha_up    = texture(TEXTURE, UV + vec2(0.0,  size.y)).a;
    float alpha_down  = texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    float alpha_left  = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    float alpha_right = texture(TEXTURE, UV + vec2( size.x, 0.0)).a;

    float outline = max(max(alpha_up, alpha_down), max(alpha_left, alpha_right));

    // Если текущий пиксель прозрачный, но рядом есть непрозрачный — рисуем outline
    if (color.a < 0.1 && outline > 0.1) {
        COLOR = vec4(outline_color.rgb, outline_color.a * outline);
    } else {
        COLOR = color;
    }
}