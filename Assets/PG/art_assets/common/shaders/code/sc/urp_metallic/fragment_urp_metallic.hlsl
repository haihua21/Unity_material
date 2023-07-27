#ifndef SC_URP_METALLIC_PASS_INCLUDED
#define SC_URP_METALLIC_PASS_INCLUDED

#include "../../lib/fragment_lighting_pbr_urp_metallic.hlsl"
#include "../../lib/com_func/com_func_distance_transparency.hlsl"
#include "simple_pass.hlsl"


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


// Used for StandardSimpleLighting shader
half4 PassFragmentUrpMetallic(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    #if defined(_CALC_SCREEN_UV)
    surfaceData.emission += SamplePlanarReflection(input.screen_pos, surfaceData.smoothness, surfaceData.metallic, inputData.viewDirectionWS, inputData.normalWS, input.normal);
    #endif


    half4 color = UniversalFragmentSimple(inputData, surfaceData);

    #if defined(_DIRTY_MAP)
    half dirty_color = SAMPLE_TEXTURE2D(_DirtyMap, sampler_DirtyMap, TRANSFORM_TEX(input.uv, _DirtyMap)).r;
    dirty_color = saturate(1 - dirty_color);
    color.rgb *= lerp(half3(1, 1, 1), dirty_color * _DirtyColor, _DirtyAmount * dirty_color);
    #endif

    color.rgb = CustomMixFog(color.rgb, inputData.fogCoord);
    color.a = surfaceData.alpha;

    #if defined(_DISTANCE_TRANSPARENCY)
    color.a = DistanceTransparencyAlpha(input.posWS);
    #endif

    AlphaDiscard(color.a, _Cutoff);

    return saturate(color);
}


#endif
