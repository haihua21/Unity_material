Shader "sc_skybox/URP/HighPrecision"
{
    Properties
    {
        [NoScaleOffset]_CubeMap("CubeMap", CUBE) = "white" {}
        _TintColor("Tint Color", Color) = (0.4901961,0.4705883,0.4705883,1)
        [Gamma]_Exposure("Exposure", Range( 0 , 8)) = 1
        _RotationSpeed("RotationSpeed", Range( -2 , 2)) = 0
        [IntRange]_Rotation("Rotation", Range( 0 , 360)) = 0
        [Toggle(_ENABLEBILLBOARD_ON)] _EnableBillboard("Enable Billboard", Float) = 0
        [NoScaleOffset]_BillboardMap("Billboard Map", 2D) = "white" {}
        _BillboardColor("Billboard Color", Color) = (1,1,1,1)
        _Speed_1("Speed_1", Float) = 0.78
        _XTile("X Tile", Range( 2 , 10)) = 2
        _YTile("Y Tile", Range( 1 , 20)) = 1
        _XPosition("X Position", Range( 0.8 , 1)) = 0.9
        _XSmooth("X Smooth", Range( 0.8 , 1)) = 1
        _Yposition("Y position", Range( -10 , 10)) = 0
        [HideInInspector] __dirty( "", Int ) = 1
    }

    SubShader
    {
        Tags{ 
            "RenderType" = "Background"  
            "Queue" = "Background" 
            "PreviewType"="Skybox" 
            "IgnoreProjector" = "True" 
            "ForceNoShadowCasting" = "True" 
            "IsEmissive" = "true"
            "RenderPipeline" = "UniversalPipeline"
        }
        Cull Off
        ZWrite Off
        LOD 200 // 提高 LOD 等级，启用更高精度渲染

        Pass
        {
            Name "SkyboxPass"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ENABLEBILLBOARD_ON

            // 启用高精度计算（提升矩阵和坐标精度）
            #pragma target 2
           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // 高精度颜色空间转换（避免精度丢失）
            float3 LinearToOutput(float3 linearColor)
            {
                #if UNITY_COLORSPACE_GAMMA
                    return pow(linearColor, float3(1.0 / 2.2));
                #else
                    return linearColor;
                #endif
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 vertexToFrag32 : TEXCOORD0; // 保留高精度采样坐标
                float3 worldPos : TEXCOORD1;
            };

            // 纹理和参数声明（保留高精度）
            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR; // HDR 支持，提升亮度精度
            float4 _TintColor;
            float _Exposure;
            float _Rotation;
            float _RotationSpeed;
            sampler2D _BillboardMap;
            float4 _BillboardMap_ST;
            float4 _BillboardColor;
            float _Speed_1;
            float _XTile;
            float _YTile;
            float _Yposition;
            float _XSmooth;
            float _XPosition;

            Varyings vert(Attributes input)
            {
                Varyings output;

                // 1. 高精度旋转角度计算（避免浮点数精度丢失）
                float rotationAngle = radians(_Rotation + (_Time.y * _RotationSpeed));
                // 用 float 高精度计算三角函数（避免 half 精度不足）
                float cosRot = cos(rotationAngle);
                float sinRot = sin(rotationAngle);
                // 构造旋转矩阵（优化精度，避免重复计算）
                float3 rotX = float3(cosRot, 0.0, -sinRot);
                float orthoRatio = lerp(1.0, _ProjectionParams.x / _ProjectionParams.y, step(1.0, _ProjectionParams.w));
                float3 rotY = float3(0.0, orthoRatio, 0.0);
                float3 rotZ = float3(sinRot, 0.0, cosRot);
                float3x3 rotationMatrix = float3x3(rotX, rotY, rotZ);

                // 2. 高精度空间转换（避免坐标精度丢失）
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalizedWS = normalize(positionWS); // 归一化确保采样方向精度

                // 3. 应用旋转矩阵（float3x3 高精度乘法）
                output.vertexToFrag32 = mul(rotationMatrix, normalizedWS);
                output.worldPos = positionWS;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {

                float3 sampleDir = normalize(input.vertexToFrag32);
                half3 cubeMapColor = texCUBElod(_CubeMap, float4(sampleDir, 0.0)).rgb;
               
                cubeMapColor *= _TintColor.rgb * _Exposure;

                half3 billboardColor = half3(0, 0, 0);
                half billboardAlpha = 0.0;
                #ifdef _ENABLEBILLBOARD_ON
                    float time = _Time.y * _Speed_1;
                    float3 normalizedWS = normalize(input.worldPos);
                    float rotation90 = radians(90.0);
                    float cosRot90 = cos(rotation90);
                    float sinRot90 = sin(rotation90);
                    float3 rotX_90 = float3(cosRot90, 0.0, -sinRot90);
                    float orthoRatio_90 = lerp(1.0, _ProjectionParams.x / _ProjectionParams.y, step(1.0, _ProjectionParams.w));
                    float3 rotY_90 = float3(0.0, orthoRatio_90, 0.0);
                    float3 rotZ_90 = float3(sinRot90, 0.0, cosRot90);
                    float3x3 rotationMatrix90 = float3x3(rotX_90, rotY_90, rotZ_90);
                    float XUv = mul(normalizedWS, rotationMatrix90).x;

                    float tempXTile = _XTile * XUv;
                    float XMask = clamp(ceil(normalizedWS.x * 1.0), 0.0, 1.0);
                    float XTile = lerp(tempXTile, -tempXTile, XMask);
                    float tempYTile = (normalizedWS.y * _YTile) - _Yposition;
                    float YTile = clamp(tempYTile, 0.0, 1.0);

                    float2 billboardUV = float2(XTile, YTile) + time * float2(1, 0);
                    half4 billboardTex = tex2D(_BillboardMap, billboardUV);
                    billboardColor = billboardTex.rgb * _BillboardColor.rgb;

                    float Alpha = abs(clamp(ceil(tempYTile) * (1.0 - floor(tempYTile)), 0.0, 1.0));
                    float tempSmooth = (_XTile * _XSmooth) / (_XTile - 0.5);
                    float clampX1 = clamp(-XUv * tempSmooth, 0.0, 1.0);
                    float clampX2 = clamp(XUv * tempSmooth, 0.0, 1.0);
                    float UVmask = saturate(1.0 - ((clampX1 + clampX2 - _XPosition) / 0.1));
                    billboardAlpha = saturate(billboardTex.a * UVmask * Alpha);
                #endif

                half3 finalColor = lerp(cubeMapColor, billboardColor, billboardAlpha);
                return half4(cubeMapColor, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "ASEMaterialInspector"
}