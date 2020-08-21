Shader "Hidden/PostProcess/PlanarReflection" 
{
	Properties
	{
		_MainTex("Diffuse", 2D) = "white" {}
		_DepthScale("DepthScale", Float) = 1.0
		_DepthExponent("DepthExponent", Float) = 1.0
	}

	CGINCLUDE

	#include "UnityCG.cginc"
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;

	sampler2D _CameraDepthTexture;
	sampler2D _CameraDepthTextureCopy;

	float4 _FrustumCornersWS;
	float4 _CameraWS;
	float4 _PlaneReflectionClipPlane;
	float4 _PlaneReflectionZParams;

	half _DepthScale, _DepthExponent, _SampleMip, _CosPower, _RayPinchInfluence;


	struct VSOutput 
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 interpolatedRay	: TEXCOORD1;
		float3 interpolatedRayN	: TEXCOORD2;
	};

	VSOutput VSMain(appdata_img v)
	{
		VSOutput o;
		half index = v.vertex.z;
		v.vertex.z = 0.1;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord;
		o.interpolatedRay = _FrustumCornersWS[(int)index];
		o.interpolatedRay.w = index;
		o.interpolatedRayN = normalize(o.interpolatedRay.xyz);
		return o;
	}

	float4 frag(VSOutput i, const float2 dir)
	{
		float4 baseUV;
		baseUV.xy = i.uv.xy;
		baseUV.z = 0;
		baseUV.w = _SampleMip;

#if USE_DEPTH
		//	float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
		//	float depth = 1.f / (rawDepth * _PlaneReflectionZParams.x + _PlaneReflectionZParams.y);
		float depth = tex2D(_CameraDepthTextureCopy, i.uv);
		float3 wsDir = depth * i.interpolatedRay.xyz;
		float4 wsPos = float4(_CameraWS.xyz + wsDir, 1.f);
		float pointToPlaneDist = dot(wsPos, _PlaneReflectionClipPlane) / dot(_PlaneReflectionClipPlane.xyz, normalize(i.interpolatedRayN));
		float sampleScale1 = saturate(pow(saturate(pointToPlaneDist * _DepthScale), _DepthExponent));
		sampleScale1 = max(_RayPinchInfluence, sampleScale1);
#else
		float sampleScale1 = 1.f;
#endif
		float2 sampleScale = dir * _MainTex_TexelSize.xy * sampleScale1;

		float weight = 0.f;
		float4 color = 0.f;
		float4 uv = baseUV;

		for (int i = -32; i <= 32; i += 2) 
		{
			float2 off = i * sampleScale;
			uv.xy = baseUV.xy + off;

			// Kill any samples falling outside of the screen.
			// Otherwise, as a bright source pixel touches the edge of the screen, it suddenly
			// gets exploded by clamping to have the width/height equal to kernel's radius
			// and introduces that much more energy to the result.
			if (any(uv.xy < 0.0) || any(uv.xy > 1.0))
			{
				continue;
			}

			float4 s = tex2Dlod(_MainTex, uv);
			float c = clamp(i / 20.f, -1.57f, 1.57f);
			float w = pow(max(0.f, cos(c)), _CosPower);
			color.rgb += s.rgb * w;
			weight += w;
		}
		return color.rgbb / weight;
	}

	// pass 0
	float4 Horizontal(VSOutput i) : COLOR
	{
		return frag(i, float2(1.f, 0.f)); 
	}

	// pass 1
	float4 Vertical(VSOutput i) : COLOR
	{
		return frag(i, float2(0.f, 1.f)); 
	}
		
	// pass 2
	float Resolve(VSOutput i) : SV_Target
	{
		float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
		float depth = 1.f / (rawDepth * _PlaneReflectionZParams.x + _PlaneReflectionZParams.y);
		return depth;
	}

	ENDCG

	SubShader 
	{
		Cull Off ZTest Always ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment Horizontal
			#pragma multi_compile _ USE_DEPTH
			#pragma multi_compile _ CP0 CP1 CP2 CP3
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment Vertical
			#pragma multi_compile _ USE_DEPTH
			#pragma multi_compile _ CP0 CP1 CP2 CP3
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment Resolve
			ENDCG
		}
	}
}
