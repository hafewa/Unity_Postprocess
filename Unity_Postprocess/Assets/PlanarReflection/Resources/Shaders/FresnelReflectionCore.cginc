#ifndef FRESNEL_REFLECTION_CORE_INCLUDED
#define FRESNEL_REFLECTION_CORE_INCLUDED

#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityShaderUtilities.cginc"
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _SubTex; float4 _SubTex_ST;
sampler2D _ReflectionTex; float4 _ReflectionTex_ST;
fixed4 _Color;
fixed4 _EnvironmentColor;
half _Flesnel, _Glossiness, _Metallic, _BlendWeight;


struct VSInput
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
};

struct VSOutput
{
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
	float4 projCoord : TEXCOORD1;
	float vdotn : TEXCOORD2;
};

VSOutput VSMain(VSInput v)
{
	VSOutput o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	o.projCoord = ComputeScreenPos(o.vertex);
	float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
	o.vdotn = dot(viewDir, v.normal.xyz);
	return o;
}

fixed4 PSMain(VSOutput i) : SV_Target
{
	fixed4 baseColor = tex2D(_MainTex, i.uv);

#ifdef _REFLECT_ENABLE
	fixed4 col = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.projCoord));
	col.a = saturate(_Flesnel + (1 - _Flesnel) * pow(1 - i.vdotn, 5));
	col *= baseColor;
	return col;
#elif _REFLECT_DISABLE
	return baseColor;
#endif
}


#endif // FRESNEL_REFLECTION_CORE_INCLUDED
