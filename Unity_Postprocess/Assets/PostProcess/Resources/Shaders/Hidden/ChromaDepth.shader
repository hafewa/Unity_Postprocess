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
			#define SKYBOX_THREASHOLD_VALUE 0.999999

			sampler2D _MainTex; float4 _MainTex_TexelSize;
			sampler2D _NoiseTex; float4 _NoiseTex_TexelSize;
			sampler2D _CameraDepthTexture;
			float4 _WaveColor;
			float _WaveTrail;
			float _WaveSpeed;

			float4 _CameraWorldSpase;
			float4x4 _FrustumCornersWS;
			float2 _ScrollSpeed;
			float _NoiseScale;


			struct VSOutput
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv_depth : TEXCOORD1;
				float4 interpolatedRay : TEXCOORD2;
			};


			VSOutput VSMain(appdata_img v)
			{
				VSOutput o;
				half index = v.vertex.z;
				v.vertex.z = 0.1;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;
				o.uv_depth = v.texcoord.xy;

#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
				{
					o.uv.y = 1 - o.uv.y;
				}
#endif				
				o.interpolatedRay = _FrustumCornersWS[(int)index];
				o.interpolatedRay.w = index;
				return o;
			}

			fixed4 PSMain(VSOutput i) : SV_Target
			{
				half4 color = tex2D(_MainTex, i.uv);
				//float depth = tex2D(_CameraDepthTexture, i.uv).r;
				float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
				float depth = Linear01Depth(rawDepth);
				depth = depth * _ProjectionParams.z;
				
				if (depth >= _ProjectionParams.z)
				{
					return color;
				}

				float waveDistance = (_Time.y * _WaveSpeed) % _ProjectionParams.z;
				float waveFront = step(depth, waveDistance);
				float waveTrail = smoothstep(waveDistance - _WaveTrail, waveDistance, depth);
				float wave = waveFront * waveTrail;

				float4 wsDir = depth * i.interpolatedRay;
				float skybox = depth < SKYBOX_THREASHOLD_VALUE;
				float4 wsPos = _CameraWorldSpase + wsDir;
				float4 noiseColor = tex2D(_NoiseTex, wsPos.xz / _NoiseScale + waveDistance);
				float fogNoise = noiseColor.r;

				return lerp(color, _WaveColor + noiseColor, wave * _WaveColor.a);
			}
			ENDCG
		}
	}
}
