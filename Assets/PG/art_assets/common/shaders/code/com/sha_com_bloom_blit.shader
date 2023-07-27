Shader "code/common/bloom_blit"
{
    HLSLINCLUDE
    #pragma multi_compile_local _ _USE_RGBM
    #pragma multi_compile _ _USE_DRAW_PROCEDURAL
    
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    
    #define NAN_COLOR half3(0.0, 0.0, 0.0)
    
    TEXTURE2D_X(_SourceTex);
    TEXTURE2D_X(_MainTex);

    float4 _Bloom_Params;

    half3 DecodeHDR(half4 color)
    {
    #if UNITY_COLORSPACE_GAMMA
        color.xyz *= color.xyz; // �� to linear
    #endif

    #if _USE_RGBM
        return DecodeRGBM(color);
    #else
        return color.xyz;
    #endif
    }

    half4 EncodeHDR(half3 color)
    {
    #if _USE_RGBM
        half4 outColor = EncodeRGBM(color);
    #else
        half4 outColor = half4(color, 1.0);
    #endif

    #if UNITY_COLORSPACE_GAMMA
        return half4(sqrt(outColor.xyz), outColor.w); // linear to ��
    #else
        return outColor;
    #endif
    }
    half4 FragFinal(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        half3 blur = DecodeHDR(SAMPLE_TEXTURE2D_X(_SourceTex, sampler_LinearClamp, input.uv));

        blur = blur * _Bloom_Params.x + blur * _Bloom_Params.yzw;

        half3 base = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, input.uv));
        return EncodeHDR(blur + base);
    }

    half4 Frag(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        half3 color = SAMPLE_TEXTURE2D_X(_SourceTex, sampler_PointClamp, UnityStereoTransformScreenSpaceTex(input.uv)).xyz;

        if (AnyIsNaN(color) || AnyIsInf(color))
            color = NAN_COLOR;

        return half4(color, 1.0);
    }
    /*
    Varyings FullscreenVert(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
        output.uv = input.uv;
        return output;
    }*/
    
    ENDHLSL
    
    SubShader
    {
        Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
            LOD 100
            ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "Bloom FinalPass"

            HLSLPROGRAM
                #pragma vertex FullscreenVert
                #pragma fragment FragFinal

            ENDHLSL
        }

        Pass
        {
            Name "Stop NaN"

            HLSLPROGRAM
                #pragma vertex FullscreenVert
                #pragma fragment Frag
            ENDHLSL
        }
    }
}
