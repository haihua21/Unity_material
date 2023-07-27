Shader "Custom/null"
{
    Properties
    {
        _MaskColor("Mask Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "IgnoreProjector" = "True"
        }

        ZWrite Off

        ColorMask 0

        Pass
        {
            Name "Null"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float4 _MaskColor;

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                return float4(0,0,0,1);
            }
            ENDHLSL
        }
    }
}
