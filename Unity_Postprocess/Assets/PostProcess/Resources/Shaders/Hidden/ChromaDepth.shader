Shader "Hidden/PostProcess/ChromaDepth"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	sampler2D _DetailTex;
	sampler2D _CameraDepthTexture;

	float4 _MainTex_TexelSize;
	float4 _CameraWS;
	float4 _ScannerWS;
	float4 _LeadColor, _MidColor, _TrailColor, _HBarColor;
	float _ScanDistance, _ScanWidth, _LeadSharp;

	struct VSInput
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
		float4 ray : TEXCOORD1;
	};

	struct VSOutput
	{
		float4 vertex : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv_depth : TEXCOORD1;
		float4 interpolatedRay : TEXCOORD2;
	};

	float4 HorizontalBars(float2 p)
	{
		return 1 - saturate(round(abs(frac(p.y * 100) * 2)));
	}

	float4 HorizontalTex(float2 p)
	{
		return tex2D(_DetailTex, float2(p.x * 20, p.y * 20));
	}

	float Curve(float src, float factor)
	{
		return src - (src - src * src) * -factor;
	}

	VSOutput VSMain(VSInput v)
	{
		VSOutput o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv.xy;
		o.uv_depth = v.uv.xy;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
		{
			o.uv.y = 1 - o.uv.y;
		}
#endif
		o.interpolatedRay = v.ray;
		return o;
	}

	fixed4 PSMain(VSOutput i) : SV_Target
	{
		float4 color = tex2D(_MainTex, i.uv);
		float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
		float depth = Linear01Depth(rawDepth);
		float4 wsDir = depth * i.interpolatedRay;
		float3 wsPos = _CameraWS + wsDir;
		half4 scannerCol = half4(0, 0, 0, 0);

		// CameraとTriggerからの距離を計算
		float dist = distance(wsPos, _ScannerWS);

		// 差分
		float diff = 1 - (_ScanDistance - dist) / (_ScanWidth);

		// powの負荷を考慮してCurveで再計算
		fixed4 edge = lerp(_MidColor, _LeadColor, Curve(diff, _LeadSharp)); /*pow(diff, _LeadSharp)*/

		if (dist < _ScanDistance && dist > _ScanDistance - _ScanWidth && depth < 1)
		{
			scannerCol = lerp(_TrailColor, edge, diff);
#ifdef NOISE_ON
			// NoiseTex
			scannerCol += HorizontalTex(i.uv) * _HBarColor;
#endif
#ifdef NOISE_OFF
			// Fraction
			scannerCol += HorizontalBars(i.uv) * _HBarColor;
#endif
			scannerCol *= diff;
		}
		return color + scannerCol;
	}

	ENDCG


	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma multi_compile NOISE_ON NOISE_OFF
			ENDCG
		}
	}
}
