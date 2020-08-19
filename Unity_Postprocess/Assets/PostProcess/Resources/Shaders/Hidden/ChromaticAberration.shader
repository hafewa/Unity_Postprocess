Shader "Hidden/PostProcess/ChromaticAberration"
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
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex; float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			float2 _ROffset;
			float2 _GOffset;
			float2 _BOffset;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col;
				col.r = tex2D(_MainTex, i.uv + _ROffset).r;
				col.g = tex2D(_MainTex, i.uv + _GOffset).g;
				col.b = tex2D(_MainTex, i.uv + _BOffset).b;
				col.a = tex2D(_MainTex, i.uv).a;
				return col;
			}
			ENDCG
		}
	}

	//
}
