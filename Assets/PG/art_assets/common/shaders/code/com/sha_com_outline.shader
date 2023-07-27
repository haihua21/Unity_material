Shader "code/common/outline"
{
    Properties
    {
        _Outline ("Outline", Range(0, 1)) = 0.1
        [HDR]_OutlineColor ("Outline Color", Color) = (0,0,0,1)
    }
    
    SubShader
    {
        Pass
        {
            ZTest Always
            ZWrite Off
            Stencil
            {
                Ref 10
                Comp NotEqual
                Pass Keep
                Fail Keep
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half _Outline;
            half4 _OutlineColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };
            
            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 positionVS = TransformWorldToView(TransformObjectToWorld(IN.positionOS.xyz));
                float3 normalVS = TransformWorldToViewDir(TransformObjectToWorldNormal(IN.normalOS));
                normalVS.z = 0.0;

                // 相机 fov 计算公式
                // float t = unity_CameraProjection._m11;
                // const float Rad2Deg = 180 / UNITY_PI;
                // float fov = atan(1.0f / t ) * 2.0 * Rad2Deg;
                // 
                // positionVS.z = 相机空间下顶点离相机的距离
                // 
                positionVS += normalize(normalVS) * _Outline * abs(positionVS.z) / unity_CameraProjection._m11;
                OUT.positionCS = TransformWViewToHClip(positionVS);
                
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }
    }
}
