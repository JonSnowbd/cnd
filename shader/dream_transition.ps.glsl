#define DEG2RAD 0.03926990816987241548078304229099 // 1/180*PI

uniform float rotation = 6;
uniform float scale = 1.2;
uniform float transitionProgress = 0.0;
uniform float aspectRatio = 1.0;

vec4 transition(vec2 uv) {

}

vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 px) {
  vec4 visible = Texel(tex, uv);
  vec4 background = vec4(visible.r, visible.g, visible.b, 0.0);

  // Massage parameters
  float phase = transitionProgress < 0.5 ? transitionProgress * 2.0 : (transitionProgress - 0.5) * 2.0;
  float angleOffset = transitionProgress < 0.5 ? mix(0.0, rotation * DEG2RAD, phase) : mix(-rotation * DEG2RAD, 0.0, phase);
  float newScale = transitionProgress < 0.5 ? mix(1.0, scale, phase) : mix(scale, 1.0, phase);
  
  vec2 center = vec2(0, 0);

  // Calculate the source point
  vec2 assumedCenter = vec2(0.5, 0.5);
  vec2 p = (uv.xy - vec2(0.5, 0.5)) / newScale * vec2(ratio, 1.0);

  // This can probably be optimized (with distance())
  float angle = atan(p.y, p.x) + angleOffset;
  float dist = distance(center, p);
  p.x = cos(angle) * dist / ratio + 0.5;
  p.y = sin(angle) * dist + 0.5;
  vec4 c = transitionProgress < 0.5 ? visible : background;

  // Finally, apply the color
  return c + (transitionProgress < 0.5 ? mix(0.0, 1.0, phase) : mix(1.0, 0.0, phase));
}