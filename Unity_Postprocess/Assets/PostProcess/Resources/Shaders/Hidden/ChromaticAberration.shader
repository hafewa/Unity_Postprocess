﻿Shader "Hidden/PostProcess/ChromaticAberration"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment PSMain

			#include "UnityCG.cginc"

			sampler2D _MainTex; float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			float2 _ROffset;
			float2 _GOffset;
			float2 _BOffset;

			struct PSInput
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			PSInput VSMain(appdata_base v)
			{
				PSInput o = (PSInput)0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			fixed4 PSMain(PSInput i) : SV_Target
			{
				fixed4 col;
				col.r = tex2D(_MainTex, i.uv + _ROffset).r;
				col.g = tex2D(_MainTex, i.uv + _GOffset).g;
				col.b = tex2D(_MainTex, i.uv + _BOffset).b;
				col.a = tex2D(_MainTex, i.uv).a;
				return col;
			}
			ENDCG
		}
	}

	//
}
