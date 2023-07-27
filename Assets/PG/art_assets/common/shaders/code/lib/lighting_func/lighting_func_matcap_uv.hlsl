#ifndef LIGHTING_FUNC_MATCAP_UV_INCLUDED
#define LIGHTING_FUNC_MATCAP_UV_INCLUDED


half2 MatcapUV(float3 normalWS){
    float2 normalVS = mul(UNITY_MATRIX_V, float4(normalWS, 0)).xy;
    float2 matcap_uv = (normalVS * 0.5 +  float2(0.49, 0.49));
    
    return matcap_uv;
}




#endif
