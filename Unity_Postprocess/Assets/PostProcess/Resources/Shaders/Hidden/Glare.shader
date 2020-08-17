Shader "Hidden/PostProcess/Glare"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	SubShader
	{
		Cull Off
		ZTest Always
		ZWrite Off

		Tags { "RenderType" = "Opaque" }

		// 0: 明度を抽出するパス
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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Threshold;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = tex2D(_MainTex, i.uv);
				half brightness = max(col.r, max(col.g, col.b));
				half contribution = max(0, brightness - _Threshold);
				contribution /= max(brightness, 0.00001);
				return col * contribution;
			}
			ENDCG
		}

		//1: スターを作るパス
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
				half2 uvOffset : TEXCOORD1;
				half pathFactor : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half4 _MainTex_TexelSize;
			// x: offsetU, y: offsetY, z: pathIndex
			float3 _Params;
			float _Attenuation;
			float _Iteration;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.pathFactor = pow(4, _Params.z);
				o.uvOffset = half2(_Params.x, _Params.y) * _MainTex_TexelSize.xy * o.pathFactor;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = half4(0, 0, 0, 1);

				half2 uv = i.uv;
				for (int j = 0; j < _Iteration; ++j) {
					col.rgb += tex2D(_MainTex, uv) * pow(_Attenuation, j * i.pathFactor);
					uv += i.uvOffset;
				}
				return col;
			}
			ENDCG
		}

		// addtional scene color
		Pass
		{
			Blend One One
			ColorMask RGB
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

			sampler2D _MainTex; float4 _MainTex_ST;
			float _Intensity;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return tex2D(_MainTex, i.uv) * _Intensity / 2;
			}
			ENDCG
		}
	}
}
