Shader "code/common/transparent_receive_shadow"
{
    Properties
    {
        _Color ("Shadow Color", Color) = (0.35,0.4,0.45,1.0)
        _Intensity ("ShadowIntensity", Range(0,1)) = 0.6
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent-1"
        }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend DstColor Zero, Zero One
            Cull Back
            ZTest LEqual
            ZWrite Off
 
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _Intensity;
            CBUFFER_END
            struct Attributes
            {
                float4 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float3 positionWS               : TEXCOORD0;
            };
            Varyings vert (Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                return output;
            }
            half4 frag (Varyings input) : SV_Target
            {
                half4 color = half4(1,1,1,1);
                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE)
                    half4 shadowCoord = TransformWorldToShadowCoord(input.positionWS); 
                    Light mainLight = GetMainLight(shadowCoord); 
                    color = lerp(half4(1,1,1,1), _Color, (1.0 - mainLight.shadowAttenuation) * _Intensity);
                #endif
                return color;
            }
            ENDHLSL
        }
    }
}