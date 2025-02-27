#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform float u_Time;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Col;
out vec4 fs_Pos;
out float fs_Displacement;


const int p[] = int[](
    151,160,137,91,90,15,
    131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
    190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
    88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
    77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
    102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
    135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
    5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
    223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
    129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
    49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,151
);

vec3 fade(vec3 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float grad(int hash, float x, float y, float z) {
    int h = hash & 15;
    float u = h < 8 ? x : y;
    float v = h < 4 ? y : (h == 12 || h == 14 ? x : z);
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

float perlin(vec3 pos) {
    vec3 v1 = floor(pos);
    vec3 v2 = fract(pos);
    
    int X = int(mod(v1.x, 256.0));
    int Y = int(mod(v1.y, 256.0));
    int Z = int(mod(v1.z, 256.0));
    vec3 faded = fade(v2);
    
    int A  = int(mod(float(p[X]) + float(Y), 256.));
    int B  = int(mod(float(p[X+1]) + float(Y), 256.));
    int AA = int(mod(float(p[A]) + float(Z), 256.));
    int BA = int(mod(float(p[B]) + float(Z), 256.));
    int AB = int(mod(float(p[A+1]) + float(Z), 256.));
    int BB = int(mod(float(p[B+1]) + float(Z), 256.));

    float a = mix(grad(p[AA  ], v2.x, v2.y   , v2.z  ), grad(p[BA  ], v2.x-1.0, v2.y   , v2.z  ), faded.x);
    float b = mix(grad(p[AB  ], v2.x, v2.y-1.0, v2.z  ), grad(p[BB  ], v2.x-1.0, v2.y-1.0, v2.z  ), faded.x);
    float c = mix(grad(p[AA+1], v2.x, v2.y   , v2.z-1.0), grad(p[BA+1], v2.x-1.0, v2.y   , v2.z-1.0), faded.x);
    float d = mix(grad(p[AB+1], v2.x, v2.y-1.0, v2.z-1.0), grad(p[BB+1], v2.x-1.0, v2.y-1.0, v2.z-1.0), faded.x);
    
    float e = mix(a, b, faded.y);
    float f = mix(c, d, faded.y);

    float result = mix(e, f, faded.z);
    return result;
}



float OctavePerlin(vec3 position, int octaves, float persistence) {
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;
    float maxValue = 0.0;
    
    for(int i = 0; i < octaves; i++) {
        total += perlin(position * frequency) * amplitude;
        maxValue += amplitude;
        
        amplitude *= persistence;
        frequency *= 2.0;
    }
    
    return total / maxValue;
}

float triangleWave(float x) {
    return 2.0 * abs(2.0 * fract(x) - 1.0) - 1.0;
}

float bias(float b, float t) {
    return pow(t, log(b) / log(0.5));
}

float gain(float g, float t) {
    return t < 0.5 ? bias(1.0 - g, 2.0 * t) / 2.0 : 1.0 - bias(1.0 - g, 2.0 - 2.0 * t) / 2.0;
}

const vec4 lightPos = vec4(5, 5, 3, 1);
const float baseFrequency = 0.2;
const float baseAmplitude = 0.5;
const float fractalFrequency = 3.5;
const float fractalAmplitude = 0.2;

float baseWaveFunction(float x, float y, float z) {
    return triangleWave(baseFrequency * (x + u_Time))
         * triangleWave(baseFrequency * (y + u_Time))
         * triangleWave(baseFrequency * (z + u_Time));
         
}


float fractalWaveFunction(float x, float y, float z) { //higher-frequency, lower-amplitude
    return sin(fractalFrequency * (x + u_Time))
         * sin(fractalFrequency * (y + u_Time))
         * sin(fractalFrequency * (z + u_Time));
}

float verticalMotion(float y) {
    return y * 0.1 * sin(u_Time);
}

float directionalDisplacementBoost(vec3 normal, vec3 position) {
    float boostFromNormal = max(normal.y, 0.0);
    float boostFromNoise = OctavePerlin(position * 0.9 + vec3(u_Time, u_Time, u_Time), 2, 0.5) * 0.1;
    return gain(0.5, 1.0 + 2.0 * (boostFromNormal + boostFromNoise));
}


float dynamicFlameShape(float x, float y) {
    return x * (1.0 + 0.05 * sin(u_Time + y * 5.0));
}


void main() {
    float base = baseAmplitude * baseWaveFunction(vs_Pos.x, vs_Pos.y, vs_Pos.z);
    float fractal = fractalAmplitude * fractalWaveFunction(vs_Pos.x, vs_Pos.y, vs_Pos.z);
    float vertical = verticalMotion(vs_Pos.y);
    fs_Displacement = (base + fractal + vertical) * directionalDisplacementBoost(vs_Nor.xyz, vs_Pos.xyz);

    vec4 modifiedPos = vs_Pos + vs_Nor * fs_Displacement;
    modifiedPos.x = dynamicFlameShape(modifiedPos.x, vs_Pos.y);

    fs_Col = vs_Col;
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);
    fs_Pos = u_Model * modifiedPos;
    fs_LightVec = lightPos - fs_Pos;
    gl_Position = u_ViewProj * fs_Pos;
}