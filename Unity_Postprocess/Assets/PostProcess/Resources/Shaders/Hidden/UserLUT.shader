Shader "Hidden/PostProcess/UserLUT"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_LUT("LUT", 2D) = "white" {}
		_Contribution("Contribution", Range(0, 1)) = 1
	}

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#include "UnityCG.cginc"
			#define COLORS 32.0

			struct VSInput
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct PSIput
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _LUT; float4 _LUT_TexelSize;
			float _Contribution;

			PSIput VSMain(VSInput v)
			{
				PSIput o = (PSIput)0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			//COLOR GRADING LUT METHOD
			half4 ColorGrade(PSIput i)
			{
				float maxColor = COLORS - 1.0;
				half4 col = tex2D(_MainTex, i.uv);
				col.rgb = saturate(col.rgb);

				float halfColX = 0.5 / _LUT_TexelSize.z;
				float halfColY = 0.5 / _LUT_TexelSize.w;
				float threshold = maxColor / COLORS;
				float xOffset = halfColX + col.r * threshold / COLORS;
				float yOffset = halfColY + col.g * threshold;
				float cell = floor(col.b * maxColor);
				float2 lutPos = float2(cell / COLORS + xOffset, yOffset);
				half4 gradedCol = tex2D(_LUT, lutPos);
				return lerp(col, gradedCol, _Contribution);
			}

			half4 PSMain(PSIput i) : SV_Target
			{
				return ColorGrade(i);
			}
			ENDCG
		}
	}
}
