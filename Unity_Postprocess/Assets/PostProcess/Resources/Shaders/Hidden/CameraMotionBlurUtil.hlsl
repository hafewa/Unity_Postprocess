#ifndef CAMERAMOTIONBLURUTIL_INCLUDED
#define CAMERAMOTIONBLURUTIL_INCLUDED

static const int SmallDiscKernelSamples = 12;
static const float2 SmallDiscKernel[SmallDiscKernelSamples] = {
	float2(-0.326212,-0.40581),
	float2(-0.840144,-0.07358),
	float2(-0.695914,0.457137),
	float2(-0.203345,0.620716),
	float2(0.96234,-0.194983),
	float2(0.473434,-0.480026),
	float2(0.519456,0.767022),
	float2(0.185461,-0.893124),
	float2(0.507431,0.064425),
	float2(0.89642,0.412458),
	float2(-0.32194,-0.932615),
	float2(-0.791559,-0.59771)
};


float _SoftZDistance;
float _MaxRadiusOrKInPaper;

// combined
float4x4 _ToPrevViewProjCombined;

sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _VelTex; float4 _VelTex_ST;
sampler2D _NeighbourMaxTex; float4 _NeighbourMaxTex_ST;
sampler2D _NoiseTex; float4 _NoiseTex_ST;
sampler2D _CameraDepthTexture;

float4 _MainTex_TexelSize;
float4 _CameraDepthTexture_TexelSize;
float4 _VelTex_TexelSize;

half _Jitter, _VelocityScale, _DisplayVelocityScale;
half _MaxVelocity, _MinVelocity;

struct VSInput
{
	float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct PSInput
{
	float4 pos : SV_POSITION;
	float2 uv  : TEXCOORD0;
};

PSInput VSMain(VSInput v)
{
	PSInput o = (PSInput)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	return o;
}


float2 VectorMax(float2 a, float2 b)
{
	float ma = dot(a, a);
	float mb = dot(b, b);
	return (ma > mb) ? a : b;
}

float Cone(float2 px, float2 py, float2 v)
{
	return saturate(1.0 - (length(px - py) / length(v)));
}

float Cylinder(float2 x, float2 y, float2 v)
{
	float lv = length(v);
	return 1.0 - smoothstep(0.95 * lv, 1.05 * lv, length(x - y));
}

float SoftDepthCompare(float za, float zb)
{
	return saturate(1.0 - (za - zb) / _SoftZDistance);
}

#endif
