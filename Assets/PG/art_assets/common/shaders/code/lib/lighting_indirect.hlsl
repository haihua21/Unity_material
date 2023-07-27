#ifndef LIGHTING_INDIRECT_INCLUDED
#define LIGHTING_INDIRECT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"
#include "simple_data.hlsl"

///////////////////////////////////
//           CH GI Diffuse       //
///////////////////////////////////

half3 LightingGI_Diffuse_Gradient(float3 normalWS, half3 sky_color, half3 equator_color, half3 ground_color){
    float normal_y = normalWS.y;
    half3 gradient_color = lerp(equator_color, sky_color, max(normal_y, 0));
    gradient_color = lerp(gradient_color, ground_color, max(-normal_y, 0));
    return gradient_color;
}


///////////////////////////////////
//        GI Matcap Specular     //
///////////////////////////////////

half3 LightingGI_Specular_Matcap(half3 specular, float3 normalWS){
#if defined(_MATCAP)
    float2 normalVS = mul(UNITY_MATRIX_V, float4(normalWS, 0)).xy;
    float2 matcap_uv = (normalVS * 0.5 +  float2(0.49, 0.49));
    return SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, matcap_uv).xyz * _MatcapIntensity * specular * _MatcapColor.rgb;
#endif

    return half3(0,0,0);
}


///////////////////////////////////
//        GI CubeMap Specular     //
///////////////////////////////////
half3 LightingGI_Specular_CubeMap(float3 normalWS, float3 viewDirectionWS){
#if defined(_REFLECTION_CUBE)
    float3 reflectionWS = reflect(-viewDirectionWS, normalWS);
    half3 reflection_cube_color = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, reflectionWS, _ReflectionCubeLOD).rgb; 
    return reflection_cube_color * _ReflectionCubeIntensity * _ReflectionCubeColor;
#endif
    return half3(0,0,0);
}


///////////////////////////////////
//          GI BRDF Specular     //
///////////////////////////////////

half3 CustomEnvironmentBRDFSpecular(half3 specular, half roughness2, half grazingTerm, half fresnelTerm)
{
    float surfaceReduction = 1.0 / (roughness2 + 1.0);
    return surfaceReduction * lerp(specular, grazingTerm, fresnelTerm);
}

half3 CustomGlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness, half occlusion)
{
#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);

#if defined(UNITY_USE_NATIVE_HDR)
    half3 irradiance = encodedIrradiance.rgb;
#else
    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
#endif

    return irradiance;
#endif // GLOSSY_REFLECTIONS

    return _GlossyEnvironmentColor.rgb;
}

half3 LightingGI_BRDF_Specular(half3 specular, half perceptualRoughness, half roughness2, half grazingTerm, half occlusion, half3 normalWS, half3 viewDirectionWS){
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    half fresnelTerm = Pow4(1.0 - NoV);
    
    half3 indirect_specular = CustomGlossyEnvironmentReflection(reflectVector, perceptualRoughness, occlusion);
    return indirect_specular * CustomEnvironmentBRDFSpecular(specular, roughness2, grazingTerm, fresnelTerm);
}



#endif
