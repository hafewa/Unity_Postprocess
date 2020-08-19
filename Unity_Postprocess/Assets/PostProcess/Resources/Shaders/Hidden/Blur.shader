
Shader "Hidden/PostProcess/Blur"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		[Toggle] _ReversePass("Vertical Pass First", Float) = 0
	}

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex;
		float4 _MainTex_TexelSize;
		float _ReversePass;

		struct VSInput
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct VSOutput
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			float2 offs : TEXCOORD1;
		};

		VSOutput VSMain(VSInput v)
		{
			VSOutput o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			return o;
		}

		float4 PSMain1(VSOutput i) : SV_Target
		{
			float4 col = 0;
			float2 unit = _ReversePass > 0.5 ? float2(_MainTex_TexelSize.x, 0) : float2(0,_MainTex_TexelSize.y);
			col += tex2D(_MainTex, i.uv - 3 * unit) * 0.053;
			col += tex2D(_MainTex, i.uv - 2 * unit) * 0.123;
			col += tex2D(_MainTex, i.uv - unit) * 0.203;
			col += tex2D(_MainTex, i.uv) * 0.240;
			col += tex2D(_MainTex, i.uv + unit) * 0.203;
			col += tex2D(_MainTex, i.uv + 2 * unit) * 0.123;
			col += tex2D(_MainTex, i.uv + 3 * unit) * 0.053;
			return col;
		}

		float4 PSMain2(VSOutput i) : SV_Target
		{
			float4 col = 0;
			float2 unit = _ReversePass > 0.5 ? float2(0,_MainTex_TexelSize.y) : float2(_MainTex_TexelSize.x, 0);
			col += tex2D(_MainTex, i.uv - 3 * unit) * 0.053;
			col += tex2D(_MainTex, i.uv - 2 * unit) * 0.123;
			col += tex2D(_MainTex, i.uv - unit) * 0.203;
			col += tex2D(_MainTex, i.uv) * 0.240;
			col += tex2D(_MainTex, i.uv + unit) * 0.203;
			col += tex2D(_MainTex, i.uv + 2 * unit) * 0.123;
			col += tex2D(_MainTex, i.uv + 3 * unit) * 0.053;
			return col;
		}
		ENDCG

		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain1
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain2
			ENDCG
		}
	}
}
