#ifndef URP_METALLIC_NEW_INPUT_INCLUDED
#define URP_METALLIC_NEW_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "../../lib/surface_input.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _AlphaMap_ST;
float4 _DirtyMap_ST;
float4 _DetailNormalMap_ST;
half4 _BaseColor;

half _BlendNormalAmount;
half _Metallic;
half _Smoothness;
half _AO;
half4 _EmissionColor;
half _SpecularIntensity;

half _MatcapIntensity;
half4 _MatcapColor;

half _GI_ShadowIntensity;

half3 _DirtyColor;
half _DirtyAmount;

half _ReflectionAmount;
half _Cutoff;
half _DitherScale;
half _DitherFadeAmount;

CBUFFER_END



#ifdef UNITY_INSTANCING_ENABLED
    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

    UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4, _AlphaMap_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4, _DirtyMap_ST)      // ²¹³ä
    UNITY_DEFINE_INSTANCED_PROP(float4, _DetailNormalMap_ST) // ²¹³ä
    UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)

    UNITY_DEFINE_INSTANCED_PROP(half, _BlendNormalAmount)  // ²¹³ä

    UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
    UNITY_DEFINE_INSTANCED_PROP(half, _Smoothness)
    UNITY_DEFINE_INSTANCED_PROP(half, _AO)

    UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _SpecularIntensity)

    UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)

    UNITY_DEFINE_INSTANCED_PROP(half, _MatcapIntensity)
    UNITY_DEFINE_INSTANCED_PROP(half4, _MatcapColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _GI_ShadowIntensity)

    UNITY_DEFINE_INSTANCED_PROP(half, _ReflectionAmount)

    UNITY_DEFINE_INSTANCED_PROP(half3, _DirtyColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _DirtyAmount)      // ²¹³ä

    UNITY_DEFINE_INSTANCED_PROP(half, _DitherScale)           // ²¹³ä
    UNITY_DEFINE_INSTANCED_PROP(half, _DitherFadeAmount)     // ²¹³ä

    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    #define _DitherScale               UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DitherScale)    // ²¹³ä
    #define _DitherFadeAmount          UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DitherFadeAmount)  // ²¹³ä

    #define _BaseMap_ST                 UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST)
    #define _AlphaMap_ST                 UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _AlphaMap_ST)
    #define _DirtyMap_ST                UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DirtyMap_ST)       // ²¹³ä
    #define _DetailNormalMap_ST         UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalMap_ST) // ²¹³ä
    #define _BaseColor                  UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor)

    #define _BlendNormalAmount          UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BlendNormalAmount) // ²¹³ä

    #define _Metallic                   UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic)
    #define _Smoothness                UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness)
    #define _AO                         UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _AO)

    #define _EmissionColor              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor)
    #define _SpecularIntensity              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SpecularIntensity)

    #define _Cutoff            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff)


    #define _MatcapIntensity            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MatcapIntensity)
    #define _MatcapColor            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MatcapColor)
    #define _GI_ShadowIntensity            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GI_ShadowIntensity)

    #define _DirtyAmount                UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DirtyAmount)         // ²¹³ä
    #define _ReflectionAmount            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ReflectionAmount)
    #define _DirtyColor            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DirtyColor)

    #define _DitherScale               UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DitherScale)
    #define _DitherFadeAmount          UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DitherFadeAmount)
#else
    #define _DitherScale               _DitherScale
    #define _DitherFadeAmount          _DitherFadeAmount


#endif

TEXTURE2D(_NMSMap);
SAMPLER(sampler_NMSMap);

TEXTURE2D(_AlphaMap);
SAMPLER(sampler_AlphaMap);

#if defined(_DETAIL_NORMAL_MAP)
TEXTURE2D(_DetailNormalMap);
SAMPLER(sampler_DetailNormalMap);
#endif

#if defined(_MATCAP)
TEXTURE2D(_Matcap);
SAMPLER(sampler_Matcap);
#endif

#if defined(_PLANAR_REFLECTION)
TEXTURE2D(_PlanarReflectionTexture);
SAMPLER(sampler_PlanarReflectionTexture);
#endif

#if defined(_DIRTY_MAP)
TEXTURE2D(_DirtyMap);
SAMPLER(sampler_DirtyMap);
#endif

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    outSurfaceData = (SurfaceData)0;

    half4 nms_color = SampleNMSMap(uv, TEXTURE2D_ARGS(_NMSMap, sampler_NMSMap));

    half4 albedo_alpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    half4 alpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_AlphaMap, sampler_AlphaMap));
    
    outSurfaceData.albedo = albedo_alpha.rgb * _BaseColor.rgb;
    outSurfaceData.alpha = alpha.r * _BaseColor.a;

    outSurfaceData.metallic = nms_color.b * _Metallic;
    outSurfaceData.smoothness = nms_color.a * _Smoothness;
    outSurfaceData.specular = half(0);

    float3 normalTS;
    normalTS.xy = nms_color.rg * 2.0 - 1.0;
    normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));
   // normalTS.xy *= _BumpScale;
    normalTS = normalize(normalTS);

    #if defined(_DETAIL_NORMAL_MAP)
    float3 detail_normalTS = SampleDetailNormal(TRANSFORM_TEX(uv, _DetailNormalMap), TEXTURE2D_ARGS(_DetailNormalMap, sampler_DetailNormalMap), 1);
    float3 blendNormal = BlendNormal(normalTS, detail_normalTS);
    normalTS = lerp(normalTS, blendNormal, _BlendNormalAmount);
    #endif

    outSurfaceData.normalTS = normalTS;
   //outSurfaceData.occlusion = half(1);   
 
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));    
    
    outSurfaceData.occlusion = lerp(1, albedo_alpha.a, _AO);
    
}

void DitherFloat(float In, float2 uv, out float Out)
{
    float DITHER_THRESHOLDS[16] =
    {
        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };
    uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
    Out = In - DITHER_THRESHOLDS[index];
}

half DitherAlphaClip(half albedoAlpha, half baseColorAlpha, half cutoff)
{
    #if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
    half alpha = albedoAlpha;
    #else
    half alpha = _BaseColor.a;
    #endif

    alpha = (cutoff <= 0.0) ? 1.0 : alpha;
    half clippedAlpha = (alpha >= cutoff) ? float(alpha) : 0.0;
    half alphaToCoverageAlpha = SharpenAlpha(alpha, cutoff);
    alpha = _AlphaToMaskAvailable != 0.0 ? alphaToCoverageAlpha : clippedAlpha;

    if (alpha < cutoff)
        discard;

    return alpha;
}

#endif