
Shader "Hidden/PostProcess/Fog"
{
	Properties
	{
		_MainTex("Texture", 2D) = "black" {}
	}

	CGINCLUDE

	#include "UnityCG.cginc"
	#define SKYBOX_THREASHOLD_VALUE 0.999999

	sampler2D _MainTex; sampler2D _NoiseTex; sampler2D _CameraDepthTexture;


	// x = fog height
	// y = FdotC (CameraY-FogHeight)
	// z = k (FdotC > 0.0)
	// w = a/2
	float4 _HeightParams;
	#define _FogHeight _HeightParams.x
	#define _FdotC _HeightParams.y
	#define _FogNear _HeightParams.z
	#define _FogDensity _HeightParams.w

	// x = start distance
	// y = end distance
	float4 _DistanceParams;
	#define _StartDistance _DistanceParams.x
	#define _EndDistance _DistanceParams.y

	float4x4 _FrustumCornersWS;
	float4 _MainTex_TexelSize;
	float4 _CameraWorldSpase;
	float4 _FogColor;
	float2 _ScrollSpeed;
	half _FogNoiseScale;

	struct VSInput
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct VSOutput
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv_depth : TEXCOORD1;
		float4 interpolatedRay : TEXCOORD2;
	};

	float ComputeFog(float z)
	{
		half fog = 0.0;
		fog = (_StartDistance - z) / (_EndDistance - _StartDistance);
		return saturate(fog);
	}

	float ComputeDistance(float3 wsDir, float depth)
	{
		float dist = depth * wsDir.z;
		dist -= wsDir.y;
		return dist;
	}

	float ComputeHalfSpace(float3 wsDir)
	{
		float3 wpos = _CameraWorldSpase + wsDir;
		float FH = _FogHeight;
		float3 C = _CameraWorldSpase;
		float3 V = wsDir;
		float3 P = wpos;
		float3 aV = _FogDensity * V;
		float FdotC = _FdotC;
		float k = _FogNear;
		float FdotP = P.y - FH;
		float FdotV = wsDir.y;
		float c1 = k * (FdotP + FdotC);
		float c2 = (1 - 2 * k) * FdotP;
		float g = min(c2, 0.0);
		g = -length(aV) * (c1 - g * g / abs(FdotV + 1.0e-5f));
		return g;
	}

	VSOutput VSMain(VSInput v)
	{
		VSOutput o;
		half index = v.vertex.z;
		v.vertex.z = 0.1;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv.xy;
		o.uv_depth = v.uv.xy;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
		{
			o.uv.y = 1 - o.uv.y;
		}
#endif				
		o.interpolatedRay = _FrustumCornersWS[(int)index];
		o.interpolatedRay.w = index;
		return o;
	}

	float4 PSMain(VSOutput i) : SV_Target
	{
		float4 color = tex2D(_MainTex, i.uv);
		float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
		float depth = Linear01Depth(rawDepth);

		float4 wsDir = depth * i.interpolatedRay;
		float skybox = depth < SKYBOX_THREASHOLD_VALUE;
		float4 wsPos = _CameraWorldSpase + wsDir;

		float2 value = (wsPos.xz / _FogNoiseScale + _ScrollSpeed);
		half4 noiseColor = tex2D(_NoiseTex, value);
		half fogNoise = noiseColor.r;
		half fog = 0;

#ifdef DISTANCE_FOG
		fog = 1.0 - ComputeFog(ComputeDistance(wsPos.xyz, depth));
		return lerp(color, _FogColor, skybox * fog * _FogColor.a * fogNoise);

#elif HEIGHT_FOG
		fog = max(ComputeHalfSpace(wsDir.xyz), 0.0f);
		float4 finalColor = _FogColor + noiseColor;
		return lerp(color, finalColor, skybox * fog);
#endif

	}
	ENDCG


	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma multi_compile DISTANCE_FOG HEIGHT_FOG
			ENDCG
		}

	}
}
