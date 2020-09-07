Shader "Hidden/PostProcess/Glitch"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "GlitchUtil.hlsl"
	sampler2D _MainTex;
	half _BlockSize, _Speed, _MaxRGBSplitX, _MaxRGBSplitY;

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
		half2 block = RandomNoise(floor(i.uv * _BlockSize), _Speed);
		float displaceNoise = pow(block.x, 8.0) * pow(block.x, 3.0);
		float splitRGBNoise = pow(RandomNoise(7.2341, _Speed), 17.0);
		float offsetX = displaceNoise - splitRGBNoise * _MaxRGBSplitX;
		float offsetY = displaceNoise - splitRGBNoise * _MaxRGBSplitY;
		float noiseX = 0.05 * RandomNoise(14.0, _Speed);
		float noiseY = 0.05 * RandomNoise(7.0, _Speed);
		float2 offset = float2(offsetX * noiseX, offsetY* noiseY);
		half4 colorR = tex2D(_MainTex, i.uv);
		half4 colorG = tex2D(_MainTex, i.uv + offset);
		half4 colorB = tex2D(_MainTex, i.uv - offset);
		return half4(colorR.r , colorG.g, colorB.z, (colorR.a + colorG.a + colorB.a));
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
			ENDCG
		}
	}
}
