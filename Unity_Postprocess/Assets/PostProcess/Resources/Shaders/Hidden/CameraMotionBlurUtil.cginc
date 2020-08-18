#ifndef CAMERAMOTIONBLURUTIL_INCLUDED
#define CAMERAMOTIONBLURUTIL_INCLUDED

float _SoftZDistance;

struct v2f
{
	float4 pos : SV_POSITION;
	float2 uv  : TEXCOORD0;
};

v2f vert(appdata_img v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
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
	return clamp(1.0 - (length(px - py) / length(v)), 0.0, 1.0);
}

float Cylinder(float2 x, float2 y, float2 v)
{
	float lv = length(v);
	return 1.0 - smoothstep(0.95*lv, 1.05*lv, length(x - y));
}

float SoftDepthCompare(float za, float zb)
{
	return clamp(1.0 - (za - zb) / _SoftZDistance, 0.0, 1.0);
}

#endif