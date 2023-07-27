#ifndef LIGHTING_DIRECT_INCLUDED
#define LIGHTING_DIRECT_INCLUDED

#include "simple_data.hlsl"
#include "lighting_func/lighting_func_D_G_F.hlsl"

half3 LightingDirect_Specular_DGF(half NDotL,half NDotV,half NDotH, half HDotL, half3 specular, half roughness, half3 sssLut){
    return CalcDGF(NDotL, NDotV, NDotH, NDotL, specular, roughness, sssLut);
}


half LightingDirect_Specular_BRDF(half roughness2, half roughness2MinusOne, half normalizationTerm, half3 normalWS, half3 lightDirWS, half3 viewDirectionWS){
    float3 halfDir = SafeNormalize(float3(lightDirWS) + float3(viewDirectionWS));
    
    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirWS, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d = NoH * NoH * roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);
    specularTerm = clamp(specularTerm,0.0,6.0);  //zhh 

#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    return specularTerm;
}

half LightingDirect_Specular_BlinnPhong(half smoothness, half3 lightDirWS, half3 normalWS, half3 viewDirectionWS){
    
#if defined(_SPECULAR2)
    half gloss = max(smoothness, 0.01) * 128;
#else
    half gloss = exp2(smoothness * 10 + 1);
#endif

    float3 halfDir = SafeNormalize(float3(lightDirWS) + float3(viewDirectionWS));
    half NoH = saturate(dot(normalWS, halfDir));
    half modifier = pow(NoH, gloss) * _SpecularIntensity;
    
    return modifier;
}

half LightingDirect_Specular(SimpleData simpleData, half smoothness, half3 lightDirWS, half3 normalWS, half3 viewDirectionWS){

#if defined(_SPECULAR_BRDF)
    half modifier = LightingDirect_Specular_BRDF(simpleData.roughness2, simpleData.roughness2MinusOne, simpleData.normalizationTerm,
                                                normalWS, lightDirWS, viewDirectionWS);
#elif defined(_SPECULAR_SSS)
    half modifier = 0;
#else
    half modifier = LightingDirect_Specular_BlinnPhong(smoothness, lightDirWS, normalWS, viewDirectionWS) * smoothness;
#endif
    
    return modifier;
}




half3 MySubtractDirectMainLightFromLightmap(Light mainLight, half3 normalWS, half3 bakedGI)
{
    // Let's try to make realtime shadows work on a surface, which already contains
    // baked lighting and shadowing from the main sun light.
    // Summary:
    // 1) Calculate possible value in the shadow by subtracting estimated light contribution from the places occluded by realtime shadow:
    //      a) preserves other baked lights and light bounces
    //      b) eliminates shadows on the geometry facing away from the light
    // 2) Clamp against user defined ShadowColor.
    // 3) Pick original lightmap value, if it is the darkest one.


    // 1) Gives good estimate of illumination as if light would've been shadowed during the bake.
    // We only subtract the main direction light. This is accounted in the contribution term below.
    half shadowStrength = GetMainLightShadowStrength() * _ShadowIntensity;
    half contributionTerm = saturate(dot(mainLight.direction, normalWS));
    half3 lambert = mainLight.color * contributionTerm;
    half3 estimatedLightContributionMaskedByInverseOfShadow = lambert * (1.0 - mainLight.shadowAttenuation);
    half3 subtractedLightmap = bakedGI - estimatedLightContributionMaskedByInverseOfShadow;

    // 2) Allows user to define overall ambient of the scene and control situation when realtime shadow becomes too dark.
    half3 realtimeShadow = max(subtractedLightmap, _SubtractiveShadowColor.xyz);
    realtimeShadow = lerp(bakedGI, realtimeShadow, shadowStrength);

    // 3) Pick darkest color
    return min(bakedGI, realtimeShadow);
}

void MyMixRealtimeAndBakedGI(inout Light light, half3 normalWS, inout half3 bakedGI)
{
/*
#if defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE)
    bakedGI = MySubtractDirectMainLightFromLightmap(light, normalWS, bakedGI);
#endif
*/
#if defined(LIGHTMAP_ON)
    bakedGI = MySubtractDirectMainLightFromLightmap(light, normalWS, bakedGI);
#endif

}


#endif
