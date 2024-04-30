#pragma language glsl3
uniform float sharpness = 2.0;

float sharpen(float pix_coord) {
    float norm = (fract(pix_coord) - 0.5) * 2.0;
    float norm2 = norm * norm;
    return floor(pix_coord) + norm * pow(norm2, sharpness) / 2.0 + 0.5;
}

vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 screenuv)
{
    vec2 vres = textureSize(tex, 0);
    return texture(tex, vec2(
        sharpen(uv.x * vres.x) / vres.x,
        sharpen(uv.y * vres.y) / vres.y
    ));
}