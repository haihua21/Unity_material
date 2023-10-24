#ifndef KAWASE_BLUR
#define KAWASE_BLUR

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"//函数库：主要用于各种的空间变换

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

float _Scatter;
float4 _MainTex_TexelSize;
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

struct a2v
{
    float4 positionOS:POSITION;
    float2 texcoord:TEXCOORD;
};
struct v2f
{
    float4 positionCS:SV_POSITION;
    float2 texcoord:TEXCOORD;
};

v2f vertex(a2v i)
{
    v2f o;
    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
    o.texcoord = i.texcoord;
    return o;
}

half4 drawhighlights(v2f i):SV_TARGET  //提取高光
{              
    half3 col=SAMPLE_TEXTURE2D_X(_MainTex,sampler_MainTex,i.texcoord); //中心像素
    // half br = max(max(col.r,col.g),col.b);
    half br = Max3(col.r,col.g,col.b);
    // br = max(0.0f,(br - _Threshold)) / max(br,0.00001f);
     half softness = clamp(br - _Threshold + _ThresholdKnee, 0.0, 2.0 * _ThresholdKnee);
     softness = (softness * softness) / (4.0 * _ThresholdKnee + 1e-4);
     half multiplier = max(br - _Threshold, softness) / max(br, 1e-4);
     col *= multiplier;
     col = max(col,0);
    
    return EncodeHDR(col);
}
half4 fragment(v2f i):SV_TARGET   //模糊
{              
    half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord); //中心像素
    //四角像素
    //注意这个【_Scatter】，这就是扩大卷积核范围的参数
    tex+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord+float2(-1,-1)*_MainTex_TexelSize.xy*_Scatter); 
    tex+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord+float2(1,-1)*_MainTex_TexelSize.xy*_Scatter);
    tex+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord+float2(-1,1)*_MainTex_TexelSize.xy*_Scatter);
    tex+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord+float2(1,1)*_MainTex_TexelSize.xy*_Scatter);
    return  EncodeHDR(tex/5.0);
}
half4 fragmentmaintex(v2f i):SV_TARGET   
{              
    half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord); 
    return tex;
}
#endif