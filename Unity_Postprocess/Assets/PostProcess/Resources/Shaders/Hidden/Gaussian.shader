
Shader "Hidden/PostProcess/Gaussian"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}

	sampler2D _MainTex;
	sampler2D _BloomSource1;
	sampler2D _BloomSource2;
	fixed _Intencity1;
	fixed _Intencity2;
	fixed _Threshold;
	fixed _Radius;

	// sampling texture
	fixed3 gaussian(fixed2 deltaPixel, fixed2 uv)
	{
		float3 col = 0;
		col += tex2D(_MainTex, uv) * 0.1441444;
		col += tex2D(_MainTex, uv + deltaPixel) * 0.1304273;
		col += tex2D(_MainTex, uv + deltaPixel * 2) * 0.1067848;
		col += tex2D(_MainTex, uv + deltaPixel * 3) * 0.07910813;
		col += tex2D(_MainTex, uv + deltaPixel * 4) * 0.05302777;
		col += tex2D(_MainTex, uv + deltaPixel * 5) * 0.03216297;
		col += tex2D(_MainTex, uv + deltaPixel * 6) * 0.01765141;
		col += tex2D(_MainTex, uv + deltaPixel * 7) * 0.008765431;
		return col;
	}

	// 1pass
	fixed4 frag_threshold(v2f i) : SV_Target
	{
		return tex2D(_MainTex, i.uv) - _Threshold;
	}

	// 2pass
	fixed4 frag_cross_bloom(v2f i) : SV_Target
	{
		float3 col = 0;
		float2 pixel = (_ScreenParams.zw - 1) * _Radius;
		col += gaussian(pixel, i.uv);
		col += gaussian(pixel * float2(-1, 1), i.uv);
		col += gaussian(pixel * float2(1, -1), i.uv);
		col += gaussian(pixel * float2(-1, -1), i.uv);
		col /= 4;
		return float4(col, 1);
	}

	// 3pass
	fixed4 frag_gaussian_x(v2f i) : SV_Target
	{
		float2 pixel = (_ScreenParams.zw - 1) * _Radius;
		float3 col = gaussian(float2(pixel.x, 0), i.uv);
		col += gaussian(float2(-pixel.x, 0), i.uv);
		col /= 2;
		return float4(col, 1);
	}

	// 4pass
	fixed4 frag_gaussian_y(v2f i) : SV_Target
	{
		float2 pixel = (_ScreenParams.zw - 1) * _Radius;
		float3 col = gaussian(float2(0,  pixel.y), i.uv);
		col += gaussian(float2(0, -pixel.y), i.uv);
		col /= 2;
		return float4(col, 1);
	}

	// 5pass
	fixed4 frag_add(v2f i) : SV_Target
	{
		float3 col = 0;
		col += tex2D(_MainTex, i.uv);
		col += tex2D(_BloomSource1, i.uv) * _Intencity1;
		col += tex2D(_BloomSource2, i.uv) * _Intencity2;
		return float4(col, 1);
	}
	ENDCG

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag_threshold
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag_cross_bloom
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag_gaussian_x
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag_gaussian_y
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag_add
			ENDCG
		}
	}
}
