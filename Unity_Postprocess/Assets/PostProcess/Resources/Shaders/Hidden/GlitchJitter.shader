Shader "Hidden/PostProcess/GlitchJitter"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#define NOISE_SIMPLEX_1_DIV_289 0.00346020761245674740484429065744f

	float mod289(float x)
	{
		return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
	}

	float2 mod289(float2 x)
	{
		return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
	}

	float3 mod289(float3 x)
	{
		return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
	}

	float4 mod289(float4 x)
	{
		return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
	}

	float permute(float x)
	{
		return mod289(x * x * 34.0 + x);
	}

	float3 permute(float3 x)
	{
		return mod289(x * x * 34.0 + x);
	}

	float3 taylorInvSqrt(float3 r)
	{
		return 1.79284291400159 - 0.85373472095314 * r;
	}

	float4 taylorInvSqrt(float4 r)
	{
		return 1.79284291400159 - r * 0.85373472095314;
	}

	float snoise(float2 v)
	{
		// (3.0-sqrt(3.0))/6.0
		// 0.5*(sqrt(3.0)-1.0)
		// -1.0 + 2.0 * C.x
		// 1.0 / 41.0
		const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439); 
		float2 i = floor(v + dot(v, C.yy));
		float2 x0 = v - i + dot(i, C.xx);

		// Other corners
		float2 i1;
		i1.x = step(x0.y, x0.x);
		i1.y = 1.0 - i1.x;

		// x1 = x0 - i1  + 1.0 * C.xx;
		// x2 = x0 - 1.0 + 2.0 * C.xx;
		float2 x1 = x0 + C.xx - i1;
		float2 x2 = x0 + C.zz;

		// Permutations
		i = mod289(i); // Avoid truncation effects in permutation
		float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
		float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
		m = m * m;
		m = m * m;

		// Gradients: 41 points uniformly over a line, mapped onto a diamond.
		// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
		float3 x = 2.0 * frac(p * C.www) - 1.0;
		float3 h = abs(x) - 0.5;
		float3 ox = floor(x + 0.5);
		float3 a0 = x - ox;

		// Normalise gradients implicitly by scaling m
		m *= taylorInvSqrt(a0 * a0 + h * h);

		// Compute final noise value at P
		float3 g;
		g.x = a0.x * x0.x + h.x * x0.y;
		g.y = a0.y * x1.x + h.y * x1.y;
		g.z = a0.z * x2.x + h.z * x2.y;
		return 130.0 * dot(m, g);
	}

	sampler2D _MainTex;
	float2 _Resolution;
	half _Frequency, _RGBSplit, _Speed, _Amount;

	struct VSInput
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct VSOutput
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	VSOutput VSMain(VSInput v)
	{
		VSOutput o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}

	// pass 0
	float4 Frag_Horizontal(VSOutput i) : SV_Target
	{
		half strength = 0.0;
#ifdef LOOP_ON
		strength = 1;
#endif
#ifdef LOOP_OFF
		strength = 0.5 + 0.5 *cos(_Time.y * _Frequency);
#endif
		float uv_y = i.uv.y * _Resolution.y;
		float noise_wave_1 = snoise(float2(uv_y * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
		float noise_wave_2 = snoise(float2(uv_y * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
		float noise_wave_x = noise_wave_1 * noise_wave_2 / _Resolution.x;
		float uv_x = i.uv.x + noise_wave_x;
		float rgbSplit_uv_x = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_x / _Resolution.x;
		half4 colorG = tex2D(_MainTex, float2(uv_x, i.uv.y));
		half4 colorRB = tex2D(_MainTex, float2(uv_x + rgbSplit_uv_x, i.uv.y));
		return  half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
	}

	// pass 1
	float4 Frag_Vertical(VSOutput i) : SV_Target
	{
		half strength = 0.0;
#ifdef LOOP_ON
		strength = 1;
#endif
#ifdef LOOP_OFF
		strength = 0.5 + 0.5 *cos(_Time.y * _Frequency);
#endif
		float uv_x = i.uv.x * _Resolution.x;
		float noise_wave_1 = snoise(float2(uv_x * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
		float noise_wave_2 = snoise(float2(uv_x * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
		float noise_wave_y = noise_wave_1 * noise_wave_2 / _Resolution.x;
		float uv_y = i.uv.y + noise_wave_y;
		float rgbSplit_uv_y = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_y / _Resolution.y;
		half4 colorG = tex2D(_MainTex, float2(i.uv.x, uv_y));
		half4 colorRB = tex2D(_MainTex, float2(i.uv.x, uv_y + rgbSplit_uv_y));
		return half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
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
			#pragma fragment Frag_Horizontal
			#pragma multi_compile LOOP_ON LOOP_OFF
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment Frag_Vertical
			#pragma multi_compile LOOP_ON LOOP_OFF
			ENDCG
		}
	}
}
