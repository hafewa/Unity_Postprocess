Shader "Hidden/PostProcess/GlitchJitter"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "GlitchUtil.hlsl"

	sampler2D _MainTex;
	float2 _Resolution;
	half _Frequency, _RGBSplit, _Speed, _Amount;
	half _Blend;

	float MultiplyFrequency()
	{
		half strength = 0.0;
#ifdef LOOP_ON
		strength = 1;
#endif
#ifdef LOOP_OFF
		strength = 0.5 + 0.5 *cos(_Time.y * _Frequency);
#endif
		return strength;
	}

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

	half4 Frag_Horizontal(PSInput i) : SV_Target
	{
		half strength = MultiplyFrequency();
		float uv_y = i.uv.y * _Resolution.y;
		float noise_wave_1 = Noise(float2(uv_y * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
		float noise_wave_2 = Noise(float2(uv_y * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
		float noise_wave_x = noise_wave_1 * noise_wave_2 / _Resolution.x;
		float uv_x = i.uv.x + noise_wave_x;
		float rgbSplit_uv_x = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_x / _Resolution.x;
		half4 colorG = tex2D(_MainTex, float2(uv_x, i.uv.y));
		half4 colorRB = tex2D(_MainTex, float2(uv_x + rgbSplit_uv_x, i.uv.y));
		return  half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
	}

	half4 Frag_Vertical(PSInput i) : SV_Target
	{
		half strength = MultiplyFrequency();
		float uv_x = i.uv.x * _Resolution.x;
		float noise_wave_1 = Noise(float2(uv_x * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
		float noise_wave_2 = Noise(float2(uv_x * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
		float noise_wave_y = noise_wave_1 * noise_wave_2 / _Resolution.x;
		float uv_y = i.uv.y + noise_wave_y;
		float rgbSplit_uv_y = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_y / _Resolution.y;
		half4 colorG = tex2D(_MainTex, float2(i.uv.x, uv_y));
		half4 colorRB = tex2D(_MainTex, float2(i.uv.x, uv_y + rgbSplit_uv_y));
		return half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
	}

	half4 Frag_Mix(PSInput i) : SV_Target
	{
		half4 a = Frag_Horizontal(i);
		half4 b = Frag_Vertical(i);
		return lerp(a, b, _Blend);
	}
	ENDCG


	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		// only horizontal
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment Frag_Horizontal
			#pragma multi_compile LOOP_ON LOOP_OFF
			ENDCG
		}

		// only vertical
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment Frag_Vertical
			#pragma multi_compile LOOP_ON LOOP_OFF
			ENDCG
		}

		// mix
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment Frag_Mix
			#pragma multi_compile LOOP_ON LOOP_OFF
			ENDCG
		}
	}
}
