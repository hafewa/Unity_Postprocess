
Shader "Hidden/PostProcess/MotionBlurClear"
{

	Properties
	{
		//
	}

	SubShader
	{
		Pass 
		{
			//ZTest LEqual
			ZTest Always // lame depth test
			ZWrite Off // lame depth test

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment PSMain
			#include "UnityCG.cginc"
			sampler2D _CameraDepthTexture;

			struct VSInput 
			{
				float4 vertex : POSITION;
			};

			struct PSInput 
			{
				float4 pos : SV_POSITION;
				float4 screen : TEXCOORD0;
			};


			PSInput VSMain(VSInput v)
			{
				PSInput o = (PSInput)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screen = ComputeScreenPos(o.pos);
				COMPUTE_EYEDEPTH(o.screen.z);
				return o;
			}

			float4 PSMain(PSInput i) : SV_Target
			{
				// superlame: manual depth test needed as we can't bind depth, FIXME for 4.x
				// alternatively implement SM > 3 version where we write out custom depth
				float d = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screen));
				d = LinearEyeDepth(d);

				clip(d - i.screen.z + 1e-2f);
				return float4(0, 0, 0, 0);
			}

			ENDCG
		}
	}
	Fallback Off
}
