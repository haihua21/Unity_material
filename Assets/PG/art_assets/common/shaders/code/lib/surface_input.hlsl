#ifndef COM_SURFACE_INPUT_INCLUDED
#define COM_SURFACE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_EmissionMap);            SAMPLER(sampler_EmissionMap);
TEXTURE2D(_NormalMap);            SAMPLER(sampler_NormalMap);

///////////////////////////////////////////////////////////////////////////////
//                      Material Property Helpers                            //
///////////////////////////////////////////////////////////////////////////////

half4 SampleMatcap(float2 uv, float3 normalWS, TEXTURE2D_PARAM(matcap, sampler_matcap))
{
    float2 normalVS = mul(UNITY_MATRIX_V, float4(normalWS, 0)).xy;
    float2 matcap_uv = (normalVS * 0.5 +  float2(0.49, 0.49));

    return SAMPLE_TEXTURE2D(matcap, sampler_matcap, matcap_uv);
}


half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
}

half4 SampleSOMMap(float2 uv, TEXTURE2D_PARAM(SOMMap, sampler_SOMMap)){
    return SAMPLE_TEXTURE2D(SOMMap, sampler_SOMMap, uv);
}

float3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
{
#ifdef _NORMALMAP
    float4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
    return UnpackNormalScale(n, scale);
#else
    return float3(0.0h, 0.0h, 1.0h);
#endif
}

float3 SampleDetailNormal(float2 uv, TEXTURE2D_PARAM(detailBumpMap, sampler_detailBumpMap), half scale = 1.0h)
{
#ifdef _DETAIL_NORMAL_MAP
    float4 n = SAMPLE_TEXTURE2D(detailBumpMap, sampler_detailBumpMap, uv);
    return UnpackNormalScale(n, scale);
#else
    return float3(0.0h, 0.0h, 1.0h);
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

#endif
