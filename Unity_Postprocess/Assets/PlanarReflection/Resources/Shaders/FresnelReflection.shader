Shader "Custom/FresnelReflection"
{
	Properties
	{
		[Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2
		[KeywordEnum(DISABLE, ENABLE)] _REFLECT("REFLECT", Float) = 0

		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_SubTex("SubTex", 2D) = "white" {}
		_BlendWeight("BlendWeight",Range(0, 1)) = 0
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_Flesnel("Flesnel", Range(0, 1)) = 0.02

		[HideInInspector]_EnvironmentColor("_EnvironmentColor", Color) = (1,1,1,1)
	}

CGINCLUDE
	#define UNITY_SETUP_BRDF_INPUT MetallicSetup
ENDCG

	SubShader
	{
		Tags { "RenderType" = "Opaque" "PerformanceChecks" = "False" }
		LOD 200


		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Cull [_CullMode]

			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			#pragma multi_compile _REFLECT_ENABLE _REFLECT_DISABLE
			#include "UnityCG.cginc"
			#include "FresnelReflectionCore.cginc"
			ENDCG
		}
	}
}
