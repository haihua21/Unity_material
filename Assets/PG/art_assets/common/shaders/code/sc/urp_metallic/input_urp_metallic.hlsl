#ifndef SC_URP_METALLIC_INPUT_INCLUDED
#define SC_URP_METALLIC_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../../lib/surface_input.hlsl"

TEXTURE2D(_SOMMap);
SAMPLER(sampler_SOMMap);
TEXTURE2D(_DetailNormalMap);
SAMPLER(sampler_DetailNormalMap);


#if defined(_MATCAP)
    TEXTURE2D(_Matcap);        SAMPLER(sampler_Matcap);
#endif

#if defined(_PLANAR_REFLECTION)
    TEXTURE2D(_PlanarReflectionTexture);        SAMPLER(sampler_PlanarReflectionTexture);
#endif

#if defined(_DIRTY_MAP)
TEXTURE2D(_DirtyMap);
SAMPLER(sampler_DirtyMap);
#endif

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _DirtyMap_ST;
float4 _DetailNormalMap_ST;
half4 _BaseColor;

half _Metallic;
half _Smoothness;
half _AO;
half _BlendNormalAmount;
half _NormalScale;
half4 _EmissionColor;
half _SpecularIntensity;

half _MatcapIntensity;
half4 _MatcapColor;

half _GI_ShadowIntensity;

half3 _DirtyColor;
half _DirtyAmount;

half _ReflectionAmount;
half _Cutoff;
CBUFFER_END

#ifdef UNITY_INSTANCING_ENABLED
    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
        UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
        
        UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
        UNITY_DEFINE_INSTANCED_PROP(half, _Smoothness)
        UNITY_DEFINE_INSTANCED_PROP(half, _AO)
        UNITY_DEFINE_INSTANCED_PROP(half, _NormalScale)
        
        UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
        
        UNITY_DEFINE_INSTANCED_PROP(half, _SpecularIntensity)
        
        UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
        
        UNITY_DEFINE_INSTANCED_PROP(half, _MatcapIntensity)
        UNITY_DEFINE_INSTANCED_PROP(half4, _MatcapColor)

        UNITY_DEFINE_INSTANCED_PROP(half, _ReflectionAmount)
        
        UNITY_DEFINE_INSTANCED_PROP(half3, _DirtyColor)
        
    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
    
    #define _BaseMap_ST                 UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST)
    #define _BaseColor                  UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor)
    
    #define _Metallic                   UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic)
    #define _Smoothness                UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness)
    #define _AO                         UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _AO)
    #define _NormalScale                UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NormalScale)
    
    #define _EmissionColor              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor)
    
    #define _SpecularIntensity          UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SpecularIntensity)
    #define _Cutoff            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff)
    

    #define _MatcapIntensity            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MatcapIntensity)
    #define _MatcapColor            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MatcapColor)
   

    #define _ReflectionAmount            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ReflectionAmount)
    #define _DirtyColor            UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DirtyColor)
    
#endif

#ifdef UNITY_DOTS_INSTANCING_ENABLED
    UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
        
        UNITY_DOTS_INSTANCED_PROP(float4, _BaseMap_ST)
        UNITY_DOTS_INSTANCED_PROP(half4, _BaseColor)
        
        UNITY_DOTS_INSTANCED_PROP(half, _Metallic)
        UNITY_DOTS_INSTANCED_PROP(half, _Smoothness)
        UNITY_DOTS_INSTANCED_PROP(half, _AO)
        UNITY_DOTS_INSTANCED_PROP(half, _NormalScale)
        
        UNITY_DOTS_INSTANCED_PROP(half4, _EmissionColor)
        
        UNITY_DOTS_INSTANCED_PROP(half, _SpecularIntensity)
        
        UNITY_DOTS_INSTANCED_PROP(half, _Cutoff)
        
        UNITY_DOTS_INSTANCED_PROP(half, _MatcapIntensity)
        UNITY_DOTS_INSTANCED_PROP(half4, _MatcapColor)

        UNITY_DOTS_INSTANCED_PROP(half, _ReflectionAmount)
        
    UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
    
    #define _BaseMap_ST                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__BaseMap_ST)
    #define _BaseColor                  UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half4 , Metadata__BaseColor)
    
    #define _Metallic                   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__Metallic)
    #define _Smoothness                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__Smoothness)
    #define _AO                         UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__AO)
    #define _NormalScale                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__NormalScale)
    
    #define _EmissionColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half4 , Metadata__EmissionColor)
    
    #define _SpecularIntensity          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__SpecularIntensity)
    #define _Cutoff            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__Cutoff)
    

    #define _MatcapIntensity            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__MatcapIntensity)
    #define _MatcapColor            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__MatcapColor)
   

    #define _ReflectionAmount            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half , Metadata__ReflectionAmount)
    
#endif


half CalcSmoothness(half smoothness)
{
    #if defined(_SPECULAR_BRDF)
    return smoothness;       
    #elif defined(_SPECULAR2)
    return max(smoothness, 0.01) * 128;
    #else
    return exp2(smoothness * 10 + 1);
    #endif
}


inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    outSurfaceData = (SurfaceData)0;

    #if defined(_SOMMAP)
    half4 som_color = SampleSOMMap(uv, TEXTURE2D_ARGS(_SOMMap, sampler_SOMMap));
    #else
    half4 som_color = half4(1, 1, 1, 1);
    #endif

    #if defined(_BASEMAP)
    half4 albedo_alpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    #else
    half4 albedo_alpha = half4(1, 1, 1, 1);
    #endif

    outSurfaceData.albedo = albedo_alpha.rgb * _BaseColor.rgb;
    outSurfaceData.alpha = albedo_alpha.a * _BaseColor.a;

    outSurfaceData.metallic = som_color.b * _Metallic;
    outSurfaceData.specular = half3(0, 0, 0);

    outSurfaceData.smoothness = som_color.r * _Smoothness;
    float3 normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), _NormalScale);

    #if defined(_DETAIL_NORMAL_MAP)
    float3 detail_normalTS = SampleDetailNormal(TRANSFORM_TEX(uv, _DetailNormalMap), TEXTURE2D_ARGS(_DetailNormalMap, sampler_DetailNormalMap), _NormalScale);
    float3 blendNormal = BlendNormal(normalTS, detail_normalTS);
    normalTS = lerp(normalTS, blendNormal, _BlendNormalAmount);
    #endif

    outSurfaceData.normalTS = normalTS;

    outSurfaceData.occlusion = lerp(1, som_color.g, _AO);

    #if defined(_EMISSION)
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap)).rgb;
    #else
    outSurfaceData.emission = _EmissionColor.rgb;
    #endif
}

#endif
