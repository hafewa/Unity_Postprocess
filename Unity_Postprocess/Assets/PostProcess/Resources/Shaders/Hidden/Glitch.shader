Shader "Hidden/PostProcess/Glitch"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
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

			sampler2D _MainTex;
			half _BlockSize, _Speed, _MaxRGBSplitX, _MaxRGBSplitY;

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

			float RandomNoise(float2 seed)
			{
				return frac(sin(dot(seed * floor(_Time.y * _Speed), float2(17.13, 3.71))) * 43758.5453123);
			}

			float RandomNoise(float seed)
			{
				return RandomNoise(float2(seed, 1.0));
			}

			VSOutput VSMain(VSInput v)
			{
				VSOutput o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 PSMain(VSOutput i) : SV_Target
			{
				half2 block = RandomNoise(floor(i.uv * _BlockSize));
				float displaceNoise = pow(block.x, 8.0) * pow(block.x, 3.0);
				float splitRGBNoise = pow(RandomNoise(7.2341), 17.0);
				float offsetX = displaceNoise - splitRGBNoise * _MaxRGBSplitX;
				float offsetY = displaceNoise - splitRGBNoise * _MaxRGBSplitY;
				float noiseX = 0.05 * RandomNoise(13.0);
				float noiseY = 0.05 * RandomNoise(7.0);
				float2 offset = float2(offsetX * noiseX, offsetY* noiseY);
				half4 colorR = tex2D(_MainTex, i.uv);
				half4 colorG = tex2D(_MainTex, i.uv + offset);
				half4 colorB = tex2D(_MainTex, i.uv - offset);

				return half4(colorR.r , colorG.g, colorB.z, (colorR.a + colorG.a + colorB.a));
			}
			ENDCG
		}
	}
}
