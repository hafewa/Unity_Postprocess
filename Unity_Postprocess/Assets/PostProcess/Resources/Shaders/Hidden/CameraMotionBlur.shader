/*
	CAMERA MOTION BLUR IMAGE EFFECTS
	Reconstruction Filter:
	Based on "Plausible Motion Blur"
	http://graphics.cs.williams.edu/papers/MotionBlurI3D12/
	CameraMotion:
	Based on Alex Vlacho's technique in
	http://www.valvesoftware.com/publications/2008/GDC2008_PostProcessingInTheOrangeBox.pdf
	SimpleBlur:
	Straightforward sampling along velocities
	ScatterFromGather:
	Combines Reconstruction with depth of field type defocus
*/

Shader "Hidden/PostProcess/CameraMotionBlur" 
{
	Properties
	{
		_MainTex("-", 2D) = "white" {}
		_NoiseTex("-", 2D) = "grey" {}
		_VelTex("-", 2D) = "black" {}
		_NeighbourMaxTex("-", 2D) = "black" {}
	}

	CGINCLUDE

	#include "UnityCG.cginc"
	#include "CameraMotionBlurUtil.cginc"
	#define NUM_SAMPLES (11)
	#define MOTION_SAMPLES (16)
	float _MaxRadiusOrKInPaper;

	static const int SmallDiscKernelSamples = 12;
	static const float2 SmallDiscKernel[SmallDiscKernelSamples] =
	{
		float2(-0.326212,-0.40581),
		float2(-0.840144,-0.07358),
		float2(-0.695914,0.457137),
		float2(-0.203345,0.620716),
		float2(0.96234,-0.194983),
		float2(0.473434,-0.480026),
		float2(0.519456,0.767022),
		float2(0.185461,-0.893124),
		float2(0.507431,0.064425),
		float2(0.89642,0.412458),
		float2(-0.32194,-0.932615),
		float2(-0.791559,-0.59771)
	};

	sampler2D _MainTex;
	sampler2D _CameraDepthTexture;
	sampler2D _VelTex;
	sampler2D _NeighbourMaxTex;
	sampler2D _NoiseTex;
	sampler2D _TileTexDebug;

	float4 _MainTex_TexelSize;
	float4 _CameraDepthTexture_TexelSize;
	float4 _VelTex_TexelSize;

	// inverse view-projection matrix
	float4x4 _InvViewProj;

	// previous view-projection matrix
	float4x4 _PrevViewProj;

	// combined
	float4x4 _ToPrevViewProjCombined;

	half _Jitter, _VelocityScale, _DisplayVelocityScale;
	half _MaxVelocity, _MinVelocity;

	float4 _BlurDirectionPacked;

	// pass 0
	half4 CameraVelocity(v2f i) : SV_Target
	{
		float2 depth_uv = i.uv;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
		{
			depth_uv.y = 1 - depth_uv.y;
		}
#endif

		float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, depth_uv);
		float3 clipPos = float3(i.uv.x*2.0 - 1.0, (i.uv.y)*2.0 - 1.0, d);

		// only 1 matrix mul:
		float4 prevClipPos = mul(_ToPrevViewProjCombined, float4(clipPos, 1.0));
		prevClipPos.xyz /= prevClipPos.w;

		float2 vel = _MainTex_TexelSize.zw * _VelocityScale * (clipPos.xy - prevClipPos.xy) / 2.f;
		float vellen = length(vel);
		float maxVel = _MaxVelocity;
		float2 velOut = vel * max(0.5, min(vellen, maxVel)) / (vellen + 1e-2f);
		velOut *= _MainTex_TexelSize.xy;
		return float4(velOut, 0.0, 0.0);
	}

	// pass 1
	half4 TileMax(v2f i) : SV_Target
	{
		float2 uvCorner = i.uv - _MainTex_TexelSize.xy * (_MaxRadiusOrKInPaper * 0.5);
		float2 maxvel = float2(0,0);
		float4 baseUv = float4(uvCorner,0,0);
		float4 uvScale = float4(_MainTex_TexelSize.xy, 0, 0);

		for (int l = 0; l < (int)_MaxRadiusOrKInPaper; l++)
		{
			for (int k = 0; k < (int)_MaxRadiusOrKInPaper; k++)
			{
				maxvel = VectorMax(maxvel, tex2Dlod(_MainTex, baseUv + float4(l,k,0,0) * uvScale).xy);
			}
		}
		return float4(maxvel, 0, 1);
	}

	// pass 2
	half4 NeighbourMax(v2f i) : SV_Target
	{
		float2 x_ = i.uv;
		float2 nx = tex2D(_MainTex, x_ + float2(1.0, 1.0)*_MainTex_TexelSize.xy).xy;
		nx = VectorMax(nx, tex2D(_MainTex, x_ + float2(1.0, 0.0)*_MainTex_TexelSize.xy).xy);
		nx = VectorMax(nx, tex2D(_MainTex, x_ + float2(1.0,-1.0)*_MainTex_TexelSize.xy).xy);
		nx = VectorMax(nx, tex2D(_MainTex, x_ + float2(0.0, 1.0)*_MainTex_TexelSize.xy).xy);
		nx = VectorMax(nx, tex2D(_MainTex, x_ + float2(0.0, 0.0)*_MainTex_TexelSize.xy).xy);
		nx = VectorMax(nx, tex2D(_MainTex, x_ + float2(0.0,-1.0)*_MainTex_TexelSize.xy).xy);
		nx = VectorMax(nx, tex2D(_MainTex, x_ + float2(-1.0, 1.0)*_MainTex_TexelSize.xy).xy);
		nx = VectorMax(nx, tex2D(_MainTex, x_ + float2(-1.0, 0.0)*_MainTex_TexelSize.xy).xy);
		nx = VectorMax(nx, tex2D(_MainTex, x_ + float2(-1.0,-1.0)*_MainTex_TexelSize.xy).xy);

		return float4(nx, 0, 0);
	}

	// pass 3
	half4 ReconstructFilterBlur(v2f i) : SV_Target
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

		// largest velocity in neighbourhood
		float2 vn = tex2Dlod(_NeighbourMaxTex, float4(x2,0,0)).xy;

		// color at x
		float4 cx = tex2Dlod(_MainTex, float4(x,0,0));

		// velocity at x 
		float2 vx = tex2Dlod(_VelTex, float4(xf,0,0)).xy;

		float zx = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(x,0,0));
		zx = -Linear01Depth(zx);

		// random offset [-0.5, 0.5]
		float j = (tex2Dlod(_NoiseTex, float4(i.uv,0,0) * 11.0f).r * 2 - 1) * _Jitter;

		// sample current pixel
		float weight = 0.75; // <= good start weight choice
		float4 sum = cx * weight;

		int centerSample = (int)(NUM_SAMPLES - 1) / 2;

		for (int l = 0; l < NUM_SAMPLES; l++)
		{
			float contrib = 1.0f;
#if SHADER_API_D3D11
			if (l == centerSample)
			{
				continue;
			}
#else
			if (l == centerSample)
			{
				contrib = 0.0f;
			}
#endif

			float t = lerp(-1.0, 1.0, (l + j) / (-1 + _Jitter + (float)NUM_SAMPLES));

			float2 y = x + vn * t;

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
			float alphay = b * Cone(x, y, vx) + f * Cone(y, x, vy) + Cylinder(y, x, vy) * Cylinder(x, y, vx) * 2.0;

			float4 cy = tex2Dlod(_MainTex, float4(y,0,0));
			sum += cy * alphay * contrib;
			weight += alphay * contrib;
		}
		sum /= weight;
		return sum;
	}

	// pass 4
	half4 SimpleBlur(v2f i) : SV_Target
	{
		float2 x = i.uv;
		float2 xf = x;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
		{
			xf.y = 1 - xf.y;
		}
#endif

		// velocity at x
		float2 vx = tex2D(_VelTex, xf).xy;
		float4 sum = float4(0, 0, 0, 0);

		for (int l = 0; l < NUM_SAMPLES; l++)
		{
			float t = l / (float)(NUM_SAMPLES - 1);
			t = t - 0.5;
			float2 y = x - vx * t;
			float4 cy = tex2D(_MainTex, y);
			sum += cy;
		}
		sum /= NUM_SAMPLES;
		return sum;
	}

	// pass 5
	half4 MotionVectorBlur(v2f i) : SV_Target
	{
		float2 x = i.uv;
		float2 insideVector = (x * 2 - 1) * float2(1,_MainTex_TexelSize.w / _MainTex_TexelSize.z);
		float2 rollVector = float2(insideVector.y, -insideVector.x);

		float2 blurDir = _BlurDirectionPacked.x * float2(0,1);
		blurDir += _BlurDirectionPacked.y * float2(1,0);
		blurDir += _BlurDirectionPacked.z * rollVector;
		blurDir += _BlurDirectionPacked.w * insideVector;
		blurDir *= _VelocityScale;

		// clamp to maximum velocity (in pixels)
		float velMag = length(blurDir);
		if (velMag > _MaxVelocity)
		{
			blurDir *= (_MaxVelocity / velMag);
			velMag = _MaxVelocity;
		}

		float4 centerTap = tex2D(_MainTex, x);
		float4 sum = centerTap;
		blurDir *= smoothstep(_MinVelocity * 0.25f, _MinVelocity * 2.5, velMag);
		blurDir *= _MainTex_TexelSize.xy;
		blurDir /= MOTION_SAMPLES;

		for (int i = 0; i < MOTION_SAMPLES; i++)
		{
			float4 tap = tex2D(_MainTex, x + i * blurDir);
			sum += tap;
		}
		return sum / (1 + MOTION_SAMPLES);
	}

	// pass 6
	half4 ReconstructionDiscBlur(v2f i) : SV_Target
	{
		float2 xf = i.uv;
		float2 x = i.uv;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
		{
			xf.y = 1 - xf.y;
		}
#endif

		float2 x2 = xf;
		float2 vn = tex2Dlod(_NeighbourMaxTex, float4(x2,0,0)).xy;
		float4 cx = tex2Dlod(_MainTex, float4(x,0,0));
		float2 vx = tex2Dlod(_VelTex, float4(xf,0,0)).xy; 

		float4 noise = tex2Dlod(_NoiseTex, float4(i.uv,0,0)*11.0f) * 2 - 1;
		float zx = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(x,0,0));
		zx = -Linear01Depth(zx);
		noise *= _MainTex_TexelSize.xyxy * _Jitter;

		float weight = 1.0; // <- tweak this: bluriness amount ...
		float4 sum = cx * weight;
		float4 jitteredDir = vn.xyxy + noise.xyyz;

#ifdef SHADER_API_D3D11
		jitteredDir = max(abs(jitteredDir.xyxy), _MainTex_TexelSize.xyxy * _MaxVelocity * 0.5) * sign(jitteredDir.xyxy)  * float4(1,1,-1,-1);
#else
		jitteredDir = max(abs(jitteredDir.xyxy), _MainTex_TexelSize.xyxy * _MaxVelocity * 0.15) * sign(jitteredDir.xyxy)  * float4(1,1,-1,-1);
#endif

		for (int l = 0; l < SmallDiscKernelSamples; l++)
		{
			float4 y = i.uv.xyxy + jitteredDir.xyxy * SmallDiscKernel[l].xyxy * float4(1,1,-1,-1);
			float4 yf = y;
#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
			{
				yf.yw = 1 - yf.yw;
			}
#endif

			// velocity at y 
			float2 vy = tex2Dlod(_VelTex, float4(yf.xy,0,0)).xy;

			float zy = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(y.xy,0,0));
			zy = -Linear01Depth(zy);

			float f = SoftDepthCompare(zx, zy);
			float b = SoftDepthCompare(zy, zx);
			float alphay = b * Cone(x, y.xy, vx) + f * Cone(y.xy, x, vy) + Cylinder(y.xy, x, vy) * Cylinder(x, y.xy, vx) * 2.0;
			float4 cy = tex2Dlod(_MainTex, float4(y.xy,0,0));
			sum += cy * alphay;
			weight += alphay;

#ifdef SHADER_API_D3D11
			vy = tex2Dlod(_VelTex, float4(yf.zw,0,0)).xy;
			zy = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(y.zw,0,0));
			zy = -Linear01Depth(zy);

			f = SoftDepthCompare(zx, zy);
			b = SoftDepthCompare(zy, zx);
			alphay = b * Cone(x, y.zw, vx) + f * Cone(y.zw, x, vy) + Cylinder(y.zw, x, vy) * Cylinder(x, y.zw, vx) * 2.0;

			cy = tex2Dlod(_MainTex, float4(y.zw,0,0));
			sum += cy * alphay;
			weight += alphay;
#endif
		}
		return sum / weight;
	}

	ENDCG

	SubShader 
	{
		ZTest Always Cull Off ZWrite On Blend Off

		// pass 0
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment CameraVelocity
			ENDCG
		}

		// pass 1
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment TileMax
			ENDCG
		}

		// pass 2
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment NeighbourMax
			ENDCG
		}

		// pass 3
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert 
			#pragma fragment ReconstructFilterBlur
			ENDCG
		}

		// pass 4
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment SimpleBlur
			ENDCG
		}

		// pass 5
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment MotionVectorBlur
			ENDCG
		}

		// pass 6
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment ReconstructionDiscBlur
			ENDCG
		}
	}
}
