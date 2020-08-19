Shader "Hidden/PostProcess/GodRay"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BlurTex("Blur", 2D) = "white"{}
	}

	CGINCLUDE
	#define RADIAL_SAMPLE_COUNT 6
	#include "UnityCG.cginc"

	struct v2f_threshold
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f_blur
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float2 blurOffset : TEXCOORD1;
	};

	struct v2f_merge
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};

	sampler2D _CameraDepthTexture;
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	sampler2D _BlurTex;
	float4 _BlurTex_TexelSize;
	float4 _ViewPortLightPos;

	float4 _offsets;
	float4 _ColorThreshold;
	float4 _LightColor;
	float _LightFactor;
	float _PowFactor;
	float _LightRadius;
	float _DepthThreshold;

	v2f_threshold vert_threshold(appdata_img v)
	{
		v2f_threshold o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
		{
			o.uv.y = 1 - o.uv.y;
		}
#endif	
		return o;
	}

	fixed4 frag_threshold(v2f_threshold i) : SV_Target
	{
		fixed4 color = tex2D(_MainTex, i.uv);
		float distFromLight = length(_ViewPortLightPos.xy - i.uv);
		float distanceControl = saturate(_LightRadius - distFromLight);
		float4 thresholdColor = saturate(color - _ColorThreshold) * distanceControl;
		float luminanceColor = Luminance(thresholdColor.rgb);
		luminanceColor = pow(luminanceColor, _PowFactor);

		float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
		depth = Linear01Depth(depth);
		luminanceColor *= sign(saturate(depth - _DepthThreshold));
		return fixed4(luminanceColor, luminanceColor, luminanceColor, 1);
	}

	v2f_blur vert_blur(appdata_img v)
	{
		v2f_blur o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		o.blurOffset = _offsets * (_ViewPortLightPos.xy - o.uv);
		return o;
	}

	fixed4 frag_blur(v2f_blur i) : SV_Target
	{
		half4 color = half4(0,0,0,0);
		for (int j = 0; j < RADIAL_SAMPLE_COUNT; j++)
		{
			color += tex2D(_MainTex, i.uv.xy);
			i.uv.xy += i.blurOffset;
		}
		return color / RADIAL_SAMPLE_COUNT;
	}

	v2f_merge vert_merge(appdata_img v)
	{
		v2f_merge o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy;
		o.uv1.xy = o.uv.xy;
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
		{
			o.uv.y = 1 - o.uv.y;
		}
#endif	
		return o;
	}

	fixed4 frag_merge(v2f_merge i) : SV_Target
	{
		fixed4 ori = tex2D(_MainTex, i.uv1);
		fixed4 blur = tex2D(_BlurTex, i.uv);
		return ori + _LightFactor * blur * _LightColor;
	}
	ENDCG

	SubShader
	{
		ZTest Off Cull Off ZWrite Off 
		Fog{ Mode Off }

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert_threshold
			#pragma fragment frag_threshold
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert_blur
			#pragma fragment frag_blur
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert_merge
			#pragma fragment frag_merge
			ENDCG
		}
	}
}
