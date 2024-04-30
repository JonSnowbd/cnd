uniform float scale = 7.0;
uniform float smoothness = 0.001;
uniform float seed = 80.0403;
uniform float transitionProgress;

float random(vec2 co)
{
    highp float a = seed;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}


float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners porcentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}
  
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
  vec4 from = Texel(tex, uv);
  vec4 to = vec4(from.r, from.g, from.b, 0.0);
  float n = noise(uv * scale);
  
  float p = mix(-smoothness, 1.0 + smoothness, transitionProgress);
  float lower = p - smoothness;
  float higher = p + smoothness;
  
  float q = smoothstep(lower, higher, n);

  return mix(from, to, 1.0 - q);
}