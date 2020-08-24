Shader "Custom/FresnelReflection"
{
	Properties
	{
		[Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2
		_MainTex("Texture", 2D) = "white" {}
		//_ReflectionTex ("ReflectionTexture", 2D) = "white" {}
		_Flesnel("Flesnel", Range(0, 1)) = 0.02
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
			#include "UnityCG.cginc"
			#include "FresnelReflectionCore.cginc"
			ENDCG
		}
	}
}
