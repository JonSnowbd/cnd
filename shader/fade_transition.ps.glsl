#pragma language glsl3
uniform float transitionProgress = 0.0;
vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 px) {
  vec4 visible = Texel(tex, uv);
  vec4 background = vec4(visible.r, visible.g, visible.b, 0.0);

  return mix(visible, background, transitionProgress);
}