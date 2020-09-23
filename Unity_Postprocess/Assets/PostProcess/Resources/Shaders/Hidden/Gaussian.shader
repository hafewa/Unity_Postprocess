
Shader "Hidden/PostProcess/Gaussian"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"


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


	sampler2D _MainTex; float4 _MainTex_TexelSize;
	sampler2D _BloomSource1;
	sampler2D _BloomSource2;
	fixed _Intencity1;
	fixed _Intencity2;
	fixed _Threshold;
	fixed _Radius;

	float interleaved_gradient(float2 uv)
	{
		float3 magic = float3(0.06711056, 0.00583715, 52.9829189);
		return frac(magic.z * frac(dot(uv, magic.xy)));
	}

	float3 dither(float2 uv)
	{
		return (float3)(interleaved_gradient(uv / _MainTex_TexelSize) / 255);
	}

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

	fixed4 frag_threshold(PSInput i) : SV_Target
	{
		return tex2D(_MainTex, i.uv) - _Threshold;
	}

	fixed4 frag_cross_bloom(PSInput i) : SV_Target
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

	fixed4 frag_gaussian_x(PSInput i) : SV_Target
	{
		float2 pixel = (_ScreenParams.zw - 1) * _Radius;
		float3 col = gaussian(float2(pixel.x, 0), i.uv);
		col += gaussian(float2(-pixel.x, 0), i.uv);
		col /= 2;
		return float4(col, 1);
	}

	fixed4 frag_gaussian_y(PSInput i) : SV_Target
	{
		float2 pixel = (_ScreenParams.zw - 1) * _Radius;
		float3 col = gaussian(float2(0,  pixel.y), i.uv);
		col += gaussian(float2(0, -pixel.y), i.uv);
		col /= 2;
		return float4(col, 1);
	}

	fixed4 frag_add(PSInput i) : SV_Target
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
			#pragma vertex VSMain
			#pragma fragment frag_threshold
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment frag_cross_bloom
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment frag_gaussian_x
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment frag_gaussian_y
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment frag_add
			ENDCG
		}
	}
}
