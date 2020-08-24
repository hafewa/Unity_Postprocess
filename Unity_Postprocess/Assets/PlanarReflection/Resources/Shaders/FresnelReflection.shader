Shader "Custom/FresnelReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //_ReflectionTex ("ReflectionTexture", 2D) = "white" {}
		_Flesnel ("Flesnel", Range(0, 1)) = 0.02
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

		Blend SrcAlpha OneMinusSrcAlpha
 
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
				float3 normal : NORMAL;
			};
 
			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 projCoord : TEXCOORD1;
				float vdotn : TEXCOORD2;
			};
 
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _ReflectionTex;
			float4 _ReflectionTex_ST;
			float _Flesnel;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.projCoord = ComputeScreenPos(o.vertex);
                float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.vdotn = dot(viewDir, v.normal.xyz);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.projCoord));
				col.a = saturate(_Flesnel + (1 - _Flesnel) * pow(1 - i.vdotn, 5));
 
				return col;
			}
			ENDCG
        }
    }
}
