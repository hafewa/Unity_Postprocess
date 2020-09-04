#ifndef GLITCHUTIL_INCLUDED
#define GLITCHUTIL_INCLUDED

#define NOISE_SIMPLEX_1_DIV_289 0.00346020761245674740484429065744f


float RandomNoise(float2 seed, float speed)
{
	return frac(sin(dot(seed * floor(_Time.y * speed), float2(17.13, 3.71))) * 43758.5453123);
}

float RandomNoise(float seed, float speed)
{
	return RandomNoise(float2(seed, 1.0), speed);
}

float mod289(float x)
{
	return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
}

float3 mod289(float3 x)
{
	return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
}

float3 Permute(float3 x)
{
	return mod289(x * x * 34.0 + x);
}

float3 InvSqrt(float3 r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float Noise(float2 v)
{
	// (3.0-sqrt(3.0))/6.0
	// 0.5*(sqrt(3.0)-1.0)
	// -1.0 + 2.0 * C.x
	// 1.0 / 41.0
	const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439); 
	float2 i = floor(v + dot(v, C.yy));
	float2 x0 = v - i + dot(i, C.xx);

	// Other corners
	float2 i1;
	i1.x = step(x0.y, x0.x);
	i1.y = 1.0 - i1.x;

	// x1 = x0 - i1  + 1.0 * C.xx;
	// x2 = x0 - 1.0 + 2.0 * C.xx;
	float2 x1 = x0 + C.xx - i1;
	float2 x2 = x0 + C.zz;

	// Permutations
	// Avoid truncation effects in permutation
	i = mod289(i);
	float3 p = Permute(Permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
	float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
	m = m * m;
	m = m * m;

	// Gradients: 41 points uniformly over a line, mapped onto a diamond.
	// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
	float3 x = 2.0 * frac(p * C.www) - 1.0;
	float3 h = abs(x) - 0.5;
	float3 ox = floor(x + 0.5);
	float3 a0 = x - ox;

	// Normalise gradients implicitly by scaling m
	m *= InvSqrt(a0 * a0 + h * h);

	// Compute final noise value at P
	float3 g;
	g.x = a0.x * x0.x + h.x * x0.y;
	g.y = a0.y * x1.x + h.y * x1.y;
	g.z = a0.z * x2.x + h.z * x2.y;
	return 130.0 * dot(m, g);
}


#endif
