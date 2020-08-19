
/*
   NOTES: see CameraMotionBlur.shader
*/

Shader "Hidden/PostProcess/CameraMotionBlurDX11" 
{
	Properties
	{
		_MainTex("-", 2D) = "" {}
		_NoiseTex("-", 2D) = "grey" {}
		_VelTex("-", 2D) = "black" {}
		_NeighbourMaxTex("-", 2D) = "black" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "CameraMotionBlurUtil.cginc"

	#define NUM_SAMPLES (19)


	// pass 0
	float4 TileMax(v2f i) : SV_Target
	{
		float2 tilemax = float2(0.0, 0.0);
		float2 srcPos = i.uv - _MainTex_TexelSize.xy * _MaxRadiusOrKInPaper * 0.5;

		for (int y = 0; y < (int)_MaxRadiusOrKInPaper; y++) 
		{
			for (int x = 0; x < (int)_MaxRadiusOrKInPaper; x++) 
			{
				float2 v = tex2D(_MainTex, srcPos + float2(x,y) * _MainTex_TexelSize.xy).xy;
				tilemax = VectorMax(tilemax, v);
			}
		}
		return float4(tilemax, 0, 1);
	}

	// pass 1
	float4 NeighbourMax(v2f i) : SV_Target
	{
		float2 maxvel = float2(0.0, 0.0);
		for (int y = -1; y <= 1; y++) 
		{
			for (int x = -1; x <= 1; x++) 
			{
				float2 v = tex2D(_MainTex, i.uv + float2(x,y) * _MainTex_TexelSize.xy).xy;
				maxvel = VectorMax(maxvel, v);
			}
		}
		return float4(maxvel, 0, 1);
	}

	// pass 2
	float4 ReconstructFilterBlur(v2f i) : SV_Target
	{
		float2 x = i.uv;
		float2 xf = x;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
		{
			xf.y = 1 - xf.y;
		}
#endif

		float2 x2 = xf;
		float2 vn = tex2D(_NeighbourMaxTex, x2).xy;	// largest velocity in neighbourhood
		float4 cx = tex2D(_MainTex, x);				// color at x

		float zx = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, x);
		zx = -Linear01Depth(zx);					// depth at x
		float2 vx = tex2D(_VelTex, xf).xy;			// vel at x 

		// random offset [-0.5, 0.5]
		float j = (tex2D(_NoiseTex, i.uv * 11.0f).r * 2 - 1) * _Jitter;

		// sample current pixel
		float weight = 1.0;
		float4 sum = cx * weight;

		int centerSample = (int)(NUM_SAMPLES - 1) / 2;

		for (int l = 0; l < NUM_SAMPLES; l++)
		{
			if (l == centerSample)
			{
				continue;
			}

			// Choose evenly placed filter taps along +-vN,
			// but jitter the whole filter to prevent ghosting			
			float t = lerp(-1.0, 1.0, (l + j) / (-1 + _Jitter + (float)NUM_SAMPLES));

			float2 velInterlaved = lerp(vn, min(vx, normalize(vx) * _MainTex_TexelSize.xy * _MaxRadiusOrKInPaper), l % 2 == 0);
			float2 y = x + velInterlaved * t;

			float2 yf = y;
#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
			{
				yf.y = 1 - yf.y;
			}
#endif

			// velocity at y 
			float2 vy = tex2Dlod(_VelTex, float4(yf,0,0)).xy;
			float zy = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(y,0,0));
			zy = -Linear01Depth(zy);
			float f = SoftDepthCompare(zx, zy);
			float b = SoftDepthCompare(zy, zx);
			float alphay = f * Cone(y, x, vy) +	// blurry y in front of any x
						   b * Cone(x, y, vx) +	// any y behing blurry x; estimate background
						   Cylinder(y, x, vy) * Cylinder(x, y, vx) * 2.0;	// simultaneous blurry x and y

			float4 cy = tex2Dlod(_MainTex, float4(y,0,0));
			sum += cy * alphay;
			weight += alphay;
		}
		sum /= weight;
		return sum;
	}
	ENDCG

	SubShader 
	{
		// pass 0
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment TileMax
			ENDCG
		}

		// pass 1
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment NeighbourMax
			ENDCG
		}

		// pass 2
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert 
			#pragma fragment ReconstructFilterBlur
			ENDCG
		}
	}
}
