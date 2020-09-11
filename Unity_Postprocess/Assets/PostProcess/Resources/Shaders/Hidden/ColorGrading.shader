
Shader "Hidden/PostProcess/ColorGrading"
{
	Properties
	{
		_MainTex("-", 2D) = ""{}
		_Curves("-", 2D) = ""{}
		_Exposure("-", Float) = 1.0
		_Saturation("-", Float) = 1.0
		_Balance("-", Vector) = (1, 1, 1, 0)
	}

	CGINCLUDE

	#pragma multi_compile BALANCING_OFF BALANCING_ON
	#pragma multi_compile TONEMAPPING_OFF TONEMAPPING_ON
	#pragma multi_compile DITHER_OFF DITHER_ORDERED DITHER_TRIANGULAR
	#include "UnityCG.cginc"
	#include "ColorGrading.hlsl"


	float4 frag(v2f_img i) : SV_Target
	{
		float4 source = tex2D(_MainTex, i.uv);
		float3 rgb = source.rgb;
#if BALANCING_ON
		rgb = apply_balance(rgb);
#endif
#if !UNITY_COLORSPACE_GAMMA
	#if TONEMAPPING_ON
		// Apply the tone mapping.
		rgb = tone_mapping(rgb);
	#else
		// Convert the color into the sRGB color space.
		rgb = linear_to_srgb(rgb);
	#endif
#endif
		// Color saturation.
		rgb = apply_saturation(rgb);
		// RGB curves.
		rgb = apply_curves(rgb);
#if !DITHER_OFF
		rgb += dither(i.uv);
#endif
#if !UNITY_COLORSPACE_GAMMA
		// Take the color back into the linear color space.
		rgb = srgb_to_linear(rgb);
#endif

		return float4(rgb, source.a);
	}
	ENDCG


	Subshader
	{
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert_img
			#pragma fragment frag
			ENDCG
		}
	}
}
