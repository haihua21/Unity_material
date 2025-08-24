#ifndef UNIVERSAL_INPUT_SURFACE_INCLUDED
#define UNIVERSAL_INPUT_SURFACE_INCLUDED

#include "/include/CustomCore.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

TEXTURE2D(_CustomMap1);         SAMPLER(sampler_CustomMap1);//leo5

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);        SAMPLER(sampler_EmissionMap);

// Must match Universal ShaderGraph master node
struct SurfaceData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half  smoothness;
    half  sharpness;//leo
    half  v1;//leo5
    half  v2;//leo7
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
    half smask;//leo7
};

///////////////////////////////////////////////////////////////////////////////
//                      Material Property Helpers                            //
///////////////////////////////////////////////////////////////////////////////
half Alpha(half albedoAlpha, half4 color, half cutoff)
{
#if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
    half alpha = albedoAlpha * color.a;
#else
    half alpha = color.a;
#endif

#if defined(_ALPHATEST_ON)
    clip(alpha - cutoff);
#endif

    return alpha;
}

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
}

half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
{
#ifdef _NORMALMAP
    half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
    #if BUMP_SCALE_NOT_SUPPORTED
        return UnpackNormal(n);
    #else
        return UnpackNormalScale(n, scale);
    #endif
#else
    return half3(0.0h, 0.0h, 1.0h);
#endif
}

half3 SampleEmission(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap))
{
#ifndef _EMISSION
    return 0;
#else
    return SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv).rgb * emissionColor;
#endif
}

#endif

float2 SampleCustomMap(float2 uv, half uParallaxDepthOffset, float3 tangentEye, TEXTURE2D_PARAM(mixMap, sampler_mixMap))//leo5
{
    float3 dir = tangentEye;
    float2 maxOffset = dir.xy * (uParallaxDepthOffset / (abs(dir.z) + 0.001));
    
    float samples = saturate(3.0 * length(maxOffset));
    float incr = rcp(16) ;
    float2 tc0 = uv;
    
    float h0 = 1 - SAMPLE_TEXTURE2D(mixMap, sampler_mixMap,tc0).r;
    
    [unroll(16)]
    for (float i = incr; i <= 1.0; i += incr)
        {
            float2 tc = tc0 + maxOffset * i;
            float h1 = 1 - SAMPLE_TEXTURE2D(mixMap, sampler_mixMap,tc).r;

            if (i >= h1)
            {
						    //hit! now interpolate
                float r1 = i, r0 = i - incr;
                float t = (h0 - r0) / ((h0 - r0) + (-h1 + r1));
                float r = (r0 - t * r0) + t * r1;
                uv = tc0 + r * maxOffset;
                break;
            }
            h0 = h1;
        }
    
    return uv;
    
}

half SampleCustomMapToMask(float2 uv, TEXTURE2D_PARAM(mixMap, sampler_mixMap))//leo6
{
    half samples =  1- (SAMPLE_TEXTURE2D(mixMap, sampler_mixMap,uv).r);
    
    return samples;
}


