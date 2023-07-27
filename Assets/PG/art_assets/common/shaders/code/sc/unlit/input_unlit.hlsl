#ifndef SC_UNLIT_INPUT_INCLUDED
#define SC_UNLIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../../lib/surface_input.hlsl"

#if defined(_DIRTY_MAP)
    TEXTURE2D(_DirtyMap);        SAMPLER(sampler_DirtyMap);
#endif

#if defined(_REFLECTIONMAP)
    TEXTURECUBE(_ReflectionMap);    SAMPLER(sampler_ReflectionMap);
#endif

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    float4 _DirtyMap_ST;
    
    half _Cutoff;
    
    half4 _BaseColor;
    half _NormalScale;
    half3 _DirtyColor;
    half _DirtyAmount;
    
    half4 _ReflectionColor;
    half _ReflectionAmount;
    half3 _EmissionColor;
CBUFFER_END



inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    outSurfaceData = (SurfaceData)0;

#if defined(_BASEMAP)
    half4 albedo_alpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
#else
    half4 albedo_alpha = half4(1,1,1,1);
#endif

    outSurfaceData.albedo = albedo_alpha.rgb * _BaseColor.rgb;
    outSurfaceData.alpha = albedo_alpha.a * _BaseColor.a;
    
#if defined(_DIRTY_MAP)
    half3 dirty_color = SAMPLE_TEXTURE2D(_DirtyMap, sampler_DirtyMap, TRANSFORM_TEX(uv, _DirtyMap)).rgb * _DirtyColor;
    outSurfaceData.albedo *= lerp(half3(1,1,1), dirty_color, _DirtyAmount);
#endif
    
    outSurfaceData.metallic = 0;
    outSurfaceData.specular = half3(0,0,0);
    
    outSurfaceData.smoothness = 0.5;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), _NormalScale);
    outSurfaceData.occlusion = 1;
    
#if defined(_EMISSION)
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap)).rgb;
#else
    outSurfaceData.emission = _EmissionColor;
#endif
    
}

#endif
