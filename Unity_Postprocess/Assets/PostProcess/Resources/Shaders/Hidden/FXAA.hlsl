#ifndef FXAA_INCLUDE
#define FXAA_INCLUDE


#ifndef FXAA_PC
	#define FXAA_PC 0
#endif

#ifndef FXAA_PC_CONSOLE
	#define FXAA_PC_CONSOLE 0
#endif

#ifndef FXAA_GLSL_120
	#define FXAA_GLSL_120 0
#endif

#ifndef FXAA_GLSL_130
	#define FXAA_GLSL_130 0
#endif

#ifndef FXAA_HLSL_3
	#define FXAA_HLSL_3 0
#endif

#ifndef FXAA_HLSL_4
	#define FXAA_HLSL_4 0
#endif    

#ifndef FXAA_HLSL_5
	#define FXAA_HLSL_5 0
#endif

#ifndef FXAA_EARLY_EXIT
	#define FXAA_EARLY_EXIT 1
#endif

#ifndef FXAA_DISCARD
	#define FXAA_DISCARD 0
#endif

#ifndef FXAA_CONSOLE__EDGE_THRESHOLD
	#if 1
		#define FXAA_CONSOLE__EDGE_THRESHOLD 0.125
	#else
		#define FXAA_CONSOLE__EDGE_THRESHOLD 0.25
	#endif        
#endif

#ifndef FXAA_CONSOLE__EDGE_THRESHOLD_MIN
	#define FXAA_CONSOLE__EDGE_THRESHOLD_MIN 0.05
#endif

#ifndef FXAA_QUALITY__EDGE_THRESHOLD
	#define FXAA_QUALITY__EDGE_THRESHOLD (1.0/6.0)
#endif

#ifndef FXAA_QUALITY__EDGE_THRESHOLD_MIN
	#define FXAA_QUALITY__EDGE_THRESHOLD_MIN (1.0/12.0)
#endif

#ifndef FXAA_QUALITY__SUBPIX
	#define FXAA_QUALITY__SUBPIX (3.0/4.0)
#endif

#ifndef FXAA_GATHER4_ALPHA
	#if (FXAA_HLSL_5 == 1)
		#define FXAA_GATHER4_ALPHA 1
	#endif
	#ifdef GL_ARB_gpu_shader5
		#define FXAA_GATHER4_ALPHA 1
	#endif
	#ifdef GL_NV_gpu_shader5
		#define FXAA_GATHER4_ALPHA 1
	#endif
	#ifndef FXAA_GATHER4_ALPHA
		#define FXAA_GATHER4_ALPHA 0
	#endif
#endif

#ifndef FXAA_CONSOLE__EDGE_SHARPNESS
	#if 1 
		#define FXAA_CONSOLE__EDGE_SHARPNESS 8.0
	#endif
	#if 0
		#define FXAA_CONSOLE__EDGE_SHARPNESS 4.0
	#endif
	#if 0
		#define FXAA_CONSOLE__EDGE_SHARPNESS 2.0
	#endif
#endif

#ifndef FXAA_CONSOLE__EDGE_THRESHOLD
	#if 1
		#define FXAA_CONSOLE__EDGE_THRESHOLD 0.125
	#else
		#define FXAA_CONSOLE__EDGE_THRESHOLD 0.25
	#endif        
#endif


float4 luma(float4 color)
{
	color.a = dot(color.rgb, float3(0.299f, 0.587f, 0.114f));
	return color;
}

#define int2 float2
#define FxaaInt2 float2
#define FxaaFloat2 float2
#define FxaaFloat3 float3
#define FxaaFloat4 float4
#define FxaaTexTop(t, p) luma(tex2Dlod(t, float4(p, 0.0, 0.0)))
#define FxaaTexOff(t, p, o, r) luma(tex2Dlod(t, float4(p + (o * r), 0, 0)))

// PSMain_Speed
half4 PSMain_Speed(float2 pos, float4 posPos, sampler2D tex, float2 fxaaFrame, float4 fxaaFrameOpt)
{
	half4 dir;
	dir.y = 0.0;
	half4 lumaNe = FxaaTexTop(tex, posPos.zy); 
	lumaNe.w += half(1.0/384.0);
	dir.x = -lumaNe.w;
	dir.z = -lumaNe.w;

	half4 lumaSw = FxaaTexTop(tex, posPos.xw);
	dir.x += lumaSw.w;
	dir.z += lumaSw.w;

	half4 lumaNw = FxaaTexTop(tex, posPos.xy);
	dir.x -= lumaNw.w;
	dir.z += lumaNw.w;

	half4 lumaSe = FxaaTexTop(tex, posPos.zw);
	dir.x += lumaSe.w;
	dir.z -= lumaSe.w;

#if (FXAA_EARLY_EXIT == 1)
	half4 rgbyM = FxaaTexTop(tex, pos.xy);
	half lumaMin = min(min(lumaNw.w, lumaSw.w), min(lumaNe.w, lumaSe.w));
	half lumaMax = max(max(lumaNw.w, lumaSw.w), max(lumaNe.w, lumaSe.w));
	half lumaMinM = min(lumaMin, rgbyM.w); 
	half lumaMaxM = max(lumaMax, rgbyM.w); 
	if((lumaMaxM - lumaMinM) < max(FXAA_CONSOLE__EDGE_THRESHOLD_MIN, lumaMax * FXAA_CONSOLE__EDGE_THRESHOLD))
	#if (FXAA_DISCARD == 1)
		clip(-1);
	#else
		return rgbyM;
		//return float4(rgbyM.r, 0, 0, 1);
	#endif
#endif

	half4 dir1_pos;
	dir1_pos.xy = normalize(dir.xyz).xz;
	half dirAbsMinTimesC = min(abs(dir1_pos.x), abs(dir1_pos.y)) * half(FXAA_CONSOLE__EDGE_SHARPNESS);

	half4 dir2_pos;
	dir2_pos.xy = clamp(dir1_pos.xy / dirAbsMinTimesC, half(-2.0), half(2.0));
	dir1_pos.zw = pos.xy;
	dir2_pos.zw = pos.xy;
	half4 temp1N;
	temp1N.xy = dir1_pos.zw - dir1_pos.xy * fxaaFrameOpt.zw;

	temp1N = FxaaTexTop(tex, temp1N.xy); 
	half4 rgby1;
	rgby1.xy = dir1_pos.zw + dir1_pos.xy * fxaaFrameOpt.zw;
	rgby1 = FxaaTexTop(tex, rgby1.xy); 
	rgby1 = (temp1N + rgby1) * 0.5;

	half4 temp2N;
	temp2N.xy = dir2_pos.zw - dir2_pos.xy * fxaaFrameOpt.xy;
	temp2N = FxaaTexTop(tex, temp2N.xy); 

	half4 rgby2;
	rgby2.xy = dir2_pos.zw + dir2_pos.xy * fxaaFrameOpt.xy;
	rgby2 = FxaaTexTop(tex, rgby2.xy);
	rgby2 = (temp2N + rgby2) * 0.5; 

#if (FXAA_EARLY_EXIT == 0)
	half lumaMin = min(min(lumaNw.w, lumaSw.w), min(lumaNe.w, lumaSe.w));
	half lumaMax = max(max(lumaNw.w, lumaSw.w), max(lumaNe.w, lumaSe.w));
#endif
	rgby2 = (rgby2 + rgby1) * 0.5;

	if(rgby2.w < lumaMin || rgby2.w > lumaMax) 
	{
		rgby2 = rgby1;
	}
	return rgby2;
	//return float4(rgby2.r, 0, 0, 1);
}



float4 PSMain_Quality(float2 pos, float4 posPos, sampler2D tex, float2 fxaaFrame, float4 fxaaFrameOpt)
{   
	float2 posM;
	posM.x = pos.x;
	posM.y = pos.y;
#if (FXAA_GATHER4_ALPHA == 1)
	#if (FXAA_DISCARD == 0)
		float4 rgbyM = FxaaTexTop(tex, posM);
		#define lumaM rgbyM.w
		#endif
		float4 luma4A = FxaaTexAlpha4(tex, posM, fxaaFrame.xy);
		float4 luma4B = FxaaTexOffAlpha4(tex, posM, FxaaInt2(-1, -1), fxaaFrame.xy);
		#if (FXAA_DISCARD == 1)
			#define lumaM luma4A.w
		#endif
		#define lumaE luma4A.z
		#define lumaS luma4A.x
		#define lumaSE luma4A.y
		#define lumaNW luma4B.w
		#define lumaN luma4B.z
		#define lumaW luma4B.x
#else
	float4 rgbyM = FxaaTexTop(tex, posM);
	#define lumaM rgbyM.w
	float lumaS = FxaaTexOff(tex, posM, FxaaInt2(0, 1), fxaaFrame.xy).w;
	float lumaE = FxaaTexOff(tex, posM, FxaaInt2(1, 0), fxaaFrame.xy).w;
	float lumaN = FxaaTexOff(tex, posM, FxaaInt2(0,-1), fxaaFrame.xy).w;
	float lumaW = FxaaTexOff(tex, posM, FxaaInt2(-1,0), fxaaFrame.xy).w;
#endif

	float maxSM = max(lumaS, lumaM);
	float minSM = min(lumaS, lumaM);
	float maxESM = max(lumaE, maxSM); 
	float minESM = min(lumaE, minSM); 
	float maxWN = max(lumaN, lumaW);
	float minWN = min(lumaN, lumaW);
	float rangeMax = max(maxWN, maxESM);
	float rangeMin = min(minWN, minESM);
	float rangeMaxScaled = rangeMax * FXAA_QUALITY__EDGE_THRESHOLD;
	float range = rangeMax - rangeMin;
	float rangeMaxClamped = max(FXAA_QUALITY__EDGE_THRESHOLD_MIN, rangeMaxScaled);
	bool earlyExit = range < rangeMaxClamped;

	if(earlyExit) 
	{
		#if (FXAA_DISCARD == 1)
			clip(-1);
		#else
			return rgbyM;
			//return float4(rgbyM.r, 0, 0, 1);
		#endif
	}

	#if (FXAA_GATHER4_ALPHA == 0) 
		float lumaNW = FxaaTexOff(tex, posM, FxaaInt2(-1,-1), fxaaFrame.xy).w;
		float lumaSE = FxaaTexOff(tex, posM, FxaaInt2( 1, 1), fxaaFrame.xy).w;
		float lumaNE = FxaaTexOff(tex, posM, FxaaInt2( 1,-1), fxaaFrame.xy).w;
		float lumaSW = FxaaTexOff(tex, posM, FxaaInt2(-1, 1), fxaaFrame.xy).w;
	#else
		float lumaNE = FxaaTexOff(tex, posM, FxaaInt2(1, -1), fxaaFrame.xy).w;
		float lumaSW = FxaaTexOff(tex, posM, FxaaInt2(-1, 1), fxaaFrame.xy).w;
	#endif

	float lumaNS = lumaN + lumaS;
	float lumaWE = lumaW + lumaE;
	float subpixRcpRange = 1.0/range;
	float subpixNSWE = lumaNS + lumaWE;
	float edgeHorz1 = (-2.0 * lumaM) + lumaNS;
	float edgeVert1 = (-2.0 * lumaM) + lumaWE;

	float lumaNESE = lumaNE + lumaSE;
	float lumaNWNE = lumaNW + lumaNE;
	float edgeHorz2 = (-2.0 * lumaE) + lumaNESE;
	float edgeVert2 = (-2.0 * lumaN) + lumaNWNE;

	float lumaNWSW = lumaNW + lumaSW;
	float lumaSWSE = lumaSW + lumaSE;
	float edgeHorz4 = (abs(edgeHorz1) * 2.0) + abs(edgeHorz2);
	float edgeVert4 = (abs(edgeVert1) * 2.0) + abs(edgeVert2);
	float edgeHorz3 = (-2.0 * lumaW) + lumaNWSW;
	float edgeVert3 = (-2.0 * lumaS) + lumaSWSE;
	float edgeHorz = abs(edgeHorz3) + edgeHorz4;
	float edgeVert = abs(edgeVert3) + edgeVert4;

	float subpixNWSWNESE = lumaNWSW + lumaNESE; 
	float lengthSign = fxaaFrame.x;
	bool horzSpan = edgeHorz >= edgeVert;
	float subpixA = subpixNSWE * 2.0 + subpixNWSWNESE; 

	if (!horzSpan)
	{
		lumaN = lumaW;
		lumaS = lumaE;
	}
	float subpixB = (subpixA * (1.0/12.0)) - lumaM;

	float gradientN = lumaN - lumaM;
	float gradientS = lumaS - lumaM;
	float lumaNN = lumaN + lumaM;
	float lumaSS = lumaS + lumaM;
	bool pairN = abs(gradientN) >= abs(gradientS);
	float gradient = max(abs(gradientN), abs(gradientS));
	if(pairN) {lengthSign = -lengthSign;}

	float subpixC = saturate(abs(subpixB) * subpixRcpRange);

	float2 posB;
	posB.x = posM.x;
	posB.y = posM.y;
	float2 offNP;
	offNP.x = (!horzSpan) ? 0.0 : fxaaFrame.x;
	offNP.y = ( horzSpan) ? 0.0 : fxaaFrame.y;
	if(!horzSpan) {posB.x += lengthSign * 0.5;}
	if(horzSpan) {posB.y += lengthSign * 0.5;}

	float2 posN;
	posN.x = posB.x - offNP.x;
	posN.y = posB.y - offNP.y;

	float2 posP;
	posP.x = posB.x + offNP.x;
	posP.y = posB.y + offNP.y;
	float subpixD = ((-2.0)*subpixC) + 3.0;
	float lumaEndN = FxaaTexTop(tex, posN).w;
	float subpixE = subpixC * subpixC;
	float lumaEndP = FxaaTexTop(tex, posP).w;

	if(!pairN) {lumaNN = lumaSS;}
	float gradientScaled = gradient * 1.0/4.0;
	float lumaMM = lumaM - lumaNN * 0.5;
	float subpixF = subpixD * subpixE;
	bool lumaMLTZero = lumaMM < 0.0;

	lumaEndN -= lumaNN * 0.5;
	lumaEndP -= lumaNN * 0.5;
	bool doneN = abs(lumaEndN) >= gradientScaled;
	bool doneP = abs(lumaEndP) >= gradientScaled;
	if(!doneN) {posN.x -= offNP.x * 1.5;}
	if(!doneN) {posN.y -= offNP.y * 1.5;}

	bool doneNP = (!doneN) || (!doneP);
	if(!doneP) {posP.x += offNP.x * 1.5;}
	if(!doneP) {posP.y += offNP.y * 1.5;}
	if(doneNP) 
	{
		if(!doneN) {lumaEndN = FxaaTexTop(tex, posN.xy).w;}
		if(!doneP) {lumaEndP = FxaaTexTop(tex, posP.xy).w;}
		if(!doneN) {lumaEndN = lumaEndN - lumaNN * 0.5;}
		if(!doneP) {lumaEndP = lumaEndP - lumaNN * 0.5;}
		doneN = abs(lumaEndN) >= gradientScaled;
		doneP = abs(lumaEndP) >= gradientScaled;
		
		if(!doneN) {posN.x -= offNP.x * 2.0;}
		if(!doneN) {posN.y -= offNP.y * 2.0;}
		doneNP = (!doneN) || (!doneP);

		if(!doneP) {posP.x += offNP.x * 2.0;}
		if(!doneP) {posP.y += offNP.y * 2.0;}

		if(doneNP) 
		{
			if(!doneN) {lumaEndN = FxaaTexTop(tex, posN.xy).w;}
			if(!doneP) {lumaEndP = FxaaTexTop(tex, posP.xy).w;}
			if(!doneN) {lumaEndN = lumaEndN - lumaNN * 0.5;}
			if(!doneP) {lumaEndP = lumaEndP - lumaNN * 0.5;}
			doneN = abs(lumaEndN) >= gradientScaled;
			doneP = abs(lumaEndP) >= gradientScaled;

			if(!doneN) {posN.x -= offNP.x * 2.0;}
			if(!doneN) {posN.y -= offNP.y * 2.0;}
			doneNP = (!doneN) || (!doneP);

			if(!doneP) {posP.x += offNP.x * 2.0;}
			if(!doneP) {posP.y += offNP.y * 2.0;}
			if(doneNP) 
			{
				if(!doneN) {lumaEndN = FxaaTexTop(tex, posN.xy).w;}
				if(!doneP) {lumaEndP = FxaaTexTop(tex, posP.xy).w;}
				if(!doneN) {lumaEndN = lumaEndN - lumaNN * 0.5;}
				if(!doneP) {lumaEndP = lumaEndP - lumaNN * 0.5;}
				doneN = abs(lumaEndN) >= gradientScaled;
				doneP = abs(lumaEndP) >= gradientScaled;
				if(!doneN) {posN.x -= offNP.x * 4.0;}
				if(!doneN) {posN.y -= offNP.y * 4.0;}

				doneNP = (!doneN) || (!doneP);
				if(!doneP) {posP.x += offNP.x * 4.0;}
				if(!doneP) {posP.y += offNP.y * 4.0;}
				if(doneNP) 
				{
					if(!doneN) {lumaEndN = FxaaTexTop(tex, posN.xy).w;}
					if(!doneP) {lumaEndP = FxaaTexTop(tex, posP.xy).w;}
					if(!doneN) {lumaEndN = lumaEndN - lumaNN * 0.5;}
					if(!doneP) {lumaEndP = lumaEndP - lumaNN * 0.5;}
					doneN = abs(lumaEndN) >= gradientScaled;
					doneP = abs(lumaEndP) >= gradientScaled;
					if(!doneN) {posN.x -= offNP.x * 2.0;}
					if(!doneN) {posN.y -= offNP.y * 2.0;}
					if(!doneP) {posP.x += offNP.x * 2.0; }
					if(!doneP) {posP.y += offNP.y * 2.0; }
				} 
			} 
		} 
	}

	float dstN = posM.x - posN.x;
	float dstP = posP.x - posM.x;
	if (!horzSpan)
	{
		dstN = posM.y - posN.y;
		dstP = posP.y - posM.y;
	}

	bool goodSpanN = (lumaEndN < 0.0) != lumaMLTZero;
	float spanLength = (dstP + dstN);
	bool goodSpanP = (lumaEndP < 0.0) != lumaMLTZero;
	float spanLengthRcp = 1.0/spanLength;

	bool directionN = dstN < dstP;
	float dst = min(dstN, dstP);
	bool goodSpan = directionN ? goodSpanN : goodSpanP;
	float subpixG = subpixF * subpixF;
	float pixelOffset = (dst * (-spanLengthRcp)) + 0.5;
	float subpixH = subpixG * FXAA_QUALITY__SUBPIX;
	float pixelOffsetGood = goodSpan ? pixelOffset : 0.0;
	float pixelOffsetSubpix = max(pixelOffsetGood, subpixH);
	if(!horzSpan) 
	{
		posM.x += pixelOffsetSubpix * lengthSign;
	}
	else
	{
		posM.y += pixelOffsetSubpix * lengthSign;
	}

	half4 final = FxaaTexTop(tex, posM);
	return final; 
	//return float4(final.r, 0, 0, 1);
}

#endif
