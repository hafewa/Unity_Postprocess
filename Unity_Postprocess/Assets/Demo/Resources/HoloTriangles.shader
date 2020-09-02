﻿Shader "Custom/HoloTriangles"
{
	Properties
	{
		_Color("Main Color", Color) = (0.2, 0.5, 1.0)
		_Speed("Speed", Range(0.01, 10)) = 1
		_TrianglesScale("Triangles Scale", Range(0.01, 10)) = 1
		_RangeScale("Range Scale", Range(0.01, 10)) = 1
		_Center("Center", Vector) = (0.0, -1.0, 3.0, 1.0)
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			//ZWrite Off
			//AlphaTest Greater 0
			//ColorMask RGB
			//Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#include "UnityCG.cginc"

			#define pi 3.14159265358979
			#define reciproce_sqrt3 0.57735026918962576450914878050196

			half3 _Color;
			float _Speed;
			float _TrianglesScale;
			float _RangeScale;
			float4 _Center;
			float planeDistance = 0.2;
			float offset;

			struct VSInput
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct VSOutput
			{
				float4 vertex : SV_POSITION;
				float4 world : TEXCOORD1;
			};

			float r(float n)
			{
				return frac(abs(sin(n*55.753)*367.34));
			}

			float r(float2 n)
			{
				return r(dot(n, float2(2.46, -1.21)));
			}

			// SmallTrianglesColor
			float3 SmallTrianglesColor(float3 pos)
			{
				float a = (radians(60.0));
				float zoom = 0.125;
				//scaled coordinates
				float2 c = (pos.xy + float2(0.0, pos.z)) * float2(sin(a), 1.0) / _TrianglesScale;

				//Add rotations
				c = ((c + float2(c.y, 0.0)*cos(a)) / zoom) + float2(floor((c.x - c.y*cos(a)) / zoom * 4.0) / 4.0, 0.0);

				//Randomize type
				float type = (r(floor(c*4.0))*0.2 + r(floor(c*2.0))*0.3 + r(floor(c))*0.5);
				type += 0.3 * sin(_Time.y*5.0*type);

				float l = min(min((1.0 - (2.0 * abs(frac((c.x - c.y)*4.0) - 0.5))),
				(1.0 - (2.0 * abs(frac(c.y * 4.0) - 0.5)))),
				(1.0 - (2.0 * abs(frac(c.x * 4.0) - 0.5))));
				l = smoothstep(0.06, 0.04, l);

				return lerp(type, l, 0.3);
			}

			// LargeTrianglesColor
			float3 LargeTrianglesColor(float3 pos)
			{
				float a = (radians(60.0));
				float zoom = 0.5;
				//scaled coordinates
				float2 c = (pos.xy + float2(0.0, pos.z)) * float2(sin(a), 1.0) / _TrianglesScale;

				//Add rotations
				c = ((c + float2(c.y, 0.0)*cos(a)) / zoom) + float2(floor((c.x - c.y*cos(a)) / zoom * 4.0) / 4.0, 0.0);

				float l = min(min((1.0 - (2.0 * abs(frac((c.x - c.y)*4.0) - 0.5))),
				(1.0 - (2.0 * abs(frac(c.y * 4.0) - 0.5)))),
				(1.0 - (2.0 * abs(frac(c.x * 4.0) - 0.5))));
				l = smoothstep(0.03, 0.02, l);

				return lerp(0.01, l, 1.0);
			}

			//---------------------------------------------------------------
			// Material 
			// Defines the material (colors, shading, pattern, texturing) of the model
			// at every point based on its position and normal. In this case, it simply
			// returns a constant yellow color.
			//------------------------------------------------------------------------
			float3 DoMaterial(in float3 pos, in float3 midPos)
			{
				float d = length(pos.xz - midPos.xz) + pos.y - midPos.y;
				d /= _RangeScale;
				float border = fmod(_Time.y * _Speed, 5.0);
				float3 c1 = LargeTrianglesColor(pos);
				float3 c2 = SmallTrianglesColor(pos);
				// Small rim
				float3 c = float3(1.0, 1.0, 1.0) * smoothstep(border - 0.2, border, d);
				// Large Triangles to all
				c += c1;
				// Small triangle slightly after front
				c += c2 * smoothstep(border - 0.4, border - 0.6, d);
				// Cutoff front
				c *= smoothstep(border, border - 0.05, d);
				// Cutoff back
				c *= smoothstep(border - 3.0, border - 0.5, d);
				// fade out
				c *= smoothstep(5.0, 4.0, border);
				return c * _Color;
			}

			VSOutput VSMain(VSInput v)
			{
				VSOutput o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.world = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			fixed4 PSMain(VSOutput i) : SV_Target
			{
				return float4(DoMaterial(i.world.xyz, _Center.xyz), 1.0);
			}
			ENDCG
		}
	}
}