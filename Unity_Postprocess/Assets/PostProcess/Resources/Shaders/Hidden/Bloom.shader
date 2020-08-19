﻿Shader "Hidden/PostProcess/Bloom"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		[HDR]_Color("Color", Color) = (1,1,1,1)
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex, _SourceTex; 
	float4 _MainTex_ST, _SourceTex_ST;
	float4 _MainTex_TexelSize;
	half4 _Filter;
	half4 _Color;
	half _Intensity;

	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	v2f vert(appdata v)
	{
		v2f i;
		i.pos = UnityObjectToClipPos(v.vertex);
		i.uv = v.uv;
		return i;
	}

	half3 sample (float2 uv)
	{
		return tex2D(_MainTex, TRANSFORM_TEX(uv, _MainTex)).rgb;
	}

	half3 sampleBox(float2 uv, float delta)
	{
		float4 o = _MainTex_TexelSize.xyxy * float2(-delta, delta).xxyy;
		half3 s = sample(uv + o.xy) + sample(uv + o.zy) + sample(uv + o.xw) + sample(uv + o.zw);
		return s * 0.25f;
	}

	half3 filter(half3 c)
	{
		half brightness = max(c.r, max(c.g, c.b));
		half soft = brightness - _Filter.y;
		soft = clamp(soft, 0, _Filter.z);
		soft = soft * soft * _Filter.w;
		half contribution = max(soft, brightness - _Filter.x);
		contribution /= max(brightness, 0.00001);
		return c * contribution;
	}
	ENDCG

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		// current
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			half4 frag(v2f i) : SV_Target
			{
				return half4(filter(sampleBox(i.uv, 1)), 1);
			}
			ENDCG
		}

		// down sapmling
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			half4 frag(v2f i) : SV_Target
			{
				return half4(sampleBox(i.uv, 1), 1);
			}
			ENDCG
		}

		// up sampling
		Pass
		{
			Blend One One
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			half4 frag(v2f i) : SV_Target
			{
				return half4(sampleBox(i.uv, 0.5), 1);
			}
			ENDCG
		}

		// final color
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			half4 frag(v2f i) : SV_Target
			{
				half4 c = tex2D(_SourceTex, TRANSFORM_TEX(i.uv, _SourceTex));
				c.rgb += _Intensity * sampleBox(i.uv, 0.5);
				c.rgb += _Color.rgb;
				return c;
			}
			ENDCG
		}
	}

	//
}
