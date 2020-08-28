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
fixed4 _Color, _EnvironmentColor;
half _BlendWeight;
half _Glossiness, _Metallic, _IndirectDiffRefl, _Roughness;


struct Input
{
	float2 uv_MainTex;
	float4 projCoord;
	float4 color;
};

struct PSInput
{
	UNITY_POSITION(pos);
	float2 uv : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float4 lightMap : TEXCOORD2;
	float4 projCoord : TEXCOORD3;
	float3 viewDir : TEXCOORD4;
	float3 lightDir : TEXCOORD5;
	float3 worldNormal : NORMAL;
#ifdef _VERTCOLOR_ENABLE
	float4 color : COLOR;
#endif
	UNITY_SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)

#ifndef LIGHTMAP_ON
	#if UNITY_SHOULD_SAMPLE_SH
		half3 sh : TEXCOORD8;
	#endif
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

UNITY_INSTANCING_BUFFER_START(Props)
UNITY_INSTANCING_BUFFER_END(Props)

PSInput VSMain(appdata_full  v)
{
	PSInput o =(PSInput)0;
	UNITY_INITIALIZE_OUTPUT(PSInput, o);
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);

	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	float3 worldNormal = UnityObjectToWorldNormal(v.normal);
	o.worldPos = worldPos;
	o.worldNormal = worldNormal;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.projCoord = ComputeScreenPos(o.pos);
	o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
	o.lightDir = normalize(_WorldSpaceLightPos0.xyz);

#ifdef _VERTCOLOR_ENABLE
	o.color = v.color;
#endif

#ifdef DYNAMICLIGHTMAP_ON
	o.lightMap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

#ifdef LIGHTMAP_ON
	o.lightMap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

#ifndef LIGHTMAP_ON
	#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
	o.sh = 0;
		#ifdef VERTEXLIGHT_ON
		o.sh += Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb, unity_4LightAtten0, worldPos, worldNormal);
		#endif
		o.sh = ShadeSHPerVertex(worldNormal, o.sh);
	#endif
#endif
	UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
	UNITY_TRANSFER_FOG(o, o.pos);
	return o;
}


void surf(Input IN, inout SurfaceOutputStandard o)
{
	fixed4 baseColor = tex2D(_MainTex, IN.uv_MainTex) * _Color;
	fixed4 blendColor = tex2D(_SubTex, IN.uv_MainTex);
	o.Albedo = baseColor * (1 - _BlendWeight) + blendColor * _BlendWeight;
	o.Albedo += IN.color.rgb;

#ifdef _REFLECT_ENABLE
	fixed4 col = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(IN.projCoord));
	o.Albedo *= col;
#endif

#ifdef _VERTCOLOR_ENABLE
	o.Albedo += IN.color.rgb;
#endif

	o.Albedo *= _EnvironmentColor;
	o.Metallic = _Metallic;
	o.Smoothness = _Glossiness;
	o.Alpha = baseColor.a;
}


fixed4 PSMain(PSInput i) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(i);
	float3 worldPos = i.worldPos;
	float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
#ifndef USING_DIRECTIONAL_LIGHT
	fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#else
	fixed3 lightDir = _WorldSpaceLightPos0.xyz;
#endif
	Input surfIN;
	UNITY_INITIALIZE_OUTPUT(Input, surfIN);
	surfIN.uv_MainTex = i.uv;

#ifdef _REFLECT_ENABLE
	surfIN.projCoord = i.projCoord;
#endif

#ifdef _VERTCOLOR_ENABLE
	surfIN.color = i.color;
#endif

	SurfaceOutputStandard o;
	UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
	o.Albedo = 0.0;
	o.Emission = 0.0;
	o.Alpha = 0.0;
	o.Occlusion = 1.0;
	o.Normal = i.worldNormal;
	surf(surfIN, o);
	UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
	half4 color = 0;

	UnityGI gi;
	UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	gi.indirect.diffuse = 0;
	gi.indirect.specular = 0;
	gi.light.color = _LightColor0.rgb;
	gi.light.dir = lightDir;
	UnityGIInput giInput;
	UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
	giInput.light = gi.light;
	giInput.worldPos = worldPos;
	giInput.worldViewDir = worldViewDir;
	giInput.atten = atten;
#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
	giInput.lightmapUV = i.lightMap;
#else
	giInput.lightmapUV = 0.0;
#endif
	giInput.ambient.rgb = 0.0;
	giInput.probeHDR[0] = unity_SpecCube0_HDR;
	giInput.probeHDR[1] = unity_SpecCube1_HDR;
#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
	giInput.boxMin[0] = unity_SpecCube0_BoxMin;
#endif

	// UnityPBSLighting 
	LightingStandard_GI(o, giInput, gi);
	color += LightingStandard(o, worldViewDir, gi);
	UNITY_APPLY_FOG(i.fogCoord, color);
	UNITY_OPAQUE_ALPHA(color.a);
	return color;
}


#endif // FRESNEL_REFLECTION_CORE_INCLUDED
