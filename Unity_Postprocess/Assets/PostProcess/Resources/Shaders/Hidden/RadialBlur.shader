Shader "Hidden/PostProcess/RadialBlur"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Samples("Samples", Range(4, 32)) = 16
		_EffectAmount("Effect amount", float) = 1
		_CenterX("Center X", float) = 0.5
		_CenterY("Center Y", float) = 0.5
		_Radius("Radius", float) = 0.1
	}

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment PSMain
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half _Samples;
			half _EffectAmount;
			half _CenterX;
			half _CenterY;

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

			fixed4 PSMain(PSInput i) : SV_Target
			{
				fixed4 col = fixed4(0,0,0,0);
				float2 dist = i.uv - float2(_CenterX, _CenterY);
				for (int i = 0; i < _Samples; ++i) 
				{
					float scale = 1 - _EffectAmount * (i / _Samples)* (saturate(length(dist)));
					col += tex2D(_MainTex, dist * scale + float2(_CenterX, _CenterY));
				}
				col /= _Samples;
				return col;
			}
			ENDCG
		}
	}
}
