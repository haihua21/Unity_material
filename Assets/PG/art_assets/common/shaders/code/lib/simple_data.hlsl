#ifndef SIMPLE_DATA_INCLUDED
#define SIMPLE_DATA_INCLUDED

#if defined(_SPECULAR_BRDF) || defined(_SPECULAR_SSS) || (defined(_GI_SPECULAR) && !defined(_MATCAP))

#if !defined(_CALC_BRDF_DATA)
    #define _CALC_BRDF_DATA
#endif

#endif

struct SimpleData
{
    half3 diffuse;
    half3 specular;
    half3 reflection_specular;
    
    
#if defined(_CALC_BRDF_DATA)
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;
    half normalizationTerm;
    half roughness2MinusOne;
#endif

};


///////////////////////////////////////////////////////////////////////////////
//                      Simple Data                                         //
///////////////////////////////////////////////////////////////////////////////

inline void InitializeSimpleData(half3 albedo, half metallic, half smoothness, out SimpleData outSimpleData)
{
    half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;
    outSimpleData.diffuse = albedo * oneMinusReflectivity;
    outSimpleData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);
    outSimpleData.reflection_specular = lerp(half3(0,0,0), albedo, metallic);
    
#if defined(_CALC_BRDF_DATA)
    outSimpleData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    outSimpleData.roughness           = max(PerceptualRoughnessToRoughness(outSimpleData.perceptualRoughness), HALF_MIN_SQRT);
    outSimpleData.roughness2          = max(outSimpleData.roughness * outSimpleData.roughness, HALF_MIN);
    outSimpleData.grazingTerm         = saturate(smoothness + reflectivity);
    outSimpleData.normalizationTerm   = outSimpleData.roughness * 4.0h + 2.0h;
    outSimpleData.roughness2MinusOne  = outSimpleData.roughness2 - 1.0h;
#endif
}

#endif
