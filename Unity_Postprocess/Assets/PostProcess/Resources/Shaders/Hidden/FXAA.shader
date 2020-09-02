Shader "Hidden/PostProcess/FXAA"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	float4 _rcpFrame;
	float4 _rcpFrameOpt;

	struct v2f
	{
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
		float4 uvAux : TEXCOORD1;
	};

	v2f vert(appdata_img v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		o.uvAux.xy = v.texcoord.xy + float2(-_MainTex_TexelSize.x, +_MainTex_TexelSize.y) * 0.5f;
		o.uvAux.zw = v.texcoord.xy + float2(+_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * 0.5f;
		return o;
	}
	ENDCG

	SubShader
	{
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			//#define FXAA_PC
			//#define FXAA_HLSL_3
			#define FXAA_EARLY_EXIT 1
			#include "FXAA.cginc"

			half4 frag(v2f i) : COLOR
			{
				return PSMain_Speed(i.uv, i.uvAux, _MainTex, _rcpFrame.xy, _rcpFrameOpt);
				//return PSMain_Quality(i.uv, i.uvAux, _MainTex, _rcpFrame.xy, _rcpFrameOpt);
			}
			ENDCG
		}
	}
}
