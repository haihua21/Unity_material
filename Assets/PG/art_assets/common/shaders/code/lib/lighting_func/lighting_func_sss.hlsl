#ifndef LIGHTING_FUNC_SSS_INCLUDED
#define LIGHTING_FUNC_SSS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


half3 SSS_DiffuseTerm(TEXTURE2D_PARAM(_lut, sampler_lut), half attenuation, half NDotLBase, half sss_mask){
    half a = attenuation * 0.5 + 0.5;
    half b = NDotLBase * 0.5 + 0.5;
    
    float2 lut_uv = float2(a * b, sss_mask);
    half3 lut_color = SAMPLE_TEXTURE2D(_lut, sampler_lut, lut_uv).rgb;
    
    return lut_color;
}


#endif
