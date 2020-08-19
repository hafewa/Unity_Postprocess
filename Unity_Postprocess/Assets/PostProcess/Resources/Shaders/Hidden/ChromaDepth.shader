Shader "Hidden/PostProcess/ChromaDepth"
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
			#pragma multi_compile SONAR_DIRECTIONAL SONAR_SPHERICAL
			#include "UnityCG.cginc"

			sampler2D _MainTex; float4 _MainTex_TexelSize;
			sampler2D _NoiseTex; float4 _NoiseTex_TexelSize;
			sampler2D _CameraDepthTexture;
			float4 _WaveColor;
			float _WaveTrail;
			float _WaveSpeed;

			struct VSInput
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct VSOutput
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};


			VSOutput VSMain(VSInput v)
			{
				VSOutput o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 PSMain(VSOutput i) : SV_Target
			{
				half4 color = tex2D(_MainTex, i.uv);
				float depth = tex2D(_CameraDepthTexture, i.uv).r;
				depth = Linear01Depth(depth);
				depth = depth * _ProjectionParams.z;
				
				if (depth >= _ProjectionParams.z)
				{
					return color;
				}

				float waveDistance = (_Time.y * _WaveSpeed) % _ProjectionParams.z;
				float waveFront = step(depth, waveDistance);
				float waveTrail = smoothstep(waveDistance - _WaveTrail, waveDistance, depth);
				float wave = waveFront * waveTrail;

				return lerp(color, _WaveColor, wave);
			}
			ENDCG
		}
	}
}
