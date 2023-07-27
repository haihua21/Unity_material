#ifndef COM_LIGHTING_SIMPLE_INCLUDED
#define COM_LIGHTING_SIMPLE_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "lighting_direct.hlsl"
#include "lighting_indirect.hlsl"
#include "simple_data.hlsl"
#include "./data/ch_surface_data.hlsl"


half3 LightingGI(InputData inputData, CH_SurfaceData surfaceData, SimpleData simpleData, half3 lightColor){
    half3 color = half3(0,0,0);
#if defined(_GI_DIFFUSE)
     // color = inputData.bakedGI * simpleData.diffuse;
      color =lerp((simpleData.diffuse*0.4),0.8,inputData.bakedGI * simpleData.diffuse) ;  // zhh modify
#endif

#if defined(_GI_SPECULAR)

    color += LightingGI_Specular_CubeMap(inputData.normalWS, inputData.viewDirectionWS) * surfaceData.metallic * lightColor;
    color += LightingGI_Specular_Matcap(simpleData.reflection_specular, inputData.normalWS);

#if !defined(_REFLECTION_Cube) && !defined(_MATCAP)
    color += LightingGI_BRDF_Specular(simpleData.specular, simpleData.perceptualRoughness, simpleData.roughness2, simpleData.grazingTerm, 
                                        surfaceData.occlusion, inputData.normalWS, inputData.viewDirectionWS);
#endif

    
#endif

    return color * surfaceData.occlusion;
}

half3 LightingDirect(SimpleData simpleData, half smoothness, half3 radiance, half3 lightDirWS, half3 normalWS, half3 viewDirectionWS){
    half3 direct_color = half3(0,0,0);

#if defined(_DIRECT_DIFFUSE)
    direct_color = simpleData.diffuse;
#endif

#if defined(_DIRECT_SPECULAR)
    direct_color += simpleData.specular * LightingDirect_Specular(simpleData, smoothness, lightDirWS, normalWS, viewDirectionWS);
#endif

    return direct_color * radiance;
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

    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
    #endif
    
    MyMixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    half NoL = saturate(dot(inputData.normalWS, mainLight.direction));
#if defined(_SMOOTH_SHADOW)
    half atten =  mainLight.shadowAttenuation;
    atten = smoothstep((_SmoothShadowIntensity - 1) , _SmoothShadowSmoothness, atten);
#else
    half atten =  mainLight.shadowAttenuation;
#endif
    atten *= mainLight.distanceAttenuation;
    half3 radiance_without_NoL = mainLight.color * atten;
    half3 radiance = radiance_without_NoL * NoL;
    
    half3 indirect_color = LightingGI(inputData, surfaceData, simpleData, mainLight.color);
    
#if defined(LIGHTMAP_ON)
    half3 direct_color = half3(0,0,0);
    
    #if defined(_DIRECT_SPECULAR)
        direct_color = simpleData.specular * LightingDirect_Specular(simpleData, surfaceData.smoothness, mainLight.direction, inputData.normalWS, inputData.viewDirectionWS) * radiance;
    #endif
    
#else
    half3 direct_color = LightingDirect(simpleData, surfaceData.smoothness, radiance,
                    mainLight.direction, inputData.normalWS, inputData.viewDirectionWS);

    #ifdef _ADDITIONAL_LIGHTS

        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            
            half NoL = saturate(dot(inputData.normalWS, light.direction));
            radiance = light.color * (light.distanceAttenuation * light.shadowAttenuation) * NoL;
            direct_color += LightingDirect(simpleData, surfaceData.smoothness, radiance, 
                                light.direction, inputData.normalWS, inputData.viewDirectionWS);
        }
    #endif  // end _ADDITIONAL_LIGHTS

#endif
    


#if defined(_EMISSION_NEED_ATTEN)
    surfaceData.emission *= radiance_without_NoL * surfaceData.occlusion;
#endif

    half3 finalColor = direct_color + indirect_color + surfaceData.emission;
    
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    finalColor += inputData.vertexLighting * simpleData.diffuse;
#endif

    return half4(finalColor, 1);
}


#endif
