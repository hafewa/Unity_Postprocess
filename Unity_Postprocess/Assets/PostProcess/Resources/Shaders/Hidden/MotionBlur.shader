
Shader "Hidden/PostProcess/MotionBlur" 
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_AccumOrig("AccumOrig", Float) = 0.65
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex; float4 _MainTex_ST;

	struct VSInput
	{
		float4 vertex : POSITION;
		float2 texcoord : TEXCOORD;
	};

	struct VSOutput
	{
		float4 vertex : SV_POSITION;
		float2 texcoord : TEXCOORD;
	};

	VSOutput VSMain(VSInput v)
	{
		VSOutput o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
		return o;
	}
	ENDCG

	SubShader
	{
		ZTest Always Cull Off ZWrite Off

		Pass 
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			BindChannels 
			{
				Bind "vertex", vertex
				Bind "texcoord", texcoord
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment PSMain

			fixed _AccumOrig;

			half4 PSMain(VSOutput i) : SV_Target
			{
				return half4(tex2D(_MainTex, i.texcoord).rgb, _AccumOrig);
			}
			ENDCG
		}

		Pass 
		{
			Blend One Zero
			ColorMask A

			BindChannels 
			{
				Bind "vertex", vertex
				Bind "texcoord", texcoord
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment PSMain

			half4 PSMain(VSOutput i) : SV_Target
			{
				return tex2D(_MainTex, i.texcoord);
			}
			ENDCG
		}

	}

}
