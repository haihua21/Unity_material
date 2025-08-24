#ifndef UNIVERSAL_LIT_META_PASS_INCLUDED
#define UNIVERSAL_LIT_META_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 uv0          : TEXCOORD0;
    float2 uv1          : TEXCOORD1;
    float2 uv2          : TEXCOORD2;
    float4 tangentOS     : TANGENT;//leo6
#ifdef _TANGENT_TO_WORLD
    float4 tangentOS     : TANGENT;
#endif
};

struct Varyings
{
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD0;
    float3 tangentEye   : TEXCOORD1;//leo6
    float2 offsetuv     : TEXCOORD2;//leo6
};

Varyings UniversalVertexMeta(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);//leo5
    half3 viewPosWS = -1 * (GetCameraPositionWS() - vertexInput.positionWS);//leo5 获取观察向量
    float3 WorldSpaceNormal = normalize(mul(input.normalOS,(float3x3)UNITY_MATRIX_I_M));//leo6
    float3 WorldSpaceTangent = normalize(mul((float3x3)UNITY_MATRIX_M,input.tangentOS.xyz));//loe6
    float3 WorldSpaceBiTangent = cross(WorldSpaceNormal, WorldSpaceTangent.xyz) * input.tangentOS.w;//leo6
    float3 _Transform_Out = TransformWorldToTangent(viewPosWS, float3x3(WorldSpaceTangent, WorldSpaceBiTangent, WorldSpaceNormal));//leo6
    float3 viewPosTs =_Transform_Out; //leo5 世界位置到切线空间

    
    output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2,
        unity_LightmapST, unity_DynamicLightmapST);
    output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);
    output.offsetuv = output.uv;//leo6
    output.tangentEye = viewPosTs;//leo6
    
    return output;
}

half4 UniversalFragmentMeta(Varyings input) : SV_Target
{
    SurfaceData surfaceData;
    input.offsetuv =  SampleCustomMap(input.uv,_V1,input.tangentEye, TEXTURE2D_ARGS(_CustomMap1, sampler_CustomMap1)); //leo6

    InitializeStandardLitSurfaceData(input.uv,input.offsetuv, surfaceData);//leo5 leo6

    BRDFData brdfData;
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    MetaInput metaInput;
    metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
    metaInput.SpecularColor = surfaceData.specular;
    metaInput.Emission = surfaceData.emission;

    return MetaFragment(metaInput);
}


//LWRP -> Universal Backwards Compatibility
Varyings LightweightVertexMeta(Attributes input)
{
    return UniversalVertexMeta(input);
}

half4 LightweightFragmentMeta(Varyings input) : SV_Target
{
    return UniversalFragmentMeta(input);
}

#endif
