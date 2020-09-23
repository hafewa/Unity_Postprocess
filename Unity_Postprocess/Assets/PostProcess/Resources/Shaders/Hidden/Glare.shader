Shader "Hidden/PostProcess/Glare"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	CGINCLUDE
	#pragma target 3.0
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	float4 _MainTex_ST;
	float4 _MainTex_TexelSize;
	float _Threshold;
	float _Intensity;
	ENDCG

	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			struct PSInput
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			PSInput VSMain(appdata_base v)
			{
				PSInput o = (PSInput)0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 PSMain(PSInput i) : SV_Target
			{
				half4 col = tex2D(_MainTex, i.uv);
				half brightness = max(col.r, max(col.g, col.b));
				half contribution = max(0, brightness - _Threshold);
				contribution /= max(brightness, 0.00001);
				return col * contribution;
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			struct PSInput
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				half2 uvOffset : TEXCOORD1;
				half pathFactor : TEXCOORD2;
			};

			// x: offsetU, y: offsetY, z: pathIndex
			float3 _Params;
			float _Attenuation;
			float _Iteration;

			PSInput VSMain(appdata_base v)
			{
				PSInput o = (PSInput)0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.pathFactor = pow(4, _Params.z);
				o.uvOffset = half2(_Params.x, _Params.y) * _MainTex_TexelSize.xy * o.pathFactor;
				return o;
			}

			fixed4 PSMain(PSInput i) : SV_Target
			{
				half4 col = half4(0, 0, 0, 1);

				half2 uv = i.uv;
				for (int j = 0; j < _Iteration; ++j) 
				{
					col.rgb += tex2D(_MainTex, uv) * pow(_Attenuation, j * i.pathFactor);
					uv += i.uvOffset;
				}
				return col;
			}
			ENDCG
		}

		Pass
		{
			Blend One One
			ColorMask RGB
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			struct PSInput
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			PSInput VSMain(appdata_base v)
			{
				PSInput o = (PSInput)0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 PSMain(PSInput i) : SV_Target
			{
				return tex2D(_MainTex, i.uv) * _Intensity;
			}
			ENDCG
		}
	}
}
