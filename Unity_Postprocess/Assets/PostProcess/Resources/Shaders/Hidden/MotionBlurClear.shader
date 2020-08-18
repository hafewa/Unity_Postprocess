
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

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata 
			{
				float4 vertex : POSITION;
			};

			struct v2f 
			{
				float4 pos : SV_POSITION;
				float4 screen : TEXCOORD0;
			};

			sampler2D _CameraDepthTexture;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screen = ComputeScreenPos(o.pos);
				COMPUTE_EYEDEPTH(o.screen.z);
				return o;
			}

			float4 frag(v2f i) : SV_Target
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
