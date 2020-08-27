Shader "Custom/FresnelReflection"
{
	Properties
	{
		[Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2
		[Toggle(_REFLECT_ENABLE)] _REFLECT("Using Planar Reflection?", Float) = 0
		[Toggle(_VERTCOLOR_ENABLE)] _VERTCOLOR("Using Vertex Color?", Float) = 0

		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_SubTex("SubTex", 2D) = "white" {}
		_BlendWeight("BlendWeight",Range(0, 1)) = 0

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_IndirectDiffRefl("Indirect Diffuse Reflection", Range(0.0, 1.0)) = 1.0
		_Roughness("Roughness", Range(0.0, 1.0)) = 0.0

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
			#pragma multi_compile _ _REFLECT_ENABLE
			#pragma multi_compile _ _VERTCOLOR_ENABLE
			#include "UnityCG.cginc"
			#include "FresnelReflectionCore.cginc"
			ENDCG
		}

		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			ZWrite Off
			Blend One One
			Fog { Color(0,0,0,0) }
			ZTest LEqual

			CGPROGRAM
			#pragma vertex vertAdd
			#pragma fragment fragAdd
			#pragma target 3.0
			#pragma multi_compile_fwdadd
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			#include "UnityStandardCoreForward.cginc"
			ENDCG
		}

		Pass
		{
			Name "SHADOW_CASTER"
			Tags { "LightMode" = "ShadowCaster" }
			ZWrite On ZTest LEqual
			CGPROGRAM
			#pragma target 3.0
			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster
			#include "UnityStandardShadow.cginc"
			ENDCG
		}

		Pass
		{
			Name "META"
			Tags { "LightMode" = "Meta" }
			Cull Off
			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta
			#pragma shader_feature _EMISSION
			#pragma shader_feature_local _METALLICGLOSSMAP
			#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature_local _DETAIL_MULX2
			#pragma shader_feature EDITOR_VISUALIZATION
			#include "UnityStandardMeta.cginc"
			ENDCG
		}
	}

	Fallback Off
}
