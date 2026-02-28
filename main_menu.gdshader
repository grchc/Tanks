shader_type canvas_item;
void fragment() {
    float line = mod(floor(FRAGCOORD.y / 2.0), 2.0);
    COLOR = vec4(0.0, 0.0, 0.0, line * 0.18);
}