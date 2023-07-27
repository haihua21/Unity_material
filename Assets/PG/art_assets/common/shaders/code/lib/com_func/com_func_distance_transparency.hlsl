#ifndef COM_FUNC_DISTANCE_TRANSPARENCY_INCLUDED
#define COM_FUNC_DISTANCE_TRANSPARENCY_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

float TransparencyRange;
float TransparencyBaseAlpha;
float TransparencySoft;
float4 PlayerPosition;
float4 TransparencyRangeScaleOffset;

half DistanceTransparencyAlpha(float3 positionWS){
    float4 playerCS = TransformWorldToHClip(PlayerPosition.xyz);
    float2 playerCS_NDC = (playerCS.xy / playerCS.w) * TransparencyRangeScaleOffset.xy + TransparencyRangeScaleOffset.zw;
    
    float4 positionCS = TransformWorldToHClip(positionWS);
    float2 positionCS_NDC = positionCS.xy / positionCS.w;
    float distance_value = distance(playerCS_NDC, positionCS_NDC);
    
    float alpha = smoothstep( min(TransparencySoft, 1), 1, distance_value / TransparencyRange);
    return saturate(alpha + TransparencyBaseAlpha);
}


float3 Debug(){
    return PlayerPosition.xyz;
}

#endif
