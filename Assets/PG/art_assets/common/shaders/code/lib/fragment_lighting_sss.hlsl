#ifndef FRAGMENT_LIGHTING_SSS_INCLUDED
#define FRAGMENT_LIGHTING_SSS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "lighting_direct.hlsl"
#include "lighting_indirect.hlsl"
#include "lighting_func/lighting_func_sss.hlsl"
#include "lighting_func/lighting_func_rim.hlsl"
#include "simple_data.hlsl"



half3 LightingGI(InputData inputData, CH_SurfaceData surfaceData, SimpleData simpleData){
    half3 color = half3(0,0,0);
#if defined(_GI_DIFFUSE)
    color = simpleData.diffuse * LightingGI_Diffuse_Gradient(inputData.normalWS, _SkyColor, _EquatorColor, _GroundColor);
#endif

#if defined(_GI_SPECULAR)

#if defined(_MATCAP)
    color += LightingGI_Specular_Matcap(simpleData.reflection_specular, inputData.normalWS);
#else
    color += LightingGI_BRDF_Specular(simpleData.specular, simpleData.perceptualRoughness, simpleData.roughness2, simpleData.grazingTerm, 
                                        surfaceData.occlusion, inputData.normalWS, inputData.viewDirectionWS);
#endif
    
#endif

    return color * surfaceData.occlusion;
}

half3 LightingDirect(SimpleData simpleData, CH_SurfaceData surfaceData, half sss_mask, half smoothness, half attenuation, half3 radiance, half3 lightColor,
                    half3 lightDirWS, half3 normalWS, half3 viewDirectionWS, half NoL_base){
                    
    half3 direct_color = half3(0,0,0);
    
    half3 sss_lut = (half3)1;
#if defined(_SSS_LUT_MAP)
    sss_lut = SSS_DiffuseTerm(TEXTURE2D_ARGS(_SSSLutMap, sampler_SSSLutMap), attenuation, NoL_base, sss_mask);
#endif
    half3 diffuse_term = sss_lut * lightColor;
    

#if defined(_DIRECT_DIFFUSE)
    direct_color = simpleData.diffuse * diffuse_term;
#endif

#if defined(_DIRECT_SPECULAR) && defined(_CALC_BRDF_DATA)

#if defined(_SPECULAR_SSS)

    half3 half_dir = normalize(viewDirectionWS + lightDirWS);

    half NoL = saturate(NoL_base);
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    half NoH = saturate(dot(normalWS, half_dir));
    half HoL = saturate(dot(half_dir, lightDirWS));

    // SSS效果  高光系数使用 lut图的值
    half3 specular_dgf = LightingDirect_Specular_DGF(NoL, NoV, NoH, HoL, simpleData.specular, simpleData.perceptualRoughness, sss_lut);
    half3 indirect_color = diffuse_term * specular_dgf * 3.1415963;
#else
    
    half3 indirect_color = LightingDirect_Specular(simpleData, surfaceData.smoothness, lightDirWS, normalWS, viewDirectionWS) * simpleData.specular;
#endif
    
    direct_color += indirect_color;
    
#endif



    //return direct_color;
    return direct_color * attenuation;
}


///////////////////////////////////////////////////////////////////////////////
//                      Fragment Functions                                   //
///////////////////////////////////////////////////////////////////////////////

half4 UniversalFragmentSimple(InputData inputData, CH_SurfaceData surfaceData)
{
    half3 diffuse = half3(0,0,0);
    half3 specular = half3(0,0,0);
    SimpleData simpleData;
    InitializeSimpleData(surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, simpleData);

    Light mainLight = GetMainLight(inputData.shadowCoord);

    half3 indirect_color = LightingGI(inputData, surfaceData, simpleData);
    
    half NoL_base = dot(inputData.normalWS, mainLight.direction);
    
    half attenuation = (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
    half3 radiance = mainLight.color * attenuation;
    
    half3 direct_color = LightingDirect(simpleData, surfaceData, surfaceData.sss_mask, surfaceData.smoothness, attenuation, radiance, mainLight.color,
                    mainLight.direction, inputData.normalWS, inputData.viewDirectionWS, NoL_base);


#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        
        half NoL_base = dot(inputData.normalWS, light.direction);
        half attenuation = (light.distanceAttenuation * light.shadowAttenuation);
        half3 radiance = light.color * attenuation;
        direct_color += LightingDirect(simpleData, surfaceData, surfaceData.sss_mask, surfaceData.smoothness, attenuation, radiance,  mainLight.color,
                            light.direction, inputData.normalWS, inputData.viewDirectionWS, NoL_base);
    }
#endif


    half3 finalColor = direct_color + indirect_color + surfaceData.emission;
    
#if defined(_RIM)
    half NoV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
    half NoL = saturate(NoL_base);
    half3 rim_color = CalcRim(NoV, NoL, _RimColor, surfaceData.occlusion);
    rim_color = rim_color * attenuation;  //
    finalColor += rim_color;
#endif
    
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    finalColor += inputData.vertexLighting * simpleData.diffuse * simpleData.diffuse;
#endif


    return half4(finalColor, 1);
}



#endif
