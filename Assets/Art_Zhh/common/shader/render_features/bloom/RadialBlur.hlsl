#ifndef RADIAL_BLUR
#define RADIAL_BLUR

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

float4 _MainTex_ST;

struct appdata
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
};
struct v2f
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
};

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

float4 _MainTex_HDR;
float _BloomRange;
int _LoopCount;
float _X;
float _Y;
float _Threshold;
float _ThresholdKnee;


        // Brightness function
        half Brightness(half3 c)
        {
            return max(max(c.r, c.g), c.b);
        }
    
        // 3-tap median filter
        half3 Median(half3 a, half3 b, half3 c)
        {
            return a + b + c - min(min(a, b), c) - max(max(a, b), c);
        }
    
        // Clamp HDR value within a safe range
        half3 SafeHDR(half3 c) { return min(c, 65000); }
        half4 SafeHDR(half4 c) { return min(c, 65000); }
    
        // RGBM encoding/decoding
        half4 EncodeHDR(half3 color)
        {
        #if _USE_RGBM
            half4 outColor = EncodeRGBM(color);
        #else
            half4 outColor = half4(color, 1.0);
        #endif

        #if UNITY_COLORSPACE_GAMMA
            return half4(sqrt(outColor.xyz), outColor.w); // linear to γ
        #else
            return outColor;
        #endif
        }

        half3 DecodeHDR(half4 color)
        {
        #if UNITY_COLORSPACE_GAMMA
            color.xyz *= color.xyz; // γ to linear
        #endif

        #if _USE_RGBM
            return DecodeRGBM(color);
        #else
            return color.xyz;
        #endif
        }


v2f vert(appdata i)
{
    v2f o;
    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
    o.uv = i.uv;
    return o;
}
// half4 frag(v2f i) :SV_TARGET
// {
//     float4 col = 0;
//     float2 dir = (float2(_X,_Y) - i.uv) * _BloomRange * 0.01;

//     for(int t = 0; t < _LoopCount; t++)
//     {
//         col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
//         i.uv += dir; 
//     }
//     return col / _LoopCount;
// }
half4 frag(v2f i) :SV_TARGET
{
    half3 col = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv);
    // half br = max(max(col.r,col.g),col.b);
    half br = Max3(col.r,col.g,col.b);
    // br = max(0.0f,(br - _Threshold)) / max(br,0.00001f);
            half softness = clamp(br - _Threshold + _ThresholdKnee, 0.0, 2.0 * _ThresholdKnee);
            softness = (softness * softness) / (4.0 * _ThresholdKnee + 1e-4);
            half multiplier = max(br - _Threshold, softness) / max(br, 1e-4);
            col *= multiplier;
            col = max(col,0);
    
    return EncodeHDR(col) ;
}


#endif