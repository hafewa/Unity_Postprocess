Shader "Hidden/PostProcess/FXAA"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	CGINCLUDE
	#pragma target 3.0
	#include "UnityCG.cginc"
	sampler2D _MainTex; float4 _MainTex_TexelSize;
	float4 _FXAAFrame;
	float4 _FXAAFrameSize;

	struct PSInput
	{
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
		float4 uvAux : TEXCOORD1;
	};

	PSInput VSMain(appdata_img v)
	{
		PSInput o = (PSInput)0;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		o.uvAux.xy = v.texcoord.xy + float2(-_MainTex_TexelSize.x, +_MainTex_TexelSize.y) * 0.5f;
		o.uvAux.zw = v.texcoord.xy + float2(+_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * 0.5f;
		return o;
	}
	ENDCG

	SubShader
	{
		ZTest Always Cull Off ZWrite Off
		Fog { Mode Off }

		// fast fxaa
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#define FXAA_EARLY_EXIT 1
			#define FXAA_DISCARD 0
			#include "FXAA.hlsl"

			half4 PSMain(PSInput i) : COLOR
			{
				return PSMain_Speed(i.uv, i.uvAux, _MainTex, _FXAAFrame.xy, _FXAAFrameSize);
			}
			ENDCG
		}

		// high quality fxaa
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#define FXAA_PC
			#define FXAA_HLSL_3
			#define FXAA_EARLY_EXIT 0
			#include "FXAA.hlsl"

			half4 PSMain(PSInput i) : COLOR
			{
				return PSMain_Quality(i.uv, i.uvAux, _MainTex, _FXAAFrame.xy, _FXAAFrameSize);
			}
			ENDCG
		}
	}
}
