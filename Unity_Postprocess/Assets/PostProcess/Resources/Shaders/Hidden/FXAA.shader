Shader "Hidden/PostProcess/FXAA"
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
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment PSMain
			#include "UnityCG.cginc"

			sampler2D _MainTex; float4 _MainTex_TexelSize;

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
				// Luminance
				half3 luma = half3(0.30, 0.59, 0.11);
				float4 offset = float4(_MainTex_TexelSize.xy, -_MainTex_TexelSize.xy) * 0.5;
				half yNW = dot(tex2D(_MainTex, i.uv + offset.zy).rgb, luma);
				half yNE = dot(tex2D(_MainTex, i.uv + offset.xy).rgb, luma);
				half ySW = dot(tex2D(_MainTex, i.uv + offset.zw).rgb, luma);
				half ySE = dot(tex2D(_MainTex, i.uv + offset.xw).rgb, luma);
				yNE += 1e-4;

				// Edge
				float2 dir1 = float2(ySW + ySE - (yNW + yNE), yNW + ySW - (yNE + ySE));
				dir1 = normalize(dir1);
				float2 dir2 = clamp(dir1 / (min(abs(dir1.x), abs(dir1.y)) * 8.0), -2.0, 2.0);
				dir1 *= _MainTex_TexelSize.xy * 0.5;
				dir2 *= _MainTex_TexelSize.xy * 2.0;

				// Gradient
				fixed3 rgbP1 = tex2D(_MainTex, i.uv + dir1).rgb;
				fixed3 rgbN1 = tex2D(_MainTex, i.uv - dir1).rgb;
				fixed3 rgbP2 = tex2D(_MainTex, i.uv + dir2).rgb;
				fixed3 rgbN2 = tex2D(_MainTex, i.uv - dir2).rgb;
				fixed3 rgbA = (rgbP1 + rgbN1) * 0.5;
				fixed3 rgbB = (rgbP1 + rgbN1 + rgbP2 + rgbN2) * 0.25;

				// Color
				half yB = dot(rgbB, luma);
				half yMin = min(min(yNW, yNE), min(ySW, ySE));
				half yMax = max(max(yNW, yNE), max(ySW, ySE));
				fixed4 color = fixed4((yB < yMin || yB > yMax) ? rgbA : rgbB, 1.0);
				return color;
			}

			ENDCG
		}
	}
}
