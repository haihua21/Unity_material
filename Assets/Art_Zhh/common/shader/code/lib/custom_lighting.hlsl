#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

#include "../../lib/com_func/com_func_distance_transparency.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "../../lib/lighting_indirect.hlsl"

//temp clamp min sh to 0.2
half3 CustomSampleSHPixel(half3 L2Term, half3 normalWS)
{
    half3 sh = SampleSHPixel(L2Term, normalWS);
    sh *= max(1, 0.2 / max(0.01, Luminance(sh)));
    return sh;
}

// We either sample GI from baked lightmap or from probes.
// If lightmap: sampleData.xy = lightmapUV
// If probe: sampleData.xyz = L2 SH terms
#if defined(LIGHTMAP_ON)
#define CUSTOM_SAMPLE_GI(lmName, shName, normalWSName) SampleLightmap(lmName, normalWSName)
#else
#define CUSTOM_SAMPLE_GI(lmName, shName, normalWSName) CustomSampleSHPixel(shName, normalWSName)
#endif

#if defined(_PLANAR_REFLECTION)
    #define _CALC_SCREEN_UV
#endif

real CustomComputeFogFactor(float z){
    float clipZ_01 = UNITY_Z_0_FAR_FROM_CLIPSPACE(z);
    
    // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
    float fogFactor = saturate(clipZ_01 * unity_FogParams.z + unity_FogParams.w);
    
    half used_fog = step(0.05, fogFactor);
    fogFactor = lerp(1, fogFactor, used_fog);
    return real(fogFactor);
}

half4 SamplePlanarReflection(float4 screen_pos, half smoothness, half metallic, float3 viewDirectionWS, float3 normalWS, float3 vertexNormalWS)
{
    #if defined(_PLANAR_REFLECTION)

    half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);

    float2 normalVS = TransformWorldToViewDir(normalWS, true).xy;
    float2 vertex_normalVS = TransformWorldToViewDir(vertexNormalWS, true).xy;
    float2 normal_uv = normalVS - vertex_normalVS;
    float4 screen_pos_normalized = screen_pos / screen_pos.w;
    half4 planar_reflection_color = SAMPLE_TEXTURE2D_LOD(_PlanarReflectionTexture, sampler_PlanarReflectionTexture, screen_pos_normalized.xy + normal_uv, mip) * smoothness;
    return lerp( float4( 0,0,0,0 ) , planar_reflection_color , _ReflectionAmount);
    #else
    return half4(0, 0, 0, 0);
    #endif
}

half3 CustomMixFog(real3 fragColor, real fogFactor)
{
    return lerp(unity_FogColor.rgb, fragColor, fogFactor);
}

half2 EnvBRDFApproxLazarov(half Roughness, half NoV)
{
    // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
    // Adaptation to fit our G term.
    const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
    const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    half4 r = Roughness * c0 + c1;
    half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
    return AB;
}

half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
{
    half2 AB = EnvBRDFApproxLazarov(Roughness, NoV);

    // Anything less than 2% is physically impossible and is instead considered to be shadowing
    // Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
    float F90 = saturate(50.0 * SpecularColor.g);

    return SpecularColor * AB.x + F90 * AB.y;
}

// Taken from https://gist.github.com/romainguy/a2e9208f14cae37c579448be99f78f25
// Modified by Epic Games, Inc. To account for premultiplied light color and code style rules.

half GGX_Mobile(half Roughness, float NoH)
{
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float OneMinusNoHSqr = 1.0 - NoH * NoH; 
    half a = Roughness * Roughness;
    half n = NoH * a;
    half p = a / (OneMinusNoHSqr + n * n);
    half d = p * p;
    // clamp to avoid overlfow in a bright env
    return min(d, 2048.0);
}

half CalcSpecular(half Roughness, half NoH)
{
    return (Roughness*0.25 + 0.25) * GGX_Mobile(Roughness, NoH);
}

struct BRDFContext
{
    //half Opacity;
    half3 DiffuseColor;
    half3 SpecularColor;
    half3 SpecularLighting;
    half perceptualRoughness;
};

inline void InitBRDFContext(SurfaceData surfaceData, half NoV, out BRDFContext outShadingContext)
{
    //outShadingContext = (BRDFContext)0;
    const half DielectricSpecular = 0.04;
    outShadingContext.DiffuseColor = surfaceData.albedo - surfaceData.albedo * surfaceData.metallic;	// 1 mad
    outShadingContext.SpecularColor = (DielectricSpecular - DielectricSpecular * surfaceData.metallic) + surfaceData.albedo * surfaceData.metallic;	// 2 mad
    outShadingContext.perceptualRoughness = 1 - surfaceData.smoothness;
#ifdef _MATCAP
    outShadingContext.SpecularLighting = surfaceData.albedo * surfaceData.metallic;
#else
    outShadingContext.SpecularLighting = EnvBRDFApprox(outShadingContext.SpecularColor, outShadingContext.perceptualRoughness, NoV);
#endif
}
#endif
