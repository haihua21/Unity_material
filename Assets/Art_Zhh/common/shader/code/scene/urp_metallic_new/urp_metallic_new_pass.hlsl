#ifndef URP_METALLIC_NEW_PASS_INCLUDED
#define URP_METALLIC_NEW_PASS_INCLUDED

#include "../../lib/custom_lighting.hlsl"

struct Attributes
{
    float4 positionOS    : POSITION;
    float3 normalOS      : NORMAL;
    float4 tangentOS     : TANGENT;
    float2 texcoord      : TEXCOORD0;
    float2 lightmapUV    : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

    float3 posWS                    : TEXCOORD2;    // xyz: posWS

    float4 normal                   : TEXCOORD3;    // xyz: normal, w: viewDir.x
    float4 tangent                  : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    float4 bitangent                : TEXCOORD5;    // xyz: bitangent, w: viewDir.z

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
    #endif

    #if defined(_CALC_SCREEN_UV)
    float4 screen_pos : TEXCOORD8;
    #endif

    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData.positionWS = input.posWS;

    half3 viewDirWS = half3(input.normal.w, input.tangent.w, input.bitangent.w);
    inputData.normalWS = TransformTangentToWorld(normalTS,
        half3x3(input.tangent.xyz, input.bitangent.xyz, input.normal.xyz));

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    viewDirWS = SafeNormalize(viewDirWS);

    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.positionCS = input.positionCS;
    inputData.tangentToWorld = half3x3(input.tangent.xyz, input.bitangent.xyz, input.normal.xyz);
    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    //inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    inputData.bakedGI = CUSTOM_SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);

    //inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.normalizedScreenSpaceUV = 0;

    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Simple Lighting) shader
Varyings PassVertexSimple(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = CustomComputeFogFactor(vertexInput.positionCS.z);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.posWS.xyz = vertexInput.positionWS;
    output.positionCS = vertexInput.positionCS;

    output.normal = half4(normalInput.normalWS, viewDirWS.x);
    output.tangent = half4(normalInput.tangentWS, viewDirWS.y);
    output.bitangent = half4(normalInput.bitangentWS, viewDirWS.z);

#if defined(_CALC_SCREEN_UV)
    output.screen_pos = ComputeScreenPos(vertexInput.positionCS);
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normal.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    return output;
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

    half NoV = max(dot(inputData.normalWS, inputData.viewDirectionWS), 0);

    BRDFContext brdfContext;
    InitBRDFContext(surfaceData, NoV, brdfContext);

    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
    #else
    half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    Light mainLight = GetMainLight(inputData.shadowCoord, input.posWS, shadowMask);
    half NoL = saturate(dot(inputData.normalWS, mainLight.direction));
    half3 H = normalize(inputData.viewDirectionWS + mainLight.direction);
    half NoH = max(0, dot(inputData.normalWS, H));

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
    half3 indirectDiffuse = inputData.bakedGI * brdfContext.DiffuseColor * surfaceData.occlusion;
    half3 reflectVector = reflect(-inputData.viewDirectionWS, inputData.normalWS);
    half3 indirectSpecular = half3(0,0,0);
    #ifdef _MATCAP
    indirectSpecular = LightingGI_Specular_Matcap(brdfContext.SpecularLighting, inputData.normalWS, brdfContext.perceptualRoughness);
    #else
    indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfContext.perceptualRoughness, surfaceData.occlusion) * brdfContext.SpecularLighting;
    #endif
    indirectSpecular *= surfaceData.occlusion;
    half3 indirectColor = indirectDiffuse + indirectSpecular;
    indirectColor = lerp(indirectColor, indirectColor * NoL * mainLight.shadowAttenuation, _GI_ShadowIntensity);

    half4 color = half4(0,0,0,0);
    color.rgb = surfaceData.emission;
    color.rgb += indirectColor;

    //lightColor = mainLight.color * mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    half3 lightColor = mainLight.color * mainLight.shadowAttenuation;

    half3 directLight = half3(0,0,0);
    //subtractive lightmap don't calculate direct lighting
    #if !(defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE))
    directLight += brdfContext.DiffuseColor;
    //matcap don't calculate direct specular
    #ifndef _MATCAP
    directLight += brdfContext.SpecularLighting * CalcSpecular(brdfContext.perceptualRoughness, NoH);
    #endif
    #endif

    directLight *= NoL * lightColor;
    // add ADDITIONAL_LIGHT
    #if defined(_ADDITIONAL_LIGHTS)
    uint additionalLightsCount = GetAdditionalLightsCount();
    for (uint i = 0; i < additionalLightsCount; i++)
    {
        Light additionalLight = GetAdditionalLight(i, inputData.positionWS);
    
        
       
        half NoL_add = saturate(dot(inputData.normalWS, additionalLight.direction));      

        half3 H_add = normalize(inputData.viewDirectionWS + additionalLight.direction);
        half NoH_add = max(0, dot(inputData.normalWS, H_add));
        half3 lightColor_add = additionalLight.color * additionalLight.shadowAttenuation * additionalLight.distanceAttenuation;        

        half3 directLight_add = half3(0,0,0);
        #if !(defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE))
        directLight_add += brdfContext.DiffuseColor; 
        #ifndef _MATCAP
        directLight_add += brdfContext.SpecularLighting * CalcSpecular(brdfContext.perceptualRoughness, NoH_add);  
        #endif
        #endif
        directLight_add *= NoL_add * lightColor_add;
        
        directLight += directLight_add;
    }
    #endif
    // endadd
    
    color.rgb += directLight;
    color.rgb += inputData.vertexLighting * brdfContext.DiffuseColor;

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

#ifdef _DITHER_FADE_ON
    float cutoff = 0;
    DitherFloat(1, input.positionCS.xy / _DitherScale, cutoff);
    _Cutoff = cutoff;
    float alpha = (1 - _DitherFadeAmount);
    DitherAlphaClip(alpha, _BaseColor, _Cutoff);
#endif

    #ifdef _DEBUG_MODE
    color.rgb = ShowDebug(surfaceData, inputData, directLight, indirectDiffuse, indirectSpecular);
    #endif

    //temp clamp until fix bloom
    color.rgb = clamp(color.rgb, 0, 2);

    return color;
}


#endif