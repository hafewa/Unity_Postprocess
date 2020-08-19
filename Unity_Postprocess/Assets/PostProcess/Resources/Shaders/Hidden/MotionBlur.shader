
Shader "Hidden/PostProcess/MotionBlur" 
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_AccumOrig("AccumOrig", Float) = 0.65
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex; float4 _MainTex_ST;

	struct appdata
	{
		float4 vertex : POSITION;
		float2 texcoord : TEXCOORD;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		float2 texcoord : TEXCOORD;
	};

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
		return o;
	}
	ENDCG

	SubShader
	{
		ZTest Always Cull Off ZWrite Off

		Pass 
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			BindChannels 
			{
				Bind "vertex", vertex
				Bind "texcoord", texcoord
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			fixed _AccumOrig;

			half4 frag(v2f i) : SV_Target
			{
				return half4(tex2D(_MainTex, i.texcoord).rgb, _AccumOrig);
			}
			ENDCG
		}

		Pass 
		{
			Blend One Zero
			ColorMask A

			BindChannels 
			{
				Bind "vertex", vertex
				Bind "texcoord", texcoord
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			half4 frag(v2f i) : SV_Target
			{
				return tex2D(_MainTex, i.texcoord);
			}
			ENDCG
		}

	}

}
